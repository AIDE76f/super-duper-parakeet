local Players = game:GetService("Players")
local player = Players.LocalPlayer

local BASE_SPEED = 16
local currentMultiplier = 5

local gui = Instance.new("ScreenGui")
gui.Name = "HassanSpeedHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0.82, 0, 0, 250)
main.Position = UDim2.new(0.09, 0, 0.32, 0)
main.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 120, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.15
stroke.Parent = main

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)
padding.Parent = main

local function createText(className, name, text, size, position)
    local obj = Instance.new(className)
    obj.Name = name
    obj.Size = size
    obj.Position = position
    obj.BackgroundTransparency = 1
    obj.Text = text
    obj.TextColor3 = Color3.fromRGB(245, 247, 255)
    obj.Font = Enum.Font.GothamBold
    obj.TextSize = 14
    obj.Parent = main
    return obj
end

local title = createText(
    "TextLabel", "Title", "HASSAN SPEED HUB",
    UDim2.new(1, -35, 0, 32),
    UDim2.new(0, 0, 0, 10)
)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 17

local subtitle = createText(
    "TextLabel", "Subtitle", "WALK SPEED CONTROL",
    UDim2.new(1, 0, 0, 20),
    UDim2.new(0, 0, 0, 41)
)
subtitle.TextColor3 = Color3.fromRGB(135, 155, 190)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextSize = 10

local close = Instance.new("TextButton")
close.Name = "Close"
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -30, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 22
close.Font = Enum.Font.Gotham
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local label = createText(
    "TextLabel", "SpeedLabel", "SPEED MULTIPLIER",
    UDim2.new(1, 0, 0, 22),
    UDim2.new(0, 0, 0, 76)
)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextSize = 11

local input = Instance.new("TextBox")
input.Name = "SpeedInput"
input.Size = UDim2.new(1, 0, 0, 43)
input.Position = UDim2.new(0, 0, 0, 102)
input.BackgroundColor3 = Color3.fromRGB(29, 34, 47)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.PlaceholderText = "Enter multiplier, e.g. 5"
input.PlaceholderColor3 = Color3.fromRGB(125, 135, 155)
input.Text = "5"
input.TextSize = 16
input.Font = Enum.Font.GothamBold
input.ClearTextOnFocus = false
input.Parent = main
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 9)

local function createButton(name, text, position, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0.5, -5, 0, 40)
    button.Position = position
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
    return button
end

local apply = createButton(
    "Apply", "APPLY SPEED",
    UDim2.new(0, 0, 0, 158),
    Color3.fromRGB(45, 110, 245)
)

local reset = createButton(
    "Reset", "RESET ×1",
    UDim2.new(0.5, 5, 0, 158),
    Color3.fromRGB(47, 53, 68)
)

local status = createText(
    "TextLabel", "Status", "READY  •  5x",
    UDim2.new(1, 0, 0, 22),
    UDim2.new(0, 0, 0, 205)
)
status.TextColor3 = Color3.fromRGB(100, 220, 155)
status.TextSize = 11

local function applySpeed(multiplier)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        status.Text = "CHARACTER NOT READY"
        return
    end

    currentMultiplier = multiplier
    humanoid.WalkSpeed = BASE_SPEED * multiplier
    status.Text = "ACTIVE  •  " .. tostring(multiplier) .. "x"
end

apply.Activated:Connect(function()
    local multiplier = tonumber(input.Text)

    if multiplier and multiplier > 0
        and multiplier < math.huge
        and multiplier == multiplier then
        applySpeed(multiplier)
    else
        status.Text = "ENTER A VALID POSITIVE NUMBER"
    end
end)

reset.Activated:Connect(function()
    input.Text = "1"
    applySpeed(1)
end)

player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = BASE_SPEED * currentMultiplier
    status.Text = "ACTIVE  •  " .. tostring(currentMultiplier) .. "x"
end)

close.Activated:Connect(function()
    gui:Destroy()
end)

if player.Character then
    applySpeed(currentMultiplier)
end
