--
---- Version 0.4.0
--

local PREFEREDHAND = "right" --default equip hand.
local DEFSTACK = 64 --default stack size.
local CSLOT = 13 --default crafting slot.
local SCAN = false --on walking turtle is storing up, down and forward blocks in tWorld.
local DIG = false --on walking turtle digs it's way through.
local TESTFUELLIMIT = 0.90 --the limit of fuel level when testing a item for fuel.

digF = {["up"] = turtle.digUp, ["forward"] = turtle.dig, ["down"] = turtle.digDown} --original dig functions
movF = {["up"] = turtle.up, ["forward"] = turtle.forward, ["down"] = turtle.down} --original move functions
insF = {["up"] = turtle.inspectUp, ["down"] = turtle.inspectDown, ["forward"] = turtle.inspect} --original inspect functions
dropF = { ["up"] = turtle.dropUp, ["forward"] = turtle.drop, ["down"] = turtle.dropDown } --original drop functions
suckF = {["forward"] = turtle.suck, ["up"] = turtle.suckUp, ["down"] = turtle.suckDown} --original suck functions.
equipF = {["left"] = turtle.equipLeft, ["right"] = turtle.equipRight} --original equip functions
detF = {["up"] = turtle.detectUp, ["down"] = turtle.detectDown, ["forward"] = turtle.detect} --original detect functions
attF = {["up"] = turtle.attackUp, ["down"] = turtle.attackDown, ["forward"] = turtle.attack} --original attack functions
plaF = {["up"] = turtle.placeUp, ["down"] = turtle.placeDown, ["forward"] = turtle.place} --original place functions

dirType = {["forward"] = 0, ["right"] = 1, ["back"] = 2, ["left"] = 3, ["up"] = 4, ["down"] = 8} --moving direction options
function isDirType(sDir)
	return dirType[sDir]
end

lookingType = {["forward"] = 0, ["up"] = 4, ["down"] = 8} --where is the turtle looking, it can't look to the sides or back.
function isLookingType(sLook)
	return lookingType[sLook]
end

facingType = {["z-"] = 0, ["x+"] = 1, ["z+"] = 2, ["x-"] = 3, ["y+"] = 4, ["y-"] = 8} --axis type values
function isFacingType(sFacing)
	return facingType[sFacing]
end

carDirType = {["north"] = 0, ["east"] = 1, ["south"] = 2, ["west"] = 3} --cardinal directions
function isCarDirType(sCar)
	return carDirType[sCar]
end

negOrient = {["forward"] = "back", ["right"] = "left", ["back"] = "forward", ["left"] = "right", ["up"] = "down", ["down"] = "up", ["z+"] = "z-", ["z-"] = "z+", ["x+"] = "x-", ["x-"] = "x+", ["y+"] = "y-", ["y-"] = "y+", [0] = 2, [2] = 0, [1] = 3, [3] = 1, ["north"] = "south", ["south"] = "north", ["east"] = "west", ["west"] = "east"}

tTurtle = { ["x"] = 0, ["y"] = 0, ["z"] = 0, --coords for turtle
          facing = facingType["z-"], --the axis where the turtle is facing at
          looking = lookingType["forward"],
          leftHand = "empty",
          rightHand = "empty",
} 

tRecipes = {} --[[ ["Name"][index]["recipe"] = {{"itemName"}, {"itemName", nCol = nColumn, nLin = nLine}, ...}
                   ["Name"][index]["count"] = resulting number of items}
                   ["lastRecipe"] = sLastRecipe
                   ["CSlot"] = Crafting slot.
                   ["lastIndex"] = last recipe index]]

tEnts={["unknown"]=nil, ["unreachable"]=-1, ["empty"]=0, ["next"]=1} --table entity 20-07-2022                   
tStacks = {} --["itemName"] = nStack
tFuel = {} --[itemName] = quantity of fuel 15-10-2022
tRevEnts={[-1]="unreachable", [0]="empty"} --table for reverse lookup table entity 20-07-2022
tWorld = {} --[x][y][z] = nEnt
tSpots = {} --[sSpotName]={x, y, z, nFacing}

------ Events ------

local tInv = {
	bChanged = false, --if a inventory slot has changed
	tSlots, --wich slot has changed tSlots[nSlot] = {name, count}
	tLastInv, --snapshot of last inventory (before it changed)
  bTerminate, --if the handling is to be terminated
}

function tInv.init() --[[ Initializes the handlind of the event turtle_inventory.
  20-05-2023 v0.4.0
  Returns: true
  Sintax: tInv.init()
  Dependencies: getInventory]]

    tInv.bChanged = false
    tInv.bTerminate = false
    tInv.tLastInv = getInventory()
    parallel.waitForAny(HandleInvChange, TEST)
    return true
end

function tInv.terminate() --[[ Terminates the handlind of the event turtle_inventory.
  20-05-2023 v0.4.0
  Returns: true
  Sintax: tInv.terminate()]]

    tInv.bTerminate = true
    os.queueEvent("turtle_inventory")
    return true
end

function HandleInvChange() --[[ Function to handle the event turtle_inventory.
  20-05-2023 v0.4.0
  Returns: true
  Sintax: HandleInvChange()
  Dependencies: getInventory, cmpInventory]]

    while true do
        os.pullEvent("turtle_inventory")
        if tInv.bTerminate then return true, "Handle turtle inventory change terminated." end
        tInv.bChanged = true
        local inv2 = getInventory()
        local _, tDif = cmpInventory(tInv.tLastInv, inv2)
        tInv.tLastInv = inv2
        if tDif then tInv.tSlots = tDif
				else tInv.tSlots = false
				end
    end
end


------ Spots ------

function saveSpots() --[[ Saves table tSpots in text file tSpots.txt
  05-08-2022 v0.4.0]]
  return saveTable(tSpots,"tSpots.txt")
end

function loadSpots() --[[ Loads from file tSpots.txt to table tSpots
  05-08-2022 v0.4.0
  Dependencies: loadTable, isDicEmpty]]
  
  local t = loadTable("tSpots.txt")
	if not t then return false,"Can't load tSpots.txt"
  elseif t and isDicEmpty(t) then return false, "File tSpots.txt is empty."
  end
  tSpots = t
  return true
end

function incSpotName() --[[ Increments the name of the next spot
  04/03/2026 v0.4.0 ]]

  counter = string.sub(tSpots.sNextSpot, 5)
  counter = tonumber(counter)
  counter = counter + 1
  SpotStr = ""
  if counter < 100 then SpotStr = "Spot0" end
  if counter < 10 then SpotStr = "Spot00" end
  tSpots.sNextSpot = SpotStr..tostring(counter)
  return true
end

function setSpot(sSpotName, x, y, z, nFacing) --[[ Sets a spot in tSpots table.
  05-08-2022 v0.4.0
  Param: sSpotName - string the name of the spot.
           x, y, z - coords of spot.
           nFacing - the direction in that spot.
  Returns: sSpotName - if spot was set with success.
  Sintax: setSpot([sSpotName][, x, y, z, nFacing]=tTurtle)
  ex: setSpot("minecraft:cobblestone", 10,3,5, 0) - cobblestone at coords (10,3,5) facing z- ]]

  if not sSpotName then
    sSpotName = tSpots.sNextSpot
    incSpotName()
  elseif isNumber(sSpotName) then
    z = y
    y = x
    x = sSpotName
    sSpotName = tSpots.sNextSpot
    incSpotName()
  end
  if not x then
    x = tTurtle.x
    y = tTurtle.y
    z = tTurtle.z
    nFacing = tTurtle.facing
  end
  tSpots[sSpotName] = {["x"] = x, ["y"] = y, ["z"] = z, ["facing"] = nFacing}
  return sSpotName
end

function getSpot(sSpotName) --[[ Gets the spot.
  06-082022 v0.4.0
  Param: sSpotName - string the name of the spot to get the data from.
  Returns: table with spot - {x,y,z,facing}
  Sintax: getSpot(sSpotName)]]
  
  return tSpots[sSpotName]
end

function goToSpot(sSpotName) --[[ Turtle walks to the spot coords, and turns to spot facing.
  22-09-2022 v04.0
  Param: sSpotName - string the name of the spot.
  Returns: true - if it goes all the way to the spot.
           false - if it couldn't get there.
           nil - if the spotname was not found.
  Sintax: goToSpot(sPotName)
  Dependencies: getSpot, goTo, turnTo]]
  
  local tSpot = getSpot(sSpotName)
  if not tSpot then return nil, "Spot name not found." end
  if not goTo(tSpot.x, tSpot.y, tSpot.z) then return false, "Couldn't get there." end
  turnTo(tSpot.facing)
  return true
end

function listSpots() --[[ Gets a list of all the spots in tSpots.
  22-03-2026 v0.4.0
  Returns: table with all spots.
  Sintax: listSpots()]]

  tList = {}
  for sName, tSpot in pairs(tSpots) do
    if type(tSpot) == "table" then
      tList[sName] = sName
    end
  end
  return tList
end

function removeSpot(sSpotName) --[[ Removes the sSpotName spot, from tspots.
  19-04-2026 v04.0
  Param: sSpotName - string the name of the spot.
  Returns: true - if it was removed.
            nil - if no spotname was supplied.
          false - if spotname was not found.
  Sintax: removeSpot(sPotName) ]]

  if not sSpotName then return nil, "removeSpot(SpotName) - You must supply the spot name." end
  if tSpots[sSpotName] then tSpots[sSpotName] = nil
  else return false, "Spot not found."
  end
  return true
end

------ World ------

function setWorldEnt(x, y, z, nEnt) --[[ Set world coords containing nEnt.
  24-07-2022 v0.4.0
  Param: x, y, z - numbers world coords.
            nEnt - id of the entity from entGetId(sBlockName).
  Returns: true
  Sintax: setWorldEnt(x, y, z, nEnt)]]

  if not tWorld[x] then tWorld[x] = {} end
  if not tWorld[x][y] then tWorld[x][y] = {} end
  tWorld[x][y][z] = nEnt
  return true
end

function getWorldEnt(x, y, z) --[[ Gets the entity at coords x,y,z.
  24-07-2022 v0.4.0
  Param: x, y, z - numbers world coords.
  Returns: number the id of the block in that coords.]]

  if not tWorld[x] then return nil end
  if not tWorld[x][y] then return nil end
  return tWorld[x][y][z]
end

function saveWorld() --[[ Saves tWorld into tWorld.txt
  24-07-2022 v0.4.0
  Returns: the same as the saveTable function.
  Dependencies: saveTable]]
  
  return saveTable(tWorld,"tworld.txt")
end

function loadWorld() --[[ Loads tWorld.txt into tWorld table.
  24-07-2022 v0.4.0
  Returns: true - if success.
          false - if it couldn't load file "tworld.txt".
  Dependencies: loadTable, isDicEmpty]]
  
  local t = loadTable("tWorld.txt")
	if not t then return false,"Can't load tWorls.txt"
  elseif t and isDicEmpty(t) then return false, "File tWorld.txt is empty."
  end
  tWorld = t
  return true
end

function getNearestBlock(sBlock, nAmp) --[[ Gets the coords of the nearest block.
  15-09-2022
  Param: sBlock - string, number or table name of block.
           nAmp - radius of scan.
  Sintax: getNearestBlock([sBlock="unknown"][, nAmp = 10])
  Return: x,y,z, nID - coords of nearest block and its id.
          false - If then block name was not found in tWorld.
          nil - if the block name, was never scanned, is not in database.
  Note: if sBlock = "any" it returns the nearest block.
        if sBlock = "empty" or 0 it returns the nearest empty space.
        if sBlock = "unreachable" or -1 it returns the nearest block space marked as unreachable.
        if sBlock = "unknown" or nil it returns the first unscanned block space.
        if sBlock = getAllFuelItems() gets the nearest fuel block.
  ex: getNearestBlock({"minecraft:cobblestone", "minecraft:oak_log"}) - returns coords and id of the nearest cobblestone or oak_log.
  Dependencies: getCoords, getWorldEnt]]

  nAmp = nAmp or 10
	local nBlock
	if type(sBlock) == "string" then
		if tEnts[sBlock] then nBlock = tEnts[sBlock]
    elseif sBlock ~= "any" then
			return nil, 'getNearestBlock([sBlock="unknown"][, nAmp=10]) - block name not in database.'
    end
	elseif type(sBlock) == "number" then nBlock = sBlock
  end

	local x, y ,z = getCoords()
  local nID
	for amp = 1, nAmp do
		for dx = -amp, amp do
			for dy = -amp, amp do
				for dz = -amp, amp do
					local tx, ty, tz = x+dx, y+dy, z+dz
					local nID = getWorldEnt(tx, ty, tz)
					if type(sBlock) == "table" then
						for k,v in pairs(sBlock) do
              if type(k) == "number" then k = v end
							if tEnts[k] then 
								if nID == tEnts[k].id then return tx, ty, tz, nID end
						  end
            end
					elseif sBlock == "any" then
						if (nID ~= nil) and (nID ~= 0) then return tx, ty, tz, nID end
					elseif nID == nBlock then return tx, ty, tz, nID
					end
				end
			end
		end
	end
	return false, "Block not found in the world."
end

function worldFindBlock(sBlock) --[[ Gets the coords for sBlock in tWorld.
  19-01-2023 v0.4.0
  Param: sBlock - string name of block to search
  Return: table with coords (x,y,z)
  Sintax: worldFindBlock(sBlock)
  Ex: worldFindBlock("minecraft:cobblestone") - find coords of "minecraft:cobblestone" in tWorld]]

	local tRetBlocks = {}
	for kx, vx in pairs(tWorld) do
		for ky, vy in pairs(tWorld[kx]) do
			for kz, vz in pairs(tWorld[kx][ky]) do
				if tRevEnts[ tWorld[kx][ky][kz] ] == sBlock then
					tRetBlocks[#tRetBlocks+1] = {kx, ky, kz}
				end
			end
		end
	end
	return tRetBlocks
end


------ Entity ------

function entAdd(sEntName) --[[ Adds a entity name to table ent.
  21-07-2022 v0.4.0
  Param: sEntName - string name of entity.
  Returns: number - entity id
           nil - if not sEntName not supplied.
               - if sEntName is not a number.
  Sintax: entAdd(sEntName)
  Note: if entity already exists, it returns the existing one.
  ex: entAdd("minecraft:cobblestone") - it returns tEnts.next or the existing tEnt["minecraft:cobblestone"] ]]

  if not sEntName then return nil, "entAdd(EntName) - Must supply entity name." end
	if type(sEntName) ~= "string" then return nil, "entAdd(EntName) - Entity name must be a string." end
	if tEnts[sEntName] then return tEnts[sEntName].id end
	tEnts[sEntName] = {}
  tEnts[sEntName].id = tEnts.next
	tRevEnts[tEnts.next] = sEntName
	tEnts.next = tEnts.next + 1
	return tEnts.next-1
end

function entAddInv() --[[ Adds all the inventory items to tEnts.
  24-07-2022 v0.4.0
  Returns: true, number quantity of entities added.
          false, if no entities added.
  Dependencies: entGetId, entAdd]]

  local nTotAdded = 0
  for nSlot = 1, 16 do
    local tData = turtle.getItemDetail(nSlot)
    if tData then
      if not entGetId(tData.name) then
        entAdd(tData.name)
        nTotAdded = nTotAdded + 1
      end
    end
  end
  if nTotAdded == 0 then  return false
  else return true, nTotAdded
  end
end

function entAddSlot(nSlot) --[[ Adds item in nSlot to tEnts.
  24-07-2022 v0.4.0
  Param: nSlot - number of slot where is the item to add.
  Return: number the id of the item in nSlot.
          nil - if nSlot is not a number.
              - if nSlot is not in range[1..16] 
          false - if nslot is empty.
  Sintax: entAddSlot([nSlot = selected slot])
  ex: entAddSlot(1) - adds the item in slot 1 to table tEnts
  Dependencies: isInRange, entAdd]]

  nSlot = nSlot or turtle.getSelectedSlot()
  if type(nSlot) ~= "number" then return nil, "entAddSlot(Slot) - Slot must be a number." end
  if not isInRange(nSlot,{1,16}) then return nil, "entAddSlot(Slot) - Slot must be between 1 and 16" end
  local tData = turtle.getItemDetail(nSlot)
  if not tData then return false, "Empty Slot." end
  return entAdd(tData.name)
end

function entGetSlotId(nSlot) --[[ Gets or adds the nSlot item tEnts.
  24-07-2022 v0.4.0
  Alias for entAddSlot()
  Dependencies: entAddSlot]]
  
  return entAddSlot(nSlot)
end

function isEnt(sEntName) --[[ Alias for entGetId()
  26-03-2024 V0.4.0
  Alias for entGetId(sEntName)]]

  return entGetId(sEntName)
end

function entGetId(sEntName) --[[ Gets the entity id.
  21-07-2022 v0.4.0
  Param: sEntName - string the entity name.
  Returns: number - the entity id.
           false - the entity name was not found.
           nil - the entity name was not supplied.
               - the entity name was not a string.
  Sintax: entGetId(sEntName)
  ex: entGetId("minecraft:stick") - it returns a number, the id.]]

  if not sEntName then return nil, "entGetId(EntName) - Entity name must be supplied." end
	if type(sEntName) ~= "string" then return nil, "entGetId(EntName) - Ent name must be a string." end
	if tEnts[sEntName] then return tEnts[sEntName].id end
	return false
end

function entGetName(nId) --[[ Gets the entity name.
  21-07-2022 v0.4.0
  Param: nId - number the id of the entity to get the name.
  Returns: string - the name of the entity.
            false - if nId was not found.
              nil - if nId was not supplied.
                  - if nId is not a number
  Sintax: entGetName(nId)
  ex: entGetName(1) - gets the intity name witch has 1 for id.]]

  if not nId then return nil, "entGetName(Id) - The id of the entity must be supplied." end
	if type(nId) ~= "number" then return nil, "entGetName(Id) - The id of the entity must be a number." end
	if tRevEnts[nId] then return tRevEnts[nId] end
	return false
end

function saveEnt() --[[ Saves table tEnts into tEnts.txt file.
  21-07-2022 v0.4.0
  Returns: the same as saveTable
  Sintax: saveEnt()
  ex: saveEnt()
  Dependencies: saveTable]]

  return saveTable(tEnts, "tEnts.txt")
end

function loadEnt() --[[ Loads tEnts.txt into table tEnts.
  21-07-2022 v0.4.0
  Returns: true - if it loaded the file.
          false - if it couldn't load the file.
  Sintax: loadEnt()
  ex: loadEnt()
  Dependencies: loadTable, isDicEmpty]]

  local t = loadTable("tEnts.txt")
	if not t then return false,"Can't load tEnts.txt"
  elseif t and isDicEmpty(t) then return false, "File tEnts.txt is empty."
  end
	tEnts = t
  return true
end

function saveRevEnt() --[[ Saves tRevEnts into tRevEnts.txt file.
  21-07-2022 v0.4.0
  Returns: same as saveTable
  Sintax: saveRevEnt()
  ex: saveRevEnt()
  Dependencies: saveTable]]

  return saveTable(tRevEnts, "tRevEnts.txt")
end

function loadRevEnt() --[[ Loads tRevEnts.txt into tRevEnts table.
  21-07-2022 v0.4.0
  Returns: true - if could load tRevEnts.txt
          false - if couldn't load file tRevEnts.txt
  Sintax: loadRevEnt()
  ex: loadRevEnt()
  Dependencies: loadTable, isDicEmpty]]

  local t = loadTable("tRevEnts.txt")
	if not t then return false,"Can't load tRevEnts.txt"
  elseif t and isDicEmpty(t) then return false, "File tRevEnts.txt is empty."
  end
	tRevEnts = t
  return true
end


------ FUEL FUNCTIONS ------

function getAllFuelItems()  --[[ Gets a table with all fuel items.
16-11-2022 v0.4.0
Returns: tItems[sItemName] - quantity of fuel. ]]

  local tItems = {}
  for k, v in pairs(tEnts) do
    if type(tEnts[k]) == "table" and tEnts[k].fuel and tEnts[k].fuel > 0 then
      tItems[k] = tEnts[k].fuel
    end
  end
  return tItems
end

function getFuel(sItem) --[[ Get the fuel for sItem.
  30-10-2022 v0.4.0
  Param: sItem - string name of item to get fuel quantity.
  Sintax: getFuel([sItem = selected slot item name])
  Return: number - quantity of fuel from sItem.
          false - if item was not tested
  ex: getFuel("minecraft:cobblestone") - returns 0 or "Item not tested" if was not tested.
      getFuel() - gets the fuel from item in selected slot.
  Dependencies: getItemName]]

  sItem = sItem or getItemName()
  if sItem == "" then return false, "getFuel([Item Name=selected slot]) - empty selected slot." end
	if tEnts[sItem] and tEnts[sItem].fuel then return tEnts[sItem].fuel end
  return false, "Item not tested."
end

function setFuel(sItem, nQFuel) --[[ Sets tEnts[sItem].fuel to nQFuel.
  04/11/2022 v0.4.0
  Param: sItem - item name.
        nQFuel - quantity of fuel given by item.
  Return: true - if tEnts was set
           nil - if sItem or nQFuel not supplied.
  Sintax: setFuel(sItem, nQFuel)
  ex: setFuel("minecraft:cobblestone", 0) - sets cobblestone to give 0 fuel.
  Dependencies: checkNil, addFuel]]
  
	if checkNil(2, sItem, nQFuel) then
		return nil, "setFuel(sItem, nQFuel) - Item name and fuel quantity must be supplied."
	end
  if not tEnts[sItem] then return addFuel(sItem, nQFuel) end
	tEnts[sItem].fuel = nQFuel
	return true
end

function addFuel(sItem, nQFuel) --[[ Sets tEnts[sItem].fuel to nQFuel.
  21-11-2022 v0.4.0
  Param: sItem - name of item to set fuel.
        nQFuel - quantity of fuel sItem have.
  Sintax: addFuel(sItem, nQFuel)
  Note: if sItem is not in tEnts, adds it.
  Returns: true
  Dependencies: entAdd, setFuel]]

	local success, message = entAdd(sItem)
  if not success then return success, message end
	
  success, message = setFuel(sItem, nQFuel)
	if not success then return success, message end
	return true
end

function getFuelSlot(nSlot) --[[ Gets the quantity of fuel given by item in nSlot.
  30-10-2022 v0.4.0
  Param: nSlot - number of slot where is the item to get the fuel from.
  Return: number - quantity of fuel given by item.
             nil - if nSlot is not a number.
                 - if nSlot is not in range [1..16]
           false - if nSlot is empty.
                 - if item was never tested for fuel.
  Sintax: getFuelSlot([nSlot = selected slot])
  ex: getFuelSlot() - gets quantity of fuel given by item in selected slot.
  Dependencies: isInRange]]

  nSlot = nSlot or turtle.getSelectedSlot()
  if type(nSlot) ~= "number" then return nil, "Invalid Slot type, must be a number." end
  if not isInRange(nSlot, {1,16}) then return nil, "Slot out of range [1..16]" end
  local tData = turtle.getItemDetail(nSlot)
  if not tData then return false, "Empty slot." end
  if tEnts[tData.name] and tEnts[tData.name].fuel then return tEnts[tData.name].fuel end
  return false, tData.name.." - Item not tested"
end

function fuelTestSlot(nSlot) --[[ Test the item in nSlot for fuel.
  30-10-2022 v0.4.0
  Param: nSlot - number of slot to test.
  Return: nFuel - the fuel that this item gives.
            nil - if the nSlot is out of range [1..16]
          false - if the turtle doesn't need fuel.
                - if the fuel level is above 90% in the turtle.
                - if the slot is empty.
  Note: it consumes 1 item if it is fuel and have not been tested.
  Sintax: fuelTestSlot([nSlot = selected slot])
  ex: fuelTestSlot() - test the selected slot for fuel.
  Dependencies: isInRange, addFuel]]

  if type(turtle.getFuelLimit()) ~= "number" then return false, "Turtle doesn't need fuel." end

  if nSlot then
		if not isInRange(nSlot, {1,16}) then return nil, "fuelTestSlot(nSlot) - nSlot must be [1..16]" end
		turtle.select(nSlot)
  end

  local tData = turtle.getItemDetail()
  if not tData then return false, "fuelTestSlot(nSlot) - Empty slot." end
  if tEnts[tData.name] and tEnts[tData.name].fuel then return tEnts[tData.name].fuel end

	if turtle.getFuelLevel() > turtle.getFuelLimit()*TESTFUELLIMIT then
    return false, "Fuel is near the maximum, couldn't test item."
  end --fuel is near maximum, can't test for fuel
	
  local nIFuel = turtle.getFuelLevel() --initial fuel
	turtle.refuel(1) --test 1 entity
	
  local nFuel = turtle.getFuelLevel() - nIFuel --get fuel given by entity
	 
	if tData then addFuel(tData.name, nFuel) end
  return nFuel
end

function getInvFuel() --[[ Gets the total fuel in inventory.
  31-10-2022 v0.4.0
  Return: number - the total fuel in inventory.
  Note: it consumes 1 item if it is fuel and have not been tested.
  Sintax: getInvFuel()
  Dependencies: getFuel, fuelTestSlot]]

	local nTotFuel = 0
	for nSlot = 1, 16 do
		local tData = turtle.getItemDetail(nSlot)
    local nFuel
		if tData then
			nFuel = getFuel(tData.name)
			if nFuel then nTotFuel = nTotFuel + nFuel * tData.count
      else
        nFuel = fuelTestSlot(nSlot)
			  if nFuel then nTotFuel = nTotFuel + nFuel * (tData.count - 1) end
      end
		end
	end
	return nTotFuel
end

function checkFuel(...) --[[ Checks if the fuel is enough.
  29/06/2022 v0.4.1
  Param: ... - number of turtle moves.
             - coords where to go (x, y, z).
  Returns:	true, number remaining fuel - if the fuel is enough.
					 false, negative number missing fuel - if the fuel is not enough.
           nil - if parameters are not numbers.
               - if quantity of parameters are not 1 or 3.
  Note: returns turtle.getFuelLevel() - if no parameters.
	sintax: checkFuel([nActions/x,y,z])
  ex: checkFuel(123) - checks if turtle has enough fuel to move 132 steps.
      checkFuel() - returns turtle.getFuelLevel()
      checkFuel(10, 20, 45) - checks if fuel is enough to go to coords (10, 20, 45).]]
  arg = {...}
  if type(turtle.getFuelLimit()) == "string" then return true end
  if #arg == 0 then return turtle.getFuelLevel() end

  local nActions = 0
  local tIndex = {"x", "y", "z"}
  if #arg == 1 then 
    if type(arg[1]) ~= "number" then
      return nil, "checkFuel([Actions|x, y, z]) - Actions or coords must be numbers."
    else
      nActions = nActions + arg[1]
    end
  elseif #arg == 3 then
    for iArg = 1, 3 do
      if type(arg[iArg]) ~= "number" then
        return nil, "checkFuel([Actions|x, y, z]) - Actions or coords must be numbers."
      else
        nActions = nActions + math.abs(tTurtle[tIndex[iArg]] - arg[iArg])
      end
    end
  else return nil, "checkFuel([Actions|x, y, z]) - Invalid number of parameters."
  end
  local nDif = turtle.getFuelLevel() - nActions
  if nDif > 0 then return true, nDif
  else return false, nDif
  end
end

function isFuelEnoughTo(x, y, z) --[[ Checks if the fuel is enough to go to x,y,z
  21-07-2022 v0.4.0
  Param: x, y, z (numbers) - coords of the point where to go.
  Returns: checkFuel(...)
  Sintax: isFuelEnoughTo(x, y, z) alias for checkFuel(x,y,z)
  ex: isFuelEnoughTo(10, 20, 50) - checks if there is enough fuel to go to (10, 20, 50)
			isFuelEnoughTo(10) - checks if turtle has fuel for 10 move functions.]]

  return checkFuel(x, y, z)
end

function getSlotsToFuel(nFuel) --[[ Gets the quantity of items in each slot to fuel nFuel.
  29-11-2022 v0.4.0
  Param: nFuel - number quantity of fuel to search in slots.
  Sintax: getSlotsToFuel([nFuel=fuel limit-fuel level])
  Return: number, table{{nQ, slot},} - total fuel available, table with slot, quantity of items, needed to fuel.
  ex: getSlotsToFuel() - gets total of fuel, and table with slots and quantity to full up turtle.
      getSlotsToFuel(100) - gets total fuel available, and the table with slots and quantity needed to fill up 100 fuel.
  Dependencies: getInvFuelItems]]

  if type(turtle.getFuelLimit()) == "string" then
    return false, "Turtle doesn't need fuel"
  end

  local nNeedFuel = turtle.getFuelLimit() - turtle.getFuelLevel()
  if nNeedFuel == 0 then
    return false, "Turtle is at maximum fuel."
  end

  nFuel = nFuel or nNeedFuel
  if type(nFuel) ~= "number" then
    return nil, "getSlotsToFuel(Fuel) - Fuel must be a number > 0."
  end

  if nFuel <= 0 then return nil, "getSlotsToFuel(Fuel) - Fuel must be > 0."  end

  local tSlots, sMess = getInvFuelItems()
  if not tSlots then return false, sMess end

  local totFuel, tQ = nFuel
  for i, itFuel in pairs(tSlots) do
    local nQ = math.floor(nFuel / itFuel.fuel)
    if nQ > itFuel.nQ then nQ = itFuel.nQ end
    if nQ > 0 then
      if not tQ then tQ = {} end
      tQ[#tQ+1] = {slot = itFuel.slot, nQ = nQ}
      nFuel = nFuel - (nQ * itFuel.fuel)
      if nFuel <= 0 then break end
    end
  end
  return totFuel-nFuel, tQ
end

function getInvFuelItems() --[[ Gets the inventory slots and items that are fuel.
  29-11-2022 v9.4.0 
  Return: table in decrescent order by fuel, with slot, name, fuel, quantity
          false - if the turtle doesn't need fuel.
                - if the fuel level is above 90% in the turtle.
  Dependencies: getFuel, fuelTestSlot]]

  local tFuelItems --tFuelItems = {nSlot, sName, nFuel, nQ} - slot, fuel, and quantity of items
  for iSlot = 1, 16 do
    local tData = turtle.getItemDetail(iSlot)
    local nFuel, sMess
    if tData then
      nFuel = getFuel(tData.name)
      if not nFuel then
        nFuel, sMess = fuelTestSlot(iSlot)
        if not nFuel then return false, sMess end
        tData.count = tData.count - 1
      end
      if nFuel > 0 then
        if not tFuelItems then tFuelItems = {} end
        tFuelItems[#tFuelItems+1] = {slot = iSlot, name = tData.name, fuel = nFuel, nQ = tData.count}
      end
    end
  end
  table.sort(tFuelItems, function(a, b) return a.fuel > b.fuel end)
  return tFuelItems
end

function refuelItems(sItemName, nCount) --[[ Refuels the turtle with nCount items or fuel from inventory.
  23/09/2021 v0.4.0
  Param: sItemName - name of the item.
            nCount - number of items.
  Returns:	number of items refueled, fuel level.
						false	- "Turtle doesn't need fuel."
									- "Turtle is at maximum fuel."
                  - "Couldn't find item name."
                  - "Empty selected slot."
                  -	"Item is not fuel."
	sintax: refuelItems([sItemName = Selected slot item name][,nCount=nItems in selected slot])
  ex: refuelItems(123) - Fuels the turtle with 123 items.
  Dependencies: getParam, selectItem]] 
  
	if type(turtle.getFuelLimit()) == "string" then return false, "Turtle doesn't need fuel." end
	if turtle.getFuelLevel() == turtle.getFuelLimit() then return false, "Turtle is at maximum fuel." end
	
  sItemName, nCount = getParam("sn", {"", -1}, sItemName, nCount)

	local tData
	if sItemName ~= "" then
    if not selectItem(sItemName) then return false, "Couldn't find item name." end
  end

  tData = turtle.getItemDetail()
  if not tData then return false, "Empty selected slot." end
  if not turtle.refuel(0) then return false, "Selected Item is not fuel." end

	if nCount == -1 then nCount = tData.count end

	totRefuel = 0
	while totRefuel < nCount do
		if tData.count >= nCount then
			turtle.refuel(nCount)
			totRefuel = totRefuel + nCount
		else	turtle.refuel()
				totRefuel = totRefuel + tData.count
				if not selectItem(tData.name) then break end
		end
	end
	return totRefuel, turtle.getFuelLevel()
end


------ EQUIP ------

function getFreeHand(sHand) --[[ Gets turtle free hand: "right"|"left"|false.
  23/09/2021 v0.4.0
  Returns:	"right" or "left" the first free hand found.
	          false - if no free hand found.
              nil - if invalid hand.
  Sintax: getFreeHand([sHand=PREFEREDHAND])
  ex: getFreeHand() - Return the first free hand referenced from PREFEREDHAND and then the other hand, or false.
  Dependencies: getKey]] 

  sHand = sHand or PREFEREDHAND
  sHand = string.lower(sHand)

  local tHands = {["right"] = 0, ["left"] = 1}
  if tHands[sHand] then
    if tTurtle[sHand.."Hand"] == "empty" then return sHand end
    sHand = getKey(bit32.bxor(tHands[sHand], 1), tHands)
    if tTurtle[sHand.."Hand"] == "empty" then return sHand end
  else return nil, "getFreeHand(Hand) - Hand must be left or right"
  end
	return false
end

function equip(sSide) --[[ Equip tool from the selected slot.
  23/09/2021 v0.4.0
  Param: sSide - String: "left"|"right"
  Returns:	true - if it was equiped.
	  				false - "Invalid side."
									- "Empty selected slot."
									- if it can't equip tool.
	sintax: equip([Side=first free hand(left|right)])
  ex: equip() - Try to equip tool in the selected slot to one free hand.
  Dependencies: getFreeHand, isValue]] 
  
	sSide = sSide or getFreeHand()
  sSide = string.lower(sSide)
  if not isValue(sSide, {"left", "right"}) then return false, 'equip([Side=free hand]) - Invalid side("left"|"right").' end
	local tData
	
	tData = turtle.getItemDetail()
	if not tData then return false, "Empty selected slot." end
	
	local success, reason = equipF[sSide]()
	if not success then return success, reason end
	tTurtle[sSide.."Hand"] = tData.name
	return true
end

function unequip(sHand) --[[ Equips a tool in sHand.
  13-07-2023 v0.4.0
  Param: sHand - string: "left"|"right"
  Returns: true - if tool was equiped.
           false - if sHand is invalid.
                 - if turtle doesn't have a empty slot to unequip tool.
  Sintax: unequip([sHand = PREFEREDHAND])
  ex: unequip() - try to unequip the PREFEREDHAND.
  Dependencies: isEmptySlot, getFreeSlot]]
  
  sHand = sHand or PREFEREDHAND
  sHand = string.lower(sHand)
  
  if not equipF[sHand] then return nil, 'unequip(Hand) - Invalid hand "left"|"right".' end

  if not isEmptySlot() then
    local nSlot = getFreeSlot()
    if not nSlot then return false, "No empty slot to unequip." end
    turtle.select(nSlot)
  end

  if equipF[sHand]() then
    tTurtle[sHand.."Hand"] = "empty"
    return true
  end

  return false
end

------ TURTLE ------

function saveTurtle() --[[ Saves tTurtle to file tTurtle.txt.
  23/09/2021 v0.2.0
  Returns:	true - if it could save the file.
	         false - if it couldn't save file.
  ex: saveTurtle()
  Dependencies: saveTable]] 
  
  local success, reason = saveTable(tTurtle, "tTurtle.txt")
  if success then return success end
  return false, reason
end

function loadTurtle() --[[ Loads tTurtle from file tTurtle.txt.
  23/09/2021 v0.2.0
  Returns:	true - if it could load the file to tTurtle.
	      		false - if it couldn't load file.
  ex: turtleLoad()
  Dependencies: loadTable, isDicEmpty]] 
  
  local t = loadTable("tTurtle.txt")
  if not t then return false,"Can't load tTurtle.txt"
  elseif t and isDicEmpty(t) then return false, "File tTurtle.txt is empty."
  end
	tTurtle = t
  return true
end


------ INIT ------

function INIT() --[[ Loads files to tables, so that the turtle won't forget what it has learned.
  02/11/2021 v0.4.0
  Returns:	true
  Dependencies: loadEnt, loadRevEnt, loadWorld, loadTurtle, loadRecipes, loadSpots, tInv.init]]
  
  loadEnt()
  loadRevEnt()
  loadWorld()
	loadTurtle()
	loadRecipes()
  loadSpots()
  tSpots.sNextSpot = "Spot000" --Name of next spot
  tInv.init()  --must be the last instruction
end


------ TERMINATE ------

function TERMINATE() --[[ Saves tTurtle, tRecipes to text files.
  02/11/2021 v0.4.0
  Returns:	true
  Dependencies: tInv.terminate, saveEnt, saveRevEnt, saveWorld, saveTurtle, saveRecipes, saveSpots]]
  tInv.terminate()
  saveEnt()
  saveRevEnt()
  saveWorld()
	saveTurtle()
	saveRecipes()
  saveSpots()
	return true
end


------ TURTLE STATUS FUNCTIONS ----

function setFacing(sFacing) --[[ Sets tTurtle.facing.
  02/10/2021 v0.2.0
  Param: sFacing - "north"|"east"|"south"|"west"|"z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3
  Sintax: setFacing(sFacing)
  Returns:  number - tTurtle.facing
             false - if no parameter was supplied.
                   - if sFacing is not in facingType.
                   - if sFacing is not a string.
  ex: setFacing("z+") - Sets the tTurtle.facing to "z+"=2]]
  
  if not sFacing then return false, 'setFacing(Facing) - Must supply facing ("north"|"east"|"south"|"west"|"z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3).' end
  if type(sFacing) == "number" then
    sFacing = bit32.band(sFacing, 3)
  elseif type(sFacing) == "string" then
    sFacing = string.lower(sFacing)
    if facingType[sFacing] then sFacing = facingType[sFacing]
    elseif carDirType[sFacing] then sFacing = carDirType[sFacing]
    else return false, 'setFacing(Facing) - Invalid facing ("z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3).'
    end
  else return false, 'setFacing(Facing) - Invalid facing type, must be a string ("z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3).'
  end
  tTurtle.facing = sFacing
  return tTurtle.facing
end

function getFacing() --[[ Returns tTurtle.facing.
  02/10/2021 v0.2.0
  Sintax: getFacing()
  Returns:  tTurtle.facing.
  ex: getFacing() - Outputs whatever is in tTurtle.facing [0..3].]]
  
  return tTurtle.facing
end

function setCoords(x, y, z) --[[ Set coords x, y, z for turtle.
  03/09/2021 v0.2.0
  Param: z,y,z - numbers: new coords for tTurtle.x, tTurtle.y, tTurtle.z
  Sintax: setCoords(x, y, z)
  Returns:  true.
  ex: setCoords(10, 23, 45) - Sets coords x to 10, y to 23 and z to 45.
  Dependencies: isNumber, ]] 
  
  if not isNumber(x,y,z) then return false, "setCoords(x, y, z) - Coords must be numbers." end
	tTurtle.x, tTurtle.y, tTurtle.z = x, y, z
  return true
end

function getCoords() --[[ Gets coords from turtle.
  03/09/2021 v0.2.0
  Returns: the turtle coords x, y, z.
  Sintax: getCoords()
  ex: getCoords() - Returns coords of turtle, 3 values, x, y, z.]] 

  return tTurtle.x, tTurtle.y, tTurtle.z
end


------ ATTACK FUCTIONS ------

function attackDir(sDir) --[[ Turtle attack in sDir direction.
  05/09/2021 v0.4.0
  Param: sDir -  "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
  Returns:  true - if turtle attack something.
            false - if there is nothing to attack, or no weapon.
               nil- if invalid parameter.
  sintax: attackDir([sDir="forward"])
  ex: attackDir("left") - Rotates left and attacks.
  Dependencies: turnDir]]
  
  sDir = sDir or "forward"
  sDir = string.lower(sDir)
  
	if turnDir(sDir) then sDir = "forward" end

  if attF[sDir] then return attF[sDir]()
	else return nil, 'attackDir([Direction="forward"]) - Diretion must be "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3'
	end
end


------ MEASUREMENTS FUNCTIONS ------

function addSteps(nSteps, facing) --[[ Returns nSteps added to turtle coords.
  24/09/2021 v0.4.0
  Param: nSteps - number of waking steps for turtle.
        nFacing - number or string "north"|"east"|"south"|"west"|"z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3 direction of turtle.
  Sintax: addSteps([nSteps=1][, facing = tTurtle.facing])
  Returns:  x,y,z adding nSteps in direction turtle is facing.
            false - if nSteps is not a number.
  Note: accepts positive and negative numbers.
        resets tTurtle.looking to 0.
  ex: addSteps() - Adds 1 to the coord of the turtle is facing.
  Dependencies: getCoords]] 

  if type(nSteps) == "string" then
      local tmp = facing
      facing = nSteps
      nSteps = tmp
  end

  if not facing then
    if tTurtle.looking ~= 0 then
      facing = tTurtle.looking
      tTurtle.looking = 0
    end
  end

  nSteps = nSteps or 1

  if type(facing) == "table" then
    return false, 'addSteps([Steps=1][, facing = turtle facing]) - facing must be "north"|"east"|"south"|"west"|"z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3.'
  end

  if type(facing) == "string" then
    if facingType[facing] then facing = facingType[facing]
    elseif dirType[facing] then facing = dirType2Facing(facing)
    elseif carDirType[facing] then facing = carDirType[facing]
    else return false, 'addSteps([Steps=1][, facing = turtle facing]) - facing must be "north"|"east"|"south"|"west"|"z+"|"z-"|"x+"|"x-"|"y+"|"y-"|"z+"|"z-"|0..3.'
    end
  end

	local x, y, z = getCoords()
  x = x+(facing == 1 and nSteps or 0)+(facing == 3 and -nSteps or 0)
  y = y+(facing == 4 and nSteps or 0)+(facing == 8 and -nSteps or 0)
  z = z+(facing == 2 and nSteps or 0)+(facing == 0 and -nSteps or 0)
  return x, y, z
end

function getDist3D(p1, p2) --[[ Gets the coords of the nearest block.
  01-10-2022
  Param: p1, p2 - points in space 3d.
  Sintax: getDist3D([p1=tTurtle coords, ]p2)   ___________________________
  Return: number - the distance from p1 to p2 √(x1-x2)²+(y1-y2)²+(z1-z2)²)
          nil - If no parameter is supplied.
  ex: getDist3D({1,1,1}, {10,101,10}) - gets the distance from point (1,1,1) to point (10, 101, 10)
      getDist3D({10,1,10}) - gets the distance from turtle to point (10,1,10)]]

  if not p1 then return nil, "getDist3D([p1=tTurtle coords, ]p2) - Must supplie at least p2 = {x, y, z}." end
  if not p2 then
    p2 = {}
    p2[1] = tTurtle.x
    p2[2] = tTurtle.y
    p2[3] = tTurtle.z
  end
	return math.sqrt((p1[1]-p2[1])*(p1[1]-p2[1])+(p1[2]-p2[2])*(p1[2]-p2[2])+(p1[3]-p2[3])*(p1[3]-p2[3]))
end

function distTo(x, y, z) --[[ Gets the three components of the distance from the turtle to point.
  03/09/2021 v0.2.0
  Param: x, y, z - coords of point to calculate distance to turtle.
  Sintax: distTo(x, y, z)
  Returns:  the x,y,z distance from turtle to coords x, y, z.
  Note: returns a negative value if turtle is further away than the point x, y, z.
  ex: distTo(1, 10, 34) - Returns 3 values.
  Dependencies: isNumber]] 
  
  if not isNumber(x,y,z) then return false, "distTo(x, y, z) - Coords must be numbers." end
	return x-tTurtle.x, y-tTurtle.y, z-tTurtle.z
end

function distFromTo(x1, y1, z1, x2, y2, z2) --[[ Calculates the three componentes of the distance from x1,y1,z1 to x2, y2, z2.
  05-07-2018 v0.4.0
  Param: x1,y1,z1,x2,y2,z2 - numbers
         or x1, y1 - tables with {x1,y1,z1}, {x2,y2,z2}
  Return: number,number,number the distances betwen 2 points
  Sintax: distFromTo(x1,y1,z1,x2,y2,z2) or getDist(t1,t2)
  ex: getDistFromTo(1,1,1,10,10,10) - returns 9,9,9
      getDistFromTo({1,1,1},{10,10,10}) - returns 9,9,9]]
  
  if not x1 then return false end
  if type(x1) == "table" then
    return y1[1] - x1[1], y1[2] - x1[2], y1[3] - x1[3]
  end
  return x2 - x1, y2 - y1, z2 - z1
end

function ABSDistTo(x, y, z) --[[ Computes the distance from turtle to x, y, z.
  15-08-2022 v0.4.0
  Param: x, y, z - numbers the destination coords.
  Sintax: ABSDistTo(x, y, z)
  Returns: number - the distance from turtle to point x, y, z.]]

  return math.abs(tTurtle.x - x) + math.abs(tTurtle.y - y) + math.abs(tTurtle.z - z)
end

function ABSDistFromTo(x1, y1, z1, x2, y2, z2) --[[Gets the distance from a point to another point.
  05/07/2018 v0.4.0
  Param:x1, y1, z1 - point origin (1st point)
        x2, y2, z2 - point destination (2nd point)
  Returns: number - distance >= 0, between two sets of coords.
                      false - if no paremeters are supplied.
  sintax: getSumDist(nZ1,nX1,nY1,nZ2,nX2,nY2 or p1={z,x,y},p2={z,x,y})]]

  if not x1 then return false end
  if type(x1) == "table" then
    return math.abs(y1[1] - x1[1]) + math.abs(y1[2] - x1[2]) + math.abs(y1[3] - x1[3])
  end
  return math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1)
end

------ COMPARE FUNCTIONS ------

function compareDir(sDir, nSlot) --[[ Compares item in slot with block in sDir direction.
  21/09/2021 v0.4.0
  Param: sDir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
        nSlot - number 1..16
  Returns: true - if the item in slot and in the world is the same.
           false, "empty" - if there is no block in sDir.
           false, "diferent" - if the block in the world is diferent.
           false, "empty slot" - if nSlot is empty.
           nil - invalid direction,
               - if nSlot is not a number,
               - if nSlot is not in [1..16].
  sintax: compareDir([sDir="forward"][, nSlot=selected slot])
  ex: compareDir() compares selected slot with block in front of turtle.
  compareDir("left", 2) - compares item in slot 2 with block on the left.
  Dependencies: getParam, turnDir, isInRange]]
  
	sDir, nSlot = getParam("sn", {"forward", turtle.getSelectedSlot()}, sDir, nSlot)
	sDir  = string.lower(sDir)
	
	if turnDir(sDir) then sDir = "forward" end
	
	if type(nSlot) ~= "number" then return nil, 'compareDir([Dir="forward"][, Slot=selected slot]) - Slot is not a number.' end
  if not isInRange(nSlot, {1, 16}) then return nil, 'compareDir([Dir="forward"][, Slot=selected slot]) - Slot must be between 1 and 16.' end
  
	local invData = turtle.getItemDetail(nSlot)
	if not invData then return nil, 'empty slot' end
	
	local success, worldData

	if insF[sDir] then success, worldData = insF[sDir]()
	else return nil, 'compareDir(Dir, Slot) - Invalid direction, must be "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3'
	end
	
  if success then
	  if worldData.name == invData.name then return true
    else return false, "diferent"
    end
  else
	  return false, "empty"
  end
end

function compareAbove(nBlocks) --[[ Compares nBlocks above the turtle in a strait line with selected slot block.
  04/09/2021 v0.1.0
  Param: nBlocks - number of blocks to compare.
  Returns:  true - if all the blocks are the same.
            false, "blocked" - if it can't advance.
            false, "empty" - if it found a empty space.
            false, "diferent" - if it found a diferent block.
            false, "empty slot" - if selected slot is empty.
						nil, string - if invalid parameter.
  sintax: compareAbove([nBlocks=1])
  Note: nBlocks < 0 compares backwards, nBlocks > 0 compares forwards.
  ex: compareAbove() or compareAbove(1) - Compares 1 block up.
  Dependencies: sign, forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "compareAbove([Blocks=1]) - Blocks must be a number." end  --nBlocks must be a number.
  local dir = sign(nBlocks)
  nBlocks = math.abs(nBlocks)

  local invData = turtle.getItemDetail()
	if not invData then return false, 'empty slot' end

  for i = 1, nBlocks do
    if not turtle.compareUp() then
      if not turtle.detectUp() then return false, "empty"
      else return false, "diferent"
      end
    end
    if nBlocks ~= i then
			if not forward(dir) then return false, "blocked" end
		end
  end
  return true
end

function compareBelow(nBlocks) --[[ Compares nBlocks below the turtle in a strait line with selected slot block.
  04/09/2021 v0.1.0
  Param: nBlocks - number of blocks to compare.
  Returns:  true - if all the blocks are the same.
            false, "blocked" - if blocked.
            false, "empty" - if it found a empty space.
            false, "diferent" - it found a diferent block.
            false, "empty slot" - if selected slot is empty.
						nil, string - if invalid parameter.
  sintax: compareBelow([nBlocks=1])
  Note: nBlocks < 0 compares backwards, nBlocks > 0 compares forwards.
  ex: compareBelow() or compareBelow(1) - Compares 1 block down.
  Dependencies: sign, ]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "compareBelow([Blocks=1]) - Blocks must be a number." end
  local dir = sign(nBlocks)
  nBlocks = math.abs(nBlocks)
  
  local invData = turtle.getItemDetail()
	if not invData then return false, 'empty slot' end

  for i = 1, nBlocks do
    if not turtle.compareDown() then
      if not turtle.detectDown() then return false, "empty"
      else return false, "diferent"
      end
    end
    if nBlocks ~= i then
			if not forward(dir) then return false, "blocked" end
		end
  end
  return true
end


------ DETECT FUNCTIONS ------

function detectAt(x, y, z) --[[ Detect if block at x,y,z exists.
  26-01-2023 v0.4.0
  Param: x,y,z - numbers coords of block to detectCoord.
  Returns: true - if block exists.
           0 - if block doesn't exist (code for empty space).
           false - if it couldn't get to neighbor.
           nil - if parameters < 3.
               - if x,y,z are not numbers.
  Sintax: detectAt(x,y,z)
  ex: detectAt(10,10,10) - turtle goes to one neighbor of 10,10,10, turns to 10,10,10, and returns detectCoord that block.
  Dependencies: checkNil, isNumber, goToNeighbor, detectCoordDir, getKey]]

  if checkNil(3, x, y, z) then return nil, "detectCoord(x,y,z) - invalid number os parameters." end
  if not isNumber(x, y, z) then return nil, "detectCoord(x,y,z) - x,y,z must be numbers." end
  if not goToNeighbor(x, y, z) then return false, "detectCoord(x,y,z) - couldn't get to neighbor of x,y,z." end
  if not detectCoordDir(getKey(tTurtle.looking, lookingType)) then return 0 end
  return true
end

function detectDir(sDir) --[[ Detects if is a block in sDir direction.
  03/09/2021 v0.4.0
  Param: sDir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
  Returns:  true - If turtle detects a block.
           false - if turtle didn't detect a block.
             nil - invalid parameter.
	Sintax: detectDir([sDir="forward"])
  ex: detectDir() - Detect blocks forward.
			detectDir(0) or detectDir("z-") or detectDir("north") - Detect blocks to the north.
  Dependencies: turnDir]]
  
	sDir = sDir or "forward"
  sDir = string.lower(sDir)
	
	turnDir(sDir)

	if detF[sDir] then return detF[sDir]()
	else return nil, 'detectDir([Dir="forward"]) - Invalid Direction'
	end
end

function detectAbove(nBlocks) --[[ Detects nBlocks forwards or backwards, 1 block above the turtle.
  03/09/2021 v0.1.0
  Param: nBlocks - number of blocks to detect.
  Returns:  true - if turtle detects a line of nBlocks above it.
           false - if blocked, empty space.
	  				nil - if invalid parameter.
  sintax: detectAbove([nBlocks=1])
  Note: nBlocks < 0 detects backwards, nBlocks > 0 detects forwards.
  ex: detectAbove() or detectAbove(1) - Detects 1 block up.
  Dependencies: forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "detectAbove([Blocks=1]) - Blocks must be a number." end
  local dir = sign(nBlocks)

  for i = 1, nBlocks, dir do
    if not turtle.detectUp() then return false, "Didn't detect a block." end
    if nBlocks ~= i then
			if not forward(dir) then return false, "Can't advance forward."  end
		end
  end
  return true
end

function detectBelow(nBlocks) --[[ Detects nBlocks forwards or backwards, 1 block below the turtle.
  03/09/2021 v0.1.0
  Param: nBlocks - number of blocks to detect.
  Returns:  true - if turtle detects a line of nBlocks below.
           false - if blocked, empty space.
             nil - if invalid parameter
  sintax: detectBelow([nBlocks=1])
  Note: nBlocks < 0 detects backwards, nBlocks > 0 detects forwards.
  ex: detectBelow() or detectBelow(1) - Detect 1 block down.
  Dependencies: sign, forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "detectBelow([Blocks=1]) - Blocks must be a number." end
  local dir = sign(nBlocks)

  for i = 1, nBlocks, dir do
    if not turtle.detectDown() then return false, "Didn't detect a block." end
    if i ~= nBlocks then
			if not forward(dir) then return false, "Can't advance forward." end
		end
  end
  return true
end


------ INSPECT FUNCTIONS ------

function inspectAt(x, y, z) --[[ Inspects the block at coord x,y,z.
  13-07-2023 v0.4.0
  Param: x,y,z - numbers: coord of block to inspect.
  Returns: true, table - boolean, data from block.
           false, 0 - if there is no block to inspect.
           false - if turtle couldn't get to x,y,z.
           nil - if x,y,z are not numbers.
  Sintax: inspect(x,y,z)
  ex: inspect(10,10,10) - turtle move to a neighbor of 10,10,10 and inspect the block at coord 10,10,10.
  Dependencies: isNumber, goToNeighbor, inspectDir, getKey]]
  
  if not isNumber(x, y, z) then return nil, "inspect(x,y,z) - x,y,z must be numbers." end
  if not goToNeighbor(x, y, z) then return false, "inspect(x,y,z) - couldn't get to neighbor of x,y,z." end
  local success, t = inspectDir(getKey(tTurtle.looking, lookingType))
  if not success then return true, 0 end
  return success, t
end

function inspect(...) --[[ Returns the information for block.
  27-01-2023 v0.4.0
  Param: x,y,z - nmbers coords of block to inspect.
	        sDir - inspects a block in sDir.
  Returns: true, table - if block exists.
           true, 0 - if there is no block (empty space).
           false - if it couldn't go to the neighbor of x,y,z.
           nil - if number of parameters ~= 0|1|3
               - if x,y,z are not numbers.
  Sintax: inspect([x,y,z]|[sDir])
  sDir = "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3
  ex: inspect(10,10,10) - turtle goes to one neighbor of 10,10,10, turns to 10,10,10, and returns inspect that block.
      inspect("left") - inspects the block in the left.
  Dependencies: inspectDir, inspectAt]]

  arg = {...}
  if #arg == 0 then return inspectDir("forward") end
  if #arg == 1 then
     if not inspectDir(arg[1]) then return false, "inspect([x,y,z]|[sDir]) - invalid direction" end
  end
	if #arg ~= 3 then return nil, "inspect(x,y,z) - invalid number os parameters." end
  return inspectAt(arg[1], arg[2], arg[3])
end

function inspectDir(sDir) --[[ Inspect a block in sDir direction.
  05/09/2021 v0.4.0
  Param: sDir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
  Returns:  true, table with data - If turtle detects a block.
            false, message - if turtle didn't detect a block.
            nil - if invalid parameter sDir.
  Sintax: detectDir([sDir="forward"])
	ex: inspectDir("forward") or inspectDir() - inspects a block forward.
			inspectDir("z-") or inspectDir("north") or inspect(0) - inspects a block to the north.
  Dependencies: strLower, turnDir]]
  
	sDir = sDir or "forward"
  sDir = strLower(sDir)

  if turnDir(sDir) then sDir = "forward" end
	
	if insF[sDir] then return insF[sDir]()
	else return nil, 'inspectDir([Dir="forward"]) - Invalid parameter: Dir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.'
	end
end

------ SCANNING ------

function scan(sDir) --[[ Inspects the block in sDir, and sets tWorld.
  02-11-2022 v0.4.0
  Param: sDir - direction to inspect "forward"|"up"|"down"
  Return: true - if could set tWorld with tEnt code.
          nil - if sDir is not a string.
              - if sDir is not "forward"|"up"|"down"
  Sintax: scan([sDir = "forward"])
  ex: scan("up") - inspects the block up, sets tEnt and tWorld with its code.
  Dependencies: addSteps, entAdd, setWorldEnt]]

  sDir = sDir or "forward"
  if type(sDir) ~= "string" then
    return nil, 'scan(sDir) - Invalid sDir type, must be a string ""forward"|"up"|"down"'
  end
  if not insF[sDir] then
    return nil, 'scan(sDir) - Invalid sDir must be "forward"|"up"|"down"'
  end
  local success, tData = insF[sDir]()
  local x, y, z = addSteps(1, sDir)
  local nID
  if not success then nID = 0
  else nID = entAdd(tData.name)
  end

  setWorldEnt(x, y, z, nID)
  return true
end

function scanAll() --[[ Inspects up, down and forward, puts the result in tWorld.
  02-11-2022 v0.4.0
  Return: true
  Dependencies: scan]]
  
  local tDir = {"up", "forward", "down"}
  for i = 1, #tDir do
    scan(tDir[i])
  end
  return true
end


------ MOVING FUNCTIONS ------

function forward(nBlocks) --[[ Moves nBlocks forward or backwards, until blocked.
  27/08/2021 v0.4.0
  Param: nBlocks - number of blocks to walk.
  Returns:  true - if turtle goes all way.
           false - "Can't advance forward."
             nil - invalid nBlocks type.
  Sintax: forward([nBlocks=1])
  Note: nBlocks < 0 moves backwards, nBlocks > 0 moves forward.
  ex: forward(3) - Moves 3 blocks forward.
  Dependencies: back, scanAll, dig]] 
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "forward([Blocks=1]) - Blocks must be a number." end
  if nBlocks < 0 then return back(math.abs(nBlocks)) end
  if SCAN then scanAll() end
  for i = 1, nBlocks do
    local success, message = turtle.forward()
    if not success then
			if not DIG then return false, message
			elseif not dig() then return false, "Can't dig/advance forward."
			end
		end
    tTurtle.x, tTurtle.y, tTurtle.z = addSteps(1, "forward")
    if SCAN then scanAll() end
  end
  return true
end

function back(nBlocks) --[[ Moves nBlocks back or forward, until blocked.
  27/08/2021 v0.4.0
  Param: nBlocks - number of blocks to walk backwards. 
  Returns:  true - if turtle goes all way.
           false - if turtle was blocked.
             nil - if nBlocks is not a number.
  Note: nBlocks < 0 moves forward, nBlocks > 0 moves backwards.
  ex: back(-3) - Moves 3 blocks forward.
  Dependencies: forward, scanAll]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "back([Blocks=1]) - Blocks must be a number." end
  if nBlocks < 0 then return forward(math.abs(nBlocks)) end
  if SCAN then scanAll() end
  for i = 1, nBlocks do
    local success, message = turtle.back()
    if not success then return false, message
    else
      tTurtle.x, tTurtle.y, tTurtle.z = addSteps(1, "back")
      if SCAN then scanAll() end
    end
  end
  return true
end

function up(nBlocks) --[[ Moves nBlocks up or down, until blocked.
  27/08/2021 v0.4.0
  Param: nBlocks - number of blocks to walk up.
  Returns:  true - if turtle goes all way.
           false - if turtle was blocked.
             nil - if nBlocks is not a number.
  Note: nBlocks < 0 moves downwards, nBlocks > 0 moves upwards.
  ex: up(3) - Moves 3 blocks up.
  Dependencies: down, scanAll, digUp]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "up([Blocks=1]) - Blocks must be a number." end
  if nBlocks < 0 then return down(math.abs(nBlocks)) end
  if SCAN then scanAll() end
  for i = 1, nBlocks do
    local success, message = turtle.up()
    if not success then
			if not DIG then return false, message
			elseif not digUp() then return false, "Can't dig/advance up."
			end
		end
    tTurtle.y = tTurtle.y + 1
    if SCAN then scanAll() end
  end
  return true
end

function down(nBlocks) --[[ Moves nBlocks down or up, until blocked.
  27/08/2021 v0.4.0
  Param: nBlocks - number of blocks to walk down.
  Returns:  true - if turtle goes all way.
           false - if turtle was blocked.
             nil - if nBlocks is not a number.
  Note: nBlocks < 0 moves up, nBlocks > 0 moves down.
  ex: down(3) - Moves 3 blocks down.
  Dependencies: up, scanAll, digDown]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "down([Blocks=1]) - Blocks must be a number." end
  if nBlocks < 0 then return up(math.abs(nBlocks)) end
  if SCAN then scanAll() end
  for i = 1, nBlocks do
    local success, message = turtle.down()
		if not success then
			if not DIG then return false, message
			elseif not digDown() then return false, "Can't dig/advance down."
			end
		end
		tTurtle.y = tTurtle.y -1
		if SCAN then scanAll() end
  end
  return true
end

function strafeLeft(nSteps) --[[ Turns left or right and walks nSteps, turns to the initial direction.
  03-06-2023 v0.4.0
  Param: nSteps - number: steps to walk.
  Return: true - all went well.
          false - if it couldn't walk left/right.
          nil - if nSteps has invalid type.
  Sintax: strafeLeft([nSteps=1])
  Dependencies: goLeft, turnRight
  ex: strafeLeft() - turns left, advances 1 and turns right.
      strafeLeft(5) - turns left, advances 5 blocks and turns right.
      strafeLeft(-6) - turns right, advances 6 blocks and turns left.
  Dependencies: goLeft, turnRight]]

      nSteps = nSteps or 1
      if tonumber(nSteps) then nSteps = tonumber(nSteps) end
      if type(nSteps) ~= "number" then return nil, "strafeLeft([Steps = 1]) - Steps must be a number."end
      local success, message = goLeft(nSteps)
      if not success then return success, message end
      turnRight(sign(nSteps))
      return true
end

function strafeRight(nSteps) --[[ Turns right or left and walks nSteps, turns to the initial direction.
  03-06-2023 v0.4.0
  Param: nSteps - number: steps to walk.
  Return: true - all went well.
          false - if it couldn't walk right/left.
          nil - if nSteps has invalid type.
  Sintax: strafeRight([nSteps=1])
  Dependencies: goRight, turnLeft
  ex: strafeRight() - turns right, advances 1 and turns left.
      strafeRight(5) - turns right, advances 5 blocks and turns left.
      strafeRight(-6) - turns left, advances 6 blocks and turns right.
  Dependencies: goRight, turnLeft]]

  nSteps = nSteps or 1
  if tonumber(nSteps) then nSteps = tonumber(nSteps) end
  if type(nSteps) ~= "number" then return nil, "strafeRight([Steps = 1]) - Steps must be a number."end
	local success, message = goRight(nSteps)
  if not success then return success, message end
	turnLeft(sign(nSteps))
  return true
end

------ GENERAL FUNCTIONS ------

function isAny(value, ...) --[[ Compares value with all the arguments.
  04-07-2023 v0.4.0
  Param: value - the value to compare.
           ... - the arguments to compare with value.
  Returns: true - if there was at least one argument with the value.
  Sintax: isAny(value, ...)
  ex: isAny(12, "hi", {12},  ) - returns true.
  Dependencies: isAny]]
	
  arg = {...}
	for i = 1, #arg do
		if type(arg[i]) == "table" then
			local index = isAny(value, table.unpack(arg[i]))
			if index then return true end
		else if value == arg[i] then return true end
		end
	end
	return false
end
  
function fillStr(sChar, nChars) --[[ Returns a filled string with sChar having a width of nChars
  31-05-2023 v0.4.0
  Param: sChar - the char to fill the string.
         nChar - the number of chars to fill the string.
  Sintax: fillStr(sChar, nChar)
  ex: fillStr("-", 10) - returns a string with 10 "-" (minus).]]

	local sRet = ""
	for i = 1, nChars do
		sRet = sRet..sChar
	end
	return sRet
end

function rTrim(s) --[[ Removes the right spaces from a string.
  31-05-2023
  Param: s - the string from where to remove spaces.
  Sintax: rTrim(s)
  ex: rTrim("Hello world      ") - returns "Hello world"]]

	for i = #s, 1, -1 do
		if string.byte(s, i) ~= 32 then return string.sub(s, 1, i) end
	end
	return ""
end

function lTrim(s) --[[ Removes the left spaces from a string.
  31-05-2023
  Param: s - the string from where to remove spaces.
  Sintax: lTrim(s)
  ex: lTrim("   Hello world") - returns "Hello world"]]

	for i = 1, #s do
		if string.byte(s, i) ~= 32 then return string.sub(s, i, #s) end
	end
	return ""
end

function trim(s) --[[ Removes spaces at the beginning and end of a string.
  17-07-2023 v0.4.0
  Param: s - string
  Returns: string without trailing and leading spaces.
  Sintax: trim(s)
  ex: trim(" Hello World!    ") - returns "Hello World!"
  dependencies: lTrim, rTrim]]

	s = lTrim(s)
	return rTrim(s)
end

function spc(nSpaces) --[[ Returns nSpaces length filled string with spaces.
  24-05-2023 v0.4.0
  Param: nSpaces - number: the length of the string to return.
  Returns:  string - filled with spaces with length nSpaces.
  ex: spc(6) - returns a string with 6 spaces.]]

  local sRet = ""
  while #sRet < nSpaces do sRet = sRet.." " end
  return sRet
end

function strLeft(s, sep) --[[ Returns the left part of a string.
  14-05-2023 v0.4.0
  Param: s - the complete string.
       sep - the character separator or the length of the string to return.
  Returns:  nil - if the string is not supplied.
  ex: strLeft("Hello", 2) - returns He.
    strLeft("Hello", "l") - returns He.]]

  if not s then return nil, "strLeft(string, separator/length) - string not supplied" end
  if not sep then return s end
	if type(sep) == "number" then return string.sub(s, 1, sep)
	else return string.sub(s, 1, string.find(s, sep)-1)
	end
end

function strRight(s, sep) --[[ Returns the right part of a string.
  14-05-2023 v0.4.0
  Param: s - the complete string.
       sep - the character separator or the length of the string to return.
  Returns:  nil - if the string is not supplied.
  ex: strRight("Hello", 2) - returns lo.
      strRight("Hello", "l") - returns o.]]

  if not s then return nil, "strLeft(string, separator/length) - string not supplied" end
  if not sep then return s end
	if type(sep) == "number" then return string.sub(s, #s - sep + 1, #s)
	else return string.sub(s, string.find(s, sep)+1, #s)
	end
end

function strLR(s, sep) --[[ Returns the left and right part of a string.
  14-05-2023 v0.4.0
  Param: s - the complete string.
       sep - the character separator or the length of the string to return.
  Returns:  nil - if the string is not supplied.
  ex: strLR("Hello", 2) - returns He, lo.
      strLR("Hello", "l") - returns He, o.
  Dependencies: strLeft]]
  
	return strLeft(s, sep), strRight(s, sep)
end

function b2N(value) --[[ Converts boolean value to number (true - 1, false - 0)
  01-01-2023 v0.4.0
  Param: value - boolean (true/false)
  Returns: number 1 or 0]]

	return value and 1 or 0
end

function n2B(value) --[[ Converts number value to boolean (~= 0 - true, 0 - false)
  01-01-2023 v0.4.0
  Param: value - number
  Returns: boolean (true/false)]]

  return not (value == 0)
end

function checkNil(nArg, ...) --[[ Checks for nil parameters.
	21-07-2022 v0.4.0
  Param: nArg - number of parameters
          ... - parameters to test
  Returns: true, number of parameters that are nil.
           false - there is no nil parameters
           nil - if nArg not supplied.
               - if nArg not a number.
  Sintax:checkNil(nArg, ...)
	Ex: checkNil(2, 2) - returns true, 1]]

  if not nArg then return nil, "checkNil(nArg, ...) - Must supply nArg as the number of arguments." end
  if type(nArg) ~= "number" then return nil, "checkNil(nArg, ...) - narg must be a number." end

  arg = {...}
  local dif = #arg - nArg
	if dif < 0 then return true, math.abs(dif)
  else return false
  end
end

function dirType2Facing(sDir, nFacing) --[[ Adjusts the facing after a turn.
  15-01-2022 v0.4.0
  Param: sDir - "forward"|"back"|"up"|"down"|"left"|"right"
      nFacing - 0..3
  Return: facing - adjusted after a turn.
  Sintax: dirType2Facing([sDir = "forward"][, nFacing = turtle.facing])
  Ex: dirType2Facing("left", 2) - returns 1
      dirType2Facing("up", 1) - returns 4
      if turtle.facing = 0 - dirType2Facing("right") - returns 1
      if turtle.facing = 1 - dirType2Facing() - returns 1
  Dependencies: incFacing]]
      
  sDir = sDir or "forward"
  nFacing = nFacing or tTurtle.facing

  if not dirType[sDir] then return false end

  local facing
  facing = (sDir == "forward" and nFacing or 0) + (sDir == "back" and incFacing(2, nFacing) or 0)
  facing = facing + (sDir == "left" and decFacing(1, nFacing) or 0) + (sDir == "right" and incFacing(1, nFacing) or 0)
  facing = facing + (sDir == "up" and dirType[sDir] or 0) + (sDir == "down" and dirType[sDir] or 0)
  return facing
end

function isInRange(nValue, ...) --[[ Checks if nValue is in ... range
  30-10/2022 v0.4.0
  Param: nValue - value to test.
            ... - is a table with a lower limit and higher limit, or a number.
  Sintax: isInRange(nValue, ...)
  Return: true  - if nValue is in range.
          false - if value is not in range.
  ex: isInRange(1, {0,2}) - return true
      isInRange(17, {1,15},17) - return true]]

      arg = {...}
  local bInRange = false
  for i = 1, #arg do
    local lower, higher
    if type(arg[i]) == "table" then
      lower = arg[i][1]
      higher = arg[i][2]
    elseif type(arg[i]) == "number" then
      lower = arg[i]
    else return nil, "checkRange(nValue, {nLowerLimit, nHigherLimit}) - invalid type, nValue, nLowerLimit and nHogherLimit must be numbers."
    end
    if higher then
      if nValue >= lower and nValue <= higher then bInRange = true end
    elseif lower == nValue then bInRange = true
    end
  end
  return bInRange
end

function loadTable(sFileName) --[[ Loads a text file into a table.
  27/09/2021 v0.2.0
  Param: sFileName - string the file name.
  Sintax: loadTable(sFileName)
  Returns: table - if could read a text file into a table.
           false - if sFileName is not supplied,
                 - if the file couldn't be opened for reading,
                 - if the file is empty.
  ex: loadTable("oneFile.txt") - Loads file "oneFile.txt" returns it as a table.]]
  
	if not sFileName then return false, "loadTable(FileName) - Must supply file name." end
	
  local fh,t
  if not fs.exists(sFileName) then return false, "loadTable - file not found" end
  fh = fs.open(sFileName, "r")
	if not fh then return false, "loadTable - can't open file "..sFileName end
  t = textutils.unserialize(fh.readAll())
	if not t then return false, "loadTable - empty file "..sFileName end
  fh.close()
  return t
end

function saveTable(t, sFileName) --[[ Saves a table into a text file.
  27/09/2021 v0.2.0
  Param: t - table to save.
         sFileName - string filename.
  Sintax: saveTable(t, sFileName)
  Returns:  true - if saving file was a success.
           false - if t or sFileName not supplied,
                 - if no disk space,
                 - if it couldn't create file.
  Note: if not supplied extension it adds ".txt" to the file name.
  ex: saveTable(oneTable, "oneFile") - Saves table oneTable into "oneFile.txt" file.]]
  
	if not t or not sFileName then return false, "Table or filename not supplied." end --no arguments
	
  if not string.find(sFileName, "[.]") then sFileName = sFileName..".txt" end --if no extension add 1
	local str2Save = textutils.serialize(t)
	if string.len(str2Save) > fsGetFreeSpace("/") then return false,"no disk space" end
	
	local fh = fs.open(sFileName, "w") --open file for write
	if not fh then return false, "couldn't open file for write." end
	
	fh.write(str2Save) --transform table values and keys in strings
	fh.close() --close file handle(file)
	return true --return success
end

function checkType(sType, ...) --[[ Checks if parameters are from sType.
  03/09/2021 v0.1.0
  Param: sType - string where "s" stands for string, "t" for table, "n" for number, "b" for boolean.
           ... - the paremeters to check.
  Returns: true - if all parameters match the sType.
  ex: checkType("snt", "hello", number1, tTable) - Outputs: true.]]
  
	Args = { ... }
  
  if #Args ~= #sType then return false end
	for i = 1, #sType do
		if sType:sub(i,i) ~= type(Args[i]):sub(1,1) then return false end
	end
	return true
end

function dicCount(tDic) --[[ Counts number of items in a dictionary.
  17-12-2022 v0.4.0
  Param: tDic - dictionary to count items.
  Return: number - total items in dictionary.
          nil - if tDic is not a table.
  Sintax: dicCount(tDic)
  ex: dicCount({1,2,3}) - returns 3]]

  if type(tDic) ~= "table" then return nil, "Parameter is not a table." end
  local nItems = 0
  for k,v in pairs(tDic) do nItems = nItems + 1 end
  return nItems
end

function isDicEmpty(tDic) --[[ Checks if dictionary is empty.
  05-11-2022  v0.4.0
  Param: tDic - dictionary to check.
  Sintax: isDicEmpty(tDic)
  ex: isDicEmpty({}) - returns true.]]

  if not tDic then return true end
  for k, v in pairs(tDic) do
    return false
  end
  return true
end

function getKey(value, t) --[[ Gets the first key from table t where the key is the index of value.
  09-08-2022 v0.4.0
  Param: value - the value in table t.
             t - the table that has the value.
  Sintax: getKey(value, t)
  Return: the key corresponding to value in table t.
          false - if value is not found
  ex: getKey(2, {"first"=1, "second"=2}) - returns second
  Dependencies: checkNil, getParam]]

  if checkNil(2, value, t) then return nil, "getKey(value, t) - you must supply value and t table." end
  value, t = getParam("nt", {{}, -1}, value, t)
	for k, v in pairs(t) do
		if v == value then return k end
	end
	return false
end

function getParam(sParamOrder, tDefault, ...) --[[ Sorts parameters by type.
  27/08/2021 v0.1.0
  Param: sParamOrder - string where "s" stands for string, "t" for table, "n" for number, "b" for boolean.
            tDefault - table with default values.
                 ... - parameters to order.
  Returns:  Parameters sorted by type,
            nil - if no parameters.
  sintax: getParam(sParamOrder, tDefault[, ...])
  ex: getParam("sns", {"default" }, number, string) - Outputs: string, number, default.
  Note: Only sorts parameters type (string, table, number and boolean).]]

  if not sParamOrder then return nil, "getParam(sParamOrder, tDefault, ...) - Must supply string with parameters order." end
  if not tDefault then return nil, "getParam(sParamOrder, tDefault, ...) - Must supply table with default values." end
  local Args={...}
    
  local retTable = {}
  local argChecked = {}
  local paramChecked = {}

  for parami = 1, #sParamOrder do
    for argi = 1, #Args do
      if Args[argi] and (sParamOrder:sub(parami, parami) == type(Args[argi]):sub(1, 1)) and (not argChecked[argi]) then
        argChecked[argi] = true
        paramChecked[parami] = true
        table.insert(retTable, Args[argi])
        break
      end
    end
    if not paramChecked[parami] then
      paramChecked[parami] = true
      table.insert(retTable, tDefault[parami])
    end
  end

  if #retTable == 0 then return nil
  else return table.unpack(retTable);
  end
end

function isValue(value, t) --[[ Checks if value is in t table.
  21/09/2021 v0.2.0
  Param:  value - any type of value.
              t - table with values to compare.
  Sintax: isValue(value, t)
  Returns:  true, key - if value is in t, key corresponding to value.
            false - if value is not in t.
  ex: isValue(2, {["hello"] = 2, ["hi"] = 4}) - Outputs: true, "hello".]]
  
  for k,v in pairs(t) do
    if v == value then return true, k end
  end
  return false
end

function isNumber(...) --[[ Checks if all parameters are numbers.
  20/04/2022 v0.3.0
  Param:  ... - parameters to check
  Returns:  true - if all parameters are numbers.
           false - if at least one parameter is not a number.
  sintax: isNumber(...)
  ex: isNumber(2, "hello", 4}) - Outputs: false.]]
  
  Args = {...}
  if #Args == 0 then return false end
  for i = 1, #Args do
    if type(Args[i]) ~= "number" then return false end
  end
  return true
end

function tableInTable(tSearch, t) --[[ Verifies if al elements of tSearch is in table t.
  27/08/2021 v0.1.0
  Param: tSearch - table contains values to search in table t.
               t - table to search.
  Returns:  true - tSearch is in t.
           false - at the least one element of tSearch is not in table t.
  Sintax: tableInTable(tSearch, t)
  ex: tableInTable("forward", lookingType) - outputs true.]]
  
  if type(tSearch) ~= "table" then return nil, "tableInTable(tSearch, t) - tSearch (items to search in t) must be a table." end

  totMatch = 0

  for k1, v1 in pairs(tSearch) do
    for k2, v2 in pairs (t) do
      if v2 == v1 then
        totMatch = totMatch + 1
        break
      end
    end
  end

  if #tSearch ~= totMatch then return false, "There are at least 1 item not present in t." end
  return true
end

function sign(value) --[[ Returns: -1 if value < 0, 0 if value == 0, 1 if value > 0
  28/08/2021 v0.1.0
  Param: value - number to evaluate.
  Sintax: sign(value)
  Returns false if value is not a number, or not supplied.]]
  
  if type(value) ~= "number" then return false, "sign(value) - Is not a number or not supplied." end
  if value < 0 then return -1 end
  if value == 0  then return 0 end
  return 1
end

function strLower(...) --[[ Converts only strings to lowercase.
  14/10/2022 v0.4.0
  Param: ... - strings
  Sintax: strLower([string][, ...])
  Returns: nil - if empty arguments.
           strings - converted to lower case.
  ex: strLower("Hello", "This is ME", 12) - returns: hello, this is me, 12]]

  arg = {...}
  if #arg == 0 then return nil, "strLower(string[, ...])" end
  local tRS = {}
  for i = 1, #arg do
    if type(arg[i]) == "string" then tRS[#tRS+1] = string.lower(arg[i])
    else tRS[#tRS+1] = arg[i]
    end
  end
  return table.unpack(tRS)
end


------ STACK FUNCTIONS ------

function getStack(nSlot) --[[ Returns how many items can stack in slot.
  10-11-2021 v0.4.0
  Param: nSlot - slot number 1..16, or the item name.
  Sintax: getStack()
  Return: number - quantity a item can stack.
             nil - if slot is out of range[1..16].
                 - if nSlot is not a number or string
           false - if item was not found in inventory.
                 - if slot is empty.
  sintax: getStack([nSlot/sItemName = selected slot]).
  ex: getStack() - gets the stack of item in selected slot.
      getStack("minecraft:oak_planks") - gets the stack for oak_planks.
  Dependencies: search, isInRange]]
  
  nSlot = nSlot or turtle.getSelectedSlot()

  local tData
  if type(nSlot) == "string" then
    if tEnts[nSlot] and tEnts[nSlot].stack then return tEnts[nSlot].stack end
    nSlot = search(nSlot)
    if not nSlot then return false, "Item not found" end

  elseif type(nSlot) == "number" then
    if not isInRange(nSlot, {1,16}) then return nil, "getStack(Slot/ItemName) - Slot out of range[1..16]." end
  else return nil, "getStack(nSlot/item name) - Invalid type nSlot, must be number or string."
  end

  tData = turtle.getItemDetail(nSlot)
  if not tData then return false, "Empty slot." end
  if not tEnts[tData.name] then entAdd(tData.name) end
  if tEnts[tData.name].stack then return tEnts[tData.name].stack end
  tEnts[tData.name].stack = turtle.getItemSpace(nSlot) + tData.count
  return tEnts[tData.name].stack
end

function invLowerStack(sItem) --[[ Returns the lower stack of items in inventory, the slot and the name of item.
  17/12/2021 v0.2.0
  Param: sItem - string - item name.
  Return: number, number, string - the lowerstack of items in inventory, the Slot, the name of item.
          false - if item not found.
  sintax: invLowerStack([sItem = all the inventory]).
  ex: invLowerStack() - gets the lowest stack of items in inventory, the slot, and the item name.
  invLowerStack("minecraft:oak_planks") - gets the lowest stack for oak_planks in inventory, the slot and the item name.]]
  
  local nLower, nRSlot = 9999, false
  local sName = ""
  for nSlot = 1, 16 do
    local tData = turtle.getItemDetail(nSlot)
    if tData then
      if sItem then
        if sItem == tData.name then
          if nLower > tData.count then
            nLower = tData.count
            sName = tData.name
            nRSlot = nSlot
          end
        end
      else
        if nLower > tData.count then
          nLower = tData.count
          sName = tData.name
          nRSlot = nSlot
        end
      end
    end
  end
  if nLower == 9999 then return false, "Item not found."
  else return nLower, nRSlot, sName
  end
end

function setStackSlot(nSlot) --[[ Sets stack for item in nSlot.
  24-07-2022 v0.4.0
  Param: nSlot - number 1..16, the slot where is the item to set stack.
  Returns: number - how many the item can stack.
           false - if slot is empty
           nil - if nSlot is not a number.
               - if nSlot is out of bounds 1..16
  Sintax: setStackSlot([nSlot=selected slot])
  Dependencies: isInRange, setStack]]

  nSlot = nSlot or turtle.getSelectedSlot()
	
	local tData, nStack
	if type(nSlot) ~= "number" then return nil, "setStackSlot(Slot) - Must be a number [1..16]." end --nSlot is not a number
	if not isInRange(nSlot, {1, 16}) then return nil, "setStackSlot(Slot) - Must be between 1 and 16."end --is valid

  tData = turtle.getItemDetail(nSlot)
	if not tData then return false, "Slot is empty." end --is empty nSlot

  nStack = turtle.getItemSpace(nSlot) + tData.count --calculate stack for this item
	setStack(tData.name, nStack) --store nStack in tStacks[id]=nStack
  return nStack
end

function setStack(sItemName, nStack) --[[ Sets the item stack value in tEnts[item name].stack
  10-11-2021 v0.4.0
  Param: sItemName - string item name.
            nStack - number how much item can stack.
  Return: true - if it could set the stack for item.
           nil - if no item name supplied.
               - if no stack number is supplied.
               - if stack is < 0
  Sintax: setStack(sItemName, nStack)
  ex: setStack("minecraft:cobblestone", 64) - set stack for "minecraft:cobblestone" for 64.
  Dependencies: getParam, entAdd]]
  
  sItemName, nStack = getParam("sn", {"", -1}, sItemName, nStack)
  if sItemName == "" then return nil, "Must supply item name." end
  if nStack == -1 then return nil, "Must supply stack." end
  if nStack < 1 then return nil, "Stack out of range [1..]." end
  if not tEnts[sItemName] then entAdd(sItemName) end
  tEnts[sItemName].stack = nStack
  return true
end


------ RECIPES FUNCTIONS ------

function getInvItems() --[[ Builds a table with the items and quantities in inventory.
  20/11/2021 v0.3.0
  Return: table - with ingredient name and quantity.]]
  
  local tQuant = {}
  for nSlot = 1, 16 do
    local tData = turtle.getItemDetail(nSlot)
    if tData then
      if tQuant[tData.name] then tQuant[tData.name] = tQuant[tData.name] + tData.count
      else tQuant[tData.name] = tData.count
      end
    end
  end
  return tQuant
end

function getRecipeItems(sRecipe, nIndex) --[[ Builds a table with items and quantities in a recipe.
  20/11/2021 v0.3.0
  Param:  sRecipe - recipe name.
           nIndex - recipe index
  Return: table - with recipe ingredient name and quantity.
          false - if no recipe name was supplied and there isn't tRecipes.lastRecipe
                - if tRecipes[sRecipe] dosn't exist, (never was made).
                - if the tRecipes[sRecipe[nIndex] doesn't exist.
  Sintax: getRecipeItems([sRecipeName = tRecipes.lastRecipe][, nIndex=1])
  ex: getRecipeItems("minecraft:stick", 1) - returns: {["minecraft_oak_planks"] = 2}
  Dependencies: getParam, ]]
  
  sRecipe, nIndex = getParam("sn", {"", 1}, sRecipe, nIndex)

  if sRecipe == "" then sRecipe = tRecipes.lastRecipe end
  if not sRecipe then return false, "Must supply recipe name." end
  if not tRecipes[sRecipe] then return false, "Recipe name not found" end
  if not tRecipes[sRecipe][nIndex] then return false, "Recipe index not found" end

  local tRecipe = {}
  local tRecs = tRecipes[sRecipe][nIndex].recipe
  for i = 1, #tRecs do
    if tRecipe[tRecs[i][1]] then tRecipe[tRecs[i][1]] = tRecipe[tRecs[i][1]] + 1
    else tRecipe[tRecs[i][1]] = 1
    end
  end
  return tRecipe
end

function canCraftRecipe(sRecipe) --[[ Checks if you can craft sRecipe with inventory items.
  09/07/2022 v0.3.0
  Param: sRecipe - string the recipe name.
  returns: true, number index of recipe.
           false
  sintax: canCraftRecipe(sRecipe)
  Note: if you didn't craft this recipe earlier this functions returns true, even with all items in inventory.
  ex: canCraft("minecraft:stick") - if you have created this recipe and all items are in inventory it returns true.]]

  local bSuccess, tRecs = canCraft()
  if not bSuccess then return false end
  for iRec = 1, #tRecs do
    for k, v in pairs(tRecs[iRec]) do
      if sRecipe == k then return true, v end
    end
  end
  return false
end

function canCraft() --[[ Retuns a table with recipe name and index that you can craft from inventory.
  20/11/2021 v0.3.0
  Return: true, table - with recipe name and index.
                false - if no recipe can be crafted.
  Sintax: canCraft()
  Note: table={[name]=recipe index}
  ex: canCraft()
  Dependencies: getInvItems, getRecipeItems]]
  
	local tCRecipes = {} --recipes it can craft with items in inventory
	local tInvItems = getInvItems() --items in inventory
	for k, v in pairs(tRecipes) do
    if type(v)=="table" then
      for iRecipe = 1, #v do
        bFound = true
        local tRecipeItems = getRecipeItems(k, iRecipe)
        for k1, v1 in pairs(tRecipeItems) do
          if not tInvItems[k1] then
            bFound = false
            break
          else
            if tInvItems[k1]<v1 then
              bFound = false
              break
            end
          end
        end
        if bFound then tCRecipes[#tCRecipes+1] = {[k] = iRecipe} end
      end  
    end
  end
  if #tCRecipes~=0 then return true, tCRecipes
  else return false
  end
end

function haveItems(sRecipe, nIndex) --[[ Builds a table with the diference between the recipe and the inventory.
  23/11/2021 v0.3.0
  Param: sRecipe - string recipe name.
          nIndex - number index of the recipe
  Return: false/true, table - with ingredients name and the diference between the recipe and inventory.
          nil - if no recipe name was supplied and there isn't tRecipes.lastRecipe and there is not a recipe in inventory.
              - if sRecipe dosn't exist, (never was made).
  Note: on the table, negative values indicate missing items.
        if not it returns true and the table.
  Sintax: haveItems([sRecipeName = tRecipes.lastRecipe][, nIndex =1])
  ex: haveItems() = haveItems(tRecipes.lastRecipe, 1) - Retuens the table with the diference between the inventory and the recipe.
  Dependencies: getParam, getRecipeItems, getInvItems]]
  
  sRecipe, nIndex = getParam("sn", {"", 1}, sRecipe, nIndex)
  if sRecipe == "" then sRecipe = tRecipes.lastRecipe end
  if not sRecipe then return false, "haveItems(RecipeName, Index) - Recipe name not supplied." end

  local tNeededIng
  tNeededIng, message = getRecipeItems(sRecipe, nIndex)
  if not tNeededIng then return nil, "haveItems(sRecipe, nIndex) - "..message end

  local tInvIng = getInvItems()
  local tIngredients = {}
  local bHave = true
  
  for k,v in pairs(tNeededIng) do
    tIngredients[k] =  -v
    for k1,v1 in pairs(tInvIng) do
      if k == k1 then
        tIngredients[k] = tIngredients[k] + v1
      end
    end
    if tIngredients[k] < 0 then bHave = false end
  end
  return bHave, tIngredients
end

function saveRecipes() --[[ Saves tRecipes in a file as "tRecipes.txt"
  19/10/2021 v0.2.0
  Returns false - if it couldn't save file.
           true - if it could save file.
  sintax: saveRecipes()
  Dependencies: saveTable]]
  
	return saveTable(tRecipes, "tRecipes.txt")
end

function loadRecipes() --[[ Loads tRecipes from file "tRecipes.txt"
  19/10/2021 v0.2.0
  Returns false - if it couldn't load file.
           true - if it could load file.
  sintax: loadRecipes()
  Dependencies: loadTable, isDicEmpty]]
  
	local t = loadTable("tRecipes.txt")
	if not t then return false,"Can't load tRecipes.txt"
  elseif t and isDicEmpty(t) then return false, "File tRecipes.txt is empty."
  end
	tRecipes = t
  return true
end

function getRecipe(sRecipe, nIndex) --[[ Gets the recipe from tRecipes.
  14/4/2022 v0.3.0
  Param:  sRecipe - recipe name.
           nIndex - recipe index.
  Returns: table - the recipe.
           false - if recipe name is not supplied and doesn't exist last recipe.
                 - if recipe name doesn't exist.
                 - if recipe index doesn't existy.
  Sintax: getRecipe([sRecipe = tRecipes.lastRecipe][, nIndex=1])
  Dependencies: getParam]]
  
  sRecipe, nIndex = getParam("sn", {"", 1}, sRecipe, nIndex)
  if sRecipe == "" then sRecipe = tRecipes.lastRecipe end
  if not sRecipe then return false, "Must supply recipe name." end
  if not tRecipes[sRecipe] then return false, "Recipe name not found." end
  if not tRecipes[sRecipe][nIndex] then return false, "Recipe index not found." end
  return tRecipes[sRecipe][nIndex]
end

function getInvRecipe() --[[ Builds a table with items and their position from inventory (the recipe).
  19/10/2021 v0.3.0
  Returns false - if it is not a recipe in the inventory.
        tRecipe - the recipe with items and positions.
  Sintax: getInvRecipe()
  Note: Trecipe[item number].name = item name
        (the first item in table only have the item name)
        Trecipe[item number > 1].name = item name
        Trecipe[item number > 1].col = distance to first item col
        Trecipe[item number > 1].lin = distance to first item lin
        (the 2nd and posterior items have name, col and lin indexes in table)]]
  
  if not turtle.craft(0) then return false, "This is not a recipe." end
  
	local index, tFirstItem, tData, tRecipe = 1
	
	for lin = 0, 3 do
		for col = 0, 3 do
			tData = turtle.getItemDetail(lin*4+col+1)
			if tData then
				if not tFirstItem then
					tRecipe = {}
          tRecipe[index] = {}
          tRecipe[index][1] ={}
          tRecipe[index][1] = tData.name
          tFirstItem = {}
          tFirstItem.col = col
          tFirstItem.lin = lin
				else
          tRecipe[index] = {}
					tRecipe[index][1] = {}
          tRecipe[index][1] = tData.name
					tRecipe[index].col = col - tFirstItem.col
					tRecipe[index].lin = lin - tFirstItem.lin
				end
        index = index + 1
			end
		end
	end
  return tRecipe
end

function getMaxCraft() --[[ Returns maximum limit to craft the recipe on inventory.
  19/10/2021 v0.2.0
  Returns false - if it is not a recipe in the inventory.
        tRecipe - the recipe with items and positions.
  sintax: getMaxCraft()
  Dependencies: getInvItems, countItemSlot]]
  
  --if not turtle.craft(0) then return false, "This is not a recipe." end
  local tIng = getInvItems() --[ingredient name] = quantity
  local tIngSlots = countItemSlots() --[ingredient name] = quantity of slots ocupied

  local minCount = 512
	for k,v in pairs(tIng) do
    for k1, v1 in pairs(tIngSlots) do
      if k == k1 then
        if minCount > (v/v1) then
          minCount = v/v1
          break
        end
      end
    end
  end
	return math.floor(minCount)
end

function getFirstItemCoords(sRecipe, nIndex) --[[ Returns the column and line=0 of the first item in the recipe.
  19/10/2021 v0.2.0
  Param: sRecipe - stringh recipe name.
          nIndex - number index of the recipe tRecipes[sRecipe][nIndex].
  Returns:  col, lin - the column and line of first item.
               false - if the recipe name was not supplied and doesn't exist in tRecipes.lastRecipe.
                     - if this recipe does not exist.
  sintax: getFirstItemCoords([sRecipe=tRecipes.lastRecipe][, nIndex=1])
  Dependencies: getParam]]
  
  sRecipe, nIndex = getParam("sn", {tRecipes.lastRecipe, 1}, sRecipe, nIndex)                       
  if type(sRecipe) == "number" then return false, "Must supply recipe name." end
  if not tRecipes[sRecipe] then return false, "Recipe not found." end

  local col = 9
  local tRec = tRecipes[sRecipe][nIndex].recipe
  for iRec = 1, #tRec do
    if tRec[iRec].col then
      if tRec[iRec].col < col then col = tRec[iRec].col end
    end
  end
  if col > 0 then return 0, 0 end
  return math.abs(col), 0
end

function searchSpace(sItemName, nStartSlot, bWrap) --[[ Search for space in a slot that has sItemName.
  19/10/2021 v0.2.0
  Param: sItemName - string item name.
        nStartSlot - number starting slot.
             bWrap - boolean if search wraps around the inventory.
  Returns:  nSlot, nSpace - Slot where is this item, and number of space.
                    false - if it didn't find a slot with sItemName and some space.
  sintax: searchSpace(sItemName [, nStartSlot = Selected slot][, bWrap = true]).
  ex: searchSpace("minecraft:oak_planks") - Search for a not complete stack of oak boards.
      searchSpace("minecraft:cobblestone", 16, false) - Checks if slot 16 has cobblestone and space for more.
      searchSpace("minecraft:cobblestone", 5) - Searchs for cobblestone a incomplete stack, starting at slot 5 in all inventory.
  Dependencies: search, incSlot]]
  
  local nSlot, nSpace = nStartSlot
  repeat
    nSlot = search(sItemName, nSlot, bWrap)
    if nSlot then
      nSpace = turtle.getItemSpace(nSlot)
      if nSpace > 0 then return nSlot, nSpace end
    end
    nSlot = incSlot(nSlot, bWrap)
  until nSlot == nStartSlot
  return false
end

function clearSlot(nSlot, bWrap) --[[ Clears content of slot, moving items to another slot.
  19/10/2021 v0.2.0
  Param: nSlot - number slot to clear.
         bWrap - slot where to put excess items can be lower than nSlot(wrap around inventory).
  Returns:  false - if there is no space to tranfer items.
             true - if the slot is empty.
              nil - if nSlot is out of range [1..16].
  Sintax: clearSlot([nSlot=selected slot][], bWrap)
  Dependencies: getParam, isEmptySlot, leaveItems]]
  
  nSlot, bWrap = getParam("nb", {turtle.getSelectedSlot(), true}, nSlot, bWrap)
  if nSlot > 16 or nSlot < 1 then return nil, "clearSlot(Slot, Wrap) - Slot out of range." end
  if isEmptySlot(nSlot) then return true end
  if turtle.getSelectedSlot() ~= nSlot then turtle.select(nSlot) end 
  return leaveItems(0, bWrap)
end  
    
function transferFrom(nSlot, nItems) --[[ Transfer nItems from nSlot to selected slot.
  02/11/2021 v0.2.1
  Param: nSlot - number slot where to transfer from.
        nItems - number items to transfer from.
  Returns:  number of items in selected slot.
            nil - if nSlot not supplied.
                - if nItems is not a number
          false - if nSlot is empty.
                - if nSlot is out of range [1..16].
                - if selected slot is full.
  sintax: transferFrom(nSlot [, nItems=64])]]
  
  if not nSlot then return nil, "transferFrom(nSlot, nItems) - Must supply origin slot." end
  nItems = nItems or DEFSTACK --default stack
  
  local tData = turtle.getItemDetail(nSlot)
  if not tData then return false, "Empty origin slot." end
  local destSlot = turtle.getSelectedSlot()

  if nSlot < 1 or nSlot > 16 then return false, "transferFrom(nSlot, nItems) - Slot out of range [1..16]." end
  turtle.select(nSlot)

  if type(nItems) ~= "number" then return nil, "transferFrom(nSlot, nItems) - nItems must be a number." end
  if nItems < 0 then return nil, "transferFrom(nSlot, nItems) - nItems must be positive." end
  if not turtle.transferTo(destSlot, nItems) then
    turtle.select(destSlot)
     return false, "Couldn't tranfer items."
  end
  turtle.select(destSlot)
  tData = turtle.getItemDetail(destSlot)
  if not tData then return 0 end
  return tData.count
end

function recipeSlots(sRecipe, nIndex) --[[ Builds a table with item and quantity of slots ocupied by the item.
  21/01/2022 v0.2.0
  Param:  SRecipe - string recipe name.
           nIndex - number recipe index.
  Returns:  table with item name and quantity of slots ocupied by it.
            false - if sRecipe is not supplied and tRecipes.lastRecipe doesn't exist.
                  - if tRecipes[sRecipe] doesn't exist.
                  - if tRecipes[sRecipe][nIndex] doesn't exist.
	sintax: recipeSlots([sRecipe=tRecipes.lastRecipe][, nIndex=1])
	ex: recipeSlots("minecraft:wooden_shovel") - Returns: {["minecraft:oak_planks"]=1, ["minecraft:stick"]=2}
  Dependencies: getParam]]

  sRecipe, nIndex = getParam("sn", {tRecipes.lastRecipe, 1}, sRecipe, nIndex)                       
  if type(sRecipe) == "number" then return false, "recipeSlots(sRecipe, nIndex) - Must supply recipe name." end
  if not tRecipes[sRecipe] then return false, "Recipe not found." end
  if not tRecipes[sRecipe][nIndex] then return false, "Recipe index doesn't exist." end

  local tRecipe = tRecipes[sRecipe][nIndex].recipe
    local tSlots = {}
  for i=1, #tRecipe do
    if not tSlots[tRecipe[i][1] ] then tSlots[tRecipe[i][1] ] = 1
    else tSlots[tRecipe[i][1] ] = tSlots[tRecipe[i][1] ] + 1
    end
  end
  return tSlots
end

function calcAverage(tSlots, tIng) --[[ Builds a table with item and average between items and slots.
  21/01/2022 v0.2.0
  Param:  tSlots - table with item name and quantity of slots ocupied in the recipe.
            tIng - table with item name and quantity in the inventory.
  Returns: table with item and average between items and slots.
           false - if tSlots not supplied.
                 - if tIng not supplied.
	sintax: calcAverage(tSlots, tIng)
	ex: calcAverage(tSlots, tIng)]]

  if not tSlots then return false, "calcAverage(tSlots, tIng) - Table of quantity of slots ocupied by recipe not supplied." end
  if not tIng then return false, "calcAverage(tSlots, tIng) - Table of items in the inventory not supplied." end

  local tMean = {}
  for k,v in pairs(tSlots) do
    for k1,v1 in pairs(tIng) do
      if k == k1 then
        if not tMean[k] then tMean[k] = v1/v end
      end
    end
  end
  return tMean
end

function arrangeRecipe(sRecipe, nIndex) --[[ Arranges items in inventory to craft a recipe.
  21/01/2022 v0.2.0
  Param: sRecipe - recipe name.
          nIndex - recipe index (tRecipes[recipeName][index])
  Returns:  true - if items from the recipe was arranged.
            false - if no recipe name was supplied and there isn't tRecipes.lastRecipe.
                  - if the recipe is not registered.
                  - if the recipe index doesn't exist.
                  - if some slot couldn't be cleared.
                  - if it couldn't leave the exact number of items in a slot.
                  - if it doesn't have enough items to craft recipe.
  sintax: arrangeRecipe([sRecipe=tRecipes.lastRecipe][, nIndex=1])
	ex: arrangeRecipe("minecraft:wooden_shovel") - Arranges items in inventory to craft a wooden shovel.
  Dependencies: getParam, haveItems, calcAverage, getFirstItemCoords, clearSlot, incSlot, leaveItems]]

  sRecipe, nIndex = getParam("sn", {"", 1}, sRecipe, nIndex)              
  if sRecipe == "" then sRecipe = tRecipes.lastRecipe end
  if not sRecipe then return false, "arrangeRecipe(sRecipe, nIndex) - Must supply recipe name." end
  if not tRecipes[sRecipe] then return false, "Recipe name does not exist." end
  if not tRecipes[sRecipe][nIndex] then return false, "Recipe index doesn't exist." end

  if not haveItems(sRecipe, nIndex) then return false, "Don't have anough ingredients." end

  local tAverage = calcAverage(recipeSlots(sRecipe), getInvItems())
  local nRCol, nRLin = getFirstItemCoords(sRecipe, nIndex)
  local nSlot, nRSlot = 1, nRLin * 4 + nRCol + 1
  local tRecipe = tRecipes[sRecipe][nIndex].recipe
  local tTmpLeave = {}
  for iItems=1, #tRecipe do
    local sItem = tRecipe[iItems][1]
    if tRecipe[iItems].col then nRSlot = tRecipe[iItems].lin * 4 + tRecipe[iItems].col + 1 end
    while nSlot < nRSlot do
      if not clearSlot(nSlot, false) then
        return false, "Couldn't clear slot, "..tostring(nSlot)
      end
      nSlot = incSlot(nSlot, false)
    end
    nSlot = incSlot(nSlot, false)
    if not tTmpLeave[sItem] then tTmpLeave[sItem] = tAverage[sItem]
    else tTmpLeave[sItem] = tTmpLeave[sItem] + tAverage[sItem]
    end
    turtle.select(nRSlot)
    local nLeaveItem = math.floor(tTmpLeave[sItem])
    if not leaveItems(sItem, nLeaveItem, false) then
      return false, "Couldn't leave only "..tostring(nLeaveItem).." "..sItem.." items."
    end
    tTmpLeave[sItem] = tTmpLeave[sItem] - nLeaveItem
  end
  return true
end

function setCraftSlot(nSlot) --[[ Sets the craft resulting slot CSlot, in tRecipes.
  03/11/2021 v0.2.0
  Param: nSlot - number slot where the product of the recipe is put.
  Returns:  nil - if nSlot is not in range[1..16].
           true - if was set tRecipes["CSlot"].]]

  nSlot = nSlot or turtle.selectedSlot()
  if nSlot < 0 or nSlot > 16 then return nil, "setCraftSlot(nSlot) - nSlot out of range." end
  tRecipes["CSlot"] = nSlot
  return true
end

function flattenInventory() --[[ Averages all the item stacks in inventory.
  26/01/2022 v0.2.0
  Returns:  true
  Sintax: flattenInventory()
  Dependencies: getInvItems, countItemSlots, getInventory]]

  local tTotIng = getInvItems()
  local tTotSlots = countItemSlots()
  local tInv = getInventory() --get [slot][itemName]=Quantity
  local nMean

  function slotBelowMean(sItem, nMean)
    for i = 1, 16 do
      if tInv[i] and tInv[i][sItem] then
        if tInv[i][sItem] < nMean then return i, tInv[i][sItem] end
      end
    end
    return false
  end

  function slotAboveMean(sItem, nMean) 
    for i = 1, 16 do
      if tInv[i] and tInv[i][sItem] then
        if tInv[i][sItem] > nMean then return i, tInv[i][sItem] end
      end
    end
    return false
  end

  for k,v in pairs(tTotIng) do
    for k1,v1 in pairs(tTotSlots) do
      if k == k1 then
        nMean = math.floor(v / v1)
        local nDestSlot, nDestQuant = slotBelowMean(k, nMean )
        while nDestSlot do
          local nDestQuantNeeded = nMean - nDestQuant
          local nOrgSlot, nOrgQuant = slotAboveMean(k, nMean)
          while nOrgSlot do
            local nOrgTrans = nOrgQuant - nMean
            if nOrgTrans > nDestQuantNeeded then nOrgTrans = nDestQuantNeeded end
            turtle.select(nOrgSlot)
            turtle.transferTo(nDestSlot, nOrgTrans)
            tInv[nDestSlot][k] = nDestQuant + nOrgTrans
            tInv[nOrgSlot][k] = nOrgQuant - nOrgTrans
            if tInv[nDestSlot][k] >= nMean then break end
            nOrgSlot, nOrgQuant = slotAboveMean(k, nMean)
          end
          nDestSlot, nDestQuant = slotBelowMean(k, nMean )
        end
      end
    end
  end
  return true
end

function itemsBelong(sRecipe, nIndex) --[[ Checks if all the items in inventory belong to a recipe.
  26/01/2022 v0.2.0
  Param:  sRecipe - string recipe name.
           nIndex - index of tReecipes[sRecipe][nIndex].
  Returns:  false, table of items that dont belong to recipe {itemname=quantity,...}.
            nil - if sRecipe name is not supplied and tRecipes.lastRecipe is empty.
          false - if sRecipe is not in tRecipes or recipe index not found.
  Sintax: itemsBelong([sRecipe=tRecipes.lastRecipe])
  ex: itemsBelong("minecraft:wooden_shovel") - Returns false if there is items that don't belong to the recipe, otherwise returns true.
  Dependencies: getParam]]

  sRecipe, nIndex = getParam("sn", {tRecipes.lastRecipe, -1}, sRecipe, nIndex)
  if not sRecipe then return nil, "itemsBelong([sRecipe=tRecipes.lastRecipe]) - Recipe name not supplied." end
  if not tRecipes[sRecipe] then return false, "Recipe not found." end
  if nIndex ~= -1 then
    if not tRecipes[sRecipe][nIndex] then return false, "Recipe index not found." end
  end

  local bOnly1, tmpIndex, tRecipe = true, nIndex
  local tItems, bExcess = {}, true
  for nSlot = 1, 16 do
    local tData = turtle.getItemDetail(nSlot)
    if tData then
      local bFound = false
      if nIndex == -1 then
        bOnly1 = false
        tmpIndex = 1
      end

      repeat
        tRecipe = tRecipes[sRecipe][tmpIndex].recipe
        for iRec = 1, #tRecipe do
          if tRecipe[iRec][1] == tData.name then
            bFound = true
            break
          end
        end
        tmpIndex = tmpIndex + 1
      until bOnly1 or tmpIndex > #tRecipes[sRecipe] or bFound

      if not bFound then
        if tItems[tData.name] then tItems[tData.name] = tItems[tData.name]+ tData.count
        else
          tItems[tData.name] = tData.count
          bExcess = false
        end
      end
    end
  end
  return bExcess, tItems
end

function getRecipeIndex(sRecipe, tRecipe) --[[ Returns a number (index) of the recipe in tRecipes.
  01/02/2022 v0.3.0
  Param: sRecipe - string recipe name.
         tRecipe - table with a recipe from inventory.
  Returns: number - index of the recipe in tRecipes.
  Sintax: getRecipeIndex([sRecipe=tRecipes.lastRecipe][, tRecipe=recipe in inventory])
  ex:getRecipeIndex()
  Dependencies: getParam, getInvRecipe]]

  sRecipe, tRecipe = getParam("st", {tRecipes.lastRecipe,{}}, sRecipe, tRecipe)
  if not sRecipe then return false, "getRecipeIndex(sRecipe, tRecipe) - Recipe name not supplied."
  else
    if not tRecipes[sRecipe] then return false, "Recipe name not found."
    elseif #tRecipe == 0 then
      if not turtle.craft(0) then return 1
      else
        tRecipe = getInvRecipe()
        if not tRecipe then return false, "Couldn't create recipe from inventory" end
      end
    end
  end

  for iRecipes = 1, #tRecipes[sRecipe] do
    local tRecs = tRecipes[sRecipe][iRecipes].recipe
    local bFound = false
    if #tRecs == #tRecipe then
      for iItems = 1, #tRecipe do
        local bFoundItem = false
        for iRepItems = 1, #tRecs[iItems] do
          if tRecs[iItems][iRepItems] == tRecipe[iItems][1] then
            bFoundItem = true
            break
          end
        end
        if not bFoundItem then break end

        if tRecipe[iItems].col then
          if (tRecipe[iItems].col == tRecs[iItems].col) and
             (tRecipe[iItems].lin == tRecs[iItems].lin) then bFound = true
          else
              bFound = false
              break
          end
        else bFound = true
        end
      end
      if bFound then return iRecipes end
    end
  end
  return false
end

function colLinMatch(tRecs, tRec) --[[ Compares recipes items position, returns true if is the same.
  21/04/2022 v0.3.0
  Param: tRecs - recipe from tRecipes.
          tRec - recipe to compare.
  Returns: true - if items in recipes have the same position.
          false - if items in recipes have the diferent position or diferent number of items.
            nil - if invalid parameter type.
  Sintax: colLinMatch(tRecs, tRec)
  Note: get tRecs from getRecipe(), and tRec from getInvRecipe().
  ex:getRecipeIndex()]]

  if (type(tRecs) ~= "table") or (type(tRec) ~= "table") then
    return nil, "colLinMatch(tRecs, tRec) - tRecs and tRec must be tables."
  end
  if #tRecs.recipe ~= #tRec then return false end
  local bFound = true
  for iRecs = 1, #tRecs do
    if tRec[iRecs].col then
      if (tRec[iRecs].col ~= tRecs[iRecs].col) or (tRec[iRecs].lin ~= tRecs[iRecs].lin) then
        bFound = false
        break
      end
    end
  end
  return bFound
end

function getSecSumItems(nSlot, bWrap) --[[ Gets the sum of items in sequencial not empty slots.
  25/06/2022 v0.3.0
  Param: nSlot - number first slot to sum.
         bWrap - boolean if the sum wraps around the inventory.
  Returns: number the sum of items in sequencial slots.
  Sintax: getSecSumItems([nSlot=selected slot])
  Note: it stops if empty slot or end of inventory.
  ex: getSecSumItems(14) - sums the items in slot 14, 15 and 16 if not empty.)
  Dependencies: getParam, incSlot]]
  
  nSlot, bWrap = getParam("nb", {turtle.getSelectedSlot(), true}, nSlot, bWrap)
  if type(nSlot) ~= "number" then return nil, "getSecSumItems(Slot) - Slot must be a number." end
  if nSlot < 1 or nSlot > 16 then return nil, "getSecSumItems(Slot) - Slot must be between 1 and 16." end

  local nSum, nStartSlot = 0, nSlot
  repeat
    local nCount = turtle.getItemCount(nSlot)
    if nCount == 0 then return nSum end
    nSum = nSum + nCount
    nSlot = incSlot(nSlot, bWrap)
  until (not nSlot) or (nSlot == nStartSlot)
  return nSum
end

function getProdQuant() --[[Gets quantity of products made with 1 recipe in inventory.
  31/03/2022 v0.3.0
  Returns: number - quantity of products made with 1 inventory recipe.
  Sintax: getProdQuant()
  Note: this function crafts the recipe in inventory.
  ex: getProdQuant()
  Dependencies: getMaxCraft, invLowerStack, flattenInventory, getSecSumItems]]
  
  local nCount
  if not turtle.craft(0) then return false, "Inventory doesn't contain a recipe." end

  nCount = getMaxCraft()
  if nCount > invLowerStack() then flattenInventory() end

  if not tRecipes["CSlot"] then tRecipes["CSlot"] = CSLOT end
  turtle.select(tRecipes["CSlot"])

  turtle.craft(nCount)
  return getSecSumItems(tRecipes["CSlot"])/nCount
end

function addRecipe(sRecipe, tRecipe, nCount) --[[Returns index of recipe.
  31/03/2022 v0.3.0
  Param:  sRecipe - name of recipe
          tRecipe - recipe table, get if from getInvRecipe.
           nCount - quantity of products made with this recipe.
  Returns:  number - index of recipe (tRecipes[sRecipe][index])
               nil - if sRecipe not supplied and doesn't exits tRecipes.lastRecipe.
                   - if tRecipe is not supplied and there is no recipe in inventory.
  Syntax: addRecipe(sRecipe[, tRecipe=recipe in inventory][, nCount])
  Note: if no nCount is supplied this function crafts the recipe to obtain it.
  ex: addRecipe("minecraft:stick", getInvRecipe(), 4) - returns the index of the recipe stored in tRecipes["minecraft:stick"]
  Dependencies: getParam, getInvRecipe, getProdQuant, getItemName, getRecipeIndex]]
  
  sRecipe, tRecipe, nCount = getParam("stn",{"", {}, -1}, sRecipe, tRecipe, nCount )

  if next(tRecipe) == nil then
    tRecipe = getInvRecipe()
    if not tRecipe then return nil, "addRecipe(sRecipe, tRecipe, nCount) - Recipe table not supplied." end
  end

  if (nCount == -1) or (not sRecipe) then
    nCount = getProdQuant()
    if not nCount then return nil, "addRecipe(sRecipe, tRecipe, nCount) - Recipe name not supplied." end
    sRecipe = getItemName()
  end

  if tRecipes[sRecipe] then --recipe exists
    nIndex = getRecipeIndex(sRecipe, tRecipe)
    if nIndex then
      tRecipes.lastRecipe = sRecipe
      tRecipes.lastIndex = nIndex
      return nIndex
    end
  else
    tRecipes[sRecipe] = {}
    tRecipes[sRecipe][1] = {}
    tRecipes[sRecipe][1].recipe = tRecipe
    tRecipes[sRecipe][1].count = nCount
    tRecipes.lastRecipe = sRecipe
    tRecipes.lastIndex = 1
    return 1
  end

  --recipe exists but items are not the same
  nIndex = #tRecipes[sRecipe]+1
  tRecipes[sRecipe][nIndex] = {}
  tRecipes[sRecipe][nIndex].recipe = tRecipe
  tRecipes[sRecipe][nIndex].count = nCount
  tRecipes.lastRecipe = sRecipe
  tRecipes.lastIndex = nIndex
  return nIndex
end

function craftRecipe(sRecipe, nLimit) --[[ Craft a recipe.
  26/01/2022 v0.3.0
  Param: sRecipe - string recipe name.
          nLimit - number recipes to craft.
  Returns: true, string product name, number index of recipe, number quantity crafted.
           true - if nLimit == 0 and could craft a recipe.
           nil - if nLimit out of range [0..64]
               - if no recipe name was supplied in the first recipe to craft.
           false - if inventory is empty.
                 - if there is no recipe in inventory and the recipe name wasn't found
                 - if there are missing items or this recipe was never craft.
                 - if it couldn't arrange items as a recipe in inventory.
                 - if there isn't a empty slot to craft the recipe to.
                 - if inventory has items that don't belong to the recipe.
                 - if when crafting the recipe the resulting items vanishes
  Sintax: craftRecipe(sRecipe=inventory recipe/tRecipes.lastRecipe[, nLimit=64])
  ex: craftRecipe() - craft the recipe in invenrtory.
      craftRecipe("minecraft:wooden_shovel", 1) - Craft one wooden shovel.
  Dependencies: isInventoryEmpty, getParam, craftInv, getInvRecipe, getRecipeIndex, canCraftRecipe, arrageRecipe, invLowerStack, flattenInventory, setCraftSlot, isEmptySlot, getFreeSlot, getInventory, itemsBelong, cmpInvIncreased, getSecSumItems, addRecipe]]
              
  if isInventoryEmpty() then return false, "Inventory is empty." end
  sRecipe, nLimit = getParam("sn", {"", DEFSTACK}, sRecipe, nLimit)
  if nLimit == 0 then return turtle.craft(nLimit) end
  if nLimit < 0 or nLimit > DEFSTACK then return nil, "craftRecipe(sRecipe, nLimit) - nLimit must be a number[1.."..tostring(DEFSTACK).."]." end

  local nIndex
  local isRecipeInv = turtle.craft(0)
  if sRecipe == "" then
    if isRecipeInv then return craftInv(nLimit)
    else
      sRecipe = tRecipes.lastRecipe
      nIndex = tRecipes.lastIndex
      if not sRecipe then return nil, "craftRecipe(sRecipe, nLimit) - Must supply recipe name." end
    end
  end
  
  if not tRecipes[sRecipe] then
    if isRecipeInv then return craftInv(nLimit)
    else return false, "There is no recipe in inventory and recipe name not found."
    end
  end

  local tRecipe = getInvRecipe()
  if not nIndex then
    if isRecipeInv then nIndex = getRecipeIndex(sRecipe, tRecipe) end
  end

  if not nIndex then
    local bSuccess
    bSuccess, nIndex = canCraftRecipe(sRecipe)
    if not bSuccess then return false, "There are missing items or this recipe was never crafted" end
    if not arrangeRecipe(sRecipe, nIndex) then return false, "Can't arrange items in inventory." end
    tRecipe = getInvRecipe()
  end

  if invLowerStack() < nLimit then flattenInventory() end

  if not tRecipes["CSlot"] then setCraftSlot(13) end
  if not isEmptySlot(tRecipes["CSlot"]) then
    local nSlot = getFreeSlot()
    if not nSlot then return false, "No empty slot to craft recipe to." end
    tRecipes["CSlot"] = nSlot
  end
  turtle.select(tRecipes["CSlot"])

  local tInv1 = getInventory()
  if not turtle.craft(nLimit) then
    local success, tItems = itemsBelong(sRecipe)
    if not success then return false, "Remove items that do not belong to the recipe." end
  end

	local tInv2 = getInventory()

  local bInc, tInc = cmpInvIncreased(tInv1, tInv2)
  if not bInc then return false, "i don't know where the product went." end

  local nSlot, _ = next(tInc, nil)
  local sRecipe = next(tInc[nSlot]) --get the product name.
  local nCount = getSecSumItems(tRecipes["CSlot"])
  nIndex = addRecipe(sRecipe, tRecipe, nCount )

  return true, sRecipe, nIndex, nCount
end

function getLowestKey(t) --[[ Gets the lowest key of the table t.
  04/07/2022 v0.3.0
  Param: t - table to look for the lowest key.
  Return: key type - the lowest key.
  Sintax: getLowestKey(t)
  Note: All the keys must have the same type.
  ex: getLowestKey({[1]="minecraft:cobblestone", [-1]="minecraft:stick"}) - returns -1.]]
  
  local Lower
  for k, v in pairs(t) do
    if not Lower then Lower = k
    else if k < Lower then Lower = k end
    end
  end
  return Lower
end

function craftInv(nLimit) --[[ Crafts the recipe in inventory.
  20/05/2022 v0.3.0
  Param: nLimit - number products to craft.
  Returns: true, string product name, number index of recipe, number quantity crafted.
           nil - if nLimit is not a number.
               - if nLimit is out of range [1..64].
           false - if there is no recipe in inventory.
                 - if the turtle cant craft.
                 - if it craft something, but it didnt show up in inventory.
                 - if it couldn't add the recipe.
  Sintax: craftInv([nLimit=64])
  ex: craftInv(12) - craft 12 products of the recipe in inventory.
  Dependencies: getMaxCraft, getInvRecipe, getInventory, cmpInvIncreased, addRecipe]]
  
	nLimit = nLimit or DEFSTACK
	if type(nLimit) ~= "number" then return nil, "craft([Limit="..tostring(DEFSTACK).."]) - Limit must be a number." end
	if nLimit < 1 or nLimit > DEFSTACK then return nil, "craft([Limit="..tostring(DEFSTACK).."]) - Limit must be between 1 and "..tostring(DEFSTACK).."." end

	if not turtle.craft(0) then return false, "There is no recipe in inventory." end
  local nMaxCraft = getMaxCraft() 

	if not tRecipes["CSlot"] then tRecipes["CSlot"] = CSLOT end --set the default crafting slot.
	turtle.select(tRecipes["CSlot"])

	local tRecipe = getInvRecipe()
	local tInv1 = getInventory()
	if not turtle.craft(nLimit) then return false, "Could't craft "..nLimit.." products." end --craft

	local tInv2 = getInventory() --get second snapshot of inventory
	local bInc, tInc = cmpInvIncreased(tInv1, tInv2) --compares the 2 snapshots if there was a increase of items.
	if not bInc then return false, "I don't know where the products went." end --no

	local sRecipe = tInc[next(tInc)].name --get the product name.
  local nSumCount = 0
  for k, v in pairs(tInc) do
    nSumCount = nSumCount + tInc[k].count
  end
  local nCount = nSumCount/nMaxCraft --adjust count for 1 recipe

  local nIndex = addRecipe(sRecipe, tRecipe, nCount) --add the recipe to tRecipes.
  if not nIndex then return false, "Couldn't add recipe." end
  return true, sRecipe, nIndex, nCount
end


------ ROTATING FUNCTIONS ------  

function incFacing(nTurns, nFacing) --[[ Increments nFacing/tTurtle.facing by nTurns
  02/10/2021 v0.2.0
  Param: nTurns - number of 90 degrees turns to the right.
        nFacing - where is the turtle facing 0..3
  Returns: the new direction 0..3
  ex: if turtle is facing "x+"=1
      incFacing(1) - Increments nFacing, nFacing turns to "z+"=2
  Sintax: incFacing([nTurns=1][, nFacing = tTurtle.facing])]]

	local bRestore = false
	if not nFacing then
		nFacing = tTurtle.facing
		bRestore = true
	end
  nFacing = nFacing or tTurtle.facing
  nTurns = nTurns or 1
  nFacing = nFacing + nTurns
  nFacing = bit32.band(nFacing, 3)
	if bRestore then tTurtle.facing = nFacing end
  return nFacing
end

function decFacing(nTurns, nFacing) --[[ Decrements nFacing by nTurns
  02/10/2021 v0.2.0
  Param: nTurns - number of 90 degrees turns to the left.
        nFacing - where is the turtle facing 0..3
  Returns: the new direction 0..3
  Sintax: decFacing([nTurns=1][, nFacing = tTurtle.facing])
  ex: decFacing() - increments tTurtle.facing]]

	local bRestore = false
	if not nFacing then
		nFacing = tTurtle.facing
		bRestore = true
	end
  nTurns = nTurns or 1
  nFacing = nFacing - nTurns
  nFacing = bit32.band(nFacing, 3)
	if bRestore then tTurtle.facing = nFacing end
  return nFacing
end

function turnBack() --[[ Turtle turns back.
  11/09/2021 v0.1.0
  Returns:  true.
  Sintax: turnBack()
  ex: turnBack() - Turns the turtle back.
  Dependencies: turnRight]]

  return turnRight(2)
end

function turnDir(sDir) --[[ Turtle turns to sDir direction.
  27/08/2021 v0.4.0
  Param: sDir - string diretion "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
  Returns:  true - if sDir is a valid direction.
            false - if sDir is not a valid direction.
  Sintax: turnDir([sDir="back"])
  ex: turnDir("back") or turnDir() - Turns the turtle back.
			turnDir("z-") or turnDir("north") or turnDir(0) - Turns the turtle to z-, north.
  Dependencies: strLower, turnTo, turnBack, turnLeft, turnRight]]
			
  sDir = sDir or "back"
  sDir = strLower(sDir)

	if turnTo(sDir) then return true
	else
    if sDir == "forward" then return true
		elseif sDir == "back" then return turnBack()
		elseif sDir == "left" then return turnLeft()
		elseif sDir == "right" then return turnRight()
		end
	end
	return false
end

function turnLeft(nTurns) --[[ Turns the turtle left nTurns * 90 degrees.
  22-07-2022 v0.4.0
  Param: nTurns - number of 90 degrees turns to the left.
  Returns: true
           nil - if nTurns is not a number.
  Note: if nTurns < 0 it turns to the right.
         if SCAN if on stores the block in front of it, after the turn, in the tWorld table
  Sintax: turnLeft([nTurns=1])
  ex: turnLeft() - turns once to the left.
      turnLeft(-1) - turns once to the right.
  Dependencies: turnRight, decFacing, scan]]
  
  local i
  nTurns = nTurns or 1
  if type(nTurns) ~= "number" then return nil, "turnLeft(Turns) - Turns must be a number." end
  if nTurns < 0 then return turnRight(math.abs(nTurns)) end
  nTurns = bit32.band(nTurns, 3) --nTurns must be 0..3
  for i = 1, nTurns do
    turtle.turnLeft()
    tTurtle.facing = decFacing()
    if SCAN then scan() end
  end
  return true
end

function turnRight(nTurns) --[[ Turns the turtle right nTurns * 90 degrees.
  22-07-2022 v0.4.0
  Param: nTurns - number of 90 degrees turns to the right.
  Returns: true
           nil - if nTurns is not a number.
  Note: if nTurns < 0 it turns to the left.
        if SCAN if on stores the block in front of it, after the turn, in the tWorld table
  Sintax: turnRight([nTurns=1])
  ex: turnRight() - turns once to the right.
      turnRight(-1) - turns once to the left.
  Dependencies: turnLeft, incFacing, scan]]
  
  local i
  nTurns = nTurns or 1
  if type(nTurns) ~= "number" then return nil, "turnRight(Turns) - Turns must be a number." end
  if nTurns < 0 then return turnLeft(math.abs(nTurns)) end
  nTurns = bit32.band(nTurns, 3)
  for i = 1, nTurns do
    turtle.turnRight()
    tTurtle.facing = incFacing()
		if SCAN then scan() end
  end
  return true
end

function turnTo(...) --[[ Turtle turns to direction, block name, empty space, unscanned space.
  21-07-2022 v0.4.0
  Param: nsFacing - "z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3|block name|"any"|"empty"|unscanned space
  Returns: true - if it turn to specified direction, or block.
           nil - if the function has 2 arguments
					 false - if it couldn't turn to that directions ex: up|down.
  sintax: turnTo([... = unscanned space])
	ex: turnTo("up") - it returns false.
			turnTo("z+") - turns to axis z, on the positive way.
			turnTo("north") - turns to north (z-).
			turnTo(0) - turns to z-, north.
      turnTo() - turns to the nearest unscanned space.
  Dependencies: turnToCoord, turnToBlock, turnTo, getNearestBlock, getAllFuelItems, turnLeft, turnRight]]

  arg = {...}
  if #arg >= 3 then return turnToCoord(arg[1], arg[2], arg[3]) end
  if #arg == 0 then return turnToBlock() end
  if #arg ~= 1 then
    return nil, 'turnTo(something) - Invalid number of arguments. "z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3|block name|"any"|"empty"|unscanned space'
  end

  if arg[1] == "fuel" then return turnTo(getNearestBlock(getAllFuelItems())) end

  if tEnts[arg[1] ] then return turnToBlock(arg[1]) end

  local nDir, nRotate;
	nsFacing = arg[1]

  if type(nsFacing) == "number" then
    nsFacing = bit32.band(nsFacing, 3)
    nRotate = nsFacing - tTurtle.facing

  elseif type(nsFacing) == "string" then
    nsFacing = string.lower(nsFacing)
    if carDirType[nsFacing] then --is "north", "south", "west", "east"
      nRotate = carDirType[nsFacing] - tTurtle.facing

    elseif facingType[nsFacing] then --is "z+", "z-", "x+", "x-", "y+", "y-"
      if facingType[nsFacing] > 3 then return false, 'turnTo(something) - Something must be "z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3|block name|"any"|"empty"|unscanned space' end 
      nRotate = facingType[nsFacing] - tTurtle.facing --{-3..3}
    else return nil, 'turnTo(something) - Invalid direction or block not scanned "z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3|block name|"any"|"empty"|unscanned space'
    end
  else return nil, 'turnTo(something) - Invalid type only strings or numbers.'
  end

	if nRotate == 0 then return true end; --no need to rotate
	
  if nRotate < -2 then nRotate = 1 --3 lefts = 1 right
  else if nRotate > 2 then nRotate = -1 end --3 rights = 1 left
	end

	if nRotate < 0 then turnLeft(math.abs(nRotate))
	else turnRight(nRotate)
	end

	return true
end

function turnToBlock(sBlock) --[[ Turtle turns to the nearest block.
  15-10-2022 v0.4.0
  Param: sBlock - name of the block to turn to.
  Returns: true - if it turn to sBlock.
           nil - if sBlock is not known.
					 false - if the block was not found in the world.
  sintax: turnToBlock([sBlock=unknown space])
	ex: turnToBlock("minecraft:cobblestone") - turns to the nearest cobblestone.
      turnToBlock() - turns to the nearest unscanned space.
  Dependencies: getNearestBlock, turnToCoord]]

  local x, y, z = getNearestBlock(sBlock)
  if not x then return x, y end
	return turnToCoord(x, y, z)
end

function turnToFuel() --[[ Turtle turns to the nearest fuel in the world.
  14-07-2023 v0.4.0
  Sintax: turnToFuel()
  Alias for turnTo("fuel")]]
  
  return turnTo("fuel")
end

function turnToCoord(x, y, z) --[[ Turtle turns to point x,y,z.
  15-09-2022 v0.4.0
  Param: x, y, z - numbers coords of point.
  Returns: true - if it turn to specified direction
           nil - if x or y or z aren't numbers.
					 false - if it couldn't turn to that directions ex: up|down.
  sintax: turnToCoord(x, y, z)
	ex: turnToCoord(1, 0, 0) - turns to block at 1,0,0.
  Dependencies: checkType, distTo, getKey, turnTo]]

	if not checkType("nnn", x, y, z) then return nil, "turnToCoord(x, y, z) - x,y,z must be numbers" end
	local tLongerDist = {0, index = 0}
	local tDist = {distTo(x, y, z)}
	for i = 1, #tDist do
		if math.abs(tLongerDist[1]) < math.abs(tDist[i]) then tLongerDist = {tDist[i], index = i} end
	end
	local tDir = {["x"] = 1, ["y"] = 2, ["z"] = 3}
	local sDir = getKey(tLongerDist.index, tDir)
	if tLongerDist[1]<0 then sDir = sDir.."-"
	else sDir = sDir .. "+"
	end
	if not turnTo(sDir) then
    tTurtle.looking = (sDir == "y+" and 4 or 0) + (sDir == "y-" and 8 or 0)
  else tTurtle.looking = 0
  end
  return true
end


------ BUILD FUNCTIONS ------

function buildWall(width, height, sBlock) --[[ Builds a wall in front of the turtle.
  18-06-2023 v0.4.0
  Param: width, height - numbers: the width and height of the wall.
                sBlock - string: name of the block to build the wall.
  Returns: true - if all went well.
           false - if no block name was not supplied and the selected slot is empty.
                 - if the block name was not found in inventory.
                 - if there is no more blocks to place.
                 - if it couldn't place a block.
                 - if it couldn't go up/down.
  sintax: buildWall([width=1][, height=1][, sBlock=selected slot])
	ex: buildWall() - places the selected block in front of the turtle.
      buildWall(2) - builds a wall with the selected slot block, having 2 blocks wide.
      buildWall("minecraft:cobblestone") - places a block of cobblestone.
      buildWall(3,5,"minecraft:cobblestone") - builds a wall width 3, height 5, from cobblestone.
  Dependencies: getParam, getItemName, selectSlot, search, sign, place, up, strafeRight]]

  width, height, sBlock = getParam("nns", {1, 1, getItemName()}, width, height, sBlock)

  if sBlock == "" then return false, "buildWall(width, height, blockName) - empty selected slot." end
  
  if sBlock ~= getItemName() then
    if not selectSlot(search(sBlock)) then
      return false, "buildWall(width, height, blockName) - block name not found."
    end
  end

	local sw = sign(width)
	local sh = sign(height)
	for w = 1, width, sign(width) do
		for h = 1, height, sign(height) do
			if not place(sBlock) then
        if getItemName() == "" then
          if not selectSlot(search(sBlock)) then
            return false, "buildWall(width, height, blockName) - no more blocks."
          end
        else return false, "buildWall(width, height, blockName) - couldn't place block."
        end
      end
			if h ~= height then
				if not up(sh) then return false , "buildWall(width, height, blockName) - couldn't go up/down."end
			end
		end
		sh = -sh
		if w ~= width then
      if not strafeRight(sw) then return false end
    end
	end
  return true
end

function buildFloor(width, depth, sBlock) --[[ Builds a plane of blocks in the axis x,z.
  14-07-2023 v0.4.0
  Param: width, depth - the dimentions of the floor.
               sBlock - string the name of the block to build the floor from.
  Returns: true - if the floor was complete.
           false - if no sBlock was supplied and selected slot is empty.
                 - if name of block was not found in inventory.
                 - if turtle can't go up/forward/right/back/left.
                 - if there isn't enough blocks to build floor.
                 - if it couldn't place block.
  Sintax: buildFloor([width = 1][, depth = 1][, sBlock = selected slot block name]
  ex: buildFloor() - builds the floor with 1 selected slot block.
  Dependencies: getParam, getItemName, selectSlot, sign, placeDown, up, forward, strafeRight]]
  
  width, depth, sBlock = getParam("nns", {1, 1, getItemName()}, width, depth, sBlock)

  if sBlock == "" then return false, "buildFloor(width, depth, blockName) - empty selected slot." end
  
  if sBlock ~= getItemName() then
    if not selectSlot(search(sBlock)) then
      return false, "buildFloor(width, depth, blockName) - block name not found."
    end
  end

	local sw = sign(width)
	local sd = sign(depth)
	if not up() then return false, "buildFloor(width, depth, sBlock) - couldn't go up." end
	for w = 1, width do
		for d = 1, depth do
			if placeDown() == 0 then
        if getItemName() == "" then
          if not selectSlot(search(sBlock)) then
            return false, "buildFloor(width, depth, blockName) - no more blocks."
          end
        else return false, "buildFloor(width, depth, blockName) - couldn't place block."
        end
      end
      if d ~= depth then
			  if not forward(sd) then return false, "buildFloor(width, depth, sBlock) - couldn't go forward/back." end
      end
		end
		sd = -sd
    if w ~= width then
		  if not strafeRight(sw) then return false, "buildFloor(width, depth, sBlock) - couldn't go right/left." end
    end
	end
  return true
end

function buildCube(nSide , sBlock) --[[ Builds a cube.
  14-07-2023 v0.4.0
  Param: nSide - number: the cube side measurement.
        sBlock - the block name to build the cube.
  Returns: true - if the cube was built.
           false - if the name of the block was not supplied and the selected slot was empty.
                 - if the block was not found in inventory.
                 - if turtle couldn't go up/forward/right/back/left.
                 - If blocks were insufficient.
                 - if it couldn't place block.
  Sintax: buildCube([nSide = 1][, sBlock = selected slot block name])
  ex: buildCube() - builds a cube with 1 selected slot block.
  Dependencies: getParam, getItemName, selectSlot, up, placeDown, search, forward, strafeRight]]
  
  nSide, sBlock = getParam("ns", {1, getItemName()}, nSide, sBlock)

  if sBlock == "" then return false, "buildCube(size, blockName) - empty selected slot." end
  
  if sBlock ~= getItemName() then
    if not selectSlot(search(sBlock)) then
      return false, "buildCube(size, blockName) - block name not found."
    end
  end

  if nSide < 0 then nSide = math.abs(nSide) end
  local sw, sd = 1, 1
  for nPlane = 1, nSide do
    if not up() then return false, "buildCube(size, sBlock) - couldn't go up." end
    for w = 1, nSide do
      for d = 1, nSide do
        if placeDown() == 0 then
          if getItemName() == "" then
            if not selectSlot(search(sBlock)) then
              return false, "buildCube(size, blockName) - no more blocks."
            end
          else return false, "buildCube(size, blockName) - couldn't place block."
          end
        end
        if d ~= nSide then
          if not forward(sd) then return false, "buildCube(size, sBlock) - couldn't go forward/back." end
        end
      end
      sd = -sd
      if w ~= nSide then
        if not strafeRight(sw) then return false, "buildCube(size, sBlock) - couldn't go right/left." end
      end
    end
    sw = -sw
  end
  return true
end

function buildSquare(nSide , sBlock) --[[ Builds a square.
  31-07-2023 v0.4.0
  Param: nSide - number: the square side measurement.
        sBlock - the block name to build the square.
  Returns: true - if the cube was built.
           false - if no block name was supplied and the selected block is empty.
                 - if the block name was not found in inventory.
                 - if turtle couldn't go forward.
                 - If blocks were insufficient.
                 - if it couldn't place block.
  Sintax: buildSquare([nSide = 1][, sBlock = selected slot block name])
  ex: buildSquare() - builds a cube with 1 block, from selected slot.
  Dependencies: getParam, getItemName, selectSlot, up, placeBelow, search, forward, turnDir]]
  
	nSide, sBlock = getParam("ns", {1, getItemName()}, nSide, sBlock)
	if sBlock == "" then return false, "buildSquare(size, blockName) - empty selected slot." end
	if sBlock ~= getItemName() then
    if not selectSlot(search(sBlock)) then
      return false, "buildSquare(size, blockName) - block name not found."
    end
  end
  
	if not up() then return false, "buildSquare(size, sBlock) - couldn't go up." end
  if nSide == 0 then return true end
  local sTurn = (nSide < 0) and "left" or "right"
  nSide = (nSide < 0) and math.abs(nSide) or nSide
  if nSide == 1 then return placeBelow() == 1 end

	for sides = 1, 4 do
		if placeBelow( nSide - 1 ) ~= ( nSide - 1 ) then
			if getItemName() == "" then
				if not selectSlot(search(sBlock)) then
					return false, "buildSquare(size, blockName) - no more blocks."
				end
			else return false, "buildSquare(size, blockName) - couldn't place block."
			end
		end
    if not forward() then return false, "buildSquare(size, blockName) - couldn't go forward." end
    turnDir(sTurn)
  end
  return true
end

function buildRect(width, depth , sBlock) --[[ Builds a reactangle on the floor, starting at turtle position.
	26-07-2023 v0.4.0
  Param: width, depth - number: width of the rectangle.
	             sBlock - string: name of the block to build the rectangle.
	Returns: true - if the rectangle was built.
					 false - if sBlock was not supplied and the selected slot is empty.
								 - if the sBlock was not found in inventory.
								 - if it couldn't go up/forward/right/left.
								 - if there is insuficient blocks to build the rectangle.
								 - if it couldn't place block.
	Sintax: buildRect([width][,depth][, sBlock = selected slot block name])
	ex: buildRect() - builds a cube with 1 selected block.
	dependencies: getParam, getItemName, selectSlot, placeBelow, search, forward, strafeRight
	]]
	
  if width and (not depth) then depth = width end
  width, depth, sBlock = getParam("nns", {1, 1, getItemName()}, width, depth, sBlock)
  if sBlock == "" then return false, "buildRect(width, depth, blockName) - empty selected slot." end
  
  if sBlock ~= getItemName() then
    if not selectSlot(search(sBlock)) then
      return false, "buildRect(width, depth, blockName) - block name not found."
    end
  end
  
  local spot
  if not up() then
    return false, "buildRect(width, depth, blockName) - couldn't go up."
  else
    spot = setSpot()
  end
  if (width == 1) and (depth == 1) then return placeBelow() == 1 end

	local nAlreadyPlaced = {0, 1, 1, 2}
  local dir = "right"
	if isAny(0, depth, width) then return true end
  if sign(width) ~= sign(depth) then
    dir = "left"
  end
  if sign(depth) == -1 then
    turnBack()
  end
  local nSides = {depth, width, depth, width}

	for side = 1, 4 do
		local nToPlace = math.abs(nSides[side]) - nAlreadyPlaced[side]
		local nPlaced = placeBelow(nToPlace)
		while (nPlaced ~= nToPlace) do
			if getItemName() == "" then
				if not selectSlot(search(sBlock)) then
					return false, "buildRect(size, blockName) - no more blocks."
				else nPlaced = nPlaced + placeBelow(nToPlace - nPlaced)
				end
			else return false, "buildRect(size, blockName) - couldn't place block."
			end
		end
		if side ~= 4 then
      turnDir(dir)
      if (nPlaced ~= 0) and (not forward()) then return false, "buildRect(size, blockName) - couldn't advance." end
    else
      goToSpot(spot)
      removeSpot(spot)
    end
  end
  return true	
end

--not tested
function buildTriangle(width, height ,sBlock)
end

--not tested
function buildPiramid(width, depth, height , sBlock)
end

--not tested
function buildCircle(Radius , sBlock)
end

--not tested
function buildOval(Radius1, Radius2 , sBlock)
end

--not tested
function buildCylinder(Radius, height , sBlock)
end

--not tested
function buildCone(Radius, height , sBlock)
end

------ MOVING AND ROTATING FUNCTIONS ------

function goBack(nBlocks) --[[ Turns back or not and advances nBlocks until blocked.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to walk back.
  Returns:  true if turtle goes all way.
            false if blocked, or invalid parameter.
            nil - if nBlocks type is not a number.
  Note: nBlocks < 0 moves forward, nBlocks >= 0 turns back and advances nBlocks.
  ex: goBack(3) - Turns back and moves 3 blocks forward.
  Dependencies: turnBack, forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "goBack(Blocks) - Blocks must be anumber." end
  if nBlocks >= 0  then turnBack() end
  return forward(nBlocks)
end

function goDir(sDir, nBlocks) --[[ Turtle goes in sDir nBlocks until blocked.
  27/08/2021 v04.0
  Param: sDir - string "forward"|"right"|"back"|"left"|"up"|"down"|"z+"|"x+"|"z-"|"x-"|"y+"|"y-"|"north"|"south"|"west"|"east"
      nBlocks - number of blocks to walk.
  Returns:  true if turtle goes all way.
            false if blocked.
  Sintax: go([sDir="forward"], [nBlocks=1])
  ex: go("left", 3) or go(3, "left") - Rotates left and moves 3 Blocks forward.
      go() - Moves 1 block forward.
      go(-3, "up") - moves 3 blocks down.
  Dependencies: getParam, turnTo, forward, goRight, goBack, goLeft, up, down]]
  
  sDir, nBlocks = getParam("sn", {"forward", 1}, sDir, nBlocks)
  sDir = string.lower(sDir)
  
  if turnTo(sDir) then sDir = "forward" end
  if sDir == "forward" then return forward(nBlocks)
  elseif sDir == "right" then return goRight(nBlocks)
  elseif sDir == "back" then return goBack(nBlocks)
  elseif sDir == "left" then return goLeft(nBlocks)
  elseif sDir == "up" then return up(nBlocks)
  elseif sDir == "down" then return down(nBlocks)
  end
  return false
end

function goLeft(nBlocks) --[[ Turns left or  right and advances nBlocks until blocked.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to walk left.
  Returns:  true if turtle goes all way.
            false if bllocked, or invalid parameter.
            nil - if nBlocks is not a number.
  Note: nBlocks < 0 goes right, nBlocks > 0 goes left, nBlocks = 0 turns left.
  ex: goLeft(3) - Moves 3 Blocks to the left.
  Dependencies: sign, turnDir, forward]]

  nBlocks = nBlocks or 1
  if type(nBlocks) ~= "number" then return nil, "goLeft(Blocks) - Blocks must be a number." end
  local dir = sign(nBlocks)
  if dir >= 0 then turnDir("left")
  else turnDir("right")
  end

  return forward(math.abs(nBlocks))
end

function goRight(nBlocks) --[[ Turns right or left and advances nBlocks until blocked.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to walk right.
  Returns:  true if turtle goes all way.
            false if bllocked, or invalid parameter.
            nil - if nBlocks is not a number.
  Note: nBlocks < 0 goes left, nBlocks > 0 goes right, nBlocks = 0 turns right.
  ex: goRight(3) - Moves 3 Blocks to the right.
  Dependencies: sign, turnDir, forward]]

  nBlocks = nBlocks or 1
  if type(nBlocks) ~= "number" then return nil, "goRight(Blocks) - Blocks must be a number." end
  local dir = sign(nBlocks)
  if dir >= 0 then turnDir("right")
  else turnDir("left")
  end

  return forward(math.abs(nBlocks))
end

function getNeighbors(x, y, z) --[[ Gets the neighbor's coords of x, y, z, or of the turtle.
  12/09/2022 v0.4.0
  Param: x, y, z - numbers coords of block.
  Returns:  table with coords of 6 neighbors.
  Sintax: getNeighbors([x,y,z] = turtle coords)
  ex: getNeighbors() - gets the neighbor's coords, of turtle.]]

  if type(x) == "table" then
    z = x[3]
    y = x[2]
    x = x[1]
  else
    x = x or tTurtle.x
    y = y or tTurtle.y
    z = z or tTurtle.z
  end
	return {{x+1, y, z}, {x-1, y, z}, {x, y+1, z}, {x, y-1, z}, {x, y, z+1}, {x, y, z-1}}
end

function orderByDistance(tP1, tPoints) --[[ Gets the ordered table of distances from a point to a table of points.
  12/09/2022 v0.4.0
  Param: tP1 - a point in space.
     tPoints - several points in space {x, y, z}.
  Returns:  ordered table with pairs {distance from tP1 to tPoints[n], n index of tPoints}
            nil - if tP1 and or tPoints not supplied.
                - if tP1 or tPoints are not tables.
  Sintax: orderByDistance(tP1, tPoints)
  ex: orderByDistance({0,0,0}, getNeighbors(1,0,10)) - returns the ordered table of distance from point tP1 to neighbors of 1,0,10.
  Dependencies: checkType]]

  if (not tPoints) or (not tP1) then return nil, "orderByDistance(tP1, tPoints) - point Tp1 and/or table of points tPoints, not supplied." end
  if not checkType("tt", tP1, tPoints) then return nil, "orderByDistance(tP1, tPoints) - tP1 and tPoints are tables of coords {x, y, z}." end

	local tOrder = {}
	for i = 1, #tPoints do
		tOrder[i] = {math.abs(tP1[1]-tPoints[i][1])+math.abs(tP1[2]-tPoints[i][2])+math.abs(tP1[3]-tPoints[i][3]), i}
	end

	table.sort(tOrder, function(a, b) return a[1] < b[1] end)
	local tRetPoints = {}
	for i = 1, #tOrder do
		tRetPoints[i] = {}
		tRetPoints[i] = tPoints[tOrder[i][2]]
	end
	return tRetPoints
end

function goToNeighbor(x, y, z) --[[ Turtle goes to neighbor, and turns to point x,y,z.
  05-11-2022 v0.4.0
  Param: x, y, z - numbers coords of center point of neighbors to go to.
  Sintax: goToNeighbor(x,y,z)
  Return: true - if it get to one neighbor of x,y,z
          false - if it didn't
  ex: goToNeighbor(1, 5, 10) - goes to neighbor of point (1,5,10)
  Dependencies: getNeighbors, orderByDistance, goTo, turnToCoord]]
  
	local tNeighbors = getNeighbors(x, y, z)
	local tDist = orderByDistance({tTurtle.x, tTurtle.y, tTurtle.z}, tNeighbors)
	for i = 1, #tDist do
		if goTo(tDist[i][1], tDist[i][2], tDist[i][3]) then
			return turnToCoord(x, y, z)
		end
	end
	return false
end

function goTo(x, y, z) --[[ Goes to position x,y,z (no path finding).
  21-07-2022 v0.4.0
  Param: x, y, z - numbers coords to go to.
  Returns: true - if it goes all the way.
           false - if it didn't go all the way.
  ex: goTo(10, 4, 5) - goes to coords 10, 4, 5.
  Dependencies: checkNil, isFuelEnoughTo, distTo, goDir]]

  if checkNil(3, x, y, z) then return false, "goTo(x, y, z) - Must supply x, y, z" end
  if not isFuelEnoughTo(z,x,y) then return false,"goTo(x, y, z) - Not enough fuel." end --have fuel
  local dX, dY, dZ = distTo(x, y, z)
  if dX == 0 and dY == 0 and dZ == 0 then return true end
  
  repeat
    local bHasMoved = false
    if dZ > 0 then
      if goDir("z+", dZ) then bHasMoved = true end
    end
    if dZ < 0 then
      if goDir("z-", math.abs(dZ)) then bHasMoved = true end
    end

    if dX > 0 then
      if goDir("x+", dX) then bHasMoved = true end
    end
    if dX < 0 then
      if goDir("x-", math.abs(dX)) then  bHasMoved = true end
    end

    if dY > 0 then
      if goDir("up", dY) then bHasMoved = true end
    end
    if dY < 0 then
      if goDir("down", math.abs(dY)) then bHasMoved = true end
    end

    dX, dY, dZ = distTo(x, y, z)

  until (bHasMoved == false) or (dX == 0 and dY == 0 and dZ == 0)
  if (dX == 0) and (dY == 0) and (dZ == 0) then return true end
  return false
end

function goToPath(x, y, z) --[[ Turtle goes to x, y, z using path finding.
	09-02-2020	v0.4.0
  Param: x, y, z - destination coords.
  Sintax: goToPath(x, y, z) 
	ex: goToPath(10, 10, 10) - turtle goes to 10, 10, 10
  Dependencies: isNumber, getPath, goTo]]

  if not isNumber(x, y, z) then return false end
	
  local tPath = getPath(x, y, z)
  for i = #tPath, 1, -1 do
    if not goTo(table.unpack(tPath[i])) then return false end
  end
  return true
end

function left(nSteps) --[[ Turtle turns left and walks nSteps.
  31-05-2023 v0.4.0
  Param: nSteps - number the quantity of steps to walk.
  Sintax: left(nSteps)
  ex: left() - turtle turns left.
      left(10) - turtle turns left and walks 10 steps,
  Dependencies: goLeft, turnDir]]

  if nSteps then return goLeft(nSteps)
  else return turnDir("left")
  end
end

function right(nSteps) --[[ Turtle turns right and walks nSteps.
  31-05-2023 v0.4.0
  Param: nSteps - number the quantity of steps to walk.
  Sintax: right(nSteps)
  ex: right() - turtle turns left.
      right(10) - turtle turns left and walks 10 steps
  Dependencies: goRight, turnDir]]

  if nSteps then return goRight(nSteps)
  else return turnDir("right")
  end
end

------ DIG FUNCTIONS ------  

--not tested
function digDir(sDir, nBlocks) --[[ Turtle digs in sDir direction nBlocks.
  08-09-2021 v0.4.0
  Param: sDir - string direction to walk "forward"|"right"|"back"|"left"|"up"|"down"|"north"|"east"|"south"|"west"|"z-"|"x+"|"z+"|"x-"|0..3
      nBlocks - number of blocks to walk in sDir direction. 
  Returns:  true if turtle digs all the way.
            false if blocked, empty space, can't turn that way.
            nil if invalid parameter
  Sintax: digDir([sDir="forward"][, nBlocks=1])
  ex: digDir("left", 3) or digDir(3, "left") - Rotates left and digs 3 Blocks forward.
      digDir() - Digs 1 block forward.
      digDir(-3, "up") - Digs 3 blocks down.
  Dependencies: strLower, turnDir, addSteps, setWorldEnt]]

  nBlocks = nBlocks or 1
  sDir = strLower(sDir)
  
  if nBlocks < 0 then
    nBlocks = math.abs(nBlocks)
    sDir = negOrient[sDir]
  end

  local success, message = turnDir(sDir)

  if not success then
    if (sDir == "up") or (sDir == "down") then
      tTurtle.looking = dirType[sDir] 
    elseif (sDir == "y+") or (sDir == "y-") then
      sDir = (sDir == "y+" and "up" or "")..(sDir == "y-" and "down" or "")
      tTurtle.looking = dirType[sDir] 
    else return nil, "Invalid direction."
    end
  else sDir = "forward"
  end

  for i = 1, nBlocks do
    while detF[sDir]() do
      local success, message = digF[sDir]()
      if not success then return false, message end
    end
    local x, y, z = addSteps(1, sDir)
    setWorldEnt(x, y, z, 0)
    if i ~= nBlocks then
			if not movF[sDir]() then
        return false, "Can't move that way."
      else tTurtle.x, tTurtle.y, tTurtle.z = x, y, z
      end
		end
  end
  return true
end

function dig(nBlocks) --[[ Turtle digs nBlocks forward or turns back and digs nBlocks, must have a tool equiped.
  27/08/2021 v0.4.0
  Param: nBlocks - number of blocks to dig.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: dig([nBlocks=1])
  Note: nBlocks < 0 turns back and digs forward, nBlocks > 0 digs forward.
  ex: dig() or dig(1) - Dig 1 block forward.
  Dependencies: turnBack, addSteps, setWorldEnt]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "dig(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then turnBack() end
  nBlocks = math.abs(nBlocks)

  for i = 1, nBlocks do
    while turtle.detect() do
      local success, message = turtle.dig()
      if not success then return false, message end
    end
    local x, y, z = addSteps(1, "forward")
    setWorldEnt(x, y, z, 0)
    if i~= nBlocks then
			if not movF["forward"]() then
        return false, "Can't advance more."
      else tTurtle.x, tTurtle.y, tTurtle.z = x, y, z
      end
		end
  end
  return true
end

function digLeft(nBlocks) --[[ Turtle digs nBlocks to the left or right, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig left.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: digLeft([nBlocks=1])
  Note: nBlocks < 0 digs to the right, nBlocks > 0 digs to the left
  ex: digLeft() or digLeft(1) - Dig 1 block left.
  Dependencies: turDir, dig]]
  
  nBlocks = nBlocks or 1
  
	if type(nBlocks) ~= "number" then return false, "digLeft(Blocks) - Blocks must be a number." end
  if nBlocks > -1 then turnDir("left")
  else turnDir("right")
  end
  return dig(math.abs(nBlocks))
end

function digRight(nBlocks) --[[ Turtle digs nBlocks to the right or left, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig right.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: digRight([nBlocks=1])
  Note: nBlocks < 0 digs to the left, nBlocks > 0 digs to the Right.
  ex: digRight() or digRight(1) - Dig 1 block right.
  Dependencies: turnDir, dig]]
  
  nBlocks = nBlocks or 1
  
	if type(nBlocks) ~= "number" then return false, "digRight(Blocks) - Blocks must be a number." end
  if nBlocks > -1 then turnDir("right")
  else turnDir("left")
  end
  return dig(math.abs(nBlocks))
end

function digUp(nBlocks) --[[ Turtle digs nBlocks upwards or downwards, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig up.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: digUp([nBlocks=1])
  Note: nBlocks < 0 digs downwards, nBlocks > 0 digs upwards.
  ex: digUp() or digUp(1) - Dig 1 block up.
  Dependencies: digDown, ]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "digUp(Blocks) - Blocks must be anumber." end
  if nBlocks < 0 then return digDown(math.abs(nBlocks)) end

  for i = 1, nBlocks do
    while turtle.detectUp() do
      local success, message = turtle.digUp()
      if not success then return false, message end
    end
    if i ~= nBlocks then
			if not turtle.up() then return false, "Can't go up."
      else tTurtle.y = tTurtle.y + 1
      end
		end
  end
  return true
end

function digDown(nBlocks) --[[ Turtle digs nBlocks downwards or upwards, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig down.
  Returns:  true if turtle digs all way.
            false if bllocked, empty space, or invalid parameter.
  Sintax: digDown([nBlocks=1])
  Note: nBlocks < 0 digs upwards, nBlocks > 0 digs downwards.
  ex: digDown() or digDown(1) - Dig 1 block down.
  Dependencies: digUp]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "digDown(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then return digUp(math.abs(nBlocks)) end

  for i = 1, nBlocks do
    local success, message = turtle.digDown()
    if not success then return false, message end
    if i ~= nBlocks then
			if not turtle.down() then return false, "Can't go down."
      else tTurtle.y = tTurtle.y - 1
      end
		end
  end
  return true
end

function digAbove(nBlocks) --[[ Digs nBlocks forwards or backwards, 1 block above the turtle, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig forward 1 block above turtle.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: digAbove([nBlocks=1])
  Note: nBlocks < 0 digs backwards, nBlocks > 0 digs forwards.
  ex: digAbove() or digAbove(1) - Dig 1 block up.
  Dependencies: sign, forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "digAbove(Blocks) - Blocks must be a number." end
  local dir = sign(nBlocks)

  for i = 1, math.abs(nBlocks) do
    while turtle.detectUp() do
      local success, message = turtle.digUp()
      if not success then return false, message end
    end
    if i~= nBlocks then
			if not forward(dir) then return false end
		end
  end
  return true
end

function digBelow(nBlocks) --[[ Digs nBlocks forwards or backwards, 1 block below the turtle, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig forward and below turtle.
  Returns:  true if turtle digs all way.
            false if blocked, empty space, or invalid parameter.
  Sintax: digBelow([nBlocks=1])
  Note: nBlocks < 0 digs backwards, nBlocks > 0 digs forwards.
  ex: digBelow() or digBelow(1) - Dig 1 block down.
  Dependencies: sign, forward]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "digBelow(Blocks) - Blocks must be a number." end
  local dir = sign(nBlocks)
	
  for i = 1, math.abs(nBlocks) do
    local success, message = turtle.digDown()
    if not success then return false, message end
    if i~= nBlocks then
			if not forward(dir) then return false, "Can't move forward" end
		end
  end
  return true
end

function digBack(nBlocks) --[[ Turns back or not and digs Blocks forward, must have a tool equiped.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to dig.
  Returns:  true if turtle digs all way.
            false if bllocked, empty space, or invalid parameter.
  Sintax: digBack([nBlocks=1])
  Note: nBlocks < 0 digs forward, nBlocks > 0 digs backwards.
  ex: digBack() or digBack(1) - Turns back and dig 1 block forward.
  Dependencies: turnBack, dig]]
  
  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "digBack(Blocks) - Blocks must be a number." end
  if nBlocks > 0 then turnBack() end
  return dig(math.abs(nBlocks))
end


------ PLACE FUNCTIONS ------  

function placeDir(sDir, message) --[[ Places one selected block in sDir direction.
  27/08/2021 v0.4.0
  Param: sDir - string direction "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.
  Returns:  true - if turtle places the selected block.
            false - if turtle doesn't place the selected block
                  - if the selected slot is empty.
						nil - if invalid parameter.
	Note: message is the text when placing a sign:
				ex: placeDir("north", "Cobblestone/n-----------") - places a sign to the north that says Cobblestone and dashes in the next line.
  Sintax: placeDir([sDir="forward"][, message])
  ex: placeDir("forward") or placeDir() - Places 1 block in front of the turtle.
  Dependencies: strLower, getItemName, turnDir, inspectDir, entAdd, addSteps, setWorldEnt]]
	
  sDir = sDir or "forward"
  sDir = strLower(sDir)

  local sItemName = getItemName()
  if sItemName == "" then return false, "Empty selected slot" end

	if turnDir(sDir) then sDir = "forward"
  elseif (sDir == "y+") or (sDir == "y-") then
      sDir = (sDir == "y+" and "up" or "")..(sDir == "y-" and "down" or "")
  elseif not plaF[sDir] then
      if not string.find(sItemName,"sign") then
        return nil, 'placeDir([sDir = "forward"][, message]) - invalid direction, must be "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.'
      end
      message = sDir
      sDir = "forward"
  end
	
	if plaF[sDir] then
		local success, message = plaF[sDir](message)
		if not success then return false, 'placeDir([sDir = "forward"][, message]) - couldn\'t place block'
		else
			local success, t = inspectDir(sDir)
      local ent
			if success then ent = entAdd(t.name)
			else ent = 0
			end
			local x, y, z = addSteps(sDir)
			setWorldEnt(x, y, z, ent)
		end
  else return nil, 'placeDir([sDir][, message]) - invalid direction, sDir must be "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"north"|"east"|"south"|"west"|0..3.'
	end
  return true
end

function placeAt(x, y, z, sMessage) --[[ Places a block/item at coords x, y, z.
  14/05/2023 v0.4.0
  Param: x, y, z - coords of spot to place block/item.
        sMessage - if placing a sign, this is the message on the sign.
  Returns: nil - if x, y, z is not supplied
               - if x, y, z are not numbers.
           false - if the turtle couldn't get to x, y, z.
  ex: placeAt(10, 10, 2) - places the selected slot block/item in the coords 10, 10, 2.
      placeAt(10, 10, 2, "Wellcome") - if selected slot has a sign, places it at 10, 10, 2 with the word "Wellcome".
  Dependencies: checkNil, isNumber, goToNeighbor, placeDir, getKey]]

  if checkNil(3, x, y, z) then return nil, "placeAt(x,y,z) - invalid number of parameters." end
  if not isNumber(x, y, z) then return nil, "placeAt(x,y,z) - invalid parameter type." end
  if not goToNeighbor(x, y, z) then return false, "Couldn't get to x,y,z." end
  return placeDir(getKey(tTurtle.looking, lookingType), sMessage)
end

function placeSign(sDir, sMessage) --[[ Places a sign in front of the turtle.
  14-05-2023 v0.4.0
  Param: sMessage - the message printed in the sign.
  Returns:  false - if no sign was found in inventory.
            number - 1 (Quantity of items placed).
  ex: placeSign("Hello") - places a selected sign with the word "Hello".
  Dependencies: getItemName, selectItem, place]]

  if not sMessage then
    if sDir then
      local sDirTemp = strLower(sDir)
      if isDirType(sDirTemp) or isFacingType(sDirTemp) or isCarDirType(sDirTemp) then 
        sDir = strLower(sDir)
      else sMessage = sDir
           sDir = getKey(tTurtle.looking, lookingType) 
      end
    else sDir = getKey(tTurtle.looking, lookingType)
    end
  end

  local sItem = getItemName()
  if (not sItem) or (not string.find(sItem, "sign")) then
    if not selectItem("sign") then return false, "sign not found" end
  end

  local success, message = turnDir(sDir)

  if not success then
    if (sDir == "up") or (sDir == "down") then
      tTurtle.looking = dirType[sDir] 
    elseif (sDir == "y+") or (sDir == "y-") then
      sDir = (sDir == "y+" and "up" or "")..(sDir == "y-" and "down" or "")
      tTurtle.looking = dirType[sDir] 
    end
  else sDir = "forward"
  end

  if plaF[sDir] then return plaF[sDir](sMessage)
  else return nil, "Invalid direction."
  end
  return true
end

function place(...) --[[ Turtle places nBlocks in a strait line forward or backwards, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of blocks placed.
            false - invalid parameter.
  Sintax: place([nBlocks=1])
  Note: nBlocks < 0 places blocks backwards, nBlocks > 0 places blocks forwards.
  ex: place(1) or place() - Places 1 Block in front of turtle.
      place("left") or place("left", 1) - places 1 selected block to the left.
      place("minecraft:cobblestone", "left", 2) - places 2 cobblestone to the left.
      place(0, 1) - places 1 selected block to the south.
  Dependencies: isDirType, isFacingType, isCarDirType, isEnt, getItemName, selectItem, turnDir, turnBack, forward, back, placeDir, isEmptySlot]]
  
  local sItem, sDir, nQ, nDir, sMessage --arguments: sItem - item name, sDir - direction, nQ - quantity, nDir - number direction[0..3], sMessage - if placing sign.
  arg = {...}

  for i = 1, #arg do
    if type(arg[i]) == "number" then --argument is a number
      if nDir then nQ = arg[i] --the second is quantity
      else nDir = arg[i] --the first is the direction
      end

    elseif type(arg[i]) == "string" then --the argument is a string
      if (not sDir) and (isDirType(arg[i]) or isFacingType(arg[i]) or isCarDirType(arg[i])) then --is a valid direction
          sDir = arg[i]
      elseif isEnt(arg[i]) then --is a item
        sItem = arg[i]
			else --it must be a message to the sign item
        if not sItem then
          sItem = getItemName()
          if sItem == "" then
            sItem = getItemName(selectItem(arg[i]))
            if sItem == "" then return false, "place(...) - could't find item, "..arg[i] end
          end
          if string.find(sItem, "sign") then sMessage = arg[i]
          else sItem = arg[i]            
          end
        else sMessage = arg[i]
        end
      end
    end
  end

  if sItem == "" then
    sItem = getItemName()
    if sItem == "" then return false, "place(...) - empty selected slot." end
  elseif sItem ~= getItemName() then
    if not selectItem(sItem) then return false, "place(...) - item not found." end
  end

  if not nQ then
    if nDir then nQ = nDir
    else nQ = 1
    end
  end
  
  if sDir then
    if turnDir(sDir) then sDir = "forward" end
  end

  if nQ < 0 then
    turnBack()
    nQ = math.abs(nQ)
  end

  for i = 2, nQ do
    if not forward() then
      nQ = i - 2
      if nQ > 0 then back() end
      break
    end
  end

  local placed = 0
  for i = 1, nQ do
    local bPlaced = placeDir(sDir, sMessage)
    if (not bPlaced) and isEmptySlot() and selectItem(sItem) then
      bPlaced = turtle.place()
    end
    if bPlaced then
      placed = placed + 1
    end
      
    if i ~= nQ then
      if not back() then return placed end
    end
  end
  return placed ~= 0, placed
end

--not tested
function placeBack(nBlocks) --[[ Turtle turns back and places nBlocks in a strait line forward or backwards, and returns to starting point.
  27/08/2021 v0.3.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of blocks placed.
            nil - invalid parameter.
  Sintax: placeBack([nBlocks=1])
  Note: nBlocks < 0 places blocks backwards, nBlocks > 0 places blocks forwards.
  ex: placeBack(1) or placeBack() - Places 1 Block in front of turtle.
Dependencies: back, sign, turnBack, forward]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "placeBack(Blocks) - Blocks must be a number." end
  if nBlocks > 0 then
    turnBack()
    nBlocks = math.abs(nBlocks)
  end

  for i = 2, nBlocks do
    if not forward() then
      nBlocks = i - 2
      back(sign(nBlocks))
      break
    end
  end

  local placed = 0
  for i = 1, nBlocks do
    if turtle.place() then placed = placed + 1 end
    if i ~= nBlocks then
      if not back() then return placed end
    end
  end
  return placed
end

function placeUp(nBlocks) --[[ Places nBlocks upwards or downwards, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number os blocks placed.
            false - if turtle was blocked on the way back.
                  - invalid parameter.
  Sintax: placeUp([nBlocks=1])
  Note: nBlocks < 0 places blocks downwards, nBlocks > 0 places blocks upwards.
  ex: placeUp(1) or placeUp() - Places 1 Block up.
  Dependencies: placeDown, up, down, sign]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "placeUp(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then return placeDown(math.abs(nBlocks)) end
  for i = 2, nBlocks do
    if not up() then
      nBlocks = i - 2
      down(sign(nBlocks))
      break
    end
  end

  local placed = 0
  for i = 1, nBlocks do
    if turtle.placeUp() then placed = placed + 1 end
    if i ~= nBlocks then
      if not down() then return placed end
    end
  end
  return placed
end

function placeDown(nBlocks) --[[ Places nBlocks downwards or upwards, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of blocks placed.
            false - if turtle was blocked on the way back.
                  - invalid parameter.
  Sintax: placeDown([nBlocks=1])
  Note: nBlocks < 0 places blocks upwards, nBlocks > 0 places blocks downwards.
  ex: placeDown(1) or placeDown() - Places 1 Block Down.
  Dependencies: placeUp, down, up, sign]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "placeDown(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then return placeUp(math.abs(nBlocks)) end
  for i = 2, nBlocks do
    if not down() then
      nBlocks = i - 2
      up(sign(nBlocks))
      break
    end
  end

  local placed = 0
  for i = 1, nBlocks do
    if turtle.placeDown() then placed = placed + 1 end
    if i ~= nBlocks then
      if not up() then return placed end
    end
  end
  return placed
end
  
function placeLeft(nBlocks) --[[ Places Blocks to the left or right, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of placed blocks.
            false - if turtle was blocked on the way back.
                  - invalid parameter.
                  - couldn't place block.
  Sintax: placeLeft([nBlocks=1])
  Note: nBlocks < 0 places blocks to the right, nBlocks > 0 places blocks to the left.
  ex: placeLeft(1) or placeLeft() - Places one Block to the left of the turtle.
  Dependencies: turnDir, place]]

  nBlocks = nBlocks or 1

  if type(nBlocks) ~= "number" then return false, "placeLeft(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then turnDir("right")
	else turnDir("left")
	end
  return place(math.abs(nBlocks))
end
  
function placeRight(nBlocks) --[[ Places Blocks to the right or left, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  true if turtle places all blocks all the way.
            false - if turtle was blocked on the way back.
                  - invalid parameter.
                  - couldn't place block
  Sintax: placeRight([nBlocks=1])
  Note: nBlocks < 0 places blocks to the left, nBlocks > 0 places blocks to the right.
  ex: placeRight(1) or placeLeft() - Places 1 Block on the right of the turtle.
  Dependencies: turnDir, place]]

  nBlocks = nBlocks or 1

  if type(nBlocks) ~= "number" then return false, "placeRight(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then turnDir("left")
	else turnDir("right")
	end
  return place(math.abs(nBlocks))
end

function placeBelow(nBlocks) --[[ Places nBlocks forwards or backwards in a strait line, 1 block below the turtle.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of placed blocks.
						nil - if nBlocks is not a number.
            false - if it couldn't go forward.
  Sintax: placeBelow([Blocks=1])
  ex: placeBelow(1) or placeBelow() - Places one Block below the turtle.]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "placeBelow(Blocks) - Blocks must be a number." end
  if nBlocks == 0 then return 0 end

  local sItemName = getItemName()
	if sItemName == "" then return 0, "placeBelow(nBlocks) - empty selected slot." end

  local placed, nEnt = 0, entAdd(sItemName)
	for i = 1, math.abs(nBlocks) do
    while not turtle.placeDown() do
      if getItemName() == "" then
        if not selectItem(sItemName) then return placed, "placeBelow(nBlocks) - no more items to place." end
      else return placed, "placeBelow(nBlocks) - couldn't place item below."
      end
    end
    placed = placed + 1
    setWorldEnt(tTurtle.x, tTurtle.y - 1, tTurtle.z, nEnt)
		if i ~= math.abs(nBlocks) then
			if not forward(sign(nBlocks)) then return false, "placeBelow(Blocks) - couldn't go forward" end
		end
  end
  return placed
end

function placeAbove(nBlocks) --[[ Places nBlocks forwards or backwards in a strait line, 1 block above the turtle.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of placed blocks.
						nil - if nBlocks is not a number.
            false - if it couldn't go forward.
  Sintax: placeAbove([Blocks=1])
  ex: placeAbove(1) or placeAbove() - Places one Block above the turtle.]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return nil, "placeAbove(Blocks) - Blocks must be a number." end
  
	local sItemName = getItemName()
  if sItemName == "" then return 0, "placeAbove(nBlocks) - empty selected slot." end

  local placed, nEnt = 0, entAdd(sItemName)
  for i = 1, math.abs(nBlocks) do
    while not turtle.placeUp() do
      if getItemName() == "" then
        if not selectItem(sItemName) then return placed, "placeBelow(nBlocks) - no more items to place." end
      else return placed, "placeBelow(nBlocks) - couldn't place item below."
      end
    end
    placed = placed + 1
    setWorldEnt(tTurtle.x, tTurtle.y - 1, tTurtle.z, nEnt)
		if i ~= math.abs(nBlocks) then
			if not forward(sign(nBlocks)) then return false, "placeBelow(Blocks) - couldn't go forward" end
		end
  end
  return placed
end

function placeAboveR(nBlocks) --[[ Places nBlocks forwards or backwards in a strait line, 1 block above the turtle, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of blocks placed
            false - if turtle was blocked on the way back.
                  - couldn't place block.
                  - invalid parameter.
  Sintax: placeAboveR([nBlocks=1])
  ex: placeAboveR(1) or placeAboveR() - Places one Block above turtle.
  Dependencies: turnBack, forward, down, back]]

    nBlocks = nBlocks or 1
    
    if type(nBlocks) ~= "number" then return false, "placeAboveR(Blocks) - Blocks must be a number." end
    if nBlocks < 0 then
      nBlocks = math.abs(nBlocks)
      turnBack()
    end
    for i = 2, nBlocks do --goto last pos to place
      if i == 2 then
        if not up() then
          nBlocks = 1
          break
        end
      elseif not forward() then
        nBlocks = i - 1
        break
      end
    end
    
    local placed = 0
    for i = 1, nBlocks do --place backwards
      local ent = entAdd(getItemName())
      if i == nBlocks then
        if i ~= 1 then
          if not down() then return false, "Can't move down." end
        end
        if turtle.placeUp() then
          placed = placed + 1
          setWorldEnt(tTurtle.x, tTurtle.y + 1, tTurtle.z, ent)
        end
      else
        if turtle.place() then
          placed = placed + 1
          local x, y, z = addSteps(1, tTurtle.facing)
          setWorldEnt(x, y, z, ent)
        end
        if (i ~= (nBlocks-1)) then
          if not back() then return placed end
        end
      end
    end
    return placed
end

function placeBelowR(nBlocks) --[[ Places nBlocks forwards or backwards in a strait line, 1 block below the turtle, and returns to starting point.
  27/08/2021 v0.1.0
  Param: nBlocks - number of blocks to place.
  Returns:  number of placed blocks.
            false - if turtle was blocked on the way back.
                  - couldn't place block.
                  - invalid parameter.
  Sintax: placeBelowR([Blocks=1])
  ex: placeBelowR(1) or placeBelowR() - Places one Block below turtle.
  Dependencies: turnBackdown, forwardup, back]]

  nBlocks = nBlocks or 1
  
  if type(nBlocks) ~= "number" then return false, "placeBelowR(Blocks) - Blocks must be a number." end
  if nBlocks < 0 then
    nBlocks = math.abs(nBlocks)
    turnBack()
  end
  for i = 2, nBlocks do
    if i == 2 then
      if not down() then
        nBlocks = 1
        break
      end
    elseif not forward() then
      nBlocks = i - 1
      break
    end
  end
  
  local placed = 0
  for i = 1, nBlocks do
    local ent = entAdd(getItemName())
    if i == nBlocks then
      if i ~= 1 then
        if not up() then return false, "Can't go up." end
      end
      if turtle.placeDown() then
        placed = placed + 1
        setWorldEnt(tTurtle.x, tTurtle.y - 1, tTurtle.z, ent)
      end
    else
      if turtle.place() then
        placed = placed + 1
        local x, y, z = addSteps(1, tTurtle.facing)
        setWorldEnt(x, y, z, ent)
      end
      if (i ~= (nBlocks-1)) then
        if not back() then return placed end
      end
    end
  end
  return placed
end


------ INVENTORY FUNCTIONS ------

function cmpInventory(tInv1, tInv2) --[[ Compares 2 snapshots of inventory.
  11/05/2022 v0.3.0
  Param: tInv1, tInv2 - snapshots from inventory (getInventory).
  Returns: nil - if tInv1 or tInv2 not supplied.
              true - if snapshots are equals.
              table - if snapshots are diferent.
  Sintax: cmpInventory(tInv1, tInv2)
  ex: cmpInventory(tInv1, tInv2) - compares tInv1 with tInv2.]]

  if (not tInv1) or (not tInv2) then
      return nil, "cmpInventory(tInv1, tInv2) - You must supply inventory1 and inventory2 to compare"
  end
  local tDif
  for iSlot = 1, 16 do
      if tInv1[iSlot] then
          for k, v in pairs(tInv1[iSlot]) do
              if tInv2[iSlot] and tInv2[iSlot][k] then
                  if tInv2[iSlot][k] ~= tInv1[iSlot][k] then
                      if not tDif then tDif = {} end	
                      tDif[iSlot] = {["name"] = k, ["count"] = tInv2[iSlot][k] - tInv1[iSlot][k]}
                  end
              elseif not tDif then tDif = {}
                  tDif[iSlot] = {["name"] = k, ["count"] = -tInv1[iSlot][k]}
              end
          end
      elseif tInv2[iSlot] then
          for k, v in pairs(tInv2[iSlot]) do
              if not tDif then tDif = {} end	
              tDif[iSlot] = {["name"] = k, ["count"] = tInv2[iSlot][k]}
          end
      end
  end

  if tDif then return false, tDif
  else return true
  end
end

function cmpInvIncreased(tInv1, tInv2) --[[ Verifies if inventory quantities have increased.
  03/07/2022 v0.3.0
  Param: tInv1, tInv2 - snapshot of inventory from getInventory()
  Returns: true, t - if items have increased, table with slot, name, quantity.
           false - if items haven't increased.
  Sintax: cmpInvIncreased(tInv1, tInv2)
  ex: cmpInvIncreased(inv1, inv2) - verifies if inventory snapshot inv2 has more items than inv1.
  Dependencies: cmpInventory]]

	local bDif, tInvCmpRes = cmpInventory(tInv1, tInv2)
	if bDif then return false end
	
	local tInc
	for kSlot, v in pairs(tInvCmpRes) do
    if tInvCmpRes[kSlot].count > 0 then
      if not tInc then tInc = {} end
      tInc[kSlot] = {["name"] = tInvCmpRes[kSlot].name, ["count"] = tInvCmpRes[kSlot].count}
    end
	end
	if tInc then return true, tInc
	else return false
	end
end

function countItemSlots() --[[ Counts how many slots is ocupied with each item.
  04/12/2021 v0.2.0
  Returns: table[itemName]=Slots ocupied by item.
  Sintax: countItemSlots()]]

  local tItemSlots = {}
  for iSlot = 1, 16 do
    local tData = turtle.getItemDetail(iSlot)
    if tData then
      if tItemSlots[tData.name] then tItemSlots[tData.name] = tItemSlots[tData.name] + 1
      else tItemSlots[tData.name] = 1
      end
    end
  end
  return tItemSlots
end

function decSlot(nSlot, bWrap) --[[ Decreases nSlot in range [1..16].
  02/11/2021 v0.2.0
  Param: nSlot - number slot to decrease.
         bWrap - boolean if slot wraps around inventory.
  Returns:  the number of slot decreased by 1.
            nil - if nSlot if not a number.
            false - if bWrap and nSlot = 1.
  Sintax: decSlot([nSlot = turtle.getSelectedSlot()][, bWrap = true])
  ex: decSlot() - Decrements the selected slot.
      decSlot(1, false) - Returns false.
      decSlot(16, false) - Returns 15
  Dependencies: getParam]]

  nSlot, bWrap = getParam("nb", {turtle.getSelectedSlot(), true}, nSlot, bWrap)
  if type(nSlot) ~= "number" then return nil, "decSlot([Slot=selected slot][, Wrap=true]) - Slot must be a number." end
	nSlot = nSlot - 1
  if not bWrap and nSlot < 1 then return false end
  return nSlot == 0 and 16 or nSlot
end

function freeCount() --[[ Get number of free slots in turtle's inventory.
  07/10/2021 v0.2.0
  Returns:  number of free slots.
  Sintax: freeCount()]]

  local nFree,i=0
  for i = 1, 16 do
    if turtle.getItemCount(i)==0 then nFree=nFree+1 end
  end	
  return nFree
end

function getFreeSlot(nStartSlot, bWrap) --[[ Get the first free slot, wrapig the search or not.
  07/10/2021 v0.2.0
  Param:  nStartSlot - number slot where to start the search.
               bWrap - boolean if the search wraps around the inventory.
  Returns:  number - first free slot number.
            false - if no free slot.
  Sintax: getFreeSlot([nStartSlot=1][, bWrap=true])
  Note: if nStartSlot<0 search backwards
  Dependencies: getParam, sign]]

	nStartSlot, bWrap = getParam("nb",{1, true}, nStartSlot, bWrap)

  if not type(nStartSlot) == "number" then return false, "getFreeSlot([StartSlot=1][, Wrap=true]) - Slot must be a number." end
  local dir = sign(nStartSlot)
  nStartSlot = math.abs(nStartSlot)
  local nEndSlot = nStartSlot
  
  repeat
    local tData = turtle.getItemDetail(nStartSlot)
    if not tData then return nStartSlot end
    nStartSlot = nStartSlot + dir
    if not bWrap then
      if dir == 1 then
        if nStartSlot == 17 then break end
      else
        if nStartSlot == 0 then break end
      end
    end
    nStartSlot = bit32.band(nStartSlot-1, 15)+1
  until (nEndSlot == nStartSlot)
  return false
end

function getInventory() --[[ Builds a table with the slot, the name and quantity of items in inventory.
  04/12/2021 v0.2.0
  Returns:  table[slot][itemName]=Quantity.
  Sintax: getInventory()]]

  local tInv = {}
  for iSlot = 1, 16 do
    local tData = turtle.getItemDetail(iSlot)
    if tData then
      tInv[iSlot] = {}
      tInv[iSlot][tData.name] = tData.count
    end
  end
  return tInv
end

function groupItems() --[[ Groups the same type of items in one slot in inventory.
  07/10/2021 v0.2.0
  Returns:  true.
  Sintax: groupItems()]]

  local destSlot,orgSlot,tmpSlot
 
  for destSlot=1,15 do --destination slot
    if turtle.getItemCount(destSlot) ~=0 then --has some items?
      for orgSlot=destSlot+1,16 do --origin slot
        if turtle.getItemCount(orgSlot) ~= 0 then --has some items
          turtle.select(orgSlot) --select the origin slot
          if turtle.compareTo(destSlot) then --is the same family entity
            turtle.transferTo(destSlot) --transfer to destination slot if possible, doesn't matter if not
          end
        end
      end
    end
  end
	return true
end

function incSlot(nSlot, bWrap) --[[ Increases nSlot in range [1..16].
  02/11/2021 v0.2.0
  Param: nSlot - number slot to be increased.
         bWrap - boolean true if the slot number wraps around inventory.
  Returns:  the number of slot increased by 1.
            false - if it couldn't increase slot.
  Sintax: incSlot([Slot.selecetd slot][, Wrap=true])
  ex: incSlot(16) - returns 1.
  Dependencies: getParam]]

  nSlot, bWrap = getParam("nb", {turtle.getSelectedSlot(), true}, nSlot, bWrap)
  if type(nSlot) ~= "number" then return nil, "incSlot([Slot.selecetd slot][, Wrap=true]) - Slot must be a number." end
  nSlot = nSlot + 1
  if not bWrap and (nSlot > 16) then return false end
  return bit.band(nSlot-1, 15) + 1
end

function itemSpace(nSlot) --[[ Get how many items more you can store in inventory.
  23/09/2021 v0.1.0
  Param: nSlot/sItemName - number of slot/string item name.
  Returns: number of items you can store more in inventory/slot.
           false - if item is not in inventory.
                 - 1 - if slot is empty.
  Sintax: itemSpace([nSlot/item name=turtle.getSelectedSlot()])
  ex: itemSpace() gets how many items you can store, like the item in selected slot.
      itemSpace("minecraft:cobblestone") - gets how more cobblestone you can store.
      itemSpace(12) - gets how more items, like item in slot 12, you can store.]]

	nSlot = nSlot or turtle.getSelectedSlot() --default slot is the selected slot
	local stack = 0
	
	if type(nSlot) == "string" then --is it  "minecraft:cobblestone" for example.
		nSlot = search(nSlot)
		if not nSlot then return false, "Item not found." end
	end
	
	local tData = turtle.getItemDetail(nSlot)
	if not tData then return -1 end
  local itemName = tData.name
	stack = turtle.getItemSpace(nSlot) + tData.count
	
	nSlot = bit.band(nSlot-1, 15)+1 --nSlot, the start slot [1..16]
	totSpace = 0
	
	for i = 1, 16 do
		tData = turtle.getItemDetail(i)
		if tData then
      if tData.name == itemName then totSpace = totSpace + stack - tData.count end
		else totSpace = totSpace + stack
		end
	end
	
	return totSpace
end

function isEmptySlot(nSlot) --[[ Checks if nSlot is empty.
  23/09/2021 v0.2.0
  Param: nSlot - number slot to check.
  Returns: true - if nSlot is empty.
           false - if nSlot is not empty.
  Sintax: isEmptySlot([nSlot=selected slot])
  ex: isEmptySlot() - Checks if selected slot is empty.
      isEmptySlot(12) - checks if slot 12 is empty.]]

  nSlot = nSlot or turtle.getSelectedSlot()
  if type(nSlot) ~= "number" then return nil, "isEmptySlot(Slot) - Slot is not a number." end
  return turtle.getItemDetail(nSlot) == nil
end

function isInventoryEmpty() --[[ Checks if inventory is empty.
  30/04/2022 v0.1.0
  Returns: true - if inventory is empty.
          false - if inventory is not empty.
  Sintax: isInventoryEmpty()
  ex: isInventoryEmpty() - Checks if inventory is empty.]]

  for nSlot = 1, 16 do
    if turtle.getItemDetail(nSlot) then return false end
  end
  return true
end

function itemCount(nSlot) --[[ Counts items in inventory
  31/08/2021
  Param: nSlot/"inventory"/item name - number slot/string "inventory"/string item name.
  Returns: number of items counted.
           nil - if nSlot <0 or > 16.
               - if nSlot is neither a string nor a number.
  Sintax: itemCount([nSlot=turtle.getSelectedSlot() / "inventory" / item name])
  ex: itemCount() counts items in selected slot.
      itemCount("inventory") - counts items in inventory.
      itemCount("minecraft:cobblestone") - counts cobblestone in inventory.]]

  nSlot = nSlot or turtle.getSelectedSlot()
  totItems = 0

  if type(nSlot) == "number" then
    if (nSlot < 1) or (nSlot > 16) then return nil, 'itemCount(nSlot/itemName/"inventory") - Slot must be a number [1..16].' end
    tData = turtle.getItemDetail(nSlot)
    if tData then totItems = tData.count end
  else
    if type(nSlot) ~= "string" then return nil, 'itemCount(nSlot/itemName/"inventory") - Invalid parameter type [number|string].' end
    for i = 1, 16 do
      tData = turtle.getItemDetail(i)
      if tData then
        if nSlot == "inventory" then totItems = totItems + tData.count
        elseif nSlot == tData.name then totItems = totItems + tData.count
        end
      end
    end
  end
  return totItems
end

function getItemName(nSlot) --[[ Gets the item name from Slot/selected slot.
  05/09/2021 v0.3.0
  Param: nSlot - number slot where to get the item name.
  Returns: item name - if slot is not empty.
           "" - if slot is empty.
  Sintax: getItemName([nSlot=selected slot])
  ex: getItemName() - retuns the name of item in selected slot.
  Dependencies: isInRange]]

  if not nSlot then nSlot = nSlot or turtle.getSelectedSlot()
  elseif type(nSlot) ~= "number" then return nil, "getItemName([Slot=selected slot]) - Slot must be a number."
  elseif not isInRange(nSlot, {1, 16}) then return false, "Slot "..nSlot.." out of range."
  end

  local tData = turtle.getItemDetail(nSlot)
  if not tData then return "" end
  return tData.name
end

function selectItem(itemName) --[[ Selects slot [1..16] or first item with Item Name, or the turtle selected slot.
  29/08/2021 v0.1.0
  Param: slot/itemName - number slot/string name of the item to select.
  Returns:  number, number - The selected slot, and number of items in that slot.
            False - if it didn't find the item name.
            nil - if type of itemName/Slot is not a number or string.
                - if itemName/Slot is a number out of range [1..16].
  Note: if executed selectItem() is the same as turtle.getSelectedSlot()
  Sintax: selectItem([Slot/Item Name])
  ex: selectItem("minecraft:cobblestone") - Selects first slot with "minecraft:cobblestone"
  Dependencies: isInRange, search]]

  local nSlot
  local tData

  if itemName == nil then
    nSlot = turtle.getSelectedSlot()
  elseif type(itemName) == "number" then
    if not isInRange(itemName, {1, 16}) then return nil, "selectItem([itemName/slot]=selected slot) - Slot must be number 1..16." end
    nSlot = itemName
  elseif type(itemName) == "string" then
    nSlot = search(itemName)
    if not nSlot then return false, "Item name not found." end
  else
    return nil, "selectItem([itemName/slot]=selected slot) - Slot/itemName must be a number 1..16 or a string (item name)."
  end
  
  turtle.select(nSlot)
  tData = turtle.getItemDetail()
  if tData then return nSlot, tData.count
  else return nSlot, 0
  end
end

function selectSlot(nSlot) --[[ Selects nSlot
  04-06-2023 v0.4.0
  Param: nSlot - the slot number to be selected.
  Sintax: selectSlot(nSlot)
  ex: selectSlot(1) - select slot 1.
  Alias for selectItem]]

  return selectItem(nSlot)
end

function leaveItems(sItemName, nQuant, bWrap) --[[ Leaves nQuant of item in Selected Slot, moving item from or to another slot.
  19/10/2021 v0.2.0
  Param: sItemName - string name of the item.
            nQuant - number quantity of items to leave in selected slot.
             bWrap - boolean if it cam put excess items in lower slots (wrap around inventory).
  Returns:  true - if there is nQuant of items in selected slot.
           false - if sItemName not supplied.
           false - if there is no items to tranfer to selected slot or no space to tranfer items to.
  Sintax: leaveItems([sItemName = Selected Slot Item Name][, nQuant=0][, bWrap=true])
  ex: leaveItems() - Removes items from selected slot.
      leaveItems("minecraft:cobblestone") - Removes items from selected slot.
      leaveItems("minecraft:cobblestone", 6) - Leaves 6 items of cobllestone in selected slot
  Dependencies: getParam, clearSlot, incSlot, searchSpace, getFreeSlot, search, tranferFrom]]
  
  sItemName, nQuant, bWrap = getParam("snb", {"", 0, true}, sItemName, nQuant, bWrap)
  local tData = turtle.getItemDetail()

  local nOrgSlot, nStored = turtle.getSelectedSlot()
  local nLastSlot = nOrgSlot

  if sItemName == "" then
    if not tData then return false, "Slot empty and item name not supplied."
    else sItemName = tData.name
    end
  else
    if tData then
      if tData.name ~= sItemName then
        clearSlot(nOrgSlot, bWrap)
        tData = turtle.getItemDetail()
      end
    end
  end

  if tData then nStored = tData.count
  else nStored = 0
  end

  if nQuant < 0 then nQuant = nStored + nQuant end

  while (nStored ~= nQuant) do
    local nDestSlot, nDestSpace, nOrgSpace
    nLastSlot = incSlot(nLastSlot, bWrap)
    if not nLastSlot then break end

    if nStored > nQuant then
      nDestSlot, nDestSpace = searchSpace(sItemName, nLastSlot, bWrap)

      if not nDestSlot or (nDestSlot == nOrgSlot) then
        nDestSlot = getFreeSlot(nLastSlot, bWrap)
        if not nDestSlot then break end
        nDestSpace=64
      end

      if nDestSpace > (nStored - nQuant) then
        turtle.transferTo(nDestSlot, nStored - nQuant)
      else 
        turtle.transferTo(nDestSlot, nDestSpace)
      end
    else
      nDestSlot = search(sItemName, nLastSlot, bWrap)
      if not nDestSlot then break end
      transferFrom(nDestSlot, nQuant - nStored)
    end
    nLastSlot = nDestSlot
    nStored = turtle.getItemCount()
  end
  if nStored == nQuant then return true end
  return false
end

function search(sItemName, nStartSlot, bWrap) --[[ Search inventory for ItemName, starting at startSlot, and if search wrap. 
  28/08/2021 v0.1.0
  Param: sItemName - string the item name.
        nStartSlot - number slot where to start the search.
             bWrap - boolean true if the search wraps around inventory.
  Returns:  number, number - first slot where the item was found, and the quantity.
            nil - if sItemName not supplied.
                - if nStartSlot is not a number.
            False - if the item was not found
  Note: nStartSlot < 0 search backwards, nStartSlot > 0 searchs forward.
        if not supplied nStartSlot, default is the selected slot.
        if not supplied bWrap, it defaults to true.
  Sintax: Search(sItemName [, nStartSlot=turtle.getSelectedSlot()][, bWrap=true])
  Dependencies: getParam, sign, ]]

	sItemName, nStartSlot , bWrap= getParam("snb", {"", turtle.getSelectedSlot(), true}, sItemName, nStartSlot, bWrap)
  if sItemName == "" then return nil, "search(sItemName, nStartSlot, bWrap) - Item name must be supplied." end
  if type(nStartSlot) ~= "number" then return nil, "search(sItemName, nStartSlot, bWrap) - Start slot must be a number." end
  dir = sign(nStartSlot)
  nStartSlot = math.abs(nStartSlot) - 1
  nStartSlot = bit32.band(nStartSlot, 15)
	slot = nStartSlot
	
	repeat
    local tData = turtle.getItemDetail(slot + 1)

    if tData then
      if string.sub(sItemName,1,1) == "=" then
        if tData.name == string.sub(sItemName,2,#sItemName) then return slot + 1, tData.count end
      elseif string.find(tData.name, sItemName) then
        return slot + 1, tData.count
      end
    end
    slot = slot + dir
    if not bWrap then
      if dir == -1 then
        if slot == -1 then break end
      else
        if slot == 16 then break end
      end
    end
    slot = bit32.band(slot, 15)
  until (slot == nStartSlot)
  return false
end

function selectFreeSlot(nStartSlot, bWrap) --[[ Selects the first free slot starting at nStartSlot, and if the search wraps or not.
  07/10/2021 v0.2.0
  Param: nStartSlot - number slot where to start search for free slot.
              bWrap - boolean true if the search wraps around inventory.
  Returns:  free slot number.
            false - if no free slot.
  Sintax: selectFreeSlot([StartSlot=1][, Wrap=true])
  ex: selectFreeSlot(16, false) - Selects slot 16 if it is empty.
      selectFreeSlot(15, true) - Checks all slots starting at 15, and selects first empty.
  Dependencies: getFreeSlot]]

  local nSlot

  nSlot = getFreeSlot(nStartSlot, bWrap) --get a free slot
  if not nSlot then return false end --not found
  if turtle.select(nSlot) then return nSlot end
  return false --couldn't select nSlot
end


------ SUCK FUNCTIONS ------

function suckAt(x, y, z, nQuant) --[[ Sucks items at coords x, y, z.
  14-05-2024 v0.4.0
  Param: x, y, z - numbers the coords where are the items to suck.
          nQuant - number of items to suck
  Returns:  nil - if x,y,z not supplied.
                - if x, y, z are not numbers.
            false - if the turtle could't get to coords.
  Sintax: suckAt(x, y, z, nQuant)
  ex: suckAt(10, 10, 10, 10) - sucks 10 items at coords 10, 10, 10.
  Dependencies: checkNil, isNumber, goToNeighbor, suckDir, getKey]]

	if checkNil(3, x, y, z) then return nil, "suckAt(x,y,z) - invalid number of parameters." end
  if not isNumber(x,y,z) then return nil, "suckAt(x,y,z) - invalid parameter type." end
  if not gotoNeighbor(x, y, z) then return false, "Couldn't get to x,y,z." end
  return suckDir(getKey(tTurtle.looking, lookingType), nQuant)
end

function suckDir(sDir, nItems) --[[ Sucks or drops nItems into sDir direction.
  05/09/2021 v0.4.0
  Param:  sDir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.
        nItems - number of items to suck.
  Returns:  true - if turtle collects some items.
            false - if there are no items to take.
						nil - if invalid parameter.
  Sintax: suckDir([sDir="forward][,nItems=all the items])
  Note: if nItems < 0 it sucks nItems from oposite direction.
  ex: suckDir() - Turtle sucks all the items forward.
      suckDir(0) - suck all the items in 0, "z-", north direction.
      suckDir(4) - suck 4 items in front of the turtle.
  Dependencies: strLower, dropDir, turnDir]]
	
  sDir = sDir or "forward"
  sDir = strLower(sDir)
  if type(sDir) == "number" then
    if sDir > 3 then
      if not nItems then
        nItems = sDir
        sDir = "forward"
      else local tmp = nItems
        nItems = sDir
        sDir = tmp
      end
    end
  end

  if nItems and nItems < 0 then return dropDir(sDir, math.abs(nItems)) end

	if turnDir(sDir) then sDir = "forward"
  elseif (sDir == "y+") or (sDir == "y-") then
    sDir = (sDir == "y+" and "up" or "")..(sDir == "y-" and "down" or "")
  elseif not suckF[sDir] then
    if type(sDir) == "number" then
      nItems = sDir
      sDir = "forward"
    else return nil, 'suckDir(sDir, nItems) - Invalid direction must be: "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.'
    end
  end

  if suckF[sDir] then return suckF[sDir](nItems)
	else return nil, 'suckDir(sDir, nItems) - invalid direction sDir must be "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.'
	end
end


------ FILE SYSTEM FUNCTIONS ------

function fsGetFreeSpace() --[[ Gets the total free space on disk.
  02/10/2021 v0.2.0
  Returns:  Free space on disk.
  ex: fsGetFreeSpace() - Outputs free space on disk.]]

	return fs.getFreeSpace("/")
end


------ DROP FUNCTIONS ------  

function dropDir(sDir, nItems) --[[ Drops or sucks nItems from selected slot and inventory into the world to sDir direction.
  29/08/2021 v0.4.0
  Param:  sDir - "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.
        nItems - number of items to drop/suck
  Returns:  number of dropped itemsm, name of item.
            false - empty selected slot.
            nil - if invalid direction.
                - if nItems is not a number.
  Sintax: drop([sDir="forward"] [, nItems=stack of items])
  Note: if nItems not supplied, drops all items in selected slot.
        if nItems < 0 sucks nItems.
  ex: dropDir() - Drops all blocks from selected slot, forward.
      dropDir(205, "up") - Drops 205 blocks from inventory like the one on selected slot, upwards.
      dropDir(-5, "down") - Suck 5 items from down.
      dropDir(0) - Drops all the items in selected slot to 0, "z-", "north" direction.
      dropDir(4) - Drops 4 items forward.
  Dependencies: strLower, turnDir, suckDir]]

  sDir = sDir or "forward"
	sDir = strLower(sDir)
  if type(sDir) == "number" then
    if sDir > 3 then
      if not nItems then
        nItems = sDir
        sDir = "forward"
      else local tmp = nItems
        nItems = sDir
        sDir = tmp
      end
    end
  end
  
  if turnDir(sDir) then sDir = "forward"
  elseif (sDir == "y+") or (sDir == "y-") then
    sDir = (sDir == "y+" and "up" or "")..(sDir == "y-" and "down" or "")
  elseif not dropF[sDir] then
    if type(sDir) == "number" then
      nItems = sDir
      sDir = "forward"
    else return nil, 'dropDir(sDir, nItems) - Invalid direction must be: "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..3.'
    end
  end
	
  local selectedSlot = turtle.getSelectedSlot() --save selected slot
  local tData = turtle.getItemDetail() --check the selected slot for items
  if not nItems then --drop all the stack from selected slot
    if tData then --is there a item to frop?
      dropF[sDir]()
      return tData.count, tData.name
    else return dropF[sDir]()
    end
	else if type(nItems) ~= "number" then
    return nil, "dropDir(Dir, Items) - Items must be a number."
  end
  end

  if (not tData) and (nItems > -1) then return false, "Empty selected slot." end --no items                

  if nItems < 0 then return suckDir(sDir, math.abs(nItems)) end
	local blocksDropped = 0 --total blocks dropped

	while (blocksDropped < nItems) do
    if tData.count > (nItems-blocksDropped) then
      dropF[sDir](nItems-blocksDropped)
      blocksDropped = blocksDropped + (nItems-blocksDropped)
    else
      dropF[sDir]()
      blocksDropped = blocksDropped + tData.count
      nextSlot, tData.count = search("="..tData.name)
      if nextSlot then turtle.select(nextSlot)
      elseif blocksDropped < nItems then break
      end
    end
  end

  turtle.select(selectedSlot) --restore selected slot
  return blocksDropped, tData.name
end

function drop(...) --[[ Drops or sucks items.
  24-05-2023 v0.4.0
  Param: dir - string/number: "forward"|"right"|"back"|"left"|"up"|"down"|"z-"|"x+"|"z+"|"x-"|"y+"|"y-"|"north"|"east"|"south"|"west"|0..4,8(z-,x+,z+,x-,y+,y-).
         item - string: name of the item.
         q - number: quantity of items to drop.
         slot - number: slot number.
  Returns:  number of dropped items, name of the item.
            false - if item was not found.
  Sintax: drop([Dir=forward][, Item=selected][, Q=stack])
  ex: drop() - Drops all items from selected slot, in front of the turtle.
      drop(205) - Drops 205 items from inventory like the one on selected slot, forward.
      drop("left", 5) - drops 5 items to the left from the selected slot.
      drop(0, 6) - drops 6 items from the selected slot to z-
      drop{slot = 10, q = 8} - drops 8 items from slot 10, forward.
  Dependencies: getItemName, search, dropDir]]

  local snDir, nDir, nQ, sItem, nSlot
  arg = {...}

  for i = 1, #arg do
    if type(arg[i] ) == "number" then
      if not nQ then nQ = arg[i]
      else
        snDir = nQ
        nQ = arg[i]
      end

    elseif type(arg[i]) == "string" then
      if dirType[arg[i] ] or facingType[arg[i] ] or carDirType[arg[i] ] then snDir = arg[i]
      else sItem = arg[i]
      end

    elseif type(arg[i]) == "table" then
      if arg[i].slot then turtle.select(arg[i].slot) end
      if arg[i].dir then snDir = arg[i].dir end
      if arg[i].item then sItem = arg[i].item end
      if arg[i].q then nQ = arg[i].q end

    end
  end

  if sItem and (getItemName() ~= sItem) then
      nSlot, _ = search(sItem)
      if not nSlot then return false, "drop([Dir=forward][, Item=selected][, Q=stack]) - item not found." end
      turtle.select(nSlot)
  end
  if not snDir then snDir = "forward" end
  return dropDir(snDir, nQ)
end

function dropUp(nBlocks) --[[ Drops or sucks nBlocks upwards.
  29/08/2021 v0.1.0
  Param: nBlocks - number of blocks to drop up.
  Returns:  number of dropped items.
            false - empty selected slot.
            true - if suck some items.
  Sintax: dropUp([nBlocks])
  Note: if nBlocks not supplied, drops all items from selected slot.
  ex: dropUp() - Drops all blocks from selected slot, upwards.
      dropUp(205) - Drops 205 blocks from inventory like the one on selected slot, upwards.
  Dependencies: dropDir]]

  return dropDir("up", nBlocks)
end

function dropDown(nBlocks) --[[ Drops or sucks nBlocks downwards.
  29/08/2021 v0.1.0
  Param: nBlocks - number of blocks to drop down.
  Returns:  number of dropped items.
            false - empty selected slot.
            true - if suck some items.          
  Sintax: dropDown([nBlocks])
  Note: if nBlocks not supplied, drops all items from selected slot.
  ex: dropDown() - Drops all blocks from selected slot, downwards.
  dropDown(205) - Drops 205 blocks from inventory like the one on selected slot, downwards.
  Dependencies: dropDir]]

  return dropDir("down", nBlocks)
end

function dropLeft(nBlocks) --[[ Rotate left and drops or sucks nBlocks forward.
  11/09/2021 v0.1.0
  Param: nBlocks - number of blocks to drop left.
  Returns:  number of dropped items.
            false - empty selected slot.
            true - if suck some items.
  Sintax: dropLeft([nBlocks])
  Note: if nBlocks not supplied, drops all items from selected slot.
  ex: dropLeft() - Rotate left and drops all blocks from selected slot forward.
  dropLeft(205) - Rotate left and drops 205 blocks from inventory like the one on selected slot, forward.
  Dependencies: dropDir]]

  return dropDir("left", nBlocks)
end

function dropRight(nBlocks) --[[ Rotate right and drops or sucks nBlocks forward.
  11/09/2021 v0.1.0
  Param: nBlocks - number of blocks to drop right.
  Returns:  number of dropped items.
            false - empty selected slot.
            true - if suck some items.
  Sintax: dropRight([nBlocks])
  Note: if nBlocks not supplied, drops all items from selected slot.
  ex: dropRight() - Rotate right and drops all blocks from selected slot, forward.
  dropRight(205) - Rotate right and drops 205 blocks from inventory like the one on selected slot, forward.
  Dependencies: dropDir]]

  return dropDir("right", nBlocks)
end

function dropBack(nBlocks) --[[ Rotate back and drops or sucks nBlocks forward.
  29/08/2021 v0.1.0
  Param: nBlocks - number of blocks to drop back.
  Returns:  number of dropped items.
            false - empty selected slot.
            true - if suck some items.
  Sintax: dropBack([nBlocks])
  Note: if nBlocks not supplied, drops all items from selected slot.
  ex: dropBack() - Rotate back and drops all blocks from selected slot, forward.
      dropBack(205) - Rotate back and drops 205 blocks from inventory like the one on selected slot, forward.
  Dependencies: dropDir]]

  return dropDir("back", nBlocks)
end

------ PATHFINDING ------

function getWorldPassableNeighbors(p, tIncludeEnt) --[[ Gets the neighbors of p passable.
  14-07-2018
  Param: p - table central block {x, y, z}
         tIncludeEnt - table entities passables.
  sintax: getWorldPassableNeighbors(p[, tIncludeEnt)
  Dependencies: getNeighbors, getWorldEnt]]

  if not p then return false end --p not supplied
  if not tIncludeEnt then --exclude block type
    tIncludeEnt = {-1, 0} -- nil unknown,-1 unreachable, 0 empty - passable entitys
  end
	
  local nTable = getNeighbors(p)--neighbours table
  local i, j, rTable = 1, 1, {} -- counter for neighbours table, i.e. exclude blocks table, return table
  for i = 1, #nTable do
    local block = getWorldEnt(nTable[i][1], nTable[i][2], nTable[i][3]) --get block from world
    for j = 1, #tIncludeEnt do
      if (not block) or block == tIncludeEnt[j] then --is in exclude table or is unknown then is passable
        table.insert(rTable, #rTable+1, nTable[i])
        break
      end
    end
  end
  return rTable
end

--not tested
function getPath(...) --[[ Returns the path, a table of points.
  27-05-2023 v0.4.0 Param: {x1, y1, z1}, {x2, y2, z2}|x1, y1, z1, x2, y2, z2 - the start and ending point
  Sintax: getPath({x1, y1, z1}|x1, y1, z1[, {x2, y2, z2}|x2, y2, z2] = tTurtle coords)
  ex: getPath(0, 0, 0) - returns the path from 0, 0, 0 to the coords of the turtle.
      getPath(0, 0, 0, 10, 10, 10) - gets the path from 0, 0, 0 to 10, 10, 10.
      getPath({2, 3, 5}) - gets the path from coords 2, 3, 5 to the turtle coords.
      getPath({3, 10, 5}, {10, 10, 10}) - gets the path from coords 3, 10, 5 to 10, 10, 10.
  Dependencies: getWorldEnt, ABSDistFromTo, distFromTo, getWorldPassableNeighbors]]

  local p1Index, p2Index = 1, 4 --if there is no table in the arg table
  local x1, y1, z1, x2, y2, z2
  arg = {...}

  if not arg[1] then return false --there is no arg
  elseif type(arg[1]) == "table" then
    x1, y1, z1 = table.unpack(arg[1])
    p2Index = 2
  elseif type(arg[1]) == "number" then
    x1, y1, z1 = table.unpack(arg)
  else return false
  end

  if not arg[p2Index] then
    x2 = tTurtle.x
    y2 = tTurtle.y
    z2 = tTurtle.z
  elseif type(arg[p2Index]) == "table" then
    x2, y2, z2 = table.unpack(arg[p2Index])
  elseif type(arg[p2Index]) == "number" then
    x2 = arg[p2Index]
    y2 = arg[p2Index+1]
    z2 = arg[p2Index+2]
  else return false
  end

  local destBlock = getWorldEnt(x2, y2, z2)
  local pTable={} --to return table with all the points
  local pStart = {x1, y1, z1, ["totDist"] = 0, ["checked"] = false, ["parent"] = false }
  local pEnd ={x2, y2, z2, ["totDist"] = 0, ["checked"] = false, ["parent"] = false }
  local pForTurning = ABSDistFromTo(pStart, pEnd) --penalty for turning
  local pForWrongDir = pForTurning * pForTurning --penalty for wrong way

  function pGetDir(p1,p2) --get the direction from p1 to p2
    local dx, dy, dz = distFromTo(p1, p2)
    return (dx>0 and 1 or 0) + (dx<0 and 3 or 0) + (dy > 0 and 4 or 0) + (dy < 0 and 8 or 0) + (dz > 0 and 2 or 0) + (dz < 0 and 0 or 0)
  end

  function pAdd(pPoint, parent) --return:table adds a point to the table and sets the parent if supplied
    if pPoint == nil then return false end --must have point

    if not pTable[pPoint[1] ] then pTable[pPoint[1] ] = {} end --is there a x coord on table
    if not pTable[pPoint[1] ][pPoint[2] ] then pTable[pPoint[1] ][pPoint[2] ] = {} end --is there a y coord on table
    if not pTable[pPoint[1] ][pPoint[2] ][pPoint[3] ] then pTable[pPoint[1] ][pPoint[2] ][pPoint[3] ] = {} end --is there a z coord on table

    local pT = pTable[pPoint[1] ][pPoint[2] ][pPoint[3] ] --pt is shorter than ...
    if pT.checked == true then return true end --this point was checked before

    local totDist = ABSDistFromTo(pPoint[1], pPoint[2], pPoint[3], pEnd[1], pEnd[2], pEnd[3]) --distance to end point
    totDist = totDist + ABSDistFromTo(pStart[1], pStart[2], pStart[3], pPoint[1], pPoint[2], pPoint[3]) --dist to start point
    local dir
    if parent then --there is a parent of this point
      totDist = totDist + parent.totDist --add total distance of parent
      dir = pGetDir(parent, pPoint) --the direction from parent to this
      --if bit32.band(pGetDir(pPoint, pEnd),dir)==0 then totDist=totDist+pForWrongDir end --penalty for wrong direction
      if parent.dir then --parent has direction? start hasn't
        if dir ~= parent.dir then --there was change in direction
          totDist = totDist + pForTurning --penalty for turning direction
        end
      end
    end


    if pT.totDist then --this point was calculated before
      if totDist >= pT.totDist then return true end
      pT.totDist = totDist
    else
      pT[1] = pPoint[1] --save cords for easy handling
      pT[2] = pPoint[2]
      pT[3] = pPoint[3]
      pT.totDist = totDist
      pT.checked = false --this point is not checked
    end
    pT.parent = parent --and set the parent
    pT.dir = dir
    return true
  end

  function pCompare(p1, p2) --return:boolean if p1==p2
    if (p1[1] == p2[1]) and (p1[2] == p2[2]) and (p1[3] == p2[3]) then return true end
    return false
  end

  function pGetLowerDistPoint(bChecked) -- return:point the lower totDist of all points and the point.checked==bChecked
    if bChecked == nil then bChecked = false end

    local distLow, iPoint --lower distance, pointIndex
    local kx, ky, kz, v --keys and value for points
    local x, y, z --cords
    for kx,v in pairs(pTable) do --first key=kz v=table(kx,v)
      for ky,v in pairs(v) do	--key=kx, v=(ky,v)
        for kz,v in pairs(v) do	--key=ky v={z,x,y,totDist,checked,parent}
          if v.checked == bChecked then --this point was checked?
            if not distLow then --is the first distance?
              distLow = v.totDist
              iPoint = pTable[kx][ky][kz] --set ipoint to return later
            else
              if v.totDist < distLow then --is not the first distance
                distLow = v.totDist
                iPoint = pTable[kx][ky][kz]
              end
            end
          end
        end
      end
    end
    return iPoint
  end

  function pReturn(p) --return:path points, only when the turtle turn direction
    local i, rTable = 1, {}
    local ip = p --ip is the last point = endPoint
    repeat --lets reverse the order
      if ip.parent then 
        if ip.parent.dir ~= ip.dir then i = i + 1 end --if point has parent and did turn count 1 point
      end
      ip = ip.parent
    until not ip
    ip = p
    rTable[i] = {} --save the last point
    rTable[i][1] = ip[1]
    rTable[i][2] = ip[2]
    rTable[i][3] = ip[3]
    i = i - 1
    repeat
      if ip.parent then
        if ip.parent.dir ~= ip.dir then --if point did turn direction save parent point, that's where it changed direction
          rTable[i] = {}
          rTable[i][1] = ip.parent[1]
          rTable[i][2] = ip.parent[2]
          rTable[i][3] = ip.parent[3]
          i = i - 1
        end
      end
      ip = ip.parent
    until not ip
    return rTable
  end


  ---- main getPath ----
  
  pAdd(pStart) --add start point
  local actPoint = pStart
	local iter = 0
  while not pCompare(pEnd, actPoint) do
		iter = iter + 1
		if iter > 2000 then return false end --cant find a path
    if not actPoint then return false end
    actPoint.checked = true --lets checked this point
    local neighbours = getWorldPassableNeighbors(actPoint) --get empty or unknown neighbours
    local i
    for i = 1,#neighbours do
      pAdd(neighbours[i], actPoint)
    end
    actPoint = pGetLowerDistPoint()
		if not actPoint then return false end
  end
  return pReturn(actPoint)
end 


------ TERMINAL FUNCTIONS ------

function printAt(nCol, nLin, ...) --[[ Prints at col, lin args separated by spaces (tab).
  20-05-2023 v0.4.0
  Param: nCol, nLin - numbers, column and line where to print.
  Returns:  true.
  Sintax: printAt(nColumn, nLine[, ...])
  Note: if no args to print it only sets the cursor at nCol, nLine.
  ex: printAt(10, 10, "hello", "world") - prints at 10, 10, "hello world"]]

	term.setCursorPos(nCol, nLin)
  arg = {...}

	for i = 1, #arg do
		term.write(arg[i].."\t")
	end
  return true
end

--not tested
function getCursorCol() --[[ Returns the column of the cursor.
  25-03-2024 v0.4.0
  Returns:  number - the column of the cursor
  Sintax: getCursorCol()
  ex: getCursorCol]]

    local x, _ = term.getCursorPos()
    return x
end

--not tested
function getCursorLin() --[[ Returns the line of the cursor.
  25-03-2024 v0.4.0
  Returns:  number - the line of the cursor.
  Sintax: getCursorLin
  ex: getCursorLin()]]

  local _, y = term.getCursorPos()
  return y
end

function writeAt(nCol, nLin, ...) --[[ Writes at col, lin args.
  20-05-2023 v0.4.0
  Param: nCol, nLin - numbers, column and line where to write.
  Returns:  true.
  Sintax: writeAt(nColumn, nLine[, ...])
  Note: if no args to write it only sets the cursor at nCol, nLine.
  ex: printAt(10, 10, "hello", "world") - prints at 10, 10, "helloworld"]]

	term.setCursorPos(nCol, nLin)
  arg = {...}
  
	for i = 1, #arg do
		term.write(arg[i])
	end
  return true
end

function term.getWidth() --[[ Returns the width of the terminal.
  20-05-2023 v0.4.0
  Returns:  number - the width of the terminal
  Sintax: term.getWidth()
  ex: term.getWidth() - returns the width of the terminal.]]

	local width, _ = term.getSize()
	return width
end

function term.getHeight() --[[ Returns the height of the terminal.
  20-05-2023 v0.4.0
  Returns:  number - the height of the terminal
  Sintax: term.geHeight()
  ex: term.getHeight() - returns the height of the terminal.]]

	local _, height = term.getSize()
	return height
end

function writeCenter(s, line) --[[ Writes a string or number centered in line.
  20-05-2023 v0.4.0
  Param: s - the string or number to write.
      line - the number of the line where to write.
  Returns:  true
  Sintax: writeCenter([s][, line])
  ex: writeCenter("hello world", 1) - writes "hello world" centered in line 1.
      writeCenter() - places the cursor at the center of the current line.
  Dependencies: term.getWidth]]

  if type(s) == "number" then s = tostring(s) end
	local col = term.getWidth()/2 - (s and (#s/2) or 0) + 1
  if not line then _, line = term.getCursorPos() end
  term.setCursorPos(col, line)
	if s then term.write(s) end
  return true
end

function printCenter(s, line) --[[ Prints a string or number centered, and moves the cursor to the beginning of the next line.
  20-05-2023 v0.4.0
  Param: s - the string or number to print.
      line - the number of the line where to print.
  Returns:  true
  Sintax: printCenter([s][, line])
  ex: printCenter("hello world", 1) - prints "hello world" centered in line 1.
      printCenter() - places the cursor at the center of the current line.
  Dependencies: term.getWidth]]

	if type(s) == "number" then s = tostring(s) end
	local col = term.getWidth()/2 - (s and (#s/2) or 0) + 1
  if not line then _, line = term.getCursorPos() end
  term.setCursorPos(col, line)
	if s then print(s) end
  return true
end

function clearLineTo(column) --[[ Clears the cursor line from column 1 to column.
  24-05-2023 v0.4.0
  Param: column - number: the last column to be cleared.
  Sintax: clearLineTo(column)
  ex: clearLineTo(10) - clears from column 1 to column 10.]]

  local _, line = term.getCursorPos()
  term.setCursorPos(1, line)
  term.write(spc(column))
end

function clearLineFrom(column) --[[ Clears the cursor line from column, to the last column.
  24-05-2023 v0.4.0
  Param: column - number: the first column to be cleared.
  Sintax: clearLineFrom(column)
  ex: clearLineFrom(10) - clears from column 10 to the last column.
  Dependencies: term.getWidth]]

  local _, line = term.getCursorPos()
  local width = term.getWidth() - column + 1
  term.setCursorPos(column, line)
  term.write(spc(width))
end

function clearColumn(column) --[[ Clears the column.
  24-05-2023 v0.4.0
  Param: column - number: the column to be cleared.
  Sintax: clearColumn(column)
  ex: clearColumn(10) - clears column 10.
  Dependencies: term.getHeight]]

  local height = term.getHeight()
  for i = 1, height do
    term.setCursorPos(column, i)
    term.write(" ")
  end
end

function clearColumnTo(line) --[[ Clears the cursor column from line 1 to line.
  24-05-2023 v0.4.0
  Param: line - number: the last line to be cleared.
  Sintax: clearColumnTo(line)
  ex: clearColumnTo(10) - clears the cursor column, from line 1 to  10.]]

  local column, _ = term.getCursorPos()
  for i = 1, line do
    term.setCursorPos(column, i)
    term.write(" ")
  end
end

function clearColumnFrom(line) --[[ Clears the cursor column from line to last line.
  24-05-2023 v0.4.0
  Param: line - number: the last line to be cleared.
  Sintax: clearColumnFrom(line)
  ex: clearColumnFrom(10) - clears the cursor column, from line 10 to last line.
  Dependencies: term.getHeight]]

  local column, _ = term.getCursorPos()
  for i = line, term.getHeight() do
    term.setCursorPos(column, i)
    term.write(" ")
  end
end

function paper(color) --[[ Sets the background color.
  24-05-2023 v0.4.0
  Param: color - number/string: the color code or name.
  Sintax: paper(color)
  ex: paper("white") - sets the background color to white.
      paper(32768) - sets the background color to black.]]

  if type(color) == "string" then color = colors[color] end
  term.setBackgroundColor(color)
end

function ink(color) --[[ Sets the text color.
  24-05-2023 v0.4.0
  Param: color - number/string: the color code or name.
  Sintax: ink(color)
  ex: ink("white") - sets the text color to white.
      ink(32768) - sets the text color to black.]]

  if type(color) == "string" then color = colors[color] end
  term.setTextColor(color)
end

function fillScr(sChar) --[[ Fills the screen with sChar.
  24-05-2023 v0.4.0
  Param: sChar - string: the character to fill the screen.
  Sintax: fillScr(sChar)
  ex: fillScr("-") - fills the screen with -.]]

  local width, height = term.getSize()
  for col = 1, width do
    for lin = 1, height do
      term.setCursorPos(col, lin)
      term.write(sChar)
    end
  end
end

function cls(backColor, textColor) --[[ Sets the background and text colors, the cursor pos to 1,1, and clears the screen.
  24-05-2023 v0.4.0
  Param: backColor - string/number: the background color.
         textColor - string/number: the text color.
  Sintax: cls(backColor, textColor)
  ex: cls("white", 32768) - sets the background color to white, and the text color to black.]]

  if type(backColor) == "string" then backColor = colors[backColor] end
  if type(textColor) == "string" then textColor = colors[textColor] end
  term.setBackgroundColor(backColor)
  term.setTextColor(textColor)
  term.setCursorPos(1, 1)
  term.clear()
end

------ TEST AREA ------

function TEST()

  -- test code bellow this line
  -----------------------------
  print(goToSpot("Home"))
  --print(down())
  --print(buildRect(-4, -4, "minecraft:cobblestone"))
  --back()
  --turnBack()
  --forward(4)
  --turnBack()
  --back(2)


  ---------------------------
  -- test code above this line
end

INIT()  
TERMINATE()