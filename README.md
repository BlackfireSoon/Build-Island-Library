# Blackfire’s Build Island Library

Functions n stuff for creating scripts for the Roblox game **Build Island**.

## Load it by
```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/SolarSimulator/Build-Island-Library/refs/heads/main/main.lua'))()
```

## Functions

### `GetRank(Player: Player?) → number`
Returns the player’s rank.  
If no player is provided, defaults to `LocalPlayer`.

### `GetBuildingArea(Player: Player?) → Model?`
Returns the player’s **BuildingArea**.  
May return `nil`.  
Defaults to `LocalPlayer`.

### `Stamp(Block: string | number, Position: CFrame | Vector3, Size: Vector3) → Model`
Places a block and returns the created model.
**Args**
- 1. **Block:** Block name or AssetId  
- 2. **Position:** A `CFrame`, or a `Vector3` (auto-converted to `CFrame`)  
- 3. **Size:** The size of the block
