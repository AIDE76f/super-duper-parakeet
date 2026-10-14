
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    Accent = Color3.fromRGB(235, 45, 65),
    Background = Color3.fromRGB(18, 18, 23),
    Panel = Color3.fromRGB(29, 29, 36),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(160, 160, 175),
    BaseSpeed = 16,
    MaxMultiplier = 10,
}

local State = {
    ESP = false,
    Speed = false,
    Multiplier = 2,
    Highlights = {},
    Connections = {},
}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(State.Connections, connection)
    return connection
end

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local Screen = Create("ScreenGui", {
    Name = "HassanHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(370, 390),
    Position = UDim2.new(0.5, -185, 0.5, -195),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
}, Screen)

Create("UICorner", {CornerRadius = UDim.new(0, 12)}, Main)

Create("UIStroke", {
    Color = Config.Accent,
    Thickness = 1.5,
    Transparency = 0.2,
}, Main)

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = Config.Panel,
    BorderSizePixel = 0,
}, Main)

Create("UICorner", {CornerRadius = UDim.new(0, 12)}, Header)

Create("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = Config.Panel,
    BorderSizePixel = 0,
}, Header)

Create("TextLabel", {
    Position = UDim2.fromOffset(16, 0),
    Size = UDim2.new(1, -110, 1, 0),
    BackgroundTransparency = 1,
    Text = "HASSAN HUB",
    TextColor3 = Config.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local Close = Create("TextButton", {
    Position = UDim2.new(1, -44, 0, 10),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Config.Accent,
    Text = "×",
    TextColor3 = Config.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 23,
    AutoButtonColor = true,
}, Header)

Create("UICorner", {CornerRadius = UDim.new(0, 8)}, Close)

local Floating = Create("TextButton", {
    Visible = false,
    Position = UDim2.new(0, 18, 0.5, -24),
    Size = UDim2.fromOffset(52, 48),
    BackgroundColor3 = Config.Accent,
    Text = "H",
    TextColor3 = Config.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    ZIndex = 10,
}, Screen)

Create("UICorner", {CornerRadius = UDim.new(0, 14)}, Floating)

local function SetVisible(visible)
    Main.Visible = visible
    Floating.Visible = not visible
end

Connect(Close.Activated, function()
    SetVisible(false)
end)

Connect(Floating.Activated, function()
    SetVisible(true)
end)

Connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        SetVisible(not Main.Visible)
    end
end)

local dragging = false
local dragStart
local startPosition

Connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local Content = Create("Frame", {
    Position = UDim2.fromOffset(12, 64),
    Size = UDim2.new(1, -24, 1, -76),
    BackgroundTransparency = 1,
}, Main)

Create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Content)

local function Section(title)
    return Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Content)
end

local function Button(text)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Config.Panel,
        Text = text,
        TextColor3 = Config.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = true,
    }, Content)

    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, button)
    return button
end

local function StatusButton(name, enabled)
    local button = Button(name .. ": " .. (enabled and "ON" or "OFF"))
    button.TextColor3 = enabled and Config.Accent or Config.Text

    return button
end

Section("PLAYER ESP")

local ESPButton = StatusButton("Player ESP", false)

local function RemoveHighlight(player)
    local highlight = State.Highlights[player]
    if highlight then
        highlight:Destroy()
        State.Highlights[player] = nil
    end
end

local function ApplyHighlight(player)
    if not State.ESP or player == LocalPlayer then
        return
    end

    RemoveHighlight(player)

    local character = player.Character
    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "HassanHubESP"
    highlight.Adornee = character
    highlight.FillColor = Config.Accent
    highlight.OutlineColor = Color3.fromRGB(255, 90, 100)
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    State.Highlights[player] = highlight
end

local function RefreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if State.ESP then
                ApplyHighlight(player)
            else
                RemoveHighlight(player)
            end
        end
    end
end

Connect(ESPButton.Activated, function()
    State.ESP = not State.ESP
    ESPButton.Text = "Player ESP: " .. (State.ESP and "ON" or "OFF")
    ESPButton.TextColor3 = State.ESP and Config.Accent or Config.Text
    RefreshESP()
end)

local function TrackPlayer(player)
    Connect(player.CharacterAdded, function()
        task.wait(0.3)
        if State.ESP then
            ApplyHighlight(player)
        end
    end)

    Connect(player.CharacterRemoving, function()
        RemoveHighlight(player)
    end)

    if player.Character and State.ESP then
        ApplyHighlight(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        TrackPlayer(player)
    end
end

Connect(Players.PlayerAdded, function(player)
    TrackPlayer(player)
end)

Connect(Players.PlayerRemoving, function(player)
    RemoveHighlight(player)
end)

Section("SPEED CHANGER")

local SpeedInput = Create("TextBox", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Config.Panel,
    Text = "2x",
    PlaceholderText = "Multiplier: 2x, 5x, 10x",
    TextColor3 = Config.Text,
    PlaceholderColor3 = Config.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ClearTextOnFocus = false,
}, Content)

Create("UICorner", {CornerRadius = UDim.new(0, 8)}, SpeedInput)

local SpeedStatus = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Text = "Speed: 16 | Multiplier: 1x",
    TextColor3 = Config.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Content)

local function GetHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function UpdateSpeed()
    local humanoid = GetHumanoid()
    if not humanoid then
        SpeedStatus.Text = "Speed: waiting for character"
        return
    end

    local multiplier = State.Speed and State.Multiplier or 1
    humanoid.WalkSpeed = Config.BaseSpeed * multiplier

    SpeedStatus.Text = string.format(
        "Speed: %g | Multiplier: %gx",
        humanoid.WalkSpeed,
        multiplier
    )
end

local SpeedButton = StatusButton("Speed Changer", false)
local ApplyButton = Button("Apply Speed")
local ResetButton = Button("Reset Speed")

Connect(SpeedButton.Activated, function()
    State.Speed = not State.Speed
    SpeedButton.Text = "Speed Changer: " .. (State.Speed and "ON" or "OFF")
    SpeedButton.TextColor3 = State.Speed and Config.Accent or Config.Text

    UpdateSpeed()
end)

Connect(ApplyButton.Activated, function()
    local raw = SpeedInput.Text:lower():gsub("%s+", "")
    local numberText = raw:gsub("x$", "")
    local multiplier = tonumber(numberText)

    if not multiplier
        or multiplier ~= multiplier
        or multiplier < 1
        or multiplier > Config.MaxMultiplier
        or multiplier == math.huge
    then
        SpeedStatus.Text = "Invalid multiplier (1x - 10x)"
        return
    end

    State.Multiplier = multiplier
    State.Speed = true

    SpeedButton.Text = "Speed Changer: ON"
    SpeedButton.TextColor3 = Config.Accent

    UpdateSpeed()
end)

Connect(ResetButton.Activated, function()
    State.Speed = false
    State.Multiplier = 1
    SpeedInput.Text = "1x"

    SpeedButton.Text = "Speed Changer: OFF"
    SpeedButton.TextColor3 = Config.Text

    UpdateSpeed()
end)

Connect(LocalPlayer.CharacterAdded, function(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        UpdateSpeed()
    end
end)

if LocalPlayer.Character then
    UpdateSpeed()
end

Connect(Screen.Destroying, function()
    for _, connection in ipairs(State.Connections) do
        connection:Disconnect()
    end

    for player in pairs(State.Highlights) do
        RemoveHighlight(player)
    end
end)
