return function(input)
    -- 1. Load Blackfire's Build Island Library into the global environment
    local success, err = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/BlackfireSoon/Build-Island-Library/refs/heads/main/main.lua'))()
    end)
    if not success then
        warn("Failed to load Build Island Library: " .. tostring(err))
    end

    -- 2. Setup the UI container
    local CoreGui = game:GetService("CoreGui")
    -- Fallback for standard Studio testing, though executors use CoreGui
    if not pcall(function() local _ = CoreGui.Name end) then
        CoreGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    local guiName = "BlackfireUIPanel"
    if CoreGui:FindFirstChild(guiName) then
        CoreGui[guiName]:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = CoreGui

    -- 3. Main Frame (Sleek, Dark Theme)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopUICorner = Instance.new("UICorner")
    TopUICorner.CornerRadius = UDim.new(0, 8)
    TopUICorner.Parent = TopBar
    
    -- Fix bottom corners of top bar to blend with main frame
    local Filler = Instance.new("Frame")
    Filler.Size = UDim2.new(1, 0, 0, 10)
    Filler.Position = UDim2.new(0, 0, 1, -10)
    Filler.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Filler.BorderSizePixel = 0
    Filler.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Blackfire's Build Island Panel"
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -30, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TopBar
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- 4. Code Execution Section
    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(1, -20, 0, 200)
    CodeBox.Position = UDim2.new(0, 10, 0, 45)
    CodeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    CodeBox.TextColor3 = Color3.fromRGB(200, 255, 200)
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextSize = 14
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.ClearTextOnFocus = false
    CodeBox.MultiLine = true
    CodeBox.Text = type(input) == "string" and input or "-- Write your sequence here...\n"
    CodeBox.Parent = MainFrame

    local CodeUICorner = Instance.new("UICorner")
    CodeUICorner.CornerRadius = UDim.new(0, 6)
    CodeUICorner.Parent = CodeBox

    local ExecuteBtn = Instance.new("TextButton")
    ExecuteBtn.Size = UDim2.new(0.5, -15, 0, 35)
    ExecuteBtn.Position = UDim2.new(0, 10, 0, 255)
    ExecuteBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteBtn.Text = "Run Sequence"
    ExecuteBtn.Font = Enum.Font.GothamBold
    ExecuteBtn.TextSize = 14
    ExecuteBtn.Parent = MainFrame
    Instance.new("UICorner", ExecuteBtn).CornerRadius = UDim.new(0, 6)

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(0.5, -15, 0, 35)
    SaveBtn.Position = UDim2.new(0.5, 5, 0, 255)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.Text = "Save Build (Copy to Clipboard)"
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.TextSize = 14
    SaveBtn.Parent = MainFrame
    Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

    -- 5. Asset ID Fetcher Section
    local FetchFrame = Instance.new("Frame")
    FetchFrame.Size = UDim2.new(1, -20, 0, 80)
    FetchFrame.Position = UDim2.new(0, 10, 0, 305)
    FetchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    FetchFrame.Parent = MainFrame
    Instance.new("UICorner", FetchFrame).CornerRadius = UDim.new(0, 6)

    local FetchTitle = Instance.new("TextLabel")
    FetchTitle.Size = UDim2.new(1, -20, 0, 20)
    FetchTitle.Position = UDim2.new(0, 10, 0, 5)
    FetchTitle.BackgroundTransparency = 1
    FetchTitle.Text = "Get Block Asset ID"
    FetchTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    FetchTitle.Font = Enum.Font.GothamBold
    FetchTitle.TextSize = 12
    FetchTitle.TextXAlignment = Enum.TextXAlignment.Left
    FetchTitle.Parent = FetchFrame

    local BlockInput = Instance.new("TextBox")
    BlockInput.Size = UDim2.new(0.5, -15, 0, 35)
    BlockInput.Position = UDim2.new(0, 10, 0, 30)
    BlockInput.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    BlockInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    BlockInput.Text = "Block Name"
    BlockInput.ClearTextOnFocus = true
    BlockInput.Font = Enum.Font.Gotham
    BlockInput.TextSize = 13
    BlockInput.Parent = FetchFrame
    Instance.new("UICorner", BlockInput).CornerRadius = UDim.new(0, 6)

    local FetchBtn = Instance.new("TextButton")
    FetchBtn.Size = UDim2.new(0.25, -15, 0, 35)
    FetchBtn.Position = UDim2.new(0.5, 5, 0, 30)
    FetchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    FetchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FetchBtn.Text = "Get ID"
    FetchBtn.Font = Enum.Font.GothamBold
    FetchBtn.TextSize = 13
    FetchBtn.Parent = FetchFrame
    Instance.new("UICorner", FetchBtn).CornerRadius = UDim.new(0, 6)

    local FetchResult = Instance.new("TextBox")
    FetchResult.Size = UDim2.new(0.25, -15, 0, 35)
    FetchResult.Position = UDim2.new(0.75, 0, 0, 30)
    FetchResult.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    FetchResult.TextColor3 = Color3.fromRGB(255, 200, 100)
    FetchResult.Text = "Result"
    FetchResult.Font = Enum.Font.Gotham
    FetchResult.TextSize = 13
    FetchResult.TextEditable = false
    FetchResult.ClearTextOnFocus = false
    FetchResult.Parent = FetchFrame
    Instance.new("UICorner", FetchResult).CornerRadius = UDim.new(0, 6)

    -- 6. Logic Connections
    ExecuteBtn.MouseButton1Click:Connect(function()
        local code = CodeBox.Text
        local func, err = loadstring(code)
        if func then
            local success, runErr = pcall(func)
            if not success then
                warn("Runtime Error: " .. tostring(runErr))
            end
        else
            warn("Syntax Error: " .. tostring(err))
        end
    end)

    function Save()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/BlackfireSoon/Build-Island-Library/refs/heads/main/savebuild.lua'))()
end

    SaveBtn.MouseButton1Click:Connect(function()
        if getgenv().Save then
            getgenv().Save()
        else
            -- Fallback in case globals aren't passing cleanly
            Save()
        end
    end)

    FetchBtn.MouseButton1Click:Connect(function()
        local blockName = BlockInput.Text
        -- getBlock is loaded globally by the library
        local success, id = pcall(function()
            -- Access the global environment function
            return getfenv().getBlock(blockName) or getgenv().getBlock(blockName)
        end)
        
        if success and id then
            FetchResult.Text = tostring(id)
        else
            FetchResult.Text = "Not Found"
        end
    end)
end
