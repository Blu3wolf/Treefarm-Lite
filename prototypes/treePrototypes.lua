data:extend(
{	
	{
		type = "tree",
		name = "tf-germling",
		icon = "__Treefarm-Lite__/graphics/icons/germling.png",
		flags = {"placeable-neutral", "breaths-air"},
		emissions_per_tick = -0.0001,
		minable =
		{
			count = 1,
			mining_particle = "wooden-particle",
			mining_time = 0.1,
			result = "tf-germling"
		},
		max_health = 10,
		collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
		selection_box = {{-0.1, -0.1}, {0.1, 0.1}},
		drawing_box = {{0.0, 0.0}, {1.0, 1.0}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/germling.png",
				priority = "extra-high",
				width = 32,
				height = 32,
				shift = {0.0, 0.0}
			}
		}
	},

	{
		type = "tree",
		name = "tf-very-small-tree",
		icon = "__Treefarm-Lite__/graphics/icons/germling.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0002,
		minable =
		{
			count = 1,
			mining_particle = "wooden-particle",
			mining_time = 0.2,
			result = "raw-wood"
		},
		max_health = 20,
		collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
		selection_box = {{-0.2, -0.55}, {0.2, 0.2}},
		drawing_box = {{-0.2, -0.7}, {0.2, 0.2}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-01.png",
				priority = "extra-high",
				width = math.floor(155/4),
				height = math.floor(118/4),
				shift = {1.1/4, -1/4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-02.png",
				priority = "extra-high",
				width = math.floor(144/4),
				height = math.floor(169/4),
				shift = {1.2/4, -0.8/4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-03.png",
				priority = "extra-high",
				width = math.floor(151/4),
				height = math.floor(131/4),
				shift = {0.8/4, -0.7/4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-04.png",
				priority = "extra-high",
				width = math.floor(167/4),
				height = math.floor(131/4),
				shift = {2/4, -1/4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-05.png",
				priority = "extra-high",
				width = math.floor(156/4),
				height = math.floor(154/4),
				shift = {1.5/4, -1.7/4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/very-small-tree-06.png",
				priority = "extra-high",
				width = math.floor(113/4),
				height = math.floor(111/4),
				shift = {0.7/4, -0.9/4}
			}
		} 
	},

	{
		type = "tree",
		name = "tf-small-tree",
		icon = "__Treefarm-Lite__/graphics/icons/germling.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0003,
		minable =
		{
			count = 2,
			mining_particle = "wooden-particle",
			mining_time = 0.5,
			result = "raw-wood"
		},
		max_health = 50/2,
		collision_box = {{-0.7/2, -0.8/2}, {0.7/2, 0.8/2}},
		selection_box = {{-0.8/2, -2.2/2}, {0.8/2, 0.8/2}},
		drawing_box = {{-0.8/2, -2.8/2}, {0.8/2, 0.8/2}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-01.png",
				priority = "extra-high",
				width = math.floor(155/2),
				height = math.floor(118/2),
				shift = {1.1/2, -1/2}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-02.png",
				priority = "extra-high",
				width = math.floor(144/2),
				height = math.floor(169/2),
				shift = {1.2/2, -0.8/2}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-03.png",
				priority = "extra-high",
				width = math.floor(151/2),
				height = math.floor(131/2),
				shift = {0.8/2, -0.7/2}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-04.png",
				priority = "extra-high",
				width = math.floor(167/2),
				height = math.floor(131/2),
				shift = {2/2, -1/2}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-05.png",
				priority = "extra-high",
				width = math.floor(156/2),
				height = math.floor(154/2),
				shift = {1.5/2, -1.7/2}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/small-tree-06.png",
				priority = "extra-high",
				width = math.floor(113/2),
				height = math.floor(111/2),
				shift = {0.7/2, -0.9/2}
			}
		}
	},

	{
		type = "tree",
		name = "tf-medium-tree",
		icon = "__Treefarm-Lite__/graphics/icons/germling.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0004,
		minable =
		{
			count = 3,
			mining_particle = "wooden-particle",
			mining_time = 1.0,
			result = "raw-wood"
		},
		max_health = math.floor(50*0.75),
		collision_box = {{-0.7*0.75, -0.8*0.75}, {0.7*0.75, 0.8*0.75}},
		selection_box = {{-0.8*0.75, -2.2*0.75}, {0.8*0.75, 0.8*0.75}},
		drawing_box = {{-0.8*0.75, -2.8*0.75}, {0.8*0.75, 0.8*0.75}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-01.png",
				priority = "extra-high",
				width = math.floor(155*0.75),
				height = math.floor(118*0.75),
				shift = {1.1*0.75, -1*0.75}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-02.png",
				priority = "extra-high",
				width = math.floor(144*0.75),
				height = math.floor(169*0.75),
				shift = {1.2*0.75, -0.8*0.75}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-03.png",
				priority = "extra-high",
				width = math.floor(151*0.75),
				height = math.floor(131*0.75),
				shift = {0.8*0.75, -0.7*0.75}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-04.png",
				priority = "extra-high",
				width = math.floor(167*0.75),
				height = math.floor(131*0.75),
				shift = {2*0.75, -1*0.75}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-05.png",
				priority = "extra-high",
				width = math.floor(156*0.75),
				height = math.floor(154*0.75),
				shift = {1.5*0.75, -1.7*0.75}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/medium-tree-06.png",
				priority = "extra-high",
				width = math.floor(113*0.75),
				height = math.floor(111*0.75),
				shift = {0.7*0.75, -0.9*0.75}
			}
		}
	},

	{
		type = "tree",
		name = "tf-mature-tree",
		icon = "__Treefarm-Lite__/graphics/icons/germling.png",
		order="b-b-h",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.001,
		minable =
		{
			count = 4,
			mining_particle = "wooden-particle",
			mining_time = 2,
			result = "raw-wood"
		},
		max_health = 50,
		collision_box = {{-0.7, -0.8}, {0.7, 0.8}},
		selection_box = {{-0.8, -2.2}, {0.8, 0.8}},
		drawing_box = {{-0.8, -2.8}, {0.8, 0.8}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-01.png",
				priority = "extra-high",
				width = 155,
				height = 118,
				shift = {1.1, -1}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-02.png",
				priority = "extra-high",
				width = 144,
				height = 169,
				shift = {1.2, -0.8}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-03.png",
				priority = "extra-high",
				width = 151,
				height = 131,
				shift = {0.8, -0.7}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-04.png",
				priority = "extra-high",
				width = 167,
				height = 131,
				shift = {2, -1}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-05.png",
				priority = "extra-high",
				width = 156,
				height = 154,
				shift = {1.5, -1.7}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-06.png",
				priority = "extra-high",
				width = 113,
				height = 111,
				shift = {0.7, -0.9}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-07.png",
				priority = "extra-high",
				width = 116,
				height = 125,
				shift = {1, -0.7}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-08.png",
				priority = "extra-high",
				width = 162,
				height = 129,
				shift = {1.4, -1.3}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-09.png",
				priority = "extra-high",
				width = 156,
				height = 164,
				shift = {1.7, -1.1}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-10.png",
				priority = "extra-high",
				width = 196,
				height = 129,
				shift = {1.1, -1.1}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-11.png",
				priority = "extra-high",
				width = 196,
				height = 129,
				shift = {1.3, -1.4}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/treefarm/big-tree-12.png",
				priority = "extra-high",
				width = 175,
				height = 164,
				shift = {1.6, -1.2}
			}
		}
	},

	{
		type = "tree",
		name = "tf-coral-seed",
		icon = "__Treefarm-Lite__/graphics/icons/coral-seed.png",
		flags = {"placeable-neutral", "breaths-air"},
		emissions_per_tick = -0.0001,
		minable =
		{
			count = 1,
			mining_particle = "wooden-particle",
			mining_time = 0.1,
			result = "tf-coral-seed"
		},
		max_health = 10,
		collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
		selection_box = {{-0.1, -0.1}, {0.1, 0.1}},
		drawing_box = {{0.0, 0.0}, {1.0, 1.0}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/coral-seed.png",
				priority = "extra-high",
				width = 9,
				height = 12,
				shift = {0.0, 0.0}
			}
		}
	},

	{
		type = "tree",
		name = "tf-small-coral",
		icon = "__Treefarm-Lite__/graphics/icons/coral-seed.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0002,
		minable =
		{
			count = 1,
			mining_particle = "wooden-particle",
			mining_time = 0.2,
			result = "raw-wood"
		},
		max_health = 20,
		collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
		selection_box = {{-0.2, -0.55}, {0.2, 0.2}},
		drawing_box = {{-0.2, -0.7}, {0.2, 0.2}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/small-coral-01.png",
				priority = "extra-high",
				width = 19,
        height = 23,
        shift = {0.4 / 4.5, -0.4 / 4.5}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/small-coral-02.png",
				priority = "extra-high",
				width = 26,
        height = 32,
        shift = {0.7 / 4.5, -0.05 / 4.5}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/small-coral-03.png",
				priority = "extra-high",
				width = 14,
        height = 18,
        shift = {0.2 / 4.5, 0 / 4.5}
			}
		}
	},

	{
		type = "tree",
		name = "tf-medium-coral",
		icon = "__Treefarm-Lite__/graphics/icons/coral-seed.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0003,
		minable =
		{
			count = 2,
			mining_particle = "wooden-particle",
			mining_time = 0.2,
			result = "raw-wood"
		},
		max_health = 20,
		collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
		selection_box = {{-0.2, -0.55}, {0.2, 0.2}},
		drawing_box = {{-0.2, -0.7}, {0.2, 0.2}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/medium-coral-01.png",
				priority = "extra-high",
				width = 29,
        height = 35,
        shift = {0.4 / 3.0, -0.4 / 3.0}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/medium-coral-02.png",
				priority = "extra-high",
				width = 39,
        height = 49,
        shift = {0.7 / 3.0, -0.05 / 3.0}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/medium-coral-03.png",
				priority = "extra-high",
				width = 21,
        height = 27,
        shift = {0.2 / 3.0, 0 / 3.0}
			}
		}
	},

	{
		type = "tree",
		name = "tf-mature-coral",
		icon = "__Treefarm-Lite__/graphics/icons/coral-seed.png",
		order="b-b-g",
		flags = {"placeable-neutral", "placeable-off-grid", "breaths-air"},
		emissions_per_tick = -0.0006,
		minable =
		{
			count = 3,
			mining_particle = "wooden-particle",
			mining_time = 0.2,
			result = "raw-wood"
		},
		max_health = 20,
		collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
		selection_box = {{-0.2, -0.55}, {0.2, 0.2}},
		drawing_box = {{-0.2, -0.7}, {0.2, 0.2}},
		pictures =
		{
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/mature-coral-01.png",
				priority = "extra-high",
				width = 58,
        height = 69,
        shift = {0.4 / 2.0, -0.4 / 2.0}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/mature-coral-02.png",
				priority = "extra-high",
				width = 77,
        height = 97,
        shift = {0.7 / 2.0, -0.05 / 2.0}
			},
			{
				filename = "__Treefarm-Lite__/graphics/entities/coral/mature-coral-03.png",
				priority = "extra-high",
				width = 41,
        height = 54,
        shift = {0.2 / 2.0, 0 / 2.0}
			}
		}
	}
}
)