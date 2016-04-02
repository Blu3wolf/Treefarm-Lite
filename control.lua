require "defines"
require "interfaces"

function initialise()
	global.tf = {}
	global.tf.fieldList = {}
	global.tf.fieldsToMaintain = {}
	global.tf.fieldmk2sToMaintain = {}
	global.tf.seedPrototypes = {}
	global.tf.treesToGrow = {}
	defineStandardSeedPrototypes()
	populateSeedTypeLookUpTable()
	global.tf.playersData = {}
	for pIndex, player in ipairs(game.players) do
		if global.tf.playersData[pIndex] == nil then
			global.tf.playersData[pIndex] = {}
			global.tf.playersData[pIndex].guiOpened = false
			global.tf.playersData[pIndex].overlayStack = {}
		end
	end
end

local seedTypeLookUpTable = {}
function populateSeedTypeLookUpTable()
  for seedTypeName, seedType in pairs(global.tf.seedPrototypes) do
    for _, stateName in pairs(seedType.states) do
      seedTypeLookUpTable[stateName] = seedTypeName
    end
  end
end

script.on_init(function()
	initialise()
end)

script.on_configuration_changed(function(data)
	for seedTypeName, seedPrototype in pairs (global.tf.seedPrototypes) do
		if game.item_prototypes[seedPrototype.states[1]] == nil then
			global.tf.seedPrototypes[seedTypeName] = nil
		end
	end
	
	if data.mod_changes ~= nil and data.mod_changes["Treefarm-Lite"] ~= nil then
		if data.mod_changes["Treefarm-Lite"].old_version == nil then
			initialise()
		else
			local oldVer = tonumber(string.sub(data.mod_changes["Treefarm-Lite"].old_version, 3, 5))
			if oldVer < 3 then
				v3Update()
			elseif oldVer < 3.4 then
				v34Update()
			end
		end
	end
end)

script.on_load(function()
	for _, plantTypes in pairs(global.tf.seedPrototypes) do
		if plantTypes.efficiency.other == 0 then
			plantTypes.efficiency.other = 0.01
		end
	end
	if seedTypeLookUpTable ~= nil then
		seedTypeLookUpTable = {}
	end
	populateSeedTypeLookUpTable()
end)

script.on_event(defines.events.on_player_created, function(event)
  if global.tf.playersData[event.player_index] == nil then
    global.tf.playersData[event.player_index] = {}
    global.tf.playersData[event.player_index].guiOpened = false
    global.tf.playersData[event.player_index].overlayStack = {}
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local index = -1

  for k,field in ipairs(global.tf.fieldList) do
    if (global.tf.playersData[event.element.player_index].guiOpened ~= false) and (global.tf.playersData[event.element.player_index].guiOpened == field.entity) then
      index = k
      break
    end
  end
  if index == -1 then return end
  local player = game.players[event.player_index]
  if event.element.name == "okButton" then
    if player.gui.center.fieldmk2Root ~= nil then
      destroyOverlay(event.element.player_index)
      global.tf.playersData[event.element.player_index].guiOpened = false
      player.gui.center.fieldmk2Root.destroy()
    end
  elseif event.element.name == "toggleActiveBut" then
    if global.tf.fieldList[index].active == true then
      global.tf.fieldList[index].active = false
      mk2CancelDecontruction(global.tf.fieldList[index])
      player.gui.center.fieldmk2Root.fieldmk2Table.colLabel2.caption = "not active"
    else
      global.tf.fieldList[index].active = true
      mk2MarkDeconstruction(global.tf.fieldList[index])
      player.gui.center.fieldmk2Root.fieldmk2Table.colLabel2.caption = "active"
    end
    destroyOverlay(event.element.player_index)
    createOverlay(event.element.player_index, global.tf.fieldList[index])
  elseif event.element.name == "incAreaBut" then
    if global.tf.fieldList[index].areaRadius < 9 then
      global.tf.fieldList[index].areaRadius = global.tf.fieldList[index].areaRadius + 1
      destroyOverlay(event.element.player_index)
      createOverlay(event.element.player_index, global.tf.fieldList[index])
    end
    player.gui.center.fieldmk2Root.fieldmk2Table.areaLabel2.caption = global.tf.fieldList[index].areaRadius
  elseif event.element.name == "decAreaBut" then
    if global.tf.fieldList[index].areaRadius > 1 then
      global.tf.fieldList[index].areaRadius = global.tf.fieldList[index].areaRadius - 1
      destroyOverlay(event.element.player_index)
      createOverlay(event.element.player_index, global.tf.fieldList[index])
    end
    player.gui.center.fieldmk2Root.fieldmk2Table.areaLabel2.caption = global.tf.fieldList[index].areaRadius
  end

end)

script.on_event(defines.events.on_put_item, function(event)
  for playerIndex,player in pairs(game.players) do
    if (player ~= nil) and (player.selected ~= nil) then
      if player.selected.name == "tf-fieldmk2" then
        for index, entInfo in ipairs(global.tf.fieldList) do
          if entInfo.entity == player.selected then
            showFieldmk2GUI(index, playerIndex)
            global.tf.playersData[playerIndex].guiOpened = entInfo.entity
          end
        end
      end
    end
  end
end)

script.on_event(defines.events.on_built_entity, function(event)
  local player = game.players[event.player_index]
  if event.created_entity.type == "tree" then
    local currentSeedTypeName = seedTypeLookUpTable[event.created_entity.name]
    if currentSeedTypeName ~= nil then
      local newEfficiency = calcEfficiency(event.created_entity, false)
      local deltaTime = math.ceil((math.random() * global.tf.seedPrototypes[currentSeedTypeName].randomGrowingTime + global.tf.seedPrototypes[currentSeedTypeName].basicGrowingTime) / newEfficiency)
      local nextUpdateIn = event.tick + deltaTime
      local entInfo =
      {
        entity = event.created_entity,
        state = 1,
        efficiency = newEfficiency
      }
      insertSeed(entInfo, nextUpdateIn)
      return
    end
  elseif event.created_entity.name == "tf-field" then
    if canPlaceField(event.created_entity) ~= true then
      player.insert{name = "tf-field", count = 1}
      event.created_entity.destroy()
      player.print({"msg_buildingFail"})
      return
    else
      local entInfo =
      {
        entity = event.created_entity,
        fertAmount = 0,
        lastSeedPos = {x = 2, y = 0}
      }
	  local nextUpdate = event.tick + 60
	  table.insert(global.tf.fieldList, entInfo)
      insertField(entInfo, nextUpdate)
      return
    end
  elseif event.created_entity.name == "tf-fieldmk2Overlay" then
    local ent = game.get_surface("nauvis").create_entity{name = "tf-fieldmk2",
                    position = event.created_entity.position,
                    force = player.force}
    local entInfo =
    {
      entity = ent,
      active = true,
      areaRadius = 9,
      fertAmount = 0,
      lastSeedPos = {x = -9, y = -9},
      toBeHarvested = {}
    }
	local nextUpdate = event.tick + 60
	table.insert(global.tf.fieldList, entInfo)
	insertFieldmk2(entInfo, nextUpdate)
    showFieldmk2GUI(#global.tf.fieldmk2sToMaintain, event.player_index)
    global.tf.playersData[event.player_index].guiOpened = entInfo.entity
    event.created_entity.destroy()
    return
  end
end)


script.on_event(defines.events.on_robot_built_entity, function(event)
  --local player = game.players[event.player_index]
  if event.created_entity.type == "tree" then
    local currentSeedTypeName = seedTypeLookUpTable[event.created_entity.name]
    if currentSeedTypeName ~= nil then
      local newEfficiency = calcEfficiency(event.created_entity, false)
      local deltaTime = math.ceil((math.random() * global.tf.seedPrototypes[currentSeedTypeName].randomGrowingTime + global.tf.seedPrototypes[currentSeedTypeName].basicGrowingTime) / newEfficiency)
      local nextUpdateIn = event.tick + deltaTime
      local entInfo =
      {
        entity = event.created_entity,
        state = 1,
        efficiency = newEfficiency
      }
      insertSeed(entInfo, nextUpdateIn)
      return
    end
  elseif event.created_entity.name == "tf-field" then
    if canPlaceField(event.created_entity) ~= true then
      game.get_surface("nauvis").create_entity{name = "item-on-ground", position = event.created_entity.position, stack = {name = "tf-field", count = 1}}
      event.created_entity.destroy()
      return
    else
      local entInfo =
      {
        entity = event.created_entity,
        fertAmount = 0,
        lastSeedPos = {x = 2, y = 0}
      }
	  local nextUpdate = event.tick + 60
	  insertField(entInfo, nextUpdate)
      return
    end
  elseif event.created_entity.name == "tf-fieldmk2Overlay" then
    local ent = game.get_surface("nauvis").create_entity
    	{
    		name = "tf-fieldmk2",
                position = event.created_entity.position,
                force = event.created_entity.force
        }
    local entInfo =
    {
      entity = ent,
      active = true,
      areaRadius = 9,
      fertAmount = 0,
      lastSeedPos = {x = -9, y = -9},
      toBeHarvested = {}
    }
	local nextUpdate = event.tick + 60
	insertFieldmk2(entInfo, nextUpdate)

    --global.treefarm.tmpData.fieldmk2Index = #global.treefarm.fieldmk2
    --showFieldmk2GUI(#global.treefarm.fieldmk2, event.playerindex)
    event.created_entity.destroy()
    return
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
	
end)



script.on_event(defines.events.on_tick, function(event)
	if global.tf.treesToGrow[event.tick] ~= nil then
		growTrees(global.tf.treesToGrow, event.tick)
		global.tf.treesToGrow[event.tick] = nil
	end
	
	if global.tf.fieldsToMaintain[event.tick] ~= nil then
		fieldMaintainer(event.tick)
		global.tf.fieldsToMaintain[event.tick] = nil
	end
	
	if global.tf.fieldmk2sToMaintain[event.tick] ~= nil then
		fieldmk2Maintainer(event.tick)
		global.tf.fieldmk2sToMaintain[event.tick] = nil
	end
end)

function v3Update()
	if global.tf.treesToGrow == nil then
		global.tf.treesToGrow = {}
		for i, entInfo in pairs(global.tf.growing) do
			local nextGrowthTick = entInfo.nextUpdate
			local seedTable = 
			{
				entity = entInfo.entity,
				state = entInfo.state,
				efficiency = entInfo.efficiency
			}
			insertSeed(seedTable, nextGrowthTick)
		end
		global.tf.growing = nil
	end
end

function v34Update()
	if global.tf.fieldList then
		global.tf.fieldList = nil
	end
end

function insertSeed(seedTable, nextGrowthTick)
	if global.tf.treesToGrow[nextGrowthTick] == nil then
		global.tf.treesToGrow[nextGrowthTick] = {}
	end
	table.insert(global.tf.treesToGrow[nextGrowthTick], seedTable)
end

function insertField(fieldTable, nextUpdate)
	if global.tf.fieldsToMaintain[nextUpdate] == nil then
		global.tf.fieldsToMaintain[nextUpdate] = {}
	end
	table.insert(global.tf.fieldsToMaintain[nextUpdate], fieldTable)
end

function insertFieldmk2(fieldTable, nextUpdate)
	if global.tf.fieldmk2sToMaintain[nextUpdate] == nil then
		global.tf.fieldmk2sToMaintain[nextUpdate] = {}
	end
	table.insert(global.tf.fieldmk2sToMaintain[nextUpdate], fieldTable)
end

function growTrees(treesToGrow, cur_tick)
	for i, seedTable in pairs(treesToGrow[cur_tick]) do
		local seedTypeName
		local newState
		local oldPlant = treesToGrow[cur_tick][i]
		if oldPlant.entity.valid then
			seedTypeName = seedTypeLookUpTable[oldPlant.entity.name]
			newState = oldPlant.state + 1
			if newState <= #global.tf.seedPrototypes[seedTypeName].states then
				local tmpPos = oldPlant.entity.position
				local newEnt = game.get_surface("nauvis").create_entity{name = global.tf.seedPrototypes[seedTypeLookUpTable[oldPlant.entity.name]].states[newState], position = tmpPos}
				oldPlant.entity.destroy()
				local deltaTime = math.ceil((math.random() * global.tf.seedPrototypes[seedTypeName].randomGrowingTime + global.tf.seedPrototypes[seedTypeName].basicGrowingTime) / oldPlant.efficiency)
				local updatedEntry =
				{
					entity = newEnt,
					state = newState,
					efficiency = oldPlant.efficiency,
				}
				local nextUpdate = cur_tick + deltaTime
				insertSeed(updatedEntry, nextUpdate)
			elseif (isInMk2Range(oldPlant.entity.position)) then
				oldPlant.entity.order_deconstruction(game.forces.player)
			end
		end
	end
end

function canPlaceField(field)
  local fPosX, fPosY = field.position.x, field.position.y
  for x = 1, 9 do
    for y = 0, 7 do
      if not game.get_surface("nauvis").can_place_entity{name="wooden-chest", position = {fPosX + x, fPosY + y}} then
        local playerEnt = game.get_surface("nauvis").find_entities_filtered{area = {{fPosX + x - 1, fPosY + y - 1},{fPosX + x + 1, fPosY + y + 1}}, name="player"}
        local trees = game.get_surface("nauvis").find_entities_filtered{area = {{fPosX + x - 1, fPosY + y - 1},{fPosX + x + 1, fPosY + y + 1}}, type="tree"}
        if not (#playerEnt > 0) and not (#trees > 0) then return false end
      end
    end
  end

  local blockingField = game.get_surface("nauvis").find_entities_filtered{area = {{x = fPosX - 9, y = fPosY - 8}, {fPosX + 8, fPosY + 8}}, name="tf-field"}
  if #blockingField > 1 then return false end
  return true
end



function defineStandardSeedPrototypes()
  global.tf.seedPrototypes.basicTree =
  {
    states =
    {
      "tf-germling",
      "tf-very-small-tree",
      "tf-small-tree",
      "tf-medium-tree",
      "tf-mature-tree"
    },
    output = {"raw-wood", 5},
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
    basicGrowingTime = 18000, 
    randomGrowingTime = 9000, 
    fertilizerBoost = 1.00
  }

  global.tf.seedPrototypes.basicCoral =
  {
    states =
    {
      "tf-coral-seed",
      "tf-small-coral",
      "tf-medium-coral",
      "tf-mature-coral"
    },
    output = {"raw-wood", 3},
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
    basicGrowingTime = 9000,
    randomGrowingTime = 9000,
    fertilizerBoost = 2.00
  }
end



function calcEfficiency(entity, fertilizerApplied)
  local seedType = seedTypeLookUpTable[entity.name]
  local currentTilename = game.get_surface("nauvis").get_tile(entity.position.x, entity.position.y).name or "other"

  local efficiency
  if global.tf.seedPrototypes[seedType].efficiency[currentTilename] == nil then
    return global.tf.seedPrototypes[seedType].efficiency.other
  else
    efficiency = global.tf.seedPrototypes[seedType].efficiency[currentTilename]
    if fertilizerApplied then
      return efficiency + global.tf.seedPrototypes[seedType].fertilizerBoost
    else
      return efficiency
    end
  end
end

function isInMk2Range(plantPos)
  for _, field in ipairs(global.tf.fieldList) do
    if (field.entity.valid) and (field.entity.name == "tf-fieldmk2") and (field.active == true) then
      local fieldPos = field.entity.position
      local areaPosMin = {x = fieldPos.x - field.areaRadius - 1, y = fieldPos.y - field.areaRadius - 1}
      local areaPosMax = {x = fieldPos.x + field.areaRadius + 1, y = fieldPos.y + field.areaRadius + 1}
      if (plantPos.x >= areaPosMin.x) and
         (plantPos.x <= areaPosMax.x) and
         (plantPos.y >= areaPosMin.y) and
         (plantPos.y <= areaPosMax.y) then
        return true
      end
    end
  end
  return false
end

function fieldMaintainer(tick)
	for _, fieldObj in pairs(global.tf.fieldsToMaintain[tick]) do
		if not fieldObj.entity.valid then
			for i, fieldEnt in pairs(global.tf.fieldList) do
				if fieldEnt == fieldObj then
					table.remove(global.tf.fieldList, i)
					break
				end
			end
		else
			local fieldSur = fieldObj.entity.surface.name
			local fieldPos = fieldObj.entity.position
			-- seedplanting --
			local seedInInv = {}
			for _, seedType in pairs(global.tf.seedPrototypes) do
				local newAmount = fieldObj.entity.get_inventory(1).get_item_count(seedType.states[1])
				if newAmount > 0 then
					seedInInv = 
					{
						name = seedType.states[1],
						amount = newAmount
					}
					break
				end
			end
		
			local seedPos = false
			if seedInInv.name ~= nil then
				local placed = false
				local lastPos = fieldObj.lastSeedPos
				for dx = lastPos.x, 8 do
					for dy = 0, 6 do
						if (game.get_surface(fieldSur).can_place_entity{name = "tf-germling", position = {fieldPos.x + dx - 0.5, fieldPos.y + dy - 0.5}}) then
							seedPos = 
							{
								x = fieldPos.x + dx - 0.5,
								y = fieldPos.y + dy - 0.5
							}
							placed = true
							fieldObj.lastSeedPos = 
							{
								x = dx,
								y = dy
							}
							break
						end
					end
					if placed == true then
						break
					end
				end
				if (placed == false) and (lastPos.x ~= 2) then
					for dx = 2, lastPos.x - 1 do
						for dy = 0, 6 do
							if (game.get_surface(fieldSur).can_place_entity{name = "tf-germling", position = {fieldPos.x + dx - 0.5, fieldPos.y + dy - 0.5}}) then
								seedPos = 
								{
									x = fieldPos.x + dx - 0.5, 
									y = fieldPos.y + dy - 0.5
								}
								placed = true
								fieldObj.lastSeedPos = 
								{
									x = dx,
									y = dy
								}
								break
							end
						end
						if placed == true then
							break
						end
					end
				end
				if seedPos ~= false then
					local seedTypeName = seedTypeLookUpTable[seedInInv.name]
					local newPlant = game.get_surface(fieldSur).create_entity{name = seedInInv.name, position = seedPos}
					local newFertilized = false
					
					if (fieldObj.fertAmount < 0.1) and (game.item_prototypes["tf-fertilizer"]) ~= nil and (fieldObj.entity.get_inventory(2).get_item_count("tf-fertilizer") > 0) then
						fieldObj.fertAmount = 1
						fieldObj.entity.get_inventory(2).remove{name = "tf-fertilizer", count = 1}
					end
					
					if fieldObj.fertAmount >= 0.1 then
						fieldObj.fertAmount = fieldObj.fertAmount - 0.1
						newFertilized = true
					end
					
					local newEfficiency = calcEfficiency(newPlant, newFertilized)
					local nextUpdate = tick + math.ceil((math.random() * global.tf.seedPrototypes[seedTypeName].randomGrowingTime + global.tf.seedPrototypes[seedTypeName].basicGrowingTime) / newEfficiency)
					local entInfo = 
					{
						entity = newPlant,
						state = 1,
						efficiency = newEfficiency
					}
					fieldObj.entity.get_inventory(1).remove{name = seedInInv.name, count = 1}
					insertSeed(entInfo, nextUpdate)
				end
			end
			
			--harvesting--
		
			local grownEntities = game.get_surface(fieldSur).find_entities_filtered{area = {fieldPos, {fieldPos.x + 9, fieldPos.y + 8}}, type = "tree"}
			for _, entity in ipairs(grownEntities) do
				for _, seedType in pairs(global.tf.seedPrototypes) do
					if entity.name == seedType.states[#seedType.states] then
						local output = 
						{
							name = seedType.output[1],
							amount = seedType.output[2]
						}
						local stackSize = game.item_prototypes[output.name].stack_size
						if (fieldObj.entity.get_inventory(3).can_insert{name = output.name, count = output.amount}) and (stackSize - fieldObj.entity.get_inventory(3).get_item_count(output.name) >= output.amount) then
							fieldObj.entity.get_inventory(3).insert{name = output.name, count = output.amount}
							entity.destroy()
						end
					end
				end
			end
			local nextUpdate = tick + 60
			insertField(fieldObj, nextUpdate)
		end
	end
end

function fieldmk2Maintainer(tick)
  -- SEEDPLANTING --
	for _, fieldObj in pairs(global.tf.fieldmk2sToMaintain[tick]) do
		if not fieldObj.entity.valid then
			for i, fieldEnt in pairs(global.tf.fieldList) do
				if fieldObj == fieldEnt then
					table.remove(global.tf.fieldList, i)
					break
				end
			end
		else
			local seedInInv = {}
			for _, seedType in pairs(global.tf.seedPrototypes) do
				local newAmount = fieldObj,entity.get_item_count(seedType.states[1])
				if newAmount > 0 then
					seedInInv = 
					{
						name = seedType.states[1],
						amount = newAmount
					}
					break
				end
			end
			local seedPos = false
			local fieldPos = fieldObj.entity.position
			local fieldSur = fieldObj.entity.surface.name
			if seedInInv.name ~= nil then
				local placed = false
				local lastPos = fieldObj.lastSeedPos
				if lastPos.x < -fieldObj.areaRadius then
					lastPos.x = -fieldObj.areaRadius
				elseif lastPos.x > fieldObj.areaRadius then
					lastPos.x = fieldObj.areaRadius
				end
				if lastPos.y < -fieldObj.areaRadius then
					lastPos.y = -fieldObj.areaRadius
				elseif lastPos.y > fieldObj.areaRadius then
					lastPos.y = fieldObj.areaRadius
				end
				for dx = lastPos.x, fieldObj.areaRadius do
					for dy = -fieldObj.areaRadius, fieldObj.areaRadius do
						if (game.get_surface(fieldSur).can_place_entity{name = "tf-germling", position = {fieldPos.x + dx - 0.5, fieldPos.y + dy - 0.5}}) then
							seedPos = {x = fieldPos.x + dx - 0.5, y = fieldPos.y + dy - 0.5}
							placed = true
							fieldObj.lastSeedPos = {x = dx, y = dy}
							break
						end
					end
					if placed == true then
						break
					end
				end
				if (placed == false) and (lastPos.x ~= -fieldObj.areaRadius) then
					for dx = -fieldObj.areaRadius, lastPos.x - 1 do
						for dy = -fieldObj.areaRadius, fieldObj.areaRadius do
							if (game.get_surface(fieldSur).can_place_entity{name = "tf-germling", position = {fieldPos.x + dx - 0.5, fieldPos.y + dy - 0.5}}) then
								seedPos = {x = fieldPos.x + dx - 0.5, y = fieldPos.y + dy - 0.5}
								placed = true
								fieldObj.lastSeedPos = {x = dx, y = dy}
								break
							end
						end
						if placed == true then
							break
						end
					end
				end
				if seedPos ~= false then
					local seedTypeName = seedTypeLookUpTable[seedInInv.name]
					local newEntity = game.get_surface("nauvis").create_entity{name = seedInInv.name, position = seedPos}
					local newFertilized = false
					if (fieldObj.fertAmount < 0.1) and (game.item_prototypes["tf-fertilizer"] ~= nil) and (fieldObj.entity.get_inventory(1).get_item_count("tf-fertilizer") > 0) then
						fieldObj.fertAmount = 1
						fieldObj.entity.get_inventory(1).remove{name = "tf-fertilizer", count = 1}
					end
					if fieldObj.fertAmount >= 0.1 then
						fieldObj.fertAmount = fieldObj.fertAmount - 0.1
						newFertilized = true
					end
					local newEfficiency = calcEfficiency(newEntity, newFertilized)
					local nextUpdate = tick + math.ceil((math.random() * global.tf.seedPrototypes[seedTypeName].randomGrowingTime + global.tf.seedPrototypes[seedTypeName].basicGrowingTime) / newEfficiency)
					local entInfo = 
					{
						entity = newEntity,
						state = 1,
						efficiency = newEfficiency
					}
					fieldObj.entity.get_inventory(1).remove{name = seedInInv.name, count = 1}
					insertSeed(entInfo, nextUpdate)
				end
			end
			-- harvesting--
			local nextUpdate = tick + 60
			insertFieldmk2(fieldObj, nextUpdate)
		end
    end
end

function showFieldmk2GUI(index, playerIndex)
	local player = game.players[playerIndex]
	if player.gui.center.fieldmk2Root == nil then
		local rootFrame = player.gui.center.add{type = "frame", name = "fieldmk2Root", caption = game.entity_prototypes["tf-fieldmk2"].localised_name, direction = "vertical"}
		local rootTable = rootFrame.add{type ="table", name = "fieldmk2Table", colspan = 4}
		rootTable.add{type = "label", name = "colLabel1", caption = {"thisFieldIs"}}
		local status = "active / not active"
		if global.tf.fieldList[index].active == true then
			status = {"active"}
		else
			status = {"notActive"}
		end
		rootTable.add{type = "label", name = "colLabel2", caption = status}
		rootTable.add{type = "button", name = "toggleActiveBut", caption = {"toggleButtonCaption"}, style = "tf_smallerButtonFont"}
		rootTable.add{type = "label", name = "colLabel4", caption = ""}
		rootTable.add{type = "label", name = "areaLabel1", caption = {"usedArea"}}
		rootTable.add{type = "label", name = "areaLabel2", caption = global.tf.fieldList[index].areaRadius}
		rootTable.add{type = "button", name = "incAreaBut", caption = "+", style = "tf_smallerButtonFont"}
		rootTable.add{type = "button", name = "decAreaBut", caption = "-", style = "tf_smallerButtonFont"}
		rootFrame.add{type = "button", name = "okButton", caption = {"okButtonCaption"}, style = "tf_smallerButtonFont"}
		if (global.tf.playersData[playerIndex].overlayStack == nil) or (#global.tf.playersData[playerIndex].overlayStack == 0) then
			createOverlay(playerIndex, global.tf.fieldList[index])
		end
	end
end



function createOverlay(playerIndex, fieldTable)
  local radius = fieldTable.areaRadius
  local startPos = {x = fieldTable.entity.position.x - radius,
                    y = fieldTable.entity.position.y - radius}

  if fieldTable.active == true then
    for i = 0, 2 * radius + 1 do
      for j = 0, 2 * radius + 1 do
        local overlay = game.get_surface("nauvis").create_entity{name = "tf-overlay-green", position ={x = startPos.x + i, y = startPos.y + j}, force = game.forces.player}
        table.insert(global.tf.playersData[playerIndex].overlayStack, overlay)
      end
    end
  else
    for i = 0, 2 * radius + 1 do
      for j = 0, 2 * radius + 1 do
        local overlay = game.get_surface("nauvis").create_entity{name = "tf-overlay-red", position ={x = startPos.x + i, y = startPos.y + j}, force = game.forces.player}
        table.insert(global.tf.playersData[playerIndex].overlayStack, overlay)
      end
    end
  end
end



function destroyOverlay(playerIndex)
  for _, overlay in ipairs(global.tf.playersData[playerIndex].overlayStack) do
    if overlay.valid then
      overlay.destroy()
    end
  end
  global.tf.playersData[playerIndex].overlayStack = {}
end



function mk2CancelDecontruction(field)
  local fieldPos = {x = field.entity.position.x, y = field.entity.position.y}
  local areaPosMin = {x = fieldPos.x - field.areaRadius - 1, y = fieldPos.y - field.areaRadius - 1}
  local areaPosMax = {x = fieldPos.x + field.areaRadius + 1, y = fieldPos.y + field.areaRadius + 1}
  local tmpEntities = game.get_surface("nauvis").find_entities_filtered{area = {areaPosMin, areaPosMax}, type = "tree"}

  if #tmpEntities > 0 then
    for i = 1, #tmpEntities do
      for _, seedType in pairs(global.tf.seedPrototypes) do
        if (tmpEntities[i].name == seedType.states[#seedType.states]) and (tmpEntities[i].to_be_deconstructed(game.forces.player) == true) then
          tmpEntities[i].cancel_deconstruction(game.forces.player)
        end
      end
    end
  end
end



function mk2MarkDeconstruction(field)
  local fieldPos = {x = field.entity.position.x, y = field.entity.position.y}
  local areaPosMin = {x = fieldPos.x - field.areaRadius - 1, y = fieldPos.y - field.areaRadius - 1}
  local areaPosMax = {x = fieldPos.x + field.areaRadius + 1, y = fieldPos.y + field.areaRadius + 1}
  local tmpEntities = game.get_surface("nauvis").find_entities_filtered{area = {areaPosMin, areaPosMax}, type = "tree"}

  if #tmpEntities > 0 then
    for i = 1, #tmpEntities do
      for _, seedType in pairs(global.tf.seedPrototypes) do
        if (tmpEntities[i].name == seedType.states[#seedType.states]) and (tmpEntities[i].to_be_deconstructed(game.forces.player) == false) then
          tmpEntities[i].order_deconstruction(game.forces.player)
        end
      end
    end
  end
end
