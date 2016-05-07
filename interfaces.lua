module(..., package.seeall)

remote.add_interface("treefarm_interface",
{
  addSeed = function(seedInfo)
    if global.tf == nil then
      return "treefarm isn't initialized yet. Save the game and reload it."
    end

    if global.tf.seedPrototypes[seedInfo.name] == nil then
      global.tf.seedPrototypes[seedInfo.name] = {}
      if seedInfo.states ~= nil then
        global.tf.seedPrototypes[seedInfo.name].states = seedInfo.states
      else
        return "growing states not defined"
      end
      if seedInfo.output ~= nil then
        global.tf.seedPrototypes[seedInfo.name].output = seedInfo.output
      else
        return "result not defined"
      end
      if seedInfo.efficiency then
        global.tf.seedPrototypes[seedInfo.name].efficiency = seedInfo.efficiency
        if global.tf.seedPrototypes[seedInfo.name].efficiency.other == 0 then
          global.tf.seedPrototypes[seedInfo.name].efficiency.other = 0.01
        end
      else
        return "efficiency not defined"
      end
      if seedInfo.basicGrowingTime ~= nil then
        global.tf.seedPrototypes[seedInfo.name].basicGrowingTime = seedInfo.basicGrowingTime
      else
        return "basicGrowingTime not defined"
      end
      if seedInfo.randomGrowingTime ~= nil then     
        global.tf.seedPrototypes[seedInfo.name].randomGrowingTime = seedInfo.randomGrowingTime
      else
        return "randomGrowingTime not defined"
      end
      if seedInfo.fertilizerBoost ~= nil then
        global.tf.seedPrototypes[seedInfo.name].fertilizerBoost = seedInfo.fertilizerBoost
      else
        return "fertilizerBoost not defined"
      end
      
      if seedTypeLookUpTable ~= nil then
        seedTypeLookUpTable = {}
      end
      populateSeedTypeLookUpTable()
    else
      return "seed type already present"
    end
  end,

  readSeed = function(seedName)
    return global.tf.seedPrototypes[seedName]
  end,

  getSeedTypesData = function()
    return global.tf.seedPrototypes
  end,


  getNumGrowing = function()
    return #global.tf.growing
  end,

  getFirstPlantTick = function()
    return global.tf.growing[1].nextUpdate
  end,

  removeAllPlants = function()
    for _, plant in ipairs(global.tf.growing) do
      if plant.entity.valid then
        plant.entity.destroy()
      end
    end

    while (#global.tf.growing > 0) do
      table.remove(global.tf.growing)
    end
  end,

  clearGUIs = function()
    for pIndex, player in ipairs(game.players) do
      if player.gui.center.fieldmk2Root ~= nil then
        player.gui.center.fieldmk2Root.destroy()
      end
      global.tf.playersData[pIndex].guiOpened = false
      destroyOverlay(pIndex)
    end
  end,

  gimmeStuff1 = function(pIndex)
    if pIndex == 0 then
      for i,_ in ipairs(game.players) do
        giveStuff(i)
      end
    elseif game.players[pIndex] == nil then return
    else
      giveStuff(pIndex)
    end
  end,

  unlockAllTech = function()
    if game.forces.player.technologies["tf-advanced-treefarming"] ~= nil then
      game.forces.player.technologies["tf-advanced-treefarming"].researched = true
    end
    if game.forces.player.technologies["tf-coal-processing"] ~= nil then
      game.forces.player.technologies["tf-coal-processing"].researched = true
    end
    if game.forces.player.technologies["tf-fertilizer"] ~= nil then
      game.forces.player.technologies["tf-fertilizer"].researched = true
    end
    if game.forces.player.technologies["tf-advanced-biotechnology"] ~= nil then
      game.forces.player.technologies["tf-advanced-biotechnology"].researched = true
    end
    if game.forces.player.technologies["tf-organic-plastic"] ~= nil then
      game.forces.player.technologies["tf-organic-plastic"].researched = true
    end
    if game.forces.player.technologies["tf-medicine"] ~= nil then
      game.forces.player.technologies["tf-medicine"].researched = true
    end
    if game.forces.player.technologies["tf-biological-warfare"] ~= nil then
      game.forces.player.technologies["tf-biological-warfare"].researched = true
    end
  end,
  
  test_setup_world = function(num_treefarms, origin_position, surface)
    
    -- if no origin is given then center on the center of the world
    origin_position = origin_position or { 0,0 }
    
    -- default to the player's surface
    surface = surface or game.player.surface
    
    -- we will place treefarms in a box centered around the origin
    -- so each side of the box is sqrt(num_treefarms) long
    local treefarms_per_side = math.ceil(math.sqrt(num_treefarms))
    
    -- each treefarm occupies a 20x20 tile box, each chunk is 32x32
    -- and we only need half of the chunks (b/c we want the radius not the diameter)
    local chunk_radius = (treefarms_per_side * 20 / 32 ) / 2;
    local coordinate = treefarms_per_side * 20 / 2;
    local x_offset = origin_position.x or origin_position[1]
    local y_offset = origin_position.y or origin_position[2]
    
    -- generate the necessary chunks
    surface.request_to_generate_chunks( origin_position, chunk_radius)

    -- remove all the entities from a 1000 unit box around the center
    for _, v in pairs(surface.find_entities ({{-coordinate + x_offset,-coordinate + y_offset}, {coordinate + x_offset,coordinate + y_offset}})) 
        do v.destroy() 
    end

    -- replace all the terrain w/ grass terrain

    for i = -coordinate + x_offset, coordinate + x_offset, 1 do 
        for j = -coordinate + y_offset,coordinate + y_offset,1 do 
            surface.set_tiles ({ { name = "grass", position = { i,j } } }) 
        end 
    end
  
  end,
  
  test_create_treefarms = function(num_treefarms, origin_position, num_seeds, treefarm_type, surface)

    -- if no origin is given then center on the center of the world
    origin_position = origin_position or { 0,0 }
    
    -- default to the player's surface
    surface = surface or game.player.surface
    
    -- default to treefarm mk2
	-- NOTE other farm types are not supported
    treefarm_type = "tf-fieldmk2" -- treefarm_type or "tf-fieldmk2"

    local field_size = 20
    local treefarms_per_side = math.ceil(math.sqrt(num_treefarms))
    local coordinate = treefarms_per_side * field_size / 2
    
    local seed_type = "tf-germling"
    local x_offset = origin_position.x or origin_position[1]
    local y_offset = origin_position.y or origin_position[2]
    local stack_size = num_seeds or game.get_item_prototype ( seed_type ).stack_size
    
    for i = -coordinate + x_offset + 10, coordinate + x_offset - 10, field_size do 
        for j = -coordinate + y_offset + 10, coordinate + y_offset - 10, field_size do 
            
            local ent = game.player.surface.create_entity({name=treefarm_type, position= {i,j}, force=game.forces.player })
            if (stack_size > 0) then
                ent.insert({name=seed_type, count=stack_size})
            end
                
            test_addFieldMk2(ent)
            
            num_treefarms = num_treefarms - 1
            if (num_treefarms == 0) then
                return
            end
            
        end 
    end
    
  end
  
  
 })


function giveStuff(index)
  local player = game.players[index]
  player.insert{name="wooden-chest", count=64}
  player.insert{name="small-electric-pole", count=32}
  player.insert{name="basic-inserter", count=64}
  player.insert{name="solar-panel", count=54}
  player.insert{name="basic-transport-belt", count=50}
  player.insert{name="basic-transport-belt-to-ground", count=32}
  player.insert{name="basic-splitter", count=20}
  player.insert{name="tf-field", count=10}
  player.insert{name="raw-wood", count=100}
  player.insert{name="tf-germling", count=100}
  player.insert{name="tf-coral-seed", count=100}
  player.insert{name="tf-fieldmk2", count=8}
  player.insert{name="logistic-robot", count=32}
  player.insert{name="construction-robot", count=32}
  player.insert{name="roboport", count=8}
  player.insert{name="logistic-chest-requester", count=8}
  player.insert{name="logistic-chest-passive-provider", count=8}
  player.insert{name="logistic-chest-active-provider", count=8}
  player.insert{name="logistic-chest-storage", count=8}
  player.insert{name="smart-inserter", count=32}
  player.insert{name="assembling-machine-2", count=8}
end