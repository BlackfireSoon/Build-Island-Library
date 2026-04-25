-- Build Island BasePart Exporter
-- Converts BaseParts (and Models) in a folder into Blackfire's Build Island Library instructions
-- Output is shown in a ScrollingFrame GUI with multiple TextBoxes (200KB each)
return function()
	local EXPORT_ROOT = workspace.BuildingArea -- ← Change this to your folder

	local StamperAssets = game.ReplicatedStorage.StamperAssets

	local MAX_CHUNK_SIZE = 199900 -- just under Roblox's 200,000 character limit

	-- ===================== HELPERS =====================

	local function standard(str)
		return str:lower():gsub(' ', '')
	end

	local function clean(n)
		n = string.format("%.2f", n)
		n = n:gsub("0+$", "")
		n = n:gsub("%.$", "")
		return n
	end

	local function tostring2(arg)
		if typeof(arg) == "Vector3" then
			return clean(arg.X) .. ", " .. clean(arg.Y) .. ", " .. clean(arg.Z)
		elseif typeof(arg) == "CFrame" then
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = arg:GetComponents()
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
			return 'Vector3.new(' .. tostring2(v) .. ')'
		elseif typeof(v) == 'CFrame' then
			return 'CFrame.new(' .. tostring2(v) .. ')'
		elseif typeof(v) == 'Color3' then
			return string.format('Color3.new(%s,%s,%s)', clean(v.R), clean(v.G), clean(v.B))
		elseif typeof(v) == 'BrickColor' then
			return "BrickColor.new('" .. v.Name .. "')"
		elseif typeof(v) == 'string' then
			return "'" .. v .. "'"
		elseif typeof(v) == 'EnumItem' then
			return tostring(v)
		else
			return tostring(v)
		end
	end

	local function FindFirstDescendant(root, name)
		for _, desc in ipairs(root:GetDescendants()) do
			if standard(desc.Name) == standard(name) then
				return desc
			end
		end
		return nil
	end

	local function FindFirstDescendantOfClassAndName(root, className, name)
		for _, desc in ipairs(root:GetDescendants()) do
			if desc.ClassName == className and standard(desc.Name) == standard(name) then
				return desc
			end
		end
		return nil
	end

	-- ===================== getBlock (for Model diffing) =====================

	local function assetIdsMatch(block, assetId)
		return block:FindFirstChild('AssetId') and block.AssetId.Value == assetId
	end

	local function getBlock(name)
		if type(name) == 'string' then
			for _, folder in ipairs(StamperAssets:GetChildren()) do
				for _, block in ipairs(folder:GetChildren()) do
					if standard(block.Name) == standard(name) and block:FindFirstChild('AssetId') then
						return block:FindFirstChild('AssetId').Value
					end
				end
			end
		else
			for _, folder in ipairs(StamperAssets:GetChildren()) do
				for _, block in ipairs(folder:GetChildren()) do
					if assetIdsMatch(block, name) then
						return block
					end
				end
			end
		end
	end

	-- ===================== PAINT HELPER =====================

	-- Writes Paint() call if any properties differ from ogPart
	-- For BaseParts, ogPart can be nil — in that case we always write all non-default properties
	local DEFAULT_COLOR        = Color3.fromRGB(163, 162, 165)
	local DEFAULT_MATERIAL     = Enum.Material.SmoothPlastic
	local DEFAULT_TRANSPARENCY = 0
	local DEFAULT_REFLECTANCE  = 0
	local DEFAULT_CANCOLLIDE   = true
	local DEFAULT_ANCHORED     = false

	local function buildPaintLine(varName, part, ogPart)
		local paintProps = {}

		local function tryProp(propName, value, ogValue)
			if value ~= ogValue then
				table.insert(paintProps, propName .. ' = ' .. propertyValueToString(value))
			end
		end

		if ogPart then
			tryProp('Color',        part.Color,        ogPart.Color)
			tryProp('Material',     part.Material,     ogPart.Material)
			tryProp('Transparency', part.Transparency, ogPart.Transparency)
			tryProp('Reflectance',  part.Reflectance,  ogPart.Reflectance)
			tryProp('CanCollide',   part.CanCollide,   ogPart.CanCollide)
			tryProp('Anchored',     part.Anchored,     ogPart.Anchored)
			if part.MaterialVariant ~= ogPart.MaterialVariant then
				table.insert(paintProps, 'MaterialVariant = ' .. propertyValueToString(part.MaterialVariant))
			end
		else
			-- No ogPart to diff against — write anything non-default
			tryProp('Color',        part.Color,        DEFAULT_COLOR)
			tryProp('Material',     part.Material,     DEFAULT_MATERIAL)
			tryProp('Transparency', part.Transparency, DEFAULT_TRANSPARENCY)
			tryProp('Reflectance',  part.Reflectance,  DEFAULT_REFLECTANCE)
			tryProp('CanCollide',   part.CanCollide,   DEFAULT_CANCOLLIDE)
			tryProp('Anchored',     part.Anchored,     DEFAULT_ANCHORED)
			if part.MaterialVariant ~= '' then
				table.insert(paintProps, 'MaterialVariant = ' .. propertyValueToString(part.MaterialVariant))
			end
		end

		if #paintProps > 0 then
			return 'Paint(' .. varName .. ', {' .. table.concat(paintProps, ', ') .. '})'
		end
		return nil
	end

	-- ===================== COLLECT CHILDREN =====================

	local children = EXPORT_ROOT:GetChildren()

	-- ===================== BUILD OUTPUT =====================

	local lines = {}
	local blockIndex = {} -- instance -> index number (for Models, used in wiring)

	local function write(...)
		table.insert(lines, table.concat({...}, ''))
	end
	
	local debugint = 0
	local function debug(...)
		debugint += 1
		print('Debug ' .. debugint .. ':', ...)
	end
	
	debug('Started')

	write('-- Build Island Exporter by Blackfire')
	write('loadstring(game:HttpGet("https://raw.githubusercontent.com/BlackfireSoon/Build-Island-Library/refs/heads/main/main.lua"))()')
	write('local a = {}')

	-- ===================== PASS 1: STAMP / CONFIGURE / PAINT =====================

	local modelBlocks = {} -- collect Models separately for wiring pass
	local amount = #children
	
	debug('Iterating')
	for i, child in ipairs(children) do
		local varName = 'a[' .. i .. ']'
		if i % 3 == 0 then
			task.wait()
		end
		if i % 9 == 0 then
			print(math.round((i / amount)*100) .. '% finished')
		end

		-- ----------------------------------------------------------------
		-- MODEL — use existing logic (AssetId-based blocks)
		-- ----------------------------------------------------------------
		if child:IsA('Model') then
			if not child:FindFirstChild('AssetId') then continue end

			table.insert(modelBlocks, {block = child, idx = i})
			blockIndex[child] = i

			local assetId = child.AssetId.Value
			local part    = child.PrimaryPart or child:FindFirstChildWhichIsA('BasePart')
			local pivot   = child:GetPivot()

			local ogBlock  = getBlock(assetId)
			local ogPart   = ogBlock and (ogBlock.PrimaryPart or ogBlock:FindFirstChildWhichIsA('BasePart'))

			local size = nil
			if part and ogPart and part.Size ~= ogPart.Size then
				size = part.Size
			end

			if size then
				write(varName, ' = Stamp(', assetId, ', CFrame.new(', tostring2(pivot), '), Vector3.new(', tostring2(size), '))')
			else
				write(varName, ' = Stamp(', assetId, ', CFrame.new(', tostring2(pivot), '))')
			end

			-- Configuration
			local configFolder   = FindFirstDescendant(child, 'Configuration')
			local ogConfigFolder = ogBlock and FindFirstDescendant(ogBlock, 'Configuration')
			if configFolder then
				for _, config in ipairs(configFolder:GetChildren()) do
					if config:IsA('ValueBase') then
						local og = ogConfigFolder and ogConfigFolder:FindFirstChild(config.Name)
						if not og or og.Value ~= config.Value then
							write('Configure(', varName, ", '", config.Name, "', ", propertyValueToString(config.Value), ')')
						end
					end
				end
			end

			-- Paint
			if part and ogPart then
				local paintLine = buildPaintLine(varName, part, ogPart)
				if paintLine then write(paintLine) end
			end

			-- ----------------------------------------------------------------
			-- BASEPART — three sub-cases: MeshPart, SpecialMesh, Decal, plain
			-- ----------------------------------------------------------------
		elseif child:IsA('BasePart') then
			
			local function toInt(str: string)
				return math.round(tonumber(str:gsub('%D','')))
			end

			local part        = child
			local cframe      = part.CFrame
			local size        = part.Size
			local specialMesh = part:FindFirstChildOfClass('SpecialMesh')
			local decals      = {}
			for _, d in ipairs(part:GetChildren()) do
				if d:IsA('Decal') then
					table.insert(decals, d)
				end
			end
			
			-- ---- BasePart with Texture(s) ----
			local textures = {}
			for _, t in ipairs(part:GetChildren()) do
				if t:IsA('Texture') then table.insert(textures, t) end
			end
			
			-- ---- MeshPart ----
			if child:IsA('MeshPart') then
				local meshId    = toInt(part.MeshId)
				local textureId = toInt(part.TextureID) -- MeshPart uses TextureID (capital D)

				write(varName, ' = Stamp("Mesh Block", CFrame.new(', tostring2(cframe), '), Vector3.new(', tostring2(size), '))')
				write('Configure(', varName, ", 'MeshId', '",    meshId,    "')")
				write('Configure(', varName, ", 'TextureId', '", textureId, "')")

				local paintLine = buildPaintLine(varName, part, nil)
				if paintLine then write(paintLine) end

				-- ---- BasePart with SpecialMesh ----
			elseif specialMesh then
				local meshId    = toInt(specialMesh.MeshId:gsub('%D',''))
				local textureId = toInt(specialMesh.TextureId) -- SpecialMesh uses TextureId (lowercase d)
				local meshScale = specialMesh.Scale     -- Vector3

				write(varName, ' = Stamp("Mesh Block", CFrame.new(', tostring2(cframe), '), Vector3.new(', tostring2(meshScale), '))')
				write('Configure(', varName, ", 'MeshId', '",    meshId,    "')")
				write('Configure(', varName, ", 'TextureId', '", textureId, "')")

				local paintLine = buildPaintLine(varName, part, nil)
				if paintLine then write(paintLine) end
				
			elseif #textures > 0 then
				local tex = textures[1] -- Texture Block only supports one texture
				write(varName, ' = Stamp("Texture Block", CFrame.new(', tostring2(cframe), '), Vector3.new(', tostring2(size), '))')
				write('Configure(', varName, ", 'ImageID', ",        toInt(tex.Texture), ')')
				write('Configure(', varName, ", 'Transparency', ",   tex.Transparency, ')')
				write('Configure(', varName, ", 'StudsPerTile (U)', ", tex.StudsPerTileU, ')')
				write('Configure(', varName, ", 'StudsPerTile (V)', ", tex.StudsPerTileV, ')')
				write('Configure(', varName, ", 'OffsetStuds (U)', ",  tex.OffsetStudsU, ')')
				write('Configure(', varName, ", 'OffsetStuds (V)', ",  tex.OffsetStudsV, ')')
				write('Configure(', varName, ", 'Color (R)', ",  math.round(tex.Color3.R*255), ')')
				write('Configure(', varName, ", 'Color (G)', ", math.round(tex.Color3.G*255), ')')
				write('Configure(', varName, ", 'Color (B)', ", math.round(tex.Color3.B*255), ')')
				local paintLine = buildPaintLine(varName, part, nil)
				if paintLine then write(paintLine) end

				-- ---- BasePart with Decal(s) ----
			elseif #decals > 0 then
				write(varName, ' = Stamp("Decal Block", CFrame.new(', tostring2(cframe), '), Vector3.new(', tostring2(size), '))')
				
				local taken = {}
				for _, decal in ipairs(decals) do
					table.insert(taken, decal.Face.Name)
					local face      = tostring(decal.Face) -- e.g. "Enum.NormalId.Top" → need just the name
					-- decal.Face is an EnumItem; .Name gives "Top", "Front", etc.
					local faceName  = decal.Face.Name
					local textureId = toInt(decal.Texture)
					write('Configure(', varName, ", '", faceName, "', '", textureId, "')")
				end
				
				local ALL_FACES = {'Top', 'Bottom', 'Front', 'Back', 'Left', 'Right'}
				for _, face in ipairs(ALL_FACES) do
					if not table.find(taken, face) then
						write('Configure(', varName, ", '", face, "', '0')")
					end
				end

				local paintLine = buildPaintLine(varName, part, nil)
				if paintLine then write(paintLine) end

				-- ---- Plain BasePart (shape-aware) ----
			else
				-- Map Roblox ClassName to Build Island block name
				local CLASS_TO_BLOCK = {
					Part         = 'Block',
					WedgePart    = 'Wedge',
					CornerWedgePart = 'Corner Wedge',
					CylinderPart = 'Cylinder',
					-- Ball/Sphere: Part with Shape = Sphere (legacy) or just treat SpherePart
					SpherePart   = 'Sphere',
				}

				local blockName = CLASS_TO_BLOCK[child.ClassName]

				-- Legacy: a plain Part can also be a sphere/cylinder via its Shape property
				if child.ClassName == 'Part' then
					if child.Shape == Enum.PartType.Cylinder then
						blockName = 'Cylinder'
					elseif child.Shape == Enum.PartType.Ball then
						blockName = 'Sphere'
					else
						blockName = 'Block'
					end
				end

				-- Fallback to Block if unrecognised
				blockName = blockName or 'Block'

				write(varName, ' = Stamp("', blockName, '", CFrame.new(', tostring2(cframe), '), Vector3.new(', tostring2(size), '))')

				local paintLine = buildPaintLine(varName, part, nil)
				if paintLine then write(paintLine) end
			end
		end
	end

	-- ===================== PASS 2: WIRING (Models only) =====================

	write('')
	write('-- Wiring')

	for _, entry in ipairs(modelBlocks) do
		local block     = entry.block
		local outputIdx = entry.idx
		local outputVar = 'a[' .. outputIdx .. ']'

		for _, customEvent in ipairs(block:GetDescendants()) do
			if customEvent:IsA('CustomEvent') then
				local receivers = customEvent:GetAttachedReceivers()
				for _, receiver in ipairs(receivers) do
					local receiverBlock = receiver:FindFirstAncestorWhichIsA('Model')
					local inputIdx      = receiverBlock and blockIndex[receiverBlock]

					if inputIdx then
						local inputVar = 'a[' .. inputIdx .. ']'
						write(
							'Wire(',
							'{', outputVar, ", '", customEvent.Name, "'}, ",
							'{', inputVar,  ", '", receiver.Name,    "'}",
							')'
						)
					else
						write(
							'-- WARNING: Wire from ', outputVar, '.', customEvent.Name,
							' targets a receiver outside the export folder (',
							tostring(receiver:GetFullName()), ')'
						)
					end
				end
			end
		end
	end

	-- ===================== SPLIT INTO 200KB CHUNKS =====================

	pcall(function()
		setclipboard(
			table.concat(lines, '\n')
		)
	end)
	
	local chunks = {}
	local currentChunk = ''

	for _, line in ipairs(lines) do
		local lineWithNewline = line .. '\n'
		if #currentChunk + #lineWithNewline > MAX_CHUNK_SIZE then
			if #currentChunk > 0 then
				table.insert(chunks, currentChunk)
			end
			currentChunk = lineWithNewline
		else
			currentChunk = currentChunk .. lineWithNewline
		end
	end

	if #currentChunk > 0 then
		table.insert(chunks, currentChunk)
	end

	-- ===================== BUILD GUI =====================
	
	local LocalPlayer = game.Players.LocalPlayer
	local PlayerGui = LocalPlayer and game:GetService('CoreGui') or game.StarterGui
	local existing  = PlayerGui:FindFirstChild('BuildExporterGui')
	if existing then existing:Destroy() end

	local screenGui = Instance.new('ScreenGui')
	screenGui.Name          = 'BuildExporterGui'
	screenGui.ResetOnSpawn  = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent        = PlayerGui

	local frame = Instance.new('Frame')
	frame.Name             = 'Container'
	frame.Size             = UDim2.new(0.6, 0, 0.75, 0)
	frame.Position         = UDim2.new(0.2, 0, 0.125, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel  = 0
	frame.Parent           = screenGui

	local titleBar = Instance.new('Frame')
	titleBar.Name             = 'TitleBar'
	titleBar.Size             = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	titleBar.BorderSizePixel  = 0
	titleBar.Parent           = frame

	local titleLabel = Instance.new('TextLabel')
	titleLabel.Size               = UDim2.new(1, -50, 1, 0)
	titleLabel.Position           = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text               = 'Build Island Exporter  —  ' .. #chunks .. ' chunk(s)  |  ' .. #children .. ' object(s)'
	titleLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize           = 14
	titleLabel.Font               = Enum.Font.Code
	titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
	titleLabel.Parent             = titleBar

	local closeBtn = Instance.new('TextButton')
	closeBtn.Size             = UDim2.new(0, 36, 0, 36)
	closeBtn.Position         = UDim2.new(1, -36, 0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.BorderSizePixel  = 0
	closeBtn.Text             = 'X'
	closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled       = true
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.Parent           = titleBar

	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	local scrollFrame = Instance.new('ScrollingFrame')
	scrollFrame.Name                = 'Scroll'
	scrollFrame.Size                = UDim2.new(1, 0, 1, -36)
	scrollFrame.Position            = UDim2.new(0, 0, 0, 36)
	scrollFrame.BackgroundColor3    = Color3.fromRGB(22, 22, 22)
	scrollFrame.BorderSizePixel     = 0
	scrollFrame.ScrollBarThickness  = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent              = frame

	local listLayout = Instance.new('UIListLayout')
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding   = UDim.new(0, 8)
	listLayout.Parent    = scrollFrame

	local uiPadding = Instance.new('UIPadding')
	uiPadding.PaddingTop    = UDim.new(0, 8)
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft   = UDim.new(0, 8)
	uiPadding.PaddingRight  = UDim.new(0, 8)
	uiPadding.Parent        = scrollFrame

	for idx, chunk in ipairs(chunks) do
		local label = Instance.new('TextLabel')
		label.Size                = UDim2.new(1, -16, 0, 20)
		label.BackgroundTransparency = 1
		label.Text                = '── Chunk ' .. idx .. ' of ' .. #chunks .. ' ──'
		label.TextColor3          = Color3.fromRGB(120, 180, 255)
		label.TextSize            = 13
		label.Font                = Enum.Font.Code
		label.TextXAlignment      = Enum.TextXAlignment.Left
		label.LayoutOrder         = (idx - 1) * 2
		label.Parent              = scrollFrame

		local lineCount = 0
		for _ in chunk:gmatch('\n') do lineCount += 1 end
		local boxHeight = math.max(100, lineCount * 18 + 20)

		local textBox = Instance.new('TextBox')
		textBox.Name              = 'Chunk' .. idx
		textBox.LayoutOrder       = (idx - 1) * 2 + 1
		textBox.Size              = UDim2.new(1, -16, 0, boxHeight)
		textBox.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
		textBox.BorderSizePixel   = 0
		textBox.Text              = chunk
		textBox.TextColor3        = Color3.fromRGB(200, 230, 200)
		textBox.TextSize          = 13
		textBox.Font              = Enum.Font.Code
		textBox.TextXAlignment    = Enum.TextXAlignment.Left
		textBox.TextYAlignment    = Enum.TextYAlignment.Top
		textBox.MultiLine         = true
		textBox.TextWrapped       = false
		textBox.ClearTextOnFocus  = false
		textBox.TextEditable      = false
		textBox.Parent            = scrollFrame
	end

	print('[BuildExporter] Done! ' .. #chunks .. ' chunk(s) generated for ' .. #children .. ' object(s).')
end
