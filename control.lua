require "defines"
require "interfaces"

local constIsInDebug = true
local constFertilizerName = "tf-fertilizer"
local constRobotFarmOverlayName = "tf-fieldmk2Overlay"
local constRobotFarmName = "tf-fieldmk2"
local constFarmName = "tf-field"
local constMaxFarmRadius = 9
local constFarmTickRate = 60

-- maps the names of plant entities to the plant group they are from
local plantNameToPlantGroup
local immaturePlantNames

function debug_print(message)

	if game ~= nil and constIsInDebug then
		for i, p in ipairs(game.players) do
			p.print(message)
		end
	end
	
end

--
-- data migration functions
--
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
	global.tf.fieldsToMaintain = {}
	global.tf.fieldmk2sToMaintain = {}
	defineStandardSeedPrototypes()
	local fieldReplace = {need = false}
	for i, fieldEnt in ipairs(global.tf.fieldList) do
		if fieldEnt.nextUpdate then
			local nextUpdate = fieldEnt.nextUpdate
			if fieldEnt.entity.name == "tf-field" then
				insertField(fieldEnt, nextUpdate)
			elseif fieldEnt.entity.name == "tf-fieldmk2" then
				insertFieldmk2(fieldEnt, nextUpdate)
			end
		else
			fieldReplace.need = true
			fieldEnt.listIndex = i
			table.insert(fieldReplace, fieldEnt)
		end
	end
	if fieldReplace.need then 
		local message = "Some fields could not be updated and need to be mined and replaced"
		for i, player in ipairs(game.players) do
			player.print(message)
		end
		for i, fieldEnt in ipairs(fieldReplace) do
			if not i == need then
				table.remove(global.tf.fieldList, fieldEnt.listIndex)
			end
		end
	end
end

function data_migration_to_v4()

	-- convert field data
	global.tf.fieldsToMaintain = nil
	global.tf.fieldmk2sToMaintain = nil
	global.tf.farms = {}
	
	-- set to empty list in case there are no fields planted
	global.tf.fieldList = global.tf.fieldList or {}
	for idx, field in ipairs(global.tf.fieldList) do
		if field.entity.valid then
			local farmInfo = create_farm_info_for(field.entity)

			-- mk1 farms are always active
			if farmInfo.entity.name == constRobotFarmName then
				farmInfo.isActive = field.active
			end
			
			
			farmInfo.fieldRadius = field.areaRadius
			
			-- previous versions as fractions of 1.0, but from v4 on, fertilizer is counted in integers
			farmInfo.fertilizerAmount = field.fertAmount * 10
			table.insert(global.tf.farms, farmInfo)
		end
	end
	global.tf.fieldList = nil
	
	-- convert tree data
	global.tf.trees = {}
	
	-- set to empty list in case there are no trees growing
	global.tf.treesToGrow = global.tf.treesToGrow or {}
	for tick, list in pairs(global.tf.treesToGrow) do
		-- for each record, the associated farm will be found when the tree is ready to be harvested
		global.tf.trees[tick] = list
	end
	global.tf.treesToGrow = nil
	
	-- convert seed prototypes
	global.tf.isFertilizerAvailable = game.item_prototypes[constFertilizerName] ~= nil
	global.tf.seedPrototypes = global.tf.seedPrototypes or {}
	for k,v in pairs(global.tf.seedPrototypes) do
		global.tf.plantGroups[k] = v
	end
	
	populate_seed_name_to_plant_group()
	global.tf.seedPrototypes = nil
	
	-- convert player data and clear all open guis
	global.tf.playersData = global.tf.playersData or {}
	global.tf.playerData = global.tf.playersData
	for idx, info in ipairs(global.tf.playersData) do
		clear_player_data(idx)
		
		if info.overlayStack ~= nil then
			for i, overlay in pairs(info.overlayStack) do
				if overlay.valid then
					overlay.destroy()
				end
			end
		end
	end
	
	global.tf.playersData = nil

end

--
-- managing plants and plant groups
--

function populate_seed_name_to_plant_group()
	plantNameToPlantGroup = { }
	immaturePlantNames = {}
	
	for name, plantGroup in pairs(global.tf.plantGroups) do
		--debug_print("creating lookup for: " .. name)
		for idx, stateName in ipairs(plantGroup.states) do
			plantNameToPlantGroup[stateName] = plantGroup
			
			--debug_print("known plant name: " .. stateName)
			if idx ~= #plantGroup.states then
				immaturePlantNames[stateName] = true
			end
		end
	end
	
end

function dump_element(key, value, indent)

	indent = indent or ".    "

	if value == nil then
		debug_print(indent .. key .. " = nil")
	elseif type(value) == "table" then
		debug_print(indent .. key .. " = {")
		
		for k,v in pairs(value) do
			dump_element(k,v, indent .. "    ")
		end
		
		debug_print(indent .. "}")
	else
		debug_print(indent .. key .. " = " .. value)
	end
end



function register_plant_groups(plantGroups)
	-- plantGroups is a table w/ the following structure
	-- {
	--    plantGroupName = table with the following structure
	--    {
	--        states = list of tree names from youngest plant to oldest plant
	--        efficiency = list of mappings from a terrain type to an growth efficiency (double) on that terrain type
	--        minGrowingTime = int - min number of ticks between growth stages
	--        randomGrowingTime = int - max number of additional ticks between growth stages. 
	--        fertilizerBoost = trees planted w/ fertilizer grow at [terrain efficiency] + fertilizerBoost
	--    }
	-- }

	global.tf = global.tf or {}
	global.tf.plantGroups = global.tf.plantGroups or {}
	
	for name, group in pairs(plantGroups) do
		global.tf.plantGroups[name] = group
		
		if global.tf.plantGroups[name].efficiency.other == nil or global.tf.plantGroups[name].efficiency.other <= 0 then
			global.tf.plantGroups[name].efficiency.other = 0.01
		end
	end

	populate_seed_name_to_plant_group()
end

--
-- managing players
--

function get_player_info(player_index)
	if global.tf.playerData[player_index] == nil then
		clear_player_data(player_index)
	end
	
	return global.tf.playerData[player_index]
end

function clear_player_data(player_index)
	global.tf.playerData[player_index] = { farmInfoConfiguring = nil, overlayEntities = {} }
end

function initialize()
	
	-- this function is designed to be safe to call even when
	-- the global variables are already initialized
	global.tf = global.tf or {}
	global.tf.trees = global.tf.trees or {}
	global.tf.farms = global.tf.farms or {}
	global.tf.plantGroups = global.tf.plantGroups or {}
	global.tf.counter = global.tf.counter or 0
	global.tf.playerData = global.tf.playerData or {}
	
	-- we want to clear this on load in case changing a mod has changed a stack size
	global.tf.knownStackSizes = {}
	
	if game ~= nil then
		global.tf.isFertilizerAvailable = game.item_prototypes[constFertilizerName] ~= nil
	end
	
	-- register growth states for trees and coral
	-- which are the built-in treefarm plants
	register_plant_groups({
		basicTree = {
			name = "basicTree",
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
			basicGrowingTime = 18000, 
			randomGrowingTime = 9000, 
			fertilizerBoost = 1.00
		},
		basicCoral =
		{
			name = "basicCoral",
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
			basicGrowingTime = 9000,
			randomGrowingTime = 9000,
			fertilizerBoost = 2.00
		}
	})
	
end

function when_saved_game_loaded()

	-- the load event is fired before the loaded_mods_changed event
	-- so for saved games before v4, we need to make sure the plantGroups table exists
	
	initialize()

	populate_seed_name_to_plant_group()
end

function when_loaded_mods_changed(data)

	-- remove plantGroups that were part of another mod
	-- TODO does this need to go here
	-- TODO make sure this works
	for seedTypeName, seedPrototype in pairs (global.tf.plantGroups) do
		if game.item_prototypes[seedPrototype.states[1]] == nil then
			global.tf.plantGroups[seedTypeName] = nil
		end
	end
	
	if data.mod_changes == nil or data.mod_changes["Treefarm-Lite"] == nil then
		return
	end
	
	-- initialize has already been called - either by the saved_game_loaded or by init
	if data.mod_changes["Treefarm-Lite"].old_version == nil then
		return
	end
	
	local previousVersion = tonumber(string.sub(data.mod_changes["Treefarm-Lite"].old_version, 3, 5))

	-- NOTE: these migrations are meant to be cumulative. so to upgrade from v3 to v4, 
	-- the v3 update must run, then the v34 update, then the 4.0 update
	if previousVersion < 3 then
		v3Update()
	end
	
	if previousVersion < 3.5 then
		v34Update() 
	end
	
	if previousVersion == 3.4 then
		local message = "All treefarms are broken and need to be mined and replaced!"
		for i, player in ipairs(game.players) do
			player.print(message)
		end
	end
	
	if previousVersion < 4.0 then
		data_migration_to_v4()
	end
end

--
-- creating and managing farms
--

function event_built_entity(event)

	if event.created_entity.name == constFarmName then
	
		local tmpInfo = create_farm_info_for(event.created_entity)
		if can_place_mk1_farm(tmpInfo) then
			on_farm_created(event.created_entity)
		else
			local drop_item_on_ground = true -- robots will drop the item on the group, b/c they can't do anything else
			
			-- we won't have a player if this farm was built via robots by blueprint 
			if event.name == defines.events.on_built_entity then
				local player = game.players[event.player_index]
				
				-- add the item back to the player's inventory
				local num_inserted = player.insert({name = constFarmName, count = 1})
				if num_inserted >= 1 then
					-- VERY unlikey to happen, but handling it is free
					drop_item_on_ground = false
				end
				player.print({"msg_buildingFail"})
			end
			
			if drop_item_on_ground then
				event.created_entity.surface.spill_item_stack(event.created_entity.position, { name=constFarmName, count=1 });
				
				-- tell everyone on the same force that the building failed
				for _, plyr in pairs(event.created_entity.force.players) do
					plyr.print({"robot_buildingFail", event.created_entity.position.x, event.created_entity.position.y })
				end
				
			end
			
			event.created_entity.destroy()
		end
		
	elseif event.created_entity.name == constRobotFarmOverlayName then
		
		-- create a mk2 field to replace the overlay
		local farmEntity = event.created_entity.surface.create_entity({
			name = constRobotFarmName, 
			position = event.created_entity.position, 
			force = event.created_entity.force
		})
		local farmInfo = on_farm_created(farmEntity)
		
		-- destroy the overlay
		event.created_entity.destroy()
		
		if event.name == "on_built_entity" then
			-- show the mk2 configuration GUI
			construct_farm_configuration_gui(event.player_index, farmInfo)
		end
	elseif plantNameToPlantGroup[event.created_entity.name] ~= nil then
		plant_tree(event.created_entity, plantNameToPlantGroup[event.created_entity.name])
	end

end

function create_farm_info_for(farmEntity)
	local position = farmEntity.position
	
	local farmInfo = {
		entity = farmEntity,
		isActive = true,
		fertilizerAmount = 0,
		fieldRadius = constMaxFarmRadius,
		private_current_planting_pos = farmEntity.position
	}
	
	if farmEntity.name == constFarmName then
		farmInfo.get_farm_boundaries = mk1_get_farm_boundaries
		farmInfo.next_planting_position = mk1_next_planting_position
		farmInfo.harvest_tree = mk1_harvest_tree
		farmInfo.unharvest_tree = mk1_unharvest_tree
	else
		farmInfo.get_farm_boundaries = mk2_get_farm_boundaries
		farmInfo.next_planting_position = mk2_next_planting_position
		farmInfo.harvest_tree = mk2_harvest_tree
		farmInfo.unharvest_tree = mk2_unharvest_tree
	end
	
	farmInfo.private_current_planting_pos = farmInfo.get_farm_boundaries(farmInfo).upperLeft
	farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1
	
	return farmInfo
end

function on_farm_created(farmEntity)
	
	local farmInfo = create_farm_info_for(farmEntity)
	
	table.insert(global.tf.farms, farmInfo)
	
	harvest_trees_within_farm_area(farmInfo)
	
	return farmInfo
end

function mk1_get_farm_boundaries(farmInfoSelf)
	
	return {
		upperLeft = {
			x = farmInfoSelf.entity.position.x + 1,
			y = farmInfoSelf.entity.position.y
		},
		lowerRight = {
			x = farmInfoSelf.entity.position.x + 9,
			y = farmInfoSelf.entity.position.y + 7
		}
	}
end

function mk2_get_farm_boundaries(farmInfoSelf)

	return {
		upperLeft = {
			x = farmInfoSelf.entity.position.x - farmInfoSelf.fieldRadius - 1 ,
			y = farmInfoSelf.entity.position.y - farmInfoSelf.fieldRadius - 1
		},
		lowerRight = {
			x = farmInfoSelf.entity.position.x + farmInfoSelf.fieldRadius,
			y = farmInfoSelf.entity.position.y + farmInfoSelf.fieldRadius
		}
	}

end

function mk1_next_planting_position(farmInfoSelf)

	local boundary = farmInfoSelf.get_farm_boundaries(farmInfoSelf)
	
	if farmInfoSelf.private_current_planting_pos.x < boundary.upperLeft.x + 1 then
		farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x + 1
	end
	
	-- move the plant position 1 forward
	farmInfoSelf.private_current_planting_pos.y = farmInfoSelf.private_current_planting_pos.y + 1
	if farmInfoSelf.private_current_planting_pos.y > boundary.lowerRight.y then
		farmInfoSelf.private_current_planting_pos.y = boundary.upperLeft.y
		
		farmInfoSelf.private_current_planting_pos.x = farmInfoSelf.private_current_planting_pos.x + 1
		if farmInfoSelf.private_current_planting_pos.x > (boundary.lowerRight.x - 1) then
			farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x + 1
		end
	end
	
	return farmInfoSelf.private_current_planting_pos
	
end

function mk2_next_planting_position(farmInfoSelf)
	local boundary = farmInfoSelf.get_farm_boundaries(farmInfoSelf)
	
	-- move the plant position 1 forward
	farmInfoSelf.private_current_planting_pos.y = farmInfoSelf.private_current_planting_pos.y + 1
	if farmInfoSelf.private_current_planting_pos.y > boundary.lowerRight.y then
		farmInfoSelf.private_current_planting_pos.y = boundary.upperLeft.y
		
		farmInfoSelf.private_current_planting_pos.x = farmInfoSelf.private_current_planting_pos.x + 1
		if farmInfoSelf.private_current_planting_pos.x > boundary.lowerRight.x then
			farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x
		end
	end
	
	return farmInfoSelf.private_current_planting_pos
end

function mk1_harvest_tree(farmInfoSelf, treeEntity)

	local minable = treeEntity.prototype.mineable_properties
	if minable == nil or not minable.minable then
		return false -- can't harvest something that isn't minable
	end
	
	local inventory = farmInfoSelf.entity.get_output_inventory()
	if inventory ~= nil then
		-- is there space for all the mining products in inventory?
		local can_harvest = true
		local resultItemStacks = {}
		
		for idx, v in ipairs(minable.products) do
			local item_count = 0
			if v.amount ~= nil then
				item_count = v.amount
			elseif math.random() < v.probability then
				item_count = math.random(v.amount_min, v.amount_max)
			end
		
			local stack_size = game.item_prototypes[v.name].stack_size
			
			-- have to check that the total will be less than a single stack b/c can_insert() 
			-- will return true if only some of the items can be added to inventory
			if inventory.get_item_count(v.name) + item_count > stack_size then
				can_harvest = false
				break;
			end
			
			table.insert(resultItemStacks, { name = v.name, count = item_count })
		end
	
		if can_harvest and #inventory >= #resultItemStacks then
			for idx, simpleItemStack in ipairs(resultItemStacks) do
				inventory.insert(simpleItemStack)
			end
			
			treeEntity.destroy()
			return true
		end
	end
	
	return false
end

function mk2_harvest_tree(farmInfoSelf, treeEntity)
	treeEntity.order_deconstruction(farmInfoSelf.entity.force)
	return true
end

function mk1_unharvest_tree(farmInfoSelf, treeEntity)
	-- noop. can't unharvest trees in a mk1 farm
	return true
end

function mk2_unharvest_tree(farmInfoSelf, treeEntity)
	treeEntity.cancel_deconstruction(farmInfoSelf.entity.force)
	return true
end

function harvest_trees_within_farm_area(farmInfo)
	-- If we can't stuff into the output, there isn't any point checking each tree
	for name,number in pairs(farmInfo.entity.get_output_inventory().get_contents()) do
		local stack_size = global.tf.knownStackSizes[name]
		if (nil == stack_size) then
			stack_size = game.item_prototypes[name].stack_size
			global.tf.knownStackSizes[name] = stack_size
		end
		
		-- TODO: don't hardcode this
		if (number > stack_size - 10) then
			return
		end
	end
	
	-- harvest any mature trees within the field's boundaries
	local boundary = farmInfo.get_farm_boundaries(farmInfo)
	
	for _, treeEntity in pairs(farmInfo.entity.surface.find_entities_filtered( {area = { boundary.upperLeft, boundary.lowerRight }, type = "tree"} )) do
		if immaturePlantNames[treeEntity.name] == nil then
			farmInfo.harvest_tree(farmInfo, treeEntity)
		end
	end

end

function unharvest_trees_within_farm_area(farmInfo)
	-- undoes the effects of the harvest function
	-- so this function does nothing for the mk1 farm
	-- and unmarks trees for deconstruction for the mk2 farm
	
	if farmInfo.entity.name == constFarmName then
		return
	end
	
	local boundary = farmInfo.get_farm_boundaries(farmInfo)

	for _, treeEntity in pairs(farmInfo.entity.surface.find_entities_filtered({area = {boundary.upperLeft, boundary.lowerRight}, type = "tree"})) do
		for _, seedType in pairs(global.tf.plantGroups) do
			if treeEntity.name == seedType.states[#seedType.states] then
				farmInfo.unharvest_tree(farmInfo, treeEntity)
			end
		end
	end
end

function can_place_mk1_farm(farmInfo)
	
	local surface = farmInfo.entity.surface
	local boundary = farmInfo.get_farm_boundaries(farmInfo)
	for k, ent in ipairs( surface.find_entities ({ boundary.upperLeft, boundary.lowerRight })  ) do
		-- only players and trees are allowed to occupy the same space as a mk1 field
		if ent.name ~= "player" 
			and ent.type ~= "tree" 
			and ent.type ~= "decorative"
			and ent.type ~= "smoke"
			and ent.type ~= "explosion"
			and ent.type ~= "corpse"
			and ent.type ~= "particle"
			and ent.type ~= "leaf-particle"
			and ent.type ~= "resource"
			then
			return false
		end
	end
	
	-- check for water collisions
	for i = boundary.upperLeft.x, boundary.lowerRight.x, 1 do
		for j = boundary.upperLeft.y, boundary.lowerRight.y, 1 do
			if surface.get_tile(i,j).collides_with("water-tile") then
				return false
			end
		end
	end
	
	return true
	
--[[
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
]]
end

--
-- mk2 farm GUI management
--

function event_handle_configuration_gui_click(event)

	local playerInfo = get_player_info(event.player_index)
	if playerInfo.farmInfoConfiguring == nil then
		-- not configuring anything so there is nothing to do
		return
	end
	
	if not playerInfo.farmInfoConfiguring.entity.valid then
		-- the treefarm was somehow destroyed in between starting the configuration and this event
		clear_farm_configuration_gui(event.player_index)
		return
	end
	
	local farmInfo = playerInfo.farmInfoConfiguring
	local player = game.players[event.player_index]

	if event.element.name == "okButton" then
	
		clear_farm_configuration_gui(event.player_index)
	
	elseif event.element.name == "toggleActiveBut" then
		if farmInfo.isActive then
			farmInfo.isActive = false
			
			unharvest_trees_within_farm_area(farmInfo)
			player.gui.center.treefarmGui.treefarmGuiTable.colLabel2.caption = {"notActive"}
		else
			farmInfo.isActive = true
			
			harvest_trees_within_farm_area(farmInfo)
			player.gui.center.treefarmGui.treefarmGuiTable.colLabel2.caption = {"active"}
		end
		
		clear_farm_overlay(playerInfo)
		create_farm_overlay(playerInfo, farmInfo)
	elseif event.element.name == "incAreaBut" then
		if farmInfo.fieldRadius < constMaxFarmRadius then
			farmInfo.fieldRadius = farmInfo.fieldRadius + 1
			
			-- reset the planting position to the first position in the new radius
			farmInfo.private_current_planting_pos = farmInfo.get_farm_boundaries(farmInfo).upperLeft
			farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1
			
			clear_farm_overlay(playerInfo)
			create_farm_overlay(playerInfo, farmInfo)
		end
		
		player.gui.center.treefarmGui.treefarmGuiTable.areaLabel2.caption = farmInfo.fieldRadius
	elseif event.element.name == "decAreaBut" then
		if farmInfo.fieldRadius > 1 then
			farmInfo.fieldRadius = farmInfo.fieldRadius - 1
			
			-- reset the planting position to the first position in the new radius
			farmInfo.private_current_planting_pos = farmInfo.get_farm_boundaries(farmInfo).upperLeft
			farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1
			
			clear_farm_overlay(playerInfo)
			create_farm_overlay(playerInfo, farmInfo)
		end
		
		player.gui.center.treefarmGui.treefarmGuiTable.areaLabel2.caption = farmInfo.fieldRadius
	end
end

function construct_farm_configuration_gui(playerIndex, farmInfo)
	local player = game.players[playerIndex]
	local playerInfo = get_player_info(playerIndex)
	
	playerInfo.farmInfoConfiguring = farmInfo
	
	if player.gui.center.treefarmGui == nil then
		local rootFrame = player.gui.center.add {
			type = "frame", 
			name = "treefarmGui", 
			caption = game.entity_prototypes[constRobotFarmName].localised_name, 
			direction = "vertical"
		}
		
		local rootTable = rootFrame.add{
			type ="table", 
			name = "treefarmGuiTable", 
			colspan = 4
		}
		rootTable.add{type = "label", name = "colLabel1", caption = {"thisFieldIs"}}
		
		local status = "active / not active"
		if farmInfo.isActive then
			status = {"active"}
		else
			status = {"notActive"}
		end
		
		rootTable.add{type = "label", name = "colLabel2", caption = status}
		rootTable.add{type = "button", name = "toggleActiveBut", caption = {"toggleButtonCaption"}, style = "tf_smallerButtonFont"}
		rootTable.add{type = "label", name = "colLabel4", caption = ""}
		rootTable.add{type = "label", name = "areaLabel1", caption = {"usedArea"}}
		rootTable.add{type = "label", name = "areaLabel2", caption = farmInfo.fieldRadius}
		rootTable.add{type = "button", name = "incAreaBut", caption = "+", style = "tf_smallerButtonFont"}
		rootTable.add{type = "button", name = "decAreaBut", caption = "-", style = "tf_smallerButtonFont"}
		rootFrame.add{type = "button", name = "okButton", caption = {"okButtonCaption"}, style = "tf_smallerButtonFont"}
		
		clear_farm_overlay(playerInfo)
		create_farm_overlay(playerInfo, farmInfo)
	end
end

function clear_farm_configuration_gui(playerIndex)
	local player = game.players[playerIndex]
	local playerInfo = get_player_info(playerIndex)
	
	if player.gui.center.treefarmGui ~= nil then
		player.gui.center.treefarmGui.destroy()
	end
	
	playerInfo.farmInfoConfiguring = nil
	clear_farm_overlay(playerInfo)
end

function create_farm_overlay(playerInfo, farmInfo)

	local boundary = farmInfo.get_farm_boundaries(farmInfo)
	local overlayName = nil
	if farmInfo.isActive then overlayName = "tf-overlay-green" else overlayName = "tf-overlay-red" end
	
	if playerInfo.overlayEntities == nil then
		playerInfo.overlayEntities = {}
	end
	
	for i = boundary.upperLeft.x+1, boundary.lowerRight.x+1, 1 do
		for j = boundary.upperLeft.y+1, boundary.lowerRight.y+1, 1 do
			local overlay = farmInfo.entity.surface.create_entity({
				name = overlayName, 
				position ={i,j}, 
				force = farmInfo.entity.force
			})
			table.insert(playerInfo.overlayEntities, overlay)
		end
	end
end

function clear_farm_overlay(playerInfo)
	if playerInfo.overlayEntities ~= nil then
		for _, v in pairs(playerInfo.overlayEntities) do
			v.destroy()
		end
		
		playerInfo.overlayEntities = nil
	end
end

--
-- farm maintainence
--

function tick_farms(group_num)
	-- don't tick of there are no farms
	if global.tf.farms == nil or #global.tf.farms == 0 then
		return 0
	end

	-- constFarmTickRate governs how frequently each farm is updated, by splitting
	-- the farms into constFarmTickRate groups and updating all the farms in each
	-- group every time it is that group's turn. A tick rate of 30 means that
	-- each farm will update twice a second; a tick rate of 60 means each farm will
	-- update once per second, and a tick rate of 120 means each farm will update
	-- every 2 seconds
	
	local fieldsPerGroup = math.ceil(#global.tf.farms / constFarmTickRate)
	
	local start_idx = (group_num - 1) * fieldsPerGroup + 1
	local end_idx = math.min(start_idx + fieldsPerGroup - 1, #global.tf.farms)
	
	-- when there are more groups than farms, we need to skip groups that don't have any farms
	if #global.tf.farms < start_idx then
		return 0
	end
	
	local num_farms_ticked = 0
	for i = start_idx, end_idx do
		num_farms_ticked = num_farms_ticked + 1
		
		local farmInfo = global.tf.farms[i]
		if farmInfo == nil or not farmInfo.entity.valid then
		
			--debug_print("farm did not have a valid entity")
			table.remove(global.tf.farms, i)
			i = i - 1
			
		elseif farmInfo ~= nil and farmInfo.isActive then
			local seed = get_seed_from_farm(farmInfo)
			
			
			if seed ~= nil then
				
				local plantPos = farmInfo.next_planting_position(farmInfo)
				local surface = farmInfo.entity.surface
				
				if surface.can_place_entity({name = seed.name, position = plantPos}) then

					local treeEntity = surface.create_entity({
						name = seed.name, 
						position = plantPos, 
						force = farmInfo.entity.force
					})
					
					plant_tree(treeEntity, seed.plantGroup, farmInfo)
					consume_seed_from_farm(farmInfo, seed.name)
				end
			end
			
			if farmInfo.entity.name == constFarmName then
				harvest_trees_within_farm_area(farmInfo)
			end
		
		end
	end

	return num_farms_ticked
end

function get_seed_from_farm(farmInfo)
	for groupType, group in pairs(global.tf.plantGroups) do
		local invAmount = farmInfo.entity.get_inventory(1).get_item_count(group.states[1])
		if invAmount > 0 then
			return {name = group.states[1], plantGroup = group}
		end
	end
end

function consume_seed_from_farm(farmInfo, seedName)
	farmInfo.entity.get_inventory(1).remove({name = seedName, count = 1})
end

function plant_tree(treeEntity, plantGroup, treeFarmInfo)
	local efficiency = calc_efficiency(treeEntity, plantGroup, treeFarmInfo)
	local treeData =
	{
		entity = treeEntity,
		state = 1,
		efficiency = efficiency,
		farmInfo = treeFarmInfo
	}

	local nextTick = game.tick + math.ceil((math.random() * plantGroup.randomGrowingTime + plantGroup.basicGrowingTime) / treeData.efficiency)
	place_tree_into_list(treeData, nextTick)
end

function calc_efficiency(treeEntity, plantGroup, farmInfo)

	local position = treeEntity.position
	local tileName = treeEntity.surface.get_tile(position.x, position.y).name
	local efficiency = plantGroup.efficiency[tileName] or plantGroup.efficiency.other
	
	if farmInfo == nil then
		return efficiency
	end
	
	
	-- if the field has no available fertilizer and the fertilizer prototype is defined
	-- then try to get some fertilizer from inventory
	if farmInfo.fertilizerAmount <= 0 and global.tf.isFertilizerAvailable then
		local inv = nil
		if farmInfo.entity.name == constFarmName then
			inv = farmInfo.entity.get_inventory(2)
		else
			inv = farmInfo.entity.get_inventory(1)
		end
	
		-- consume fertilizer from the farm
		local invAmount = inv.get_item_count(constFertilizerName)
		if invAmount > 0 and inv.remove({ name = constFertilizerName, count = 1 }) then
			farmInfo.fertilizerAmount = 10
		end
		
	end

	if farmInfo.fertilizerAmount > 0 then
		efficiency = efficiency + plantGroup.fertilizerBoost
		farmInfo.fertilizerAmount = farmInfo.fertilizerAmount - 1
	end

	return efficiency
end


--
-- plant maintainence - adding to the maintainence list and growing them as needed
--

function tick_trees(tick)
	if global.tf.trees[tick] == nil then
		return
	end

	for k, treeInfo in pairs(global.tf.trees[tick]) do
		if treeInfo.entity.valid then
			local plantGroup = plantNameToPlantGroup[treeInfo.entity.name]
			
			-- NOTE the plantGroup ~= nil check handles cases where the plant is from another mod, but that
			-- mod was disabled and the game was loaded from a save that had the mod enabled
			if plantGroup ~= nil then
				-- the math.min() handles cases where a plant mod decides to change the number of states a plant has
				local newState = math.min(treeInfo.state + 1, #plantGroup.states)
				
				local newTree = treeInfo.entity.surface.create_entity({
					name = plantGroup.states[newState], 
					position = treeInfo.entity.position,
					force = treeInfo.entity.force
				})
				treeInfo.entity.destroy()
				treeInfo.entity = newTree
				treeInfo.state = newState
				
				if newState < #plantGroup.states then
					local nextTick = tick + math.ceil((math.random() * plantGroup.randomGrowingTime + plantGroup.basicGrowingTime) / treeInfo.efficiency)
					place_tree_into_list(treeInfo, nextTick)
				else
					on_tree_is_ready_to_harvest(treeInfo)
				end
			end
		end
	end

	global.tf.trees[tick] = nil

end

function on_tree_is_ready_to_harvest(treeInfo)

	local farmInfo = treeInfo.farmInfo
	if farmInfo == nil then
		-- the tree was planted manually, so we have to look for a farm
		-- we can do this the fast way by looking for any farm in the max radius a farm can have
		-- or we can do this the slow (and accurate) way by looking through every farm in the game
		-- and checking whether the tree is inside the farm's boundaries
		
		-- looks through all of the known farms for one that is in range of the tree
		local treePos = treeInfo.entity.position
		for k, fi in pairs(global.tf.farms) do
			if fi.entity.valid then
				local boundary = fi.get_farm_boundaries(fi)
				
				if treePos.x >= boundary.upperLeft.x and treePos.x <= boundary.lowerRight.x and treePos.y >= boundary.upperLeft.y and treePos.y <= boundary.lowerRight.y then
					farmInfo = fi
					break
				end
			end
		end
	end
	
	if farmInfo ~= nil and farmInfo.entity ~= nil and farmInfo.entity.valid then
		farmInfo.harvest_tree(farmInfo, treeInfo.entity)
	end
end


function place_tree_into_list(treeInfo, tick)
	if global.tf.trees[tick] == nil then
		global.tf.trees[tick] = {}
	end
	
	table.insert(global.tf.trees[tick], treeInfo)
end



--
-- event registrations
--

script.on_init(function()
	initialize()
	
	for pIndex, _ in ipairs(game.players) do
		clear_player_data(pIndex)
	end

end)
script.on_load(when_saved_game_loaded)
script.on_configuration_changed(when_loaded_mods_changed)

script.on_event(defines.events.on_player_created, function(event)
	clear_player_data(event.player_index)
end)

script.on_event(defines.events.on_tick, function(event) 
	
	--local total_trees = 0
	--if global.tf.trees[event.tick] ~= nil then 
	--	total_trees = #global.tf.trees[event.tick] 
	--end
	
	tick_trees(event.tick)
	
	if global.tf.counter == 0 then
		global.tf.counter = constFarmTickRate
	end
	
	local num_fields = tick_farms(global.tf.counter)
	global.tf.counter = global.tf.counter - 1
	
	--debug_print(".                                                                           tick: " .. event.tick .. " fields: " .. num_fields .. " trees: " .. total_trees)
end)

script.on_event(defines.events.on_built_entity, event_built_entity)
script.on_event(defines.events.on_robot_built_entity, event_built_entity)
script.on_event(defines.events.on_gui_click, event_handle_configuration_gui_click)

script.on_event(defines.events.on_put_item, function(event)
	-- on_put_item is called before the item is built (before on_built_item)
	-- so we are using this event to open the configuration gui when
	-- a player clicks on a built treefarm mk2 w/ the treefarm mk2 item in their hand
	local player = game.players[event.player_index]
	
	if player ~= nil and player.selected ~= nil and player.selected.name == constRobotFarmName then
	
		for farmIndex, farmInfo in ipairs(global.tf.farms) do
			if farmInfo.entity.valid and player.selected == farmInfo.entity then
				construct_farm_configuration_gui(event.player_index, farmInfo)
				return
			end
		end
	
	end
end)
