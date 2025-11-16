# Blackfire's Build Island Library
A bunch of functions and stuff you can use to make scripts for Build Island!

Load it with:
```lua
loadstring(game:HttpGet(""))()
```

# Functions:

GetRank(Player: Player)
Returns the rank of a player. Player defaults to LocalPlayer.

GetBuildingArea(Player: Player)
Returns the BuildingArea belonging to a player (CAN RETURN NIL). Player defaults to LocalPlayer.

Stamp(Block: string/number, Position: CFrame/Vector3, Size: Vector3): Model
-# Places a block at a set position with a set size. Also returns the block.
Block: Can either be a block's name or a block's AssetId
Position: The CFrame the block will be placed at. If it's a Vector3, it will turn it into a CFrame.
Size: The size of the block



# Variables

CharPivot: CFrame
-# The CFrame of the LocalPlayer's character on script execution
