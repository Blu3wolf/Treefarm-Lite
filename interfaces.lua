module(..., package.seeall)

remote.add_interface("treefarm",
{
  addSeed = function(seedInfo)
    initGrowthData()
    
    treeGrowthData[seedInfo.name] = seedInfo
    
    initSeedNameToSeedType()
  end
})
