local function forward(Blocks)
  Blocks = Blocks or 1
  
  for i=1, Blocks do
    if not turtle.forward() then return false end
  end
  return true
end

local function back(Blocks)
  Blocks = Blocks or 1
  
  for i=1, Blocks do
    if not turtle.back() then return false end
  end
  return true
end
