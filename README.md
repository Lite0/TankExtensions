# TankExtensions
a VScript library for custom tank implementation 
# Usage
include the main script and tank scripts of your choosing to the root table within a popfile's InitWaveOutput  
`IncludeScript("tankextensions_main", getroottable())`  
`IncludeScript("tankextensions/paratank", getroottable())`  
then list the starting tank paths nodes through `TankExt.StartingPathNames()`  
example usage can be found in the [example popfile](mvm_slick_v4_tankextensions.pop) and more info about how things work can be found within the script files themselves  
# Path Maker
you can easily create new tank paths with [TankExtension's built-in tool](https://i.imgur.com/ElIxW5x.mp4)   

after including the main script use this command: `ent_fire !activator runscriptcode "TankExt.PathMaker(self)"`  
replace `ent_fire` with `sm_ent_fire` if on a testing.potato.tf server  
blue guides are in-map path nodes and the purple guide is the best position for the last path node  
if the ending path is inside an in-map path node then the new path will merge into that path  
# Tank Names
- **Blimp**
  - blimp
  - blimp_red

- **Combat Tank**
  - combattank|weaponname|weaponname
> [!NOTE]
> intended to be on a looping path `TankExt.CreateLoopPaths()`  
> add **_red** to the first parameter to set the team to red  
> add **_nolaser** to the first parameter to remove the default laser  
> fire a **CallScriptFunction** input with a parameter of **ToggleUber** to toggle ubercharge  
>
> Combat Tank weapon names are as follows:
> - **Minigun**
>   - minigun
> - **Rocket Pod**
>   - rocketpod
>   - rocketpod_homing

- **Fire Ring Tank**
  - fireringtank

- **ParaTank**
  - paratank

- **Sentry Tank**
  - sentrytank

- **Sticky Tank**
  - stickytank

- **Tankdozer**
  - tankdozer

- **UberTank**
  - ubertank|starttime|duration
> [!NOTE]
> **starttime** and **duration** should be values (ubertank|0|30)  
> setting either value to **-1** will disable the respective parameter's functionality and will require manual inputs depending on what's disabled
> manually toggling ubercharge can be done by firing a **CallScriptFunction** input on the tank with a parameter of **ToggleUber**