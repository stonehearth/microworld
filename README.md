Microworld Stonehearth Mod
==========================

Introduction
------------

The Microworld mod provides a simple playground for mod developers to test their
changes.  It replaces the standard world creation process with one which creates
very trivial, very tiny worlds.  The mod comes with two worlds to choose from:
"mini\_game" which mimics the start of a regular game and "harvest\_test" which
creates two workers, a stockpile, and some harvestable entities.

 

For more information about Stonehearth, please visit http://stonehearth.net

 

Installing
----------

The mod should be installed in the "microworld" folder of your mods" directory.
If you are using Git, you can simply run 'git clone
https://github.com/radent/microworld.git' from inside your mods directory.

If you're downloading the zip file, make sure you rename the folder from
"microworld-\<branch\>" to "microworld"!

 

Running via Command Line
------------------------

To run Microworld, run stonehearth with the following options:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Stonehearth.exe --game.main_mod=microworld
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

You may optionally specify the flag:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 --mods.microworld.world=<world> (default:mini_game)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

To run one of the different worlds packed with the mod.  If you leave off the
world parameter, the mini\_game world get be loaded.

 

Running via User Settings
-------------------------

You can also modify the user\_settings.json file above the mods directory to set
commonly used flags.  For example, the following user\_settings.json file will
run the harvest\_test game world every time you run Stonehearth:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    ... additional options ...
    "game" : {
        "main_mod" : "microworld"
    },
    "mods" : {
        "microworld" : {
            "world" : "harvest_test"
        }
    }
}

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

 
