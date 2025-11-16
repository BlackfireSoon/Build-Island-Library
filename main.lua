local BuildingBridge = game.ReplicatedStorage.BuildingBridge
local StamperAssets = game.ReplicatedStorage.StamperAssets

CharPivot = game.Players.LocalPlayer.Character:GetPivot()
CharPosition = CharPivot.Position

local function standard(str: string)
	return str:lower():gsub(' ','')
end

local function getBlock(name: string)
	for i, folder in ipairs(StamperAssets:GetChildren()) do
		for i, block: Model in ipairs(folder:GetChildren()) do
			if (standard(block.Name) == standard(name)) and (block:FindFirstChild('AssetId')) then
				return block:FindFirstChild('AssetId').Value
			end
		end
	end
end

local function FindFirstDescendantOfClassAndName(root, className, name)
	for i, desc in ipairs(root:GetDescendants()) do
		if (desc.ClassName == className) and (standard(desc.Name) == standard(name) )then
			return desc
		end
	end
	return nil
end

function GetBuildingArea(Player: Player)
	Player = Player or game.Players.LocalPlayer
	local playerNumber = Player:FindFirstChild('playerNumber') and Player.playerNumber.Value or 271000
	return game.Workspace.BuildingAreas:FindFirstChild('Area' .. playerNumber)
end

function GetRank(Player: Player)
	Player = Player or game.Players.LocalPlayer

	local Rank = math.round(tonumber(Player.leaderstats.Rank.Value:sub(1,1)))
	return Rank
end

function Stamp(AssetId: number, Pivot: CFrame, Size: Vector3)
	if AssetId then

		Pivot = Pivot or CFrame.new()

		if type(AssetId) == 'string' then
			AssetId = getBlock(AssetId) end
		if typeof(Pivot) == 'Vector3' then
			Pivot = CFrame.new(Pivot) end

		local V, model: Model = BuildingBridge.Stamp:InvokeServer(AssetId, {Pivot, nil, nil, (Size and (Size / 2)) or nil})--: true, Instance
		return model
	else
		warn('Expected 2 args, got: ', AssetId, Pivot)
	end
end

function Delete(Block: Model)
	if Block then
		BuildingBridge.Delete:InvokeServer(Block)
	else
		warn('Expected 1 arg, got: ', Block)
	end
end

function Configure(Configuration: ValueBase, Value: any)
	if Configuration then
		BuildingBridge.Config:InvokeServer(Configuration, Value)
	else
		warn('Expected 2 args, got: ', Configuration, Value)
	end
end

function Wire(OutputInfo: {Block: Model, OutputName: string}, InputInfo: {Block: Model, OutputName: string})
	if OutputInfo and InputInfo then

		local Output = FindFirstDescendantOfClassAndName(OutputInfo[1], 'CustomEvent', OutputInfo[2])
		local Input = FindFirstDescendantOfClassAndName(InputInfo[1], 'CustomEventReceiver', InputInfo[2])

		if Output and Input then

			BuildingBridge.Wiring:InvokeServer(Output, Input, true)

		else
			print('Output or Input nil, :', Output, Input)
		end
	else
		warn('Expected 2 args, got: ', OutputInfo, InputInfo)
	end
end

function Paint(Block: Model, Properties: {[string]: any})
	if Block and Properties then
		local primary = Block.PrimaryPart or Block:FindFirstChildWhichIsA('BasePart')
		BuildingBridge.Paint:InvokeServer({primary}, Properties)
	end
end

--# Aliases
--Stamp
stamp = Stamp
build = Stamp
Place = Stamp
Build = Stamp
Place = Stamp

--Delete
delete = Delete
del = Delete
Del = Delete
Remove = Delete

--Configure
configure = Configure
config = Configure
Config = Configure
Configuration = Configure

--Wire
wire = Wire
wiring = Wire
Wiring = Wire

--Paint
paint = Paint
Painting = Paint
painting = Paint
