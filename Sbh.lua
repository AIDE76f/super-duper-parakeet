-- ==========================================
-- 🎯 Standalone Smart Aim Bot
-- Features: Smart Aim, FOV, Smooth, Trigger Bot,
--           Hitbox Expander, Wall Bang, Line of Sight
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- ⚙️ الإعدادات
-- ==========================================
local Settings = {
    Enabled = false,
    ShowFOV = true,
    FOV_Radius = 120,
    SmoothSpeed = "Medium", -- Slow / Medium / Fast / Instant
    SmoothValues = {
        Slow = 0.05,
        Medium = 0.15,
        Fast = 0.35,
        Instant = 1
    },
    TriggerBot = false,
    HitboxExpander = false,
    HitboxSize = 25,
    WallBang = false,
    TeamCheck = true,
    Friends = {},
}

-- ترتيب أولوية الأجزاء: الرأس أولاً ثم الجسم
local TargetPartsPriority = {
    "Head", "UpperTorso", "Torso", "LowerTorso",
    "RightUpperArm", "RightArm", "LeftUpperArm", "LeftArm",
    "RightLowerArm", "LeftLowerArm"
}

-- ==========================================
-- 🎨 الواجهة
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StandaloneAimbot"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- دائرة FOV
local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(0, Settings.FOV_Radius * 2, 0, Settings.FOV_Radius * 2)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Parent = ScreenGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVCircle)
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5

-- الإطار الرئيسي
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 300)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(60, 60, 75)
MainStroke.Thickness = 1

-- شريط العنوان
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 12)
TitleCover.Position = UDim2.new(0, 0, 1, -12)
TitleCover.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎯 Smart Aim Bot"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- حاوية العناصر
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -12, 1, -48)
Content.Position = UDim2.new(0, 6, 0, 42)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 2
Content.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end)

-- ==========================================
-- 🧩 عناصر التحكم
-- ==========================================
local function CreateToggle(text, callback, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 14, 0, 14)
    indicator.Position = UDim2.new(1, -22, 0.5, -7)
    indicator.BackgroundColor3 = initial and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local state = initial or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(indicator, TweenInfo.new(0.2),
            {BackgroundColor3 = state and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)}):Play()
        callback(state)
    end)

    return btn
end

local function CreateInput(text, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    container.Parent = Content
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.35, 0, 0.6, 0)
    box.Position = UDim2.new(0.62, 0, 0.2, 0)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    box.Text = placeholder
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then callback(num) else box.Text = placeholder end
    end)
end

local function CreateDropdown(text, options, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    container.ClipsDescendants = false
    container.Parent = Content
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.4, 0, 0.7, 0)
    dropdownBtn.Position = UDim2.new(0.57, 0, 0.15, 0)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    dropdownBtn.Text = default
    dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownBtn.Font = Enum.Font.GothamSemibold
    dropdownBtn.TextSize = 9
    dropdownBtn.AutoButtonColor = false
    dropdownBtn.Parent = container
    Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 4)

    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(0.4, 0, 0, #options * 22)
    optionsFrame.Position = UDim2.new(0.57, 0, 0, 34)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 10
    optionsFrame.Parent = container
    Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 4)

    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Parent = optionsFrame

    for _, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 22)
        optionBtn.BackgroundTransparency = 1
        optionBtn.Text = option
        optionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.TextSize = 9
        optionBtn.ZIndex = 10
        optionBtn.Parent = optionsFrame

        optionBtn.MouseButton1Click:Connect(function()
            dropdownBtn.Text = option
            optionsFrame.Visible = false
            callback(option)
        end)
        optionBtn.MouseEnter:Connect(function()
            optionBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            optionBtn.BackgroundTransparency = 0.3
        end)
        optionBtn.MouseLeave:Connect(function()
            optionBtn.BackgroundTransparency = 1
        end)
    end

    dropdownBtn.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
    end)
end

-- ==========================================
-- 🎛️ تعبئة القائمة
-- ==========================================
CreateToggle("Enable Aimbot", function(s) Settings.Enabled = s end, Settings.Enabled)
CreateDropdown("Smooth Speed", {"Slow", "Medium", "Fast", "Instant"}, Settings.SmoothSpeed, function(val)
    Settings.SmoothSpeed = val
end)
CreateToggle("Trigger Bot", function(s) Settings.TriggerBot = s end, Settings.TriggerBot)
CreateToggle("Hitbox Expander", function(s) Settings.HitboxExpander = s end, Settings.HitboxExpander)
CreateInput("Hitbox Size:", "25", function(val) Settings.HitboxSize = val end)
CreateToggle("Wall Bang (shoot through walls)", function(s) Settings.WallBang = s end, Settings.WallBang)
CreateToggle("Team Check", function(s) Settings.TeamCheck = s end, Settings.TeamCheck)
CreateToggle("Show FOV Circle", function(s)
    Settings.ShowFOV = s
    FOVCircle.Visible = s
end, Settings.ShowFOV)
CreateInput("FOV Radius:", "120", function(val)
    Settings.FOV_Radius = val
    FOVCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
end)

-- ==========================================
-- 🖱️ نظام السحب
-- ==========================================
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- تصغير / إغلاق
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = isMinimized and UDim2.new(0, 260, 0, 36) or UDim2.new(0, 260, 0, 300)}):Play()
    MinBtn.Text = isMinimized and "+" or "−"
end)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    Settings.TriggerBot = false
    Settings.HitboxExpander = false
    ScreenGui:Destroy()
end)

-- ==========================================
-- 🔍 التحقق من خط الرؤية (Line of Sight)
-- ==========================================
local function HasLineOfSight(targetPosition, targetCharacter)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPosition - rayOrigin)
    local distance = rayDirection.Magnitude
    rayDirection = rayDirection.Unit * distance

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = false

    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

    if rayResult then
        -- إذا كان الجزء المصاب ينتمي للاعب المستهدف = لدينا خط رؤية
        if targetCharacter and rayResult.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        return false
    end

    -- لم يصطدم بشيء = الرؤية مفتوحة
    return true
end

-- ==========================================
-- 🎯 الحصول على أفضل هدف
-- ==========================================
local function GetBestTarget()
    local bestTarget = nil
    local shortestDist = Settings.Aimbot and Settings.FOV_Radius or Settings.FOV_Radius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not Settings.Friends[player.UserId] then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Team check
                local skip = false
                if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    skip = true
                end

                if not skip then
                    for _, partName in ipairs(TargetPartsPriority) do
                        local part = player.Character:FindFirstChild(partName)
                        if part then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen and screenPos.Z > 0 then
                                local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if distFromCenter <= shortestDist then
                                    -- Wall Bang مفعّل = تجاهل فحص الجدار
                                    if Settings.WallBang then
                                        shortestDist = distFromCenter
                                        bestTarget = part
                                        break
                                    else
                                        if HasLineOfSight(part.Position, player.Character) then
                                            shortestDist = distFromCenter
                                            bestTarget = part
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- ==========================================
-- ⚙️ الحلقة الرئيسية للتصويب
-- ==========================================
RunService:BindToRenderStep("StandaloneAimbotCore", Enum.RenderPriority.Camera.Value + 1, function()
    -- تصويب سلس
    if Settings.Enabled then
        local targetPart = GetBestTarget()
        if targetPart then
            local smoothValue = Settings.SmoothValues[Settings.SmoothSpeed] or 0.15
            local targetPosition = targetPart.Position
            local newLookAt = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(newLookAt, smoothValue)
        end
    end

    -- Trigger Bot (ضغط تلقائي عند وجود هدف)
    if Settings.TriggerBot then
        local targetPart = GetBestTarget()
        if targetPart then
            VirtualUser:ClickButton1(Vector2.new())
        end
    end

    -- Hitbox Expander
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local skip = Settings.Friends[player.UserId]
                if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    skip = true
                end

                if not skip then
                    if Settings.HitboxExpander then
                        local s = Settings.HitboxSize
                        hrp.Size = Vector3.new(s, s, s)
                        hrp.Transparency = 0.7
                        hrp.BrickColor = BrickColor.new("Bright red")
                        hrp.Material = Enum.Material.ForceField
                        hrp.CanCollide = false
                    else
                        if hrp:GetAttribute("AimbotExpanded") then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.Transparency = 1
                            hrp.Material = Enum.Material.Plastic
                            hrp:SetAttribute("AimbotExpanded", nil)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- ⌨️ اختصار لتشغيل/إيقاف (Right Alt)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Settings.Enabled = not Settings.Enabled
        -- تحديث بصري للمؤشر
        -- يمكنك ربطه بالـ Toggle إذا أردت
    end
end)

print("🎯 Standalone Smart Aim Bot Loaded")
