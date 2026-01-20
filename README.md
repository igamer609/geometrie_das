# Geometrie Das 1.1 Beta 7
- small changes to jump height for the cube
- added small a correction to consecutive jumps to allow staircase-like structures to be used properly
- now level files will be named after their local id (made to differenciate playtest levels to published levels)
- when having one object selected, placing another object of the same type mentains the properties (rn only rotation)
- increased max physics steps per frame (30 for 240hz)
- discovered frame inconsistencies caused by hardware limitations/other programs (tested: OBS causes lag spikes, closing it makes the FPS and Process times stable)
- main menu background has it's scroll now dependant on delta
- changed loading popup (will add check to see if it's the first time playing)

# Geometrie Das 1.1 Beta 6
- improved player collision (fixed raycasts being in the wrong place)
- removed dependancies on delta time (for physics processes, because the project runs at a fixed 240hz to create a more unified experience)
- also adjusted cube and ship physics to be more accurate and enjoyable
- added buffering (this was very needed)
- revamped data schemas for the player data and custom levels to allow saving and loading icons, progress on levels (normal, practice, attempts, jumps --not implemented yet) both main and custom (custom levels are still playtest only but they are ready to be implemented as custom levels), statistics (still not sure what those will be, total attempts and jumps will definetely be included)
- yes i have decided to eventually make online levels possible, bro might be robtop (not yet but each update leads me closer)
- more special items in the editor (gravity portals)

# Geometrie Das 1.1 Beta 4/5 (should i name it 2.0?)
- remade player collision and physics (not yet tuned correcly)
- changed how the editor renders selected objects (uses shaders)
- added "in_level" property to objects
- a more unified naming schema for objects
- more editor objects (pads, orbs, portals)
- undo/redo functionality
- "Save and Play" button finally works as intended
- added restart button to pause menu (will change pause menu in the future to add more features)
- planned:
  - more complex player data saving up next... in preparation for something bigger :3
  - remove "Load" tab from custom level menu (will be replaced)
  - more icons
  - bug fixes
- not planned:
  - more gamemodes (maybe ufo?)

# Geometrie Das 1.1 Beta 3 (5/16/2024)
- added saved level page
- more gamemodes (wave, spider), songs and blocks comming soon (editor)
- planned:
  - decoration
  - editor layers
  - level layers (B3, B2, B1, D, T1, T2)

# Geometrie Das 1.1 Beta 2
- added level loading from file
- saved level page in the works

# Geometrie Das 1.1 Beta
- added editor
- editor files can be loaded and saved
- still working on loading levels for playing
- i have plans to add a featured tab
