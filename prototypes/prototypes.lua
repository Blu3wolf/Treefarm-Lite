data:extend
({
  -- Grouping
  {
    type = "item-group",
    name = "treefarm",
    order = "e",
    inventory_order = "e",
    icon = "__Simply Treefarms__/graphics/icons/treefarm.png"
  },

  {
    type = "item-subgroup",
    name = "tf-seeds",
    group = "treefarm",
    order = "a",
  },
  {
    type = "item-subgroup",
    name = "tf-buildings",
    group = "treefarm",
    order = "b",
  },
  {
    type = "item-subgroup",
    name = "tf-raw-materials",
    group = "treefarm",
    order = "c",
  },
  {
    type = "item-subgroup",
    name = "tf-intermediate",
    group = "treefarm",
    order = "d",
  },
  {
    type = "item-subgroup",
    name = "tf-liquids",
    group = "treefarm",
    order = "e",
  },
  {
    type = "item-subgroup",
    name = "tf-tools",
    group = "treefarm",
    order = "f",
  },
  {
    type = "item-subgroup",
    name = "tf-war",
    group = "treefarm",
    order = "g",
  },

  {
    type = "item",
    name = "tree-farm-field",
    icon = "__Simply Treefarms__/graphics/icons/field.png",
    flags = {"goes-to-quickbar"},
    subgroup = "tf-buildings",
    order = "b[fieldmk2]",
    place_result = "tree-farm-field-overlay",
    stack_size = 50
  },

  {
    type = "recipe",
    name = "tree-farm-field",
    ingredients = {{"advanced-circuit",20},{"red-wire",20},{"steel-plate",20}},
    result = "tree-farm-field",
    result_count = 1,
    enabled = "false"
  },

  {
    type = "container",
    name = "tree-farm-field-overlay",
    max_health = 100,
    icon = "__Simply Treefarms__/graphics/icons/field.png",
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 1,result = "tree-farm-field"},
    collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
    selection_box = {{-1, -1}, {1, 1}},
    inventory_size = 1,
    picture =
    {
      filename = "__Simply Treefarms__/graphics/entities/field/field overlay.png",
      priority = "extra-high",
      width = 640,
      height = 640,
      shift = {0.0, 0.0}
    }
  },

  {
    type = "logistic-container",
    name = "tree-farm-field",
    logistic_mode = "requester",
    order = "c[fieldmk2]",
    max_health = 100,
    icon = "__Simply Treefarms__/graphics/icons/field.png",
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 1,result = "tree-farm-field"},
    collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
    selection_box = {{-1, -1}, {1, 1}},
    drawing_box = {{-2.8, -0.5}, {0.5, 0.5}},
    inventory_size = 2,
    picture =
    {
      filename = "__Simply Treefarms__/graphics/entities/field/field.png",
      priority = "extra-high",
      width = 70,
      height = 170,
      shift = {0.0, -1.5}
    }
  },

  {
    type = "item",
    name = "tf-germling",
    icon = "__Simply Treefarms__/graphics/icons/germling.png",
    flags = {"goes-to-main-inventory"},
    subgroup = "tf-seeds",
    order = "a[germling]",
    place_result = "tf-germling",
    fuel_value = "1MJ",
    stack_size = 50
  },

  {
    type = "recipe",
    name = "tf-germling",
    ingredients = {{"raw-wood",1}},
    result = "tf-germling",
    result_count = 1
  },


  {
    type = "item",
    name = "tf-coral-seed",
    icon = "__Simply Treefarms__/graphics/icons/coral-seed.png",
    flags = {"goes-to-main-inventory"},
    subgroup = "tf-seeds",
    order = "b[coral]",
    place_result = "tf-coral-seed",
    fuel_value = "1MJ",
    stack_size = 50
  },

  {
    type = "recipe",
    name = "tf-coral-seed",
    ingredients = {{"raw-wood",1}},
    result = "tf-coral-seed",
    result_count = 1
  },

  {
    type = "technology",
    name = "tf-advanced-treefarming",
    icon = "__Simply Treefarms__/graphics/entities/field/field.png",
    icon_size = 128,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "tree-farm-field"
      }
    },
    prerequisites =
    {
      "construction-robotics",
      "logistic-robotics"
    },
    unit =
    {
      count = 300,
      ingredients =
      {
        {"science-pack-1", 3},
        {"science-pack-2", 2}
      },
      time = 30
    }
  },
})
