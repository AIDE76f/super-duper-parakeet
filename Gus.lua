
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local normalSpeed = 16
local activeMultiplier = 1

local old = playerGui:FindFirstChild("BloxFruitsSpeedUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BloxFruitsSpeedUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function create(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local red = Color3.fromRGB(180, 35, 45)
local gold = Color3.fromRGB(238, 186, 80)
local dark = Color3.fromRGB(20, 20, 25)
local panel = Color3.fromRGB(32, 32, 40)
local white = Color3.fromRGB(245, 245, 245)

local frame = create("Frame", {
    Size = UDim2.fromOffset(300, 250),
    Position = UDim2.new(0.5, -150, 0.45, -125),
    BackgroundColor3 = dark,
    BorderSizePixel = 0,
    Active = true
}, gui)
round(frame, 12)

create("UIStroke", {
    Color = gold,
    Thickness = 1.3,
    Transparency = 0.15
}, frame)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 43),
    BackgroundColor3 = red,
    BorderSizePixel = 0,
    Active = true
}, frame)
round(header, 12)

create("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = red,
    BorderSizePixel = 0
}, header)

create("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "BLOX FRUITS  |  SPEED",
    TextColor3 = white,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local minimize = create("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -65, 0, 6),
    BackgroundColor3 = Color3.fromRGB(120, 25, 33),
    Text = "—",
    TextColor3 = white,
    Font = Enum.Font.GothamBold,
    TextSize = 17
}, header)
round(minimize, 7)

local close = create("TextButton", {
    Size = UDim2.fromOffset(27, 30),
    Position = UDim2.new(1, -32, 0, 6),
    BackgroundColor3 = Color3.fromRGB(120, 25, 33),
    Text = "X",
    TextColor3 = white,
    Font = Enum.Font.GothamBold,
    TextSize = 13
}, header)
round(close, 7)

create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.fromOffset(12, 48),
    BackgroundTransparency = 1,
    Text = "PLAYER MOVEMENT MULTIPLIER",
    TextColor3 = gold,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local input = create("TextBox", {
    Size = UDim2.new(1, -24, 0, 38),
    Position = UDim2.fromOffset(12, 76),
    BackgroundColor3 = panel,
    TextColor3 = white,
    PlaceholderColor3 = Color3.fromRGB(155, 155, 165),
    PlaceholderText = "Enter multiplier...",
    Text = "1",
    ClearTextOnFocus = false,
    Font = Enum.Font.GothamBold,
    TextSize = 16
}, frame)
round(input, 7)

create("UIStroke", {
    Color = Color3.fromRGB(75, 75, 87),
    Thickness = 1
}, input)

local function button(text, x, width, color, y, parent)
    local b = create("TextButton", {
        Size = UDim2.new(0, width, 0, 35),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = white,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = true
    }, parent)
    round(b, 7)
    return b
end

local apply = button("APPLY SPEED", 12, 170, red, 124, frame)
local reset = button("RESET", 190, 98, Color3.fromRGB(70, 70, 82), 124, frame)

local presets = {
    {text = "×1", value = 1},
    {text = "×2", value = 2},
    {text = "×5", value = 5},
    {text = "×10", value = 10}
}

for i, preset in ipairs(presets) do
    local b = button(
        preset.text,
        12 + (i - 1) * 70,
        64,
        panel,
        168,
        frame
    )
    b.TextColor3 = gold

    b.Activated:Connect(function()
        input.Text = tostring(preset.value)
    end)
end

local status = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 214),
    BackgroundTransparency = 1,
    Text = "READY  |  SPEED: ×1",
    TextColor3 = gold,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local function setSpeed(multiplier)
    if multiplier <= 0 or multiplier ~= multiplier
        or multiplier == math.huge then
        status.Text = "ERROR  |  INVALID SPEED"
        status.TextColor3 = red
        return
    end

    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        status.Text = "WAITING FOR CHARACTER"
        return
    end

    activeMultiplier = multiplier
    humanoid.WalkSpeed = normalSpeed * multiplier

    status.Text = "ACTIVE  |  SPEED: ×" .. tostring(multiplier)
    status.TextColor3 = gold
end

apply.Activated:Connect(function()
    local multiplier = tonumber(input.Text)

    if multiplier then
        setSpeed(multiplier)
    else
        status.Text = "ERROR  |  ENTER A NUMBER"
        status.TextColor3 = red
    end
end)

reset.Activated:Connect(function()
    input.Text = "1"
    setSpeed(1)
end)

player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = normalSpeed * activeMultiplier
end)

local minimized = false

minimize.Activated:Connect(function()
    minimized = not minimized

    for _, child in ipairs(frame:GetChildren()) do
        if child ~= header and child ~= frame:FindFirstChildOfClass("UIStroke") then
            child.Visible = not minimized
        end
    end

    frame.Size = minimized
        and UDim2.fromOffset(300, 43)
        or UDim2.fromOffset(300, 250)

    minimize.Text = minimized and "+" or "—"
end)

close.Activated:Connect(function()
    gui:Destroy()
end)

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = inputObject.Position
        startPosition = frame.Position
    end
end)

UIS.InputChanged:Connect(function(inputObject)
    if dragging and (
        inputObject.UserInputType == Enum.UserInputType.MouseMovement
        or inputObject.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = inputObject.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
