# TankExtensions
VScript library for custom tank implementation 
## Usage
Include the main script and tank scripts of your choosing to the root table within a popfile's InitWaveOutput  

`IncludeScript("tankextensions_main", getroottable())`  
`IncludeScript("tankextensions/paratank", getroottable())`  

Then list the starting tank paths nodes through `TankExt.StartingPathNames()`  
Example usage can be found in the [example popfile](mvm_slick_v4_tankextensions.pop) and more info about how things work can be found within the script files themselves  
## Path Maker
You can easily create new tank paths with [TankExtension's built-in tool](https://i.imgur.com/ElIxW5x.mp4).  

After including the main script use this command: `ent_fire !activator runscriptcode "TankExt.PathMaker(self)"`  
Replace `ent_fire` with `sm_ent_fire` if on a testing.potato.tf server.  
Blue guides are in-map path nodes. The purple guide is the best position for the last path node.  
If the ending path is inside an in-map path node then the new path will merge into that path.  
## Tank Names
**Blimp**
- blimp
- blimp_red

**Combat Tank**
- combattank|weaponname|weaponname
> [!NOTE]
> Intended to be on a looping path. `TankExt.CreateLoopPaths()`  
> Add **_red** to the first parameter to set the team to red.  
> Add **_nolaser** to the first parameter to remove the default laser.  
> Fire a **CallScriptFunction** input with a parameter of **ToggleUber** to toggle ubercharge.  
>
> Combat Tank weapon names are as follows:
> - **Minigun**
>   - minigun
> - **Rocket Pod**
>   - rocketpod
>   - rocketpod_homing

**Fire Ring Tank**
- fireringtank
  
**ParaTank**
- paratank
  
**Sentry Tank**
- sentrytank
  
**Sticky Tank**
- stickytank
  
**Tankdozer**
- tankdozer
  
**UberTank**
- ubertank|starttime|duration
> [!NOTE]
> **starttime** and **duration** should be values. (ubertank|0|30)  
> Setting either value to **-1** will disable the respective parameter's functionality and will require manual inputs depending on what's disabled.  
> Manually toggling ubercharge can be done by firing a **CallScriptFunction** input on the tank with a parameter of **ToggleUber**.