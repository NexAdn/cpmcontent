# CPMcontent
CPMcontent is the public repository for CPM (https://github.com/NexAdn/cpm)

You can submit your own CC scripts to the repository:
* (Recommended) Fork the repository, insert your package as a folder with all needed data (Please look at https://raw.githubusercontent.com/NexAdn/cpm/master/doc/repostructure for more info) and send a pull request.
* Upload your script to Gist, Pastebin or any other similar hosting service. Open an issue with the Name of the script and links to your paste/gist/etc.

# Dependencies
Every CPM package must contain at least two files (CPM v0.2): main.lua and dependencies.
The main.lua is the Lua script, the dependencies contains a line-seperated list of all packages this packages depends on.
If a package doesn't have any dependencies, the dependencies file just contains

    NULL
    
to avoid parsing failures.

# Data folders and default configuration files
These features should become implemented in CPM version 0.3.