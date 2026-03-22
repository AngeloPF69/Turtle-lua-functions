# computercraft turtle lua improved commands

improving commands in lua for computer craft turtle.

## TODO TO VERSION 0.4.0

- [ ] inspect functions must update tEnt, tRevEnt and tWorld on positive inspect.
- [ ] create function isFuel(nSlot)
- [ ] and finally create getPath(P1, P2)
- [x] goto(x,y,z) not using pathfinding.
- [ ] create table for equipable tools

## DONE

- [x] cataloging each block in a table ex: tEnt[sEntityName] = nId.
	- [x] entAdd(sEntName) Adds a entity name to table ent.
	- [x] entAddInv() Adds all the inventory items to tEnts.
	- [x] entAddSlot(nSlot) Adds item in nSlot to tEnts.
	- [x] entGetSlotId(nSlot) Gets or adds the nSlot item tEnts.
	- [x] entGetId(sEntName) Gets the entity id.
- [x] save and load tEnts into/from file
	- [x] saveEnt() Saves table tEnts into tEnts.txt file.
	- [x] loadEnt() Loads tEnts.txt into table tEnts.
- [x] create set/get functions for tEnt.
- [x] create a reversed table of tEnt: tRevEnt[nID] = sEntityName	
- [x] save and load table into/from file
	- [x] saveRevEnt() Saves tRevEnts into tRevEnts.txt file.
	- [x] loadRevEnt() Loads tRevEnts.txt into tRevEnts table.
- [x] create set/get functions for tRevEnt.
	- [x] entGetName(nId) Gets the entity name.
- [x] create a table for fuel, ex: tEnts[sItemName].fuel = fuel.
- [x] create set/get functions for tFuel.
	- [x] setFuel(sItem, nQFuel) Sets tEnts[sItem].fuel to nQFuel.
	- [x] addFuel(sItem, nQFuel) Sets tEnts[sItem].fuel to nQFuel.
	- [x] getFuel(sItem) Get the fuel for sItem.
- [x] getAllFuelItems()  Gets a table with all fuel items.
- [x] getFuelSlot(nSlot) Gets the quantity of fuel given by item in nSlot.
- [x] fuelTestSlot(nSlot) Test the item in nSlot for fuel.
- [x] getInvFuel() Gets the total fuel in inventory.
- [x] checkFuel(...) Checks if the fuel is enough.
- [x] isFuelEnoughTo(x, y, z) Checks if the fuel is enough to go to x,y,z
- [x] getSlotsToFuel(nFuel) Gets the quantity of items in each slot to fuel nFuel.
- [x] getInvFuelItems() Gets the inventory slots and items that are fuel.
- [x] upgrade refuel to refuelItems(sItemName, nCount) Refuels the turtle with nCount items or fuel from inventory.
- [x] create tWorld(x, y, z, nEntId)
- [x] create set/get for tWorld
	- [x] setWorldEnt(x, y, z, nEnt) Set world coords containing nEnt.
	- [x] getWorldEnt(x, y, z) Gets the entity at coords x,y,z.
- [x] save and load tWorld into/from file
	- [x] saveWorld() Saves tWorldinto tWorld.txt
	- [x] loadWorld() Loads tWorld.txt into tWorld table.
- [x] getNearestBlock(sBlock, nAmp) Gets the coords of the nearest block.
- [x] worldFindBlock(sBlock) Gets the coords for sBlock in tWorld.
- [x] create tSpot[sSpotName] = {x, y, z, facing}
- [x] save and load tSpots into/from file
	- [x] saveSpots() Saves table tSpots in text file tSpots.txt
	- [x] loadSpots() Loads from file tSpots.txt to table tSpots
- [x] setSpot(sSpotName, x, y, z, nFacing) Sets a spot in tSpots table.
- [x]getSpot(sSpotName) Gets the spot.
- [x] goToSpot(sSpotName) Turtle walks to the spot coords, and turns to spot facing.
- [x] getFreeHand(sHand) Gets turtle free hand: "right"|"left"|false.
- [x] unequip(sHand)
	
### POSTPONED


## TODO TO VERSION 0.3.0

### DONE

- [x] isInventoryEmpty() Checks if inventory is empty.
- [x] getSecSumItems(nSlot, bWrap) Gets the sum of items in sequencial not empty slots.
- [x] craftInv(nLimit) Crafts the recipe in inventory.
- [x] cmpInventory(tInv1, tInv2) Compares 2 snapshots of inventory.
- [x] cmpInvIncreased(tInv1, tInv2) Verifies if inventory quantities have increased.
- [x] craftRecipe(sRecipe, nLimit) Craft a recipe.
- [x] getLowestKey(t) Gets the lowest key of the table t.
- [x] haveIngredients(sRecipe, nLimit) Renamed to haveItems(sRecipe, nIndex) Builds a table with the diference between the recipe and the inventory.
- [x] canCraft() Retuns a table with recipe name and index that you can craft from inventory.
- [x] canCraftRecipe(sRecipe) Checks if you can craft sRecipe with inventory items.
- [x] addRecipe(sRecipe, tRecipe, nCount) Returns index of recipe.
- [x] getInvRecipe() Builds a table with items and their position from inventory (the recipe).
- [x] getRecipe(sRecipe, nIndex) Gets the recipe from tRecipes.
- [x] getRecipeItems(sRecipe, nIndex) Builds a table with items and quantities in a recipe.
- [x] getInvItems() Builds a table with the items and quantities in inventory.
- [x] getRecipeIndex(sRecipe, tRecipe) Returns a number (index) of the recipe in tRecipes.
- [x] colLinMatch(tRecs, tRec) Compares recipes items position, returns true if is the same.
- [x] getProdQuant() Returns the quantity of products made with the recipe in inventory.
- [x] placeBack(nBlocks) Turtle turns back and places nBlocks in a strait line forward or backwards, and returns to starting point.
- [x] getItemName(nSlot) Gets the item name from Slot/selected slot.
- [x] isNumber(...) Checks if all parameters are numbers.
- [x] checkfuel(nActions) check if the fuel is enough for that action.

### POSTPONED

- [ ] detectUp([Blocks=1]) detects if upwards the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectDown([Blocks=1]) detects if downwards the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectLeft([Blocks=1]) detects if on the left of the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectRight([Blocks=1]) detects if on the right of the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectBack([Blocks=1]) detects if on the turtle backs are blocks in a strait line, stops when there isn't or blocked.
- [ ] compareUp([Blocks=1]) compare blocks upwards in a strait line with selected slot or inventory.
- [ ] compareDown([Blocks=1]) compare blocks downwards in a strsit line with selected slot or inventory.
- [ ] compareLeft([Blocks=1]) compare blocks left of the turtle in a strait line with selected slot or inventory.
- [ ] compareRight([Blocks=1]) compare blocks Right of the turtle in a strait line with selected slot or inventory.

## TODO TO VERSION 0.2.0

### OPTIONAL

- [x] flattenInventory() averages all the item stacks in inventory.
- [x] calcAverage(tSlots, tIng) builds a table with item and average between items and slots.
- [x] recipeSlots(sRecipe) builds a table with item and quantity of slots ocupied by the recipe.
- [x] leaveItems(sItemName, nQuant, bWrap) leaves nQuant of item in Selected Slot, moving item from or to another slot.
- [x] searchSpace(sItemName, nStartSlot, bWrap) search for space in a slot that has sItemName.
- [x] haveIngredients(sRecipe, nLimit) builds a table with the diference between the recipe and the inventory.
- [x] ingredients(sRecipe) builds a table with items and quantities in a recipe.
- [x] invIngredients() builds a table with the items and quantities in inventory.
- [x] invLowerStack(sItem) returns the lower stack of items in inventory, the slot and the name of item.
- [x] saveTable(t, sFileName) saves a table into a text file.
- [x] loadTable(sFileName) loads a text file into a table.
- [x] isValue(value, t) checks if value is in t table.

### POSTPONED

### IN PROGRESS


### DONE

- [x] fsGetFreeSpace() gets the total free space on disk.
- [x] selectFreeSlot(nStartSlot, bWrap) selects the first free slot starting at nStartSlot, and if the search wraps or not.
- [x] itemCount(nSlot) counts items in inventory
- [x] isEmptySlot(nSlot) checks if nSlot is empty.
- [x] incSlot(nSlot, bWrap) increases nSlot in range [1..16].
- [x] decSlot(nSlot, bWrap) decreases nSlot in range [1..16].
- [x] getInventory() builds a table with the slot, the name and quantity of items in inventory.
- [x] countItemSlots() counts how many slots is ocupied with each item.
- [x] itemsBelong(\[sRecipe=tRecipes.lastRecipe]) checks if all the items in inventory belong to a recipe.
- [x] setCraftSlot(nSlot) sets the craft resulting slot, in tRecipes CSlot
- [x] arrangeRecipe(sRecipe) arranges items in inventory to craft a recipe.
- [x] transferFrom(nSlot, nItems) transfer nItems from nSlot to selected slot.
- [x] INIT() loads tables from text files.
- [x] TERMINATE() saves tables to text files.
- [x] setStack(sItemName, nStack) sets the item stack value in tStacks.
- [x] getStack(nSlot/sItemName) returns how many items can stack.
- [x] loadStacks() loads tStacks.txt to tStacks.
- [x] saveStacks() saves tStacks to tStacks.txt.
- [x] setCoords(x,y,z) sets coords x, y, z for turtle
- [x] distTo(x, y, z) gets the three components of the distance from the turtle to point.
- [x] getCoords() gets coords from turtle.
- [x] addSteps(\[nSteps=1\]) adds nSteps to coords of turtle.
- [x] freeCount() get free slots in turtle's inventory.
- [x] getFreeSlot(nStartSlot) get the first free slot.
- [x] groupItems() groups the same type of items in one slot in inventory.
- [x] incFacing(nTurns) increments tTurtle.facing by nTurns
- [x] decFacing(nTurns) decrements tTurtle.facing by nTurns
- [x] saveRecipes() saves tRecipes in a file as "tRecipes.txt"
- [x] loadRecipes() loads tRecipes from file "tRecipes.txt"
- [x] clearSlot(nSlot) clears content of slot, moving items to another slot.
- [x] getFirstItemCoords(sRecipe) returns the column and line=0 of the first item in the recipe.
- [x] getMaxCraft() returns maximum limit to craft the recipe on inventory.
- [x] getInvRecipe() builds a table with items and their position (the recipe).
- [x] setFacing(sFacing) sets tTurtle.facing.
- [x] getFacing() returns tTurtle.facing.
- [x] saveTurtle() saves tTurtle to file tTurtle.txt.
- [x] loadTurtle() loads tTurtle from file tTurtle.txt.
- [x] getFreeHand() gets turtle free hand: "left"|"right"|false.
- [x] all base movement functions (forward, up, down, back) must change the coords in tTurtle.
  - [x] down([Blocks=1]) moves the turtle down blocks, until it hits something.
  - [x] up([Blocks=1]) moves the turtle up blocks, until it hits something.
  - [x] back([Blocks=1]) Moves the turtle backwards or forward blocks, until blocked.
  - [x] forward([Blocks=1]) Moves nBlocks forward or backwards, until blocked.
- [x] All base rotation functions (turn left and right) must update tTurtle.facing.
  - [x] turnDir([Direction="back"]) rotates turtle back, left or right.
- [x] setCoords(x,y,z) sets coords x, y, z for turtle. x
- [x] distTo(x, y, z) gets the three components of the distance from the turtle to point.
- [x] getCoords() gets coords from turtle.

## TODO TO VERSION 0.1.0

### OPTIONAL

- [x] isKey(Key, t) Checks if Key is in t table. [Eliminated]
- [x] checkType(sType, ...) Checks if parameters are from sType.
- [x] getParam(sParamOrder, tDefault, ...) Sorts parameters by type.
- [x] tableInTable(tSearch, t) Verifies if tSearch is in table t.
- [x] sign(value) Returns: -1 if value < 0, 0 if value == 0, 1 if value > 0

### POSTPONED

- [ ] detectUp([Blocks=1]) detects if upwards the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectDown([Blocks=1]) detects if downwards the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectLeft([Blocks=1]) detects if on the left of the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectRight([Blocks=1]) detects if on the right of the turtle are blocks in a strait line, stops when there isn't or blocked.
- [ ] detectBack([Blocks=1]) detects if on the turtle backs are blocks in a strait line, stops when there isn't or blocked.
- [ ] compareUp([Blocks=1]) compare blocks upwards in a strait line with selected slot or inventory.
- [ ] compareDown([Blocks=1]) compare blocks downwards in a strsit line with selected slot or inventory.
- [ ] compareLeft([Blocks=1]) compare blocks left of the turtle in a strait line with selected slot or inventory.
- [ ] compareRight([Blocks=1]) compare blocks Right of the turtle in a strait line with selected slot or inventory.

### IN PROGRESS

### DONE

- [x] refuel(\[nItems=stack\]) refuels the turtle with nItems.
- [x] itemSpace(\[slot/item Name=selected slot\]) get the how many items more you can store in inventory.
- [x] equip(\[side=empty hand\]) equip tool to left or right hand, from selected slot.
- [x] itemName([Slot=Selected slot]) gets the item name from Slot.
- [x] inspectDir([sDir="forward]) turtle inspect block in sDir direction {"forward", "right", "back", "left", "up", "down"}.
- [x] suckDir([sDir="forward"][,count=all the items]) sucks items from sDir direction {"forward", "right", "back", "left", "up", "down"}.
- [x] attackDir([sDir="forward"]) Turtle attack in sDir direction {"forward", "right", "back", "left", "up", "down"}.
- [x] compareDir([sDir="forward"][, nSlot=selected slot]) Compares item in slot with block in sDir direction.
- [x] compareAbove([Blocks=1]) compare blocks above the turtle in a strait line with selected slot.
- [x] compareBelow([Blocks=1]) compare blocks below the turtle in a strait line with selected slot.
- [x] detectAbove([Blocks=1]) detects if exits Blocks above the turtle in a strait line forward or backwards.
- [x] detectBelow([Blocks=1]) detects if exits Blocks below the turtle in a strait line forward or backwards.
- [x] detectDir([Direction="forward"]) detects if there is a block in Direction { "forward", "right", "back", "left", "up", "down" }.
- [x] itemCount([selected slot/slot/inventory/item name]) counts items in inventory.
- [x] itemSelect([Slot/Item Name]) selects slot [1..16] or first item with Item Name, or the turtle selected slot.
- [x] search([ItemName[, StartSlot=Selected Slot]]) Search inventory for ItemName, starting at StartSlot. 
- [x] placeBelow([Blocks=1]) places inventory selected Blocks in a strait line 1 block below the turtle and forward, and returns to initial position.
- [x] placeAbove([Blocks=1]) places inventory selected Blocks in a strait line 1 block above the turtle and forward, and returns to initial position.
- [x] placeRight([Blocks=1]) rotates turtle Right, places inventory selected Blocks in a strait line forward, and returns to initial position.
- [x] placeLeft([Blocks=1]) rotates turtle left, places inventory selected Blocks in a strait line forward, and returns to initial position.
- [x] place([Blocks=1]) places inventory selected Blocks in a strait line forward.
- [x] placeDown([Blocks=1]) places inventory selected Blocks in a strait line downward, and returns to initial position.
- [x] placeUp([Blocks=1]) places inventory selected Blocks in a strait line upward, and returns to initial position.
- [x] placeDir([Direction="forward"]) places inventory selected Block in Direction { "forward", "right", "back", "left", "up", "down" }.
- [x] digBack([Blocks=1]) rotates turtle back or not and dig Blocks forward.
- [x] digAbove([Blocks=1]) dig Blocks, 1 block above the turtle, and forward or backwards.
- [x] digBelow([Blocks=1]) dig Blocks, 1 block below the turtle, and forward or backwards.
- [x] digUp([Blocks=1]) dig Blocks upwards or downwards.
- [x] digDown([Blocks=1]) dig Blocks downwards or upwards.
- [x] digRight([Blocks=1]) rotates turtle Right or left and dig Blocks forward with tool.
- [X] digLeft([Blocks=1]) rotates turtle left or right and dig Blocks forward with tool.
- [x] dig([Blocks=1]) dig Blocks forward or backwards with tool.
- [x] digDir([Direction="forward"][, Blocks=1]) turtle digs in Direction direction Blocks.
- [X] turnDir([Direction="back"]) rotates turtle back, left or right.
- [x] turnBack() Turtle turns back.
- [x] goDir([Direction="forward][, nBlocks]) turtle goes in Direction { "forward", "right", "back", "left", "up", "down" } nBlocks until blocked.
- [x] goLeft(nBlocks) turns left or  right if nBlocks <0, and advances nBlocks until blocked.
- [x] goRight(nBlocks) turns right or left if nBlocks < 0, and advances nBlocks until blocked.
- [x] goBack(nBlocks) turns back or not if nBlocks < 0, and advances nBlocks until blocked.
- [x] down([Blocks=1]) moves the turtle down blocks, until it hits something.
- [x] up([Blocks=1]) moves the turtle up blocks, until it hits something.
- [x] back([Blocks=1]) Moves the turtle backwards or forward blocks, until blocked.
- [x] forward([Blocks=1]) Moves nBlocks forward or backwards, until blocked.
- [x] dropDir([sDir="forward"][, nBlocks=stack of items]) drops nBlocks from selected slot and inventory in the world in front, up or down the turtle.
- [x] drop(nBlocks) drops nBlocks from selected slot and inventory in the world in front of the turtle.
- [x] dropUp(nBlocks) drops nBlocks from selected slot and inventory in the world upwards.
- [x] dropDown(nBlocks) drops nBlocks from selected slot and inventory in the world downwards.
- [x] dropLeft(nBlocks) Rotate left and drops or sucks nBlocks forward.
- [x] dropRight(nBlocks) Rotate right and drops or sucks nBlocks forward.
- [x] dropBack(nBlocks) Rotate back and drops or sucks nBlocks forward.