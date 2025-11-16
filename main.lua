local BuildingBridge = game.ReplicatedStorage.BuildingBridge
local StamperAssets = game.ReplicatedStorage.StamperAssets

CharPivot = game.Players.LocalPlayer.Character:GetPivot()
CharPosition = CharPivot.Position

setclipboard = setclipboard or function(...)
	warn('"setclipboard" function not found')
end

local function standard(str: string)
	return str:lower():gsub(' ','')
end

local function assetIdsmatch(block: Model, assetId: number)
	if block:FindFirstChild('AssetId') and (block.AssetId.Value == assetId) then
		return true
	else
		return false
	end
end

local function getBlock(name: string)
	if type(name) == 'string' then
		for i, folder in ipairs(StamperAssets:GetChildren()) do
			for i, block: Model in ipairs(folder:GetChildren()) do
				if (standard(block.Name) == standard(name)) and (block:FindFirstChild('AssetId')) then
					return block:FindFirstChild('AssetId').Value
				end
			end
		end
	else
		for i, folder in ipairs(StamperAssets:GetChildren()) do
			for i, block: Model in ipairs(folder:GetChildren()) do
				if assetIdsmatch(block, name) then
					return block
				end
			end
		end
	end
end

local function FindFirstDescendant(root, name)
	for i, desc in ipairs(root:GetDescendants()) do
		if (standard(desc.Name) == standard(name)) then
			return desc
		end
	end
	return nil
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

function Configure(Block: Model, ConfigName: string, Value: any)
	if Block and ConfigName then
		local Configuration: Configuration = FindFirstDescendant(Block, 'Configuration')

		if Configuration then
			local Config = Configuration:FindFirstChild(ConfigName)

			if Config then
				BuildingBridge.Config:InvokeServer(Config, Value)
			end
		end
	else
		warn('Expected 3 args, got: ', Block, ConfigName, Value)
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


--Yes, clean() and tostring2() was made with chatgpt sorry not sorry
local function clean(n)
	n = string.format("%.2f", n)
	n = n:gsub("0+$", "")
	n = n:gsub("%.$", "")
	return n
end

function tostring2(arg)
	if typeof(arg) == "Vector3" then
		return clean(arg.X) .. ", " .. clean(arg.Y) .. ", " .. clean(arg.Z)
	elseif typeof(arg) == "CFrame" then
		local x,y,z,
		r00,r01,r02,
		r10,r11,r12,
		r20,r21,r22 = arg:GetComponents()

		return table.concat({
			clean(x), clean(y), clean(z),
			clean(r00), clean(r01), clean(r02),
			clean(r10), clean(r11), clean(r12),
			clean(r20), clean(r21), clean(r22)
		}, ", ")
	end
end

local function propertyValueToString(v)
	if typeof(v) == 'Vector3' then
		return 'Vector3.new('..tostring2(v)..')'
	elseif typeof(v) == 'CFrame' then
		return 'CFrame.new('..tostring2(v)..')'
	elseif typeof(v) == 'Color3' then
		return 'Color3.new('..v.R..','..v.G..','..v.B..')'
	elseif typeof(v) == 'BrickColor' then
		return 'BrickColor.new(\''..v.Name..'\')'
	elseif typeof(v) == 'string' then
		return '\''..v..'\''
	else
		return tostring(v)
	end
end

local function saveBlockProperties(block, ogBlock, i: number)
	local props = {}
	local part = block.PrimaryPart or block:FindFirstChildWhichIsA('BasePart')
	local ogPart = ogBlock.PrimaryPart or ogBlock:FindFirstChildWhichIsA('BasePart')
	if not part or not ogPart then return nil end

	if part.Transparency ~= ogPart.Transparency then
		props.Transparency = part.Transparency
	end
	if part.Material ~= ogPart.Material then
		props.Material = part.Material
	end
	if part.Reflectance ~= ogPart.Reflectance then
		props.Reflectance = part.Reflectance
	end
	if part.Color ~= ogPart.Color then
		props.Color = part.Color
	end
	if part.CanCollide ~= ogPart.CanCollide then
		props.CanCollide = part.CanCollide
	end
	if part.Anchored ~= ogPart.Anchored then
		props.Anchored = part.Anchored
	end

	if next(props) then
		local paintProps = {}
		for k,v in pairs(props) do
			paintProps[#paintProps+1] = k..' = '..propertyValueToString(v)
		end
		return 'Paint(a' .. i .. ', {'..table.concat(paintProps, ', ')..'})'
	end
	return nil
end

function Save()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/SolarSimulator/Build-Island-Library/refs/heads/main/main.lua'))()

	local BuildingArea = GetBuildingArea()
	local PlayerArea = BuildingArea.PlayerArea
	local code = [[]]

	local function write(...)
		code = table.concat({code, ...}, '') .. '\n'
	end

	for i, block in ipairs(PlayerArea:GetChildren()) do
		local AssetId = block:FindFirstChild('AssetId')
		if AssetId then
			AssetId = AssetId.Value

			local part = block.PrimaryPart or block:FindFirstChildWhichIsA('BasePart')
			local ogBlock = getBlock(AssetId)
			local ogPart = ogBlock.PrimaryPart or ogBlock:FindFirstChildWhichIsA('BasePart')

			local size
			if part and ogPart and part.Size ~= ogPart.Size then
				size = part.Size
			end

			if size then
				write('a', i, ' = ', 'Stamp(', AssetId, ', CFrame.new(', tostring2(block:GetPivot()), '), Vector3.new(', tostring2(size), '))')
			else
				write('a', i, ' = ', 'Stamp(', AssetId, ', CFrame.new(', tostring2(block:GetPivot()), '))')
			end

			local configFolder = FindFirstDescendant(block, 'Configuration')
			local ogConfigFolder = FindFirstDescendant(ogBlock, 'Configuration')
			if configFolder and ogConfigFolder then
				for _, config in ipairs(configFolder:GetChildren()) do
					if config:IsA('ValueBase') then
						local og = ogConfigFolder:FindFirstChild(config.Name)
						if og and og.Value ~= config.Value then
							write('Configure(a'..i..', \'' .. config.Name..'\', ' .. propertyValueToString(config.Value)..')')
						end
					end
				end
			end

			local paintLine = saveBlockProperties(block, ogBlock, i)
			if paintLine then
				write(paintLine)
			end

		end
	end

	setclipboard(code)
	print(code)
end

--# Aliases
--Stamp
s = Stamp
stamp = Stamp
build = Stamp
Place = Stamp
Build = Stamp
Place = Stamp

--Delete
d = Delete
delete = Delete
del = Delete
Del = Delete
Remove = Delete

--Configure
c = Configure
configure = Configure
config = Configure
Config = Configure
Configuration = Configure

--Wire
w = Wire
wire = Wire
wiring = Wire
Wiring = Wire

--Paint
p = Paint
paint = Paint
Painting = Paint
painting = Paint
