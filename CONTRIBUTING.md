# How to Contribute
* You'll need a Github account
* You'll need to fork the Treefarm-Lite repository

# Making changes
* Create a branch from where you want to base your work (generally develop)
* Make commits of logical units
* Check for unnecessary whitespace before committing
* Make commit messages of a single line description of the commit, with a more detailed explanation below that if necessary 


# Submitting Changes
* Push changes to a branch in your fork of the repository
* Open a Pull Request to the main repository (likely develop branch)

# Testing Performance Changes
* Take benchmarks both before and after your changes so that the performance improvement is accurately measured
* Report UPS, FPS, and the milliseconds Treefarm takes to run per tick (the number next to the mod name in the debug F5 view)
* Slower, consistent performance w/o lag spikes is preferable to faster performance w/ lag spikes
* Measuring Performance
  * Download and install the Test Mode mod for Factorio
  * Start a new Sandbox game
  * Explore a significant chunk of the map to force Factorio to generate the land are you will need
  * Set up the world for 2500 treefarms by running the following command in the console (accessable through '~')
    /c remote.call("treefarm_interface", "test_setup_world", 2500)
    The command will take a little while to run.
  * Double-check that enough of the world was explored to make the previous command successful by checking the generated terrain. There should be a large square of grass centered in the map. If a corner or part of an edge is missing, then explore the missing section and run the previous command again.
  * Save the game so you have a convenient point to come back to.
  * To test w/ 2500 mk1 farms, run the following command in the console
    /c remote.call("treefarm_interface", "test_create_mk1_treefarms", 2500)

  * To test w/ 2500 mk2 farms, run the following command in the console
    /c remote.call("treefarm_interface", "test_create_mk2_treefarms", 2500)