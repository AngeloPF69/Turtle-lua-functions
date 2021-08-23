local function forward(Blocks)
  Blocks = Blocks or 1
  
  for i = 1, Blocks do
    if not turtle.forward() then return false end
  end
  return true
end

local function back(Blocks)
  Blocks = Blocks or 1
  
  for i = 1, Blocks do
    if not turtle.back() then return false end
  end
  return true
end

local function up(Blocks)
  Blocks = Blocks or 1
  
  for i = 1, Blocks do
    if not turtle.up() then return false end
  end
  return true
end

local function down(Blocks)
  Blocks = Blocks or 1
  
  for i = 1, Blocks do
      if not turtle.down() then return false end
  end
  return true
end

local function goLeft(Blocks)
  Blocks = Blocks or 1
  
  turtle.turnLeft()
  for i = 1, Blocks do
    if not turtle.forward() then return false end
  end
  return true
end

local function goRight(Blocks)
  Blocks = Blocks or 1
  
  turtle.turnRight()
  for i= 1, Blocks do
    if not turtle.forward() then return false end
  end
  return true
end

local function goBack(Blocks)
  Blocks = Blocks or 1
  
  turtle.turnRight()
  turtle.turnRight()
  for i = 1, Blocks do
    if not turtle.forward() then return false end
  end
  return true
end

local function turn(sDir)
  sDir = sDir or "back"
  
  if sDir == "back" then
    turtle.turnRight()
    turtle.turnRight()
  else if sDir == "left" then
    turtle.turnLeft()
  else if sDir == "right" then
    turtle.turnRight()
  else return false
  end
  return true
end
