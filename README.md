# Geometrie Das 2.0 Beta 6
First actual relatively stable version of Geometrie Das
> Main levels are still completely broken, but next update will include the last features required for proper level making
> Player data has been remade. Levels will remain intact as they are not part of the player data save file.
- Fixed paste and duplicate (copy+paste) functionality
- Updated how objects are created
- Remade how objects use shaders (instead of instance uniforms, they use a cache of different shader materials with the appropiate properties) as instance uniforms were too limited.
- Added a basic API management autoload to help provide online functionality in the future (not yet in use)
- Added setting for levels (starting gamemode. song, main color channels like background or objects, gravity and more to come)
- Remade camera movement handling in level
- Added an air time counter to kill the player if they are falling for too long without changing gamemode, hitting an orb or pad etc. (when in any gamemode without a ceiling, like the cube)
- Updated player data to use custom resources.
- Added resume (and edit when playtesting) button to levels. Pressing escape while paused will now exit the level.
- Changed pause menu behaviour to be more deterministic (i think that's the correct term)
- Added debug labels that display properties of the player (to be extended to other things) during gameplay. Only shows when playing from the Godot Editor or from a debug build.
- Level music now starts only when the player reaches x = 0
- Camera position in the editor saved
- Added a way to set a color channel to copy aother one

# Geometrie Das 2.0 Beta 5 (beta 4 never existed ahahahaha)

> *Note:* to open the project, it is recommended you update all UID's using `Project>Tools>Upgrade Project Files`. I use Godot 4.6. Probably UID's got corrupted when I merged from the `dev` branch.
> `2.0-beta.5a` fixes import/UID corruption, now works as expected

- ok, i need a more consistent naming scheme
- remade level object, level and registry data to use`Resource` type objects
>this was made so that inconsistencies when converting into JSON to be sent to the server will be avoided and to make implementing future features much easier
- implemented a custom save/load system using compressed binary blobs
>does use the unsafe `var_to_bytes_with_objects` method, but these files are not meant to be directly shared.
- implemented a color channel system that uses an `ImageTexture2D` object shared with the `RenderingServer`. Accessed trough the `ColorManager` singleton.
- added `Trigger` superclass, used by future implementation of triggers. Contains base properties like `trigger_id` and `target_id`
- added `ColorTrigger` subclass that has handles changing the color of the channel of index`target_id` to `target_color` over `fade_time`. 
- added menus to edit the channel of one or more objects, to edit the starting color of a channel and to change the properties of one or more color triggers (can be extended for more triggers)
- added editor layers
- unified the shader used by objects both in level and in the editor to support editor layers, color channels, selection color and other effects
- added more custom UI elements that can be used for future addition
- other bug fixes and small physics changes
- other things I might have forgotten about, way too much

Oof, quite a big update... hope the next one comes soon!

# Geometrie Das 2.0 Beta 3 (and 2)
- swipe building is now functional
- fixed memory leak when using VisibleOnScreenEnabler2D
- remade objects to load new component nodes only when necessary
- more stable loading and saving
- added more objects (more decorations, tabs and color management in the future)
- level registry now unloads when entering the editor or a level
- delete levels
- levels completed while playtesting will are now verified, they become unverified when opening the editor again
- now the level editing menu shows verified status, song used and length of level
- more refactoring and stuff
- fixed bugs relating to UndoRedo

# Geometrie Das 2.0 Beta 1 (and 1a)
- added preloading of resources and scenes (mostly for level loading optimizations)
- added level editing menu (rename, add a description, edit or playtest the level)
- remade level loading and saving
- levels and the level indexex are now compressed to save disk space and allow for cheaper sharing
- refactored objects
- fixed a few minor bugs when playtesting a level

to be added:
- show details on the level editing menu (calculated length, used song, published id)
- all these systems are made with the end goal of easily implementing uploading and saving custom levels
- more objects in the editor (pink orb/pad, more blocks and spikes, decorations)
- layers (both editor and render)
- lazy loading (objects load as the player progresses trough the level, to be implemented alongside practice mode possibly)
- triggers (at least color/pulse triggers)

Online features to be added after most of these things are implemented.
I only really have time on weekends to add complex features (WE love fridays) so don't expect it finished TOO soon.
I also try to make things more general to allow building on top of current logic more easily. If you have any suggestions regarding
optimizations, I am happy to listen!

# Geometrie Das 1.1 Beta 9
- fixed bad management of instances (using direct references in _physics_process - yes i know stupid)
- fixed orbs remaining in the activation queue even if player left it's area
- overhauled graphics (it's so much prettier :3), also preparing to merge even more textures into atlases
- added button effects on button down and up (very bouncy)
- implemented preloading of objects to (potentially) improve loading times
- other small still in progress additions (not available yet)
- and misc small fixes

# Geometrie Das 1.1 Beta 8
- tuned consecutive jump correction
- decreased ship gravity to be 45% of thrust
- added highlight effects to orbs and pads when activated (will be applied to portals in the future)
- small changes to UI graphics
- added box selection to swipe mode
- added more UI elements to the editor, along with more functions (zoom in/out, swipe toggle, undo/redo buttons etc.)
- added boost when jumping into a ball portal as a cube
- added more move step buttons (8 units and 1 units) and rotate buttons in edit mode

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
