require "defines"
require "interfaces"

local fieldOverlayName = "tree-farm-field-overlay"
local fieldName = "tree-farm-field"
local fieldRadius = 9
local fieldInventoryIndex = 1
local fieldTickRate = 58
local retryCount = 2
local treeGrowthData
local seedNameToSeedType
local ceil = math.ceil
local random = math.random

function initGrowthData()
    if treeGrowthData ~= nil then
        return
    end

    treeGrowthData =
    {
        standard =
        {
            states =
            {
                "tf-germling",
                "tf-very-small-tree",
                "tf-small-tree",
                "tf-medium-tree",
                "tf-mature-tree"
            },
            efficiency =
            {
                ["grass"] = 1.00,
                ["grass-medium"] = 1.00,
                ["grass-dry"] = 0.90,
                ["dirt"] = 0.75,
                ["dirt-dark"] = 0.75,
                ["hills"] = 0.50,
                ["sand"] = 0.30,
                ["sand-dark"] = 0.30,
                ["other"] = 0.01
            },
            growth_time = 3600,
            random_time = 1800
        },
        coral =
        {
            states =
            {
                "tf-coral-seed",
                "tf-small-coral",
                "tf-medium-coral",
                "tf-mature-coral"
            },
            efficiency =
            {
                ["grass"] = 0.50,
                ["grass-medium"] = 0.50,
                ["grass-dry"] = 0.70,
                ["dirt"] = 0.75,
                ["dirt-dark"] = 0.75,
                ["hills"] = 0.75,
                ["sand"] = 1.00,
                ["sand-dark"] = 1.00,
                ["other"] = 0.01
            },
            growth_time = 9000,
            random_time = 9000
        }
    }
end

function initSeedNameToSeedType()
	seedNameToSeedType = {}
	for seedTypeName, seedType in pairs(treeGrowthData) do
		for _, stateName in pairs(seedType.states) do
			seedNameToSeedType[stateName] = seedTypeName
		end
	end
end

function init_treefarm()
    global.trees = global.trees or {}
    global.fields = global.fields or {}
    global.counter = global.counter or 0
    
    initGrowthData()
    initSeedNameToSeedType()
end

function placeTreeIntoList(treeData, tick)
    if global.trees[tick] == nil then
        global.trees[tick] = {}
    end

    table.insert(global.trees[tick], treeData);
end

function seedPlaced(seed, seedTypeName)
	local efficiency = calcEfficiency(seed, seedTypeName)
	local entInfo =
	{
		entity = seed,
		state = 1,
		efficiency = efficiency,
	}
  
  local nextTick = game.tick + ceil((random() * treeGrowthData[seedTypeName].random_time + treeGrowthData[seedTypeName].growth_time) / entInfo.efficiency)
	placeTreeIntoList(entInfo, nextTick)
end

function calcEfficiency(entity, seedTypeName)
  local position = entity.position
	local tileName = entity.surface.get_tile(position.x, position.y).name
	
  return treeGrowthData[seedTypeName].efficiency[tileName] or treeGrowthData[seedTypeName].efficiency.other
end

function builtEntity(event)
  if event.created_entity.name == fieldOverlayName then
    fieldOverlayPlaced(event.created_entity)
  elseif seedNameToSeedType[event.created_entity.name] then
		seedPlaced(event.created_entity, seedNameToSeedType[event.created_entity.name])
  end
end

function fieldOverlayPlaced(fieldOverlay)
    local position = fieldOverlay.position
    local surface = fieldOverlay.surface
    local force = fieldOverlay.force
    
    local field = surface.create_entity{name = fieldName,
                                        position = position,
                                        force = force}
		local fieldInfo =
		{
			entity = field,
      inventory = field.get_inventory(fieldInventoryIndex),
      surface = surface,
      forceName = force.name,
			plantPos = {x = position.x - fieldRadius - 0.5, y = position.y - fieldRadius - 0.5}
		}
		
		table.insert(global.fields, fieldInfo)
		
		fieldOverlay.destroy()
    
    -- Mark any trees in the immediate area of the farm
    local areaPosMin = {x = field.position.x - fieldRadius - 1, y = field.position.y - fieldRadius - 1}
		local areaPosMax = {x = field.position.x + fieldRadius + 1, y = field.position.y + fieldRadius + 1}
		for _,entity in pairs(surface.find_entities_filtered({area = {areaPosMin, areaPosMax}, type = "tree"})) do
			for _,seedType in pairs(treeGrowthData) do
				if entity.name == seedType.states[#seedType.states] then
					entity.order_deconstruction(force)
				end
			end
		end
end

function harvestTree(treeInfo)
	local treePos = treeInfo.entity.position
	
  for k,v in pairs(global.fields) do
    if v.entity.valid then
      local fieldPos = v.entity.position
      
      if fieldPos.x - fieldRadius - 1 <= treePos.x and fieldPos.x + fieldRadius + 1 >= treePos.x and fieldPos.y - fieldRadius - 1 <= treePos.y and fieldPos.y +fieldRadius + 1 >= treePos.y then
        treeInfo.entity.order_deconstruction(v.entity.force)
        return
      end
    end
  end
end

function tickTrees(tick)
  if global.trees[tick] == nil then
    return
  end
  
	for k,v in pairs(global.trees[tick]) do
		if v.entity.valid then
			local seedType = seedNameToSeedType[v.entity.name]
      if seedType ~= nil then
        local newState = v.state + 1
        
        if newState == #treeGrowthData[seedType].states then
          local newTree = v.entity.surface.create_entity({name = treeGrowthData[seedType].states[newState], position = v.entity.position})
          v.entity.destroy()
          v.entity = newTree
          
          harvestTree(v)
        else
          local newTree = v.entity.surface.create_entity({name = treeGrowthData[seedType].states[newState], position = v.entity.position})
          v.entity.destroy()
          v.entity = newTree
          v.state = newState
          
          local nextTick = game.tick + ceil((random() * treeGrowthData[seedType].random_time + treeGrowthData[seedType].growth_time) / v.efficiency)
          placeTreeIntoList(v, nextTick)
        end
      end
		end
	end
  
	global.trees[tick] = nil
end

function getSeedFromField(fieldInfo)
	for _,seedType in pairs(treeGrowthData) do
		local newAmount = fieldInfo.inventory.get_item_count(seedType.states[1])
		if newAmount > 0 then
			return {name = seedType.states[1], type = _}
		end
	end
	
	return nil
end

function consumeSeedFromField(fieldInfo, seedName)
  fieldInfo.inventory.remove({name = seedName, count = 1})
end

function tickFields()
	for k,fieldInfo in pairs(global.fields) do
    if fieldInfo.entity.valid then
      local seed = getSeedFromField(fieldInfo)
      
      if seed ~= nil then
        local retry = 0
        
        while retry < retryCount do
          if fieldInfo.surface.can_place_entity({name = seed.name, position = fieldInfo.plantPos}) then
            local entity = fieldInfo.surface.create_entity({name = seed.name, position = fieldInfo.plantPos, force = fieldInfo.forceName})
            retry = retryCount
            
            seedPlaced(entity, seed.type)
            consumeSeedFromField(fieldInfo, seed.name)
          else
            retry = retry + 1
          end
          
          -- move the plant position 1 forward
					fieldInfo.plantPos.y = fieldInfo.plantPos.y + 1
					if fieldInfo.plantPos.y > fieldInfo.entity.position.y + fieldRadius + 0.5 then
						fieldInfo.plantPos.y = fieldInfo.entity.position.y - fieldRadius - 0.5
						fieldInfo.plantPos.x = fieldInfo.plantPos.x + 1
						
						if fieldInfo.plantPos.x > fieldInfo.entity.position.x + fieldRadius + 0.5 then
							fieldInfo.plantPos.x = fieldInfo.entity.position.x - fieldRadius - 0.5
						end
					end
          -- move position
        end
        -- retry
      end
      -- seed
      
    else
      table.remove(global.fields, k)
    end
  end
end

script.on_event(defines.events.on_tick, function(event)
	tickTrees(event.tick)
	
  if global.counter == 0 then
    global.counter = fieldTickRate
    
    tickFields()
  else
    global.counter = global.counter - 1
  end
end)

script.on_configuration_changed(function(data)
  init_treefarm()
end)

script.on_init(function()
    init_treefarm()
end)

script.on_load(function()
  initGrowthData()
  initSeedNameToSeedType()
end)

script.on_event(defines.events.on_built_entity, builtEntity)
script.on_event(defines.events.on_robot_built_entity, builtEntity)