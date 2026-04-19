# Blackfire's Build Island Library
A bunch of functions and stuff you can use to make scripts for Build Island!

Load it with:
```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/BlackfireSoon/Build-Island-Library/refs/heads/main/main.lua'))()
```

# Functions:

```lua
GetRank(Player: Player)
```
↑ Returns the rank of a player. Player defaults to LocalPlayer.


```lua
GetBuildingArea(Player: Player)
```
↑ Returns the BuildingArea belonging to a player (CAN RETURN NIL). Player defaults to LocalPlayer.


```lua
Stamp(Block: string/number, Position: CFrame/Vector3, Size: Vector3): Model
```
↑ Places a block at a set position with a set size. Also returns the block.
- Block: Can either be a block's name or a block's AssetId
- Position: The CFrame the block will be placed at. If it's a Vector3, it will turn it into a CFrame.
- Size: The size of the block

```lua
Delete(Block: Model)
```
↑ Deletes a block.
- Block: Needs to be a block inside of a player's BuildingArea, or one returned from the Stamp function.

```lua
Configure(Block: Model, ConfigName: string, Value: any)
```
↑ Sets the property of a block to a specific value.
- Block: Needs to be a block inside of a player's BuildingArea, or one returned from the Stamp function.
- ConfigName: The name of the property to be changed
- Value: The value to set the property

```lua
Wire(OutputInfo: {Block: Model, OutputName: string}, InputInfo: {Block: Model, InputName: string})
```
↑ Wires a block's output to a blocks' input.
- OutputInfo.Block: Needs to be a block inside of a player's BuildingArea, or one returned from the Stamp function.
- OutputInfo.OutputName: The name of the output to be wired
- OutputInfo.Block: Needs to be a block inside of a player's BuildingArea, or one returned from the Stamp function.
- OutputInfo.InputName: The name of the input to be wired

```lua
Paint(Block: Model, Properties: {[string]: any})
```
↑ Changes the appearance of the block's PrimaryPart
- Block: Needs to be a block inside of a player's BuildingArea, or one returned from the Stamp function.
- Properties: Color, Anchored, Transparency, CanCollide, etc.

```lua
Save()
```
↑ Sets all your blocks information as Stamp(), Paint(), and Config() functions to your clipboard. This does not save wiring.
