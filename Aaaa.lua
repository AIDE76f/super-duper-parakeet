local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Config = {
    Version = "2.7",
    Background = Color3.fromRGB(15, 16, 21),
    Sidebar = Color3.fromRGB(20, 21, 28),
    Panel = Color3.fromRGB(27, 28, 36),
    PanelHover = Color3.fromRGB(37, 38, 48),
    Accent = Color3.fromRGB(239, 49, 68),
    IconRed = Color3.fromRGB(255, 0, 28),
    AccentDark = Color3.fromRGB(168, 30, 49),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(151, 154, 171),
    Border = Color3.fromRGB(53, 54, 66),

    Aimbot = {
        SmoothValues = {Slow = 0.05, Medium = 0.15, Fast = 0.35},
        TargetParts = {"Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"},
    },
}

local AimbotRenderBindingName = "HassanHubAimbot_" .. tostring(LocalPlayer.UserId)

local State = {
    Destroyed = false,
    ESP = false,
    Speed = false,
    TargetSpeed = nil,
    BaseSpeed = 16,
    FillTransparency = 0.35,
    OutlineTransparency = 0,
    Highlights = {},
    Connections = {},
    PlayerConnections = {},
    CurrentPage = "Overview",
    UpdatingSpeedInput = false,

    JumpEnabled = false,
    TargetJumpPower = nil,
    BaseJumpPower = 50,
    BaseJumpHeight = 7.2,
    BaseUseJumpPower = true,
    UpdatingJumpInput = false,

    AimbotEnabled = false,
    AimbotShowFOV = false,
    AimbotFOVRadius = 120,
    AimbotSmoothSpeed = "Medium",
    AimbotWallBang = false,
    AimbotTriggerBot = false,
    HitboxExpander = false,
    HitboxSize = 25,
    HitboxOriginalSizes = {},
}

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function Connect(signal, callback)
    local connection = signal:Connect(function(...)
        if not State.Destroyed then
            callback(...)
        end
    end)
    table.insert(State.Connections, connection)
    return connection
end

local function ConnectPlayer(player, signal, callback)
    State.PlayerConnections[player] = State.PlayerConnections[player] or {}
    local connection = signal:Connect(function(...)
        if not State.Destroyed and player.Parent == Players then
            callback(...)
        end
    end)
    table.insert(State.PlayerConnections[player], connection)
    return connection
end

local function DisconnectPlayer(player)
    local connections = State.PlayerConnections[player]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    State.PlayerConnections[player] = nil
end

local function Corner(parent, radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function Stroke(parent, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or Config.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function Label(parent, text, position, size, options)
    options = options or {}
    return Create("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = options.Color or Config.Text,
        TextSize = options.TextSize or 13,
        Font = options.Font or Enum.Font.Gotham,
        TextXAlignment = options.Align or Enum.TextXAlignment.Left,
        TextYAlignment = options.VerticalAlign or Enum.TextYAlignment.Center,
        TextWrapped = options.Wrapped or false,
        TextTruncate = options.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
        RichText = false,
    }, parent)
end

local function ActionButton(parent, text, position, size, primary)
    local baseColor = primary and Config.Accent or Config.Panel
    local hoverColor = primary and Config.AccentDark or Config.PanelHover
    local button = Create("TextButton", {
        Position = position,
        Size = size,
        BackgroundColor3 = baseColor,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Config.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, parent)
    Corner(button, 9)
    Connect(button.MouseEnter, function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
    end)
    Connect(button.MouseLeave, function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
    end)
    return button
end

local function InputBox(parent, value, placeholder, position, size)
    local input = Create("TextBox", {
        Position = position,
        Size = size,
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        Text = value or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Config.Muted,
        TextColor3 = Config.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, parent)
    Corner(input, 8)
    Stroke(input, Config.Border, 0.15, 1)
    Connect(input.Focused, function()
        TweenService:Create(input, TweenInfo.new(0.12), {BackgroundColor3 = Config.Panel}):Play()
    end)
    Connect(input.FocusLost, function()
        TweenService:Create(input, TweenInfo.new(0.12), {BackgroundColor3 = Config.Background}):Play()
    end)
    return input
end

local function ToggleRow(parent, text, initial, callback)
    local row = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    Corner(row, 8)
    Stroke(row, Config.Border, 0.15, 1)
    Label(row, text, UDim2.fromOffset(12, 0), UDim2.new(1, -70, 1, 0), {
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
    })
    local track = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        BackgroundColor3 = initial and Config.Accent or Config.Panel,
        BorderSizePixel = 0,
    }, row)
    Corner(track, 10)
    local knob = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = initial and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    Corner(knob, 7)

    local state = initial
    local function render()
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Config.Accent or Config.Panel,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        }):Play()
    end
    Connect(row.Activated, function()
        state = not state
        render()
        callback(state)
    end)
    return row
end

local function DropdownRow(parent, options, default, callback)
    local btn = Create("TextButton", {
        Size = UDim2.new(0, 110, 0, 28),
        Position = UDim2.new(1, -110, 0.5, -14),
        BackgroundColor3 = Config.Panel,
        BorderSizePixel = 0,
        Text = default,
        TextColor3 = Config.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 3,
    }, parent)
    Corner(btn, 6)

    local list = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -110, 0, 32),
        Size = UDim2.new(0, 110, 0, #options * 22 + 4),
        BackgroundColor3 = Config.Panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 60,
    }, parent)
    Corner(list, 6)
    Stroke(list, Config.Border, 0.15, 1)
    Create("UIListLayout", {Padding = UDim.new(0, 2)}, list)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    }, list)

    for _, option in ipairs(options) do
        local opt = Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 20),
            BackgroundColor3 = Config.Background,
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = Config.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 60,
        }, list)
        Corner(opt, 4)
        Connect(opt.MouseEnter, function()
            TweenService:Create(opt, TweenInfo.new(0.1), {BackgroundColor3 = Config.Accent}):Play()
        end)
        Connect(opt.MouseLeave, function()
            TweenService:Create(opt, TweenInfo.new(0.1), {BackgroundColor3 = Config.Background}):Play()
        end)
        Connect(opt.Activated, function()
            btn.Text = option
            list.Visible = false
            callback(option)
        end)
    end

    Connect(btn.Activated, function()
        list.Visible = not list.Visible
    end)
    return btn
end

local PreviousScreen = PlayerGui:FindFirstChild("HassanHubUI")
if PreviousScreen then
    PreviousScreen:Destroy()
end

local Screen = Create("ScreenGui", {
    Name = "HassanHubUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local FOVCircle = Create("Frame", {
    Name = "HassanFOVCircle",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(State.AimbotFOVRadius * 2, State.AimbotFOVRadius * 2),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 10,
}, Screen)
Corner(FOVCircle, 9999)
Create("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 1.5,
    Transparency = 0.2,
}, FOVCircle)

local Main = Create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(780, 520),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Screen)
Corner(Main, 16)
local MainStroke = Stroke(Main, Config.Border, 0.05, 1)

local UIScale = Create("UIScale", {Scale = 1}, Main)
local ResponsiveScale = 1
local WindowTransitioning = false
local MainContent
local ExpandedPosition = Main.Position

local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local fitScale = math.min((viewport.X - 24) / 780, (viewport.Y - 24) / 520)
    ResponsiveScale = fitScale >= 1 and 1 or math.clamp(fitScale, 0.42, 0.99)
    if not WindowTransitioning then
        UIScale.Scale = ResponsiveScale
    end
end
UpdateScale()
if workspace.CurrentCamera then
    Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), UpdateScale)
end

local Header = Create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 65),
    BackgroundColor3 = Config.Panel,
    BorderSizePixel = 0,
}, Main)
Corner(Header, 16)
Create("Frame", {
    Position = UDim2.new(0, 0, 1, -14),
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = Config.Panel,
    BorderSizePixel = 0,
}, Header)
local AccentLine = Create("Frame", {
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
}, Header)
Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.AccentDark),
        ColorSequenceKeypoint.new(0.48, Config.Accent),
        ColorSequenceKeypoint.new(1, Config.AccentDark),
    }),
}, AccentLine)

local Logo = Create("TextButton", {
    Position = UDim2.fromOffset(18, 12),
    Size = UDim2.fromOffset(40, 40),
    BackgroundColor3 = Config.IconRed,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Text = "H",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextTransparency = 0,
    TextStrokeColor3 = Color3.fromRGB(115, 0, 15),
    TextStrokeTransparency = 1,
    TextSize = 24,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
}, Header)
Corner(Logo, 12)

Label(Header, "HASSAN HUB", UDim2.fromOffset(70, 10), UDim2.fromOffset(220, 28), {
    TextSize = 19,
    Font = Enum.Font.GothamBlack,
})
Label(Header, "CONTROL CENTER  •  " .. Config.Version, UDim2.fromOffset(71, 36), UDim2.fromOffset(230, 17), {
    TextSize = 10,
    Color = Config.Muted,
    Font = Enum.Font.GothamMedium,
})

local SessionBadge = Create("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -102, 0.5, 0),
    Size = UDim2.fromOffset(112, 28),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
}, Header)
Corner(SessionBadge, 8)
Stroke(SessionBadge, Config.Border, 0.15, 1)
local SessionDot = Create("Frame", {
    Position = UDim2.fromOffset(10, 11),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = Color3.fromRGB(84, 220, 135),
    BorderSizePixel = 0,
}, SessionBadge)
Corner(SessionDot, 5)
Label(SessionBadge, "LOCAL SESSION", UDim2.fromOffset(22, 0), UDim2.new(1, -25, 1, 0), {
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    Color = Config.Muted,
})

local MinimizeButton = ActionButton(Header, "—", UDim2.new(1, -82, 0, 16), UDim2.fromOffset(30, 30), false)
local CloseButton = ActionButton(Header, "×", UDim2.new(1, -43, 0, 16), UDim2.fromOffset(30, 30), true)
MinimizeButton.TextSize = 17
CloseButton.TextSize = 22

local LogoGradient = Logo:FindFirstChildOfClass("UIGradient")
if LogoGradient then
    LogoGradient:Destroy()
end

local LogoOutline = Stroke(Logo, Color3.fromRGB(255, 245, 246), 0, 1.75)
local LogoScale = Create("UIScale", {Scale = 1}, Logo)
local IsMinimized = false
local LastIconPosition = UDim2.new(0, 18, 0.5, 0)
local IconDragging = false
local IconDragged = false
local IconDragInput = nil
local IconDragStart = nil
local IconStartPosition = nil
local PageTweens = {}
local WindowTweens = {}

local function Tween(object, duration, style, direction, properties)
    local info = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function CancelWindowTweens()
    while #WindowTweens > 0 do
        local tween = table.remove(WindowTweens)
        pcall(function() tween:Cancel() end)
    end
end

local function TrackWindowTween(tween)
    table.insert(WindowTweens, tween)
    local completedConnection
    completedConnection = tween.Completed:Connect(function()
        if completedConnection then
            completedConnection:Disconnect()
            completedConnection = nil
        end
        local index = table.find(WindowTweens, tween)
        if index then
            table.remove(WindowTweens, index)
        end
    end)
    tween:Play()
    return tween
end

local function PrepareFloatingLogo()
    Logo.Parent = Screen
    Logo.Name = "FloatingH"
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = LastIconPosition
    Logo.Size = UDim2.fromOffset(56, 54)
    Logo.ZIndex = 100
    Logo.Visible = true
    Logo.BackgroundColor3 = Config.IconRed
    Logo.BackgroundTransparency = 0
    Logo.BorderSizePixel = 0
    Logo.Text = "H"
    Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    Logo.TextTransparency = 0
    Logo.TextStrokeColor3 = Color3.fromRGB(110, 0, 10)
    Logo.TextStrokeTransparency = 1
    Logo.TextSize = 27
    LogoScale.Scale = 0.72
    Logo.Rotation = 0
    LogoOutline.Color = Color3.fromRGB(255, 245, 246)
    LogoOutline.Thickness = 2
    LogoOutline.Transparency = 0
end

local function RestoreHeaderLogo()
    if IsMinimized then
        LastIconPosition = Logo.Position
    end
    Logo.Parent = Header
    Logo.Name = "Logo"
    Logo.AnchorPoint = Vector2.new(0, 0)
    Logo.Position = UDim2.fromOffset(18, 12)
    Logo.Size = UDim2.fromOffset(40, 40)
    Logo.ZIndex = 1
    Logo.Visible = true
    Logo.BackgroundColor3 = Config.IconRed
    Logo.BackgroundTransparency = 0
    Logo.BorderSizePixel = 0
    Logo.Text = "H"
    Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    Logo.TextTransparency = 0
    Logo.TextStrokeColor3 = Color3.fromRGB(110, 0, 10)
    Logo.TextStrokeTransparency = 1
    Logo.TextSize = 24
    Logo.Rotation = 0
    LogoScale.Scale = 1
    LogoOutline.Color = Color3.fromRGB(255, 245, 246)
    LogoOutline.Thickness = 1.75
    LogoOutline.Transparency = 0
end

local function SetVisible(visible)
    if State.Destroyed or WindowTransitioning then return end
    CancelWindowTweens()

    if visible then
        if not IsMinimized and Main.Visible then return end

        WindowTransitioning = true
        if IsMinimized then RestoreHeaderLogo() end
        IsMinimized = false

        Main.Visible = true
        Main.Position = UDim2.new(
            ExpandedPosition.X.Scale,
            ExpandedPosition.X.Offset,
            ExpandedPosition.Y.Scale,
            ExpandedPosition.Y.Offset + 12
        )
        Main.BackgroundTransparency = 1
        MainStroke.Transparency = 1
        UIScale.Scale = ResponsiveScale
        if MainContent then MainContent.GroupTransparency = 1 end

        local moveTween = TrackWindowTween(TweenService:Create(
            Main,
            TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Position = ExpandedPosition, BackgroundTransparency = 0}
        ))
        TrackWindowTween(TweenService:Create(MainStroke, TweenInfo.new(
            0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
        ), {Transparency = 0.05}))
        TrackWindowTween(TweenService:Create(LogoScale, TweenInfo.new(
            0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out
        ), {Scale = 1}))
        TrackWindowTween(TweenService:Create(Logo, TweenInfo.new(
            0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out
        ), {Rotation = 0}))
        if MainContent then
            TrackWindowTween(TweenService:Create(MainContent, TweenInfo.new(
                0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
            ), {GroupTransparency = 0}))
        end

        task.spawn(function()
            moveTween.Completed:Wait()
            if State.Destroyed then return end
            Main.Position = ExpandedPosition
            Main.BackgroundTransparency = 0
            UIScale.Scale = ResponsiveScale
            WindowTransitioning = false
        end)
        return
    end

    if IsMinimized or not Main.Visible then return end

    WindowTransitioning = true
    ExpandedPosition = Main.Position
    IsMinimized = true
    PrepareFloatingLogo()

    TrackWindowTween(TweenService:Create(LogoScale, TweenInfo.new(
        0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out
    ), {Scale = 1}))
    TrackWindowTween(TweenService:Create(Logo, TweenInfo.new(
        0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out
    ), {Rotation = 0}))
    local fadeTween = TrackWindowTween(TweenService:Create(
        Main,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(
                ExpandedPosition.X.Scale,
                ExpandedPosition.X.Offset,
                ExpandedPosition.Y.Scale,
                ExpandedPosition.Y.Offset + 10
            ),
        }
    ))
    TrackWindowTween(TweenService:Create(MainStroke, TweenInfo.new(
        0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In
    ), {Transparency = 1}))
    if MainContent then
        TrackWindowTween(TweenService:Create(MainContent, TweenInfo.new(
            0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In
        ), {GroupTransparency = 1}))
    end

    task.spawn(function()
        fadeTween.Completed:Wait()
        if State.Destroyed then return end
        Main.Visible = false
        Main.Position = ExpandedPosition
        Main.BackgroundTransparency = 0
        MainStroke.Transparency = 0.05
        UIScale.Scale = ResponsiveScale
        if MainContent then MainContent.GroupTransparency = 0 end
        WindowTransitioning = false
    end)
end

Connect(MinimizeButton.Activated, function()
    SetVisible(false)
end)

Connect(Logo.Activated, function()
    if IconDragged then
        IconDragged = false
        return
    end
    if IsMinimized then SetVisible(true) end
end)

Connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        SetVisible(not Main.Visible)
    end
end)

Connect(Logo.InputBegan, function(input)
    if not IsMinimized then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        IconDragging = true
        IconDragged = false
        IconDragInput = input
        IconDragStart = input.Position
        IconStartPosition = Logo.Position
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not IsMinimized or not IconDragging or not IconDragInput then return end
    local shouldMove =
        (IconDragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        or (IconDragInput.UserInputType == Enum.UserInputType.Touch
            and input == IconDragInput)
    if not shouldMove then return end
    local delta = input.Position - IconDragStart
    if delta.Magnitude > 4 then IconDragged = true end
    if IconDragged then
        local nextX = IconStartPosition.X.Offset + delta.X
        local nextY = IconStartPosition.Y.Offset + delta.Y
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            local iconSize = Logo.AbsoluteSize
            nextX = math.clamp(nextX, 0, math.max(0, viewport.X - iconSize.X))
            nextY = math.clamp(
                nextY,
                -viewport.Y * 0.5 + iconSize.Y * 0.5,
                viewport.Y * 0.5 - iconSize.Y * 0.5
            )
        end
        Logo.Position = UDim2.new(
            IconStartPosition.X.Scale,
            nextX,
            IconStartPosition.Y.Scale,
            nextY
        )
        LastIconPosition = Logo.Position
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if IconDragging and IconDragInput then
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input == IconDragInput then
            IconDragging = false
            IconDragInput = nil
        end
    end
end)

Connect(Logo.MouseEnter, function()
    if IsMinimized and not IconDragging and not WindowTransitioning then
        Tween(Logo, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = Color3.fromRGB(255, 24, 48),
        })
        Tween(LogoOutline, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            Thickness = 2.25,
        })
    end
end)

Connect(Logo.MouseLeave, function()
    if IsMinimized and not IconDragging then
        Tween(Logo, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = Config.IconRed,
        })
        Tween(LogoOutline, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            Thickness = 2,
        })
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
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
        ExpandedPosition = Main.Position
    end
end)
Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(12, 77),
    Size = UDim2.new(0, 164, 1, -89),
    BackgroundColor3 = Config.Sidebar,
    BorderSizePixel = 0,
}, Main)
Corner(Sidebar, 12)
Stroke(Sidebar, Config.Border, 0.5, 1)
Label(Sidebar, "MAIN MENU", UDim2.fromOffset(15, 17), UDim2.new(1, -25, 0, 20), {
    TextSize = 10,
    Color = Config.Muted,
    Font = Enum.Font.GothamBold,
})

local PageHost = Create("Frame", {
    Name = "PageHost",
    Position = UDim2.fromOffset(188, 77),
    Size = UDim2.new(1, -200, 1, -89),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Main)

local Pages = {}
local NavButtons = {}

local function CreatePage(key, title, subtitle)
    local page = Create("ScrollingFrame", {
        Name = key,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, PageHost)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 7),
    }, page)
    Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    local intro = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, page)
    Label(intro, title, UDim2.fromOffset(3, 0), UDim2.new(1, -6, 0, 28), {
        TextSize = 22,
        Font = Enum.Font.GothamBold,
    })
    Label(intro, subtitle, UDim2.fromOffset(4, 29), UDim2.new(1, -8, 0, 19), {
        TextSize = 11,
        Color = Config.Muted,
    })
    Pages[key] = page
    return page
end

local function Card(parent, name, height, order)
    local card = Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Config.Panel,
        BorderSizePixel = 0,
        LayoutOrder = order or 2,
        ClipsDescendants = false,
    }, parent)
    Corner(card, 12)
    Stroke(card, Config.Border, 0.35, 1)
    return card
end

local function CreateNav(key, title, symbol, order)
    local button = Create("TextButton", {
        Name = key,
        Position = UDim2.fromOffset(8, 48 + (order - 1) * 49),
        Size = UDim2.new(1, -16, 0, 41),
        BackgroundColor3 = Config.Sidebar,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, Sidebar)
    Corner(button, 9)
    local indicator = Create("Frame", {
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, button)
    Corner(indicator, 3)
    Label(button, symbol, UDim2.fromOffset(10, 0), UDim2.fromOffset(24, 41), {
        TextSize = 15,
        Color = Config.Muted,
        Font = Enum.Font.GothamBold,
        Align = Enum.TextXAlignment.Center,
    })
    Label(button, title, UDim2.fromOffset(40, 0), UDim2.new(1, -46, 1, 0), {
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        Color = Config.Muted,
    })
    NavButtons[key] = {Button = button, Indicator = indicator}
    return button
end

CreateNav("Overview", "Overview", "◈", 1)
CreateNav("Visuals", "Player ESP", "◎", 2)
CreateNav("Movement", "Movement", "↗", 3)
CreateNav("AimRadar", "Aim Radar", "⌖", 4)
Label(Sidebar, "HASSAN HUB  /  " .. Config.Version, UDim2.new(0, 12, 1, -34), UDim2.new(1, -24, 0, 18), {
    TextSize = 9,
    Color = Config.Muted,
    Font = Enum.Font.GothamBold,
    Align = Enum.TextXAlignment.Center,
})

local DisplayedPage

local function ShowPage(key)
    State.CurrentPage = key
    for pageKey, page in pairs(Pages) do
        if pageKey ~= key then
            page.Visible = false
            page.Position = UDim2.fromOffset(0, 0)
        end
        local oldTween = PageTweens[pageKey]
        if oldTween then
            oldTween:Cancel()
            PageTweens[pageKey] = nil
        end
    end
    local selectedPage = Pages[key]
    if selectedPage then
        selectedPage.Visible = true
        if DisplayedPage ~= key then
            selectedPage.Position = UDim2.fromOffset(12, 0)
            PageTweens[key] = Tween(
                selectedPage,
                0.20,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out,
                {Position = UDim2.fromOffset(0, 0)}
            )
        else
            selectedPage.Position = UDim2.fromOffset(0, 0)
        end
    end
    DisplayedPage = key
    for navKey, data in pairs(NavButtons) do
        local active = navKey == key
        data.Indicator.Visible = active
        TweenService:Create(data.Button, TweenInfo.new(0.16), {
            BackgroundColor3 = active and Config.Panel or Config.Sidebar,
        }):Play()
        local textLabel = data.Button:FindFirstChildWhichIsA("TextLabel")
        if textLabel then
            TweenService:Create(textLabel, TweenInfo.new(0.14), {
                TextColor3 = active and Config.Text or Config.Muted,
            }):Play()
        end
    end
end

for key, data in pairs(NavButtons) do
    local pageKey = key
    Connect(data.Button.Activated, function() ShowPage(pageKey) end)
end

local Overview = CreatePage("Overview", "Overview", "Your features and current session at a glance.")
local Visuals = CreatePage("Visuals", "Player ESP", "Configure character highlighting and visual options.")
local Movement = CreatePage("Movement", "Movement", "Set speed and jump strength with instant numeric input.")
local AimRadar = CreatePage("AimRadar", "Aimbot & Hitbox", "FOV-based aimbot with smooth tracking and hitbox expander.")

-- =================== Overview ===================
local Hero = Card(Overview, "WelcomeCard", 136, 2)
Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(73, 23, 36)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(40, 25, 37)),
        ColorSequenceKeypoint.new(1, Config.Panel),
    }),
    Rotation = 12,
}, Hero)
Label(Hero, "WELCOME BACK", UDim2.fromOffset(19, 15), UDim2.new(1, -35, 0, 17), {
    TextSize = 10, Color = Color3.fromRGB(255, 132, 145), Font = Enum.Font.GothamBold,
})
Label(Hero, "Hassan Hub", UDim2.fromOffset(17, 36), UDim2.new(1, -35, 0, 35), {
    TextSize = 27, Font = Enum.Font.GothamBlack,
})
Label(Hero, "A cleaner, faster control interface.", UDim2.fromOffset(19, 75), UDim2.new(1, -35, 0, 22), {
    TextSize = 12, Color = Config.Muted,
})

local StatusGrid = Create("Frame", {
    Name = "StatusGrid",
    Size = UDim2.new(1, 0, 0, 104),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
}, Overview)
local VisualStatusCard = Card(StatusGrid, "VisualStatusCard", 104, 1)
VisualStatusCard.Size = UDim2.new(0.5, -6, 1, 0)
VisualStatusCard.Position = UDim2.fromOffset(0, 0)
local MovementStatusCard = Card(StatusGrid, "MovementStatusCard", 104, 2)
MovementStatusCard.Size = UDim2.new(0.5, -6, 1, 0)
MovementStatusCard.Position = UDim2.new(0.5, 6, 0, 0)
Label(VisualStatusCard, "VISUAL SYSTEM", UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 17), {
    TextSize = 10, Color = Config.Muted, Font = Enum.Font.GothamBold,
})
local OverviewESPStatus = Label(VisualStatusCard, "Player ESP / OFF", UDim2.fromOffset(13, 31), UDim2.new(1, -20, 0, 20), {
    TextSize = 12, Font = Enum.Font.GothamBold,
})
local QuickESPButton = ActionButton(VisualStatusCard, "OPEN SETTINGS", UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 25), false)
QuickESPButton.TextSize = 9
Label(MovementStatusCard, "MOVEMENT SYSTEM", UDim2.fromOffset(13, 10), UDim2.new(1, -26, 0, 17), {
    TextSize = 10, Color = Config.Muted, Font = Enum.Font.GothamBold,
})
local OverviewSpeedStatus = Label(MovementStatusCard, "Speed / DEFAULT", UDim2.fromOffset(13, 31), UDim2.new(1, -20, 0, 20), {
    TextSize = 12, Font = Enum.Font.GothamBold,
})
local QuickSpeedButton = ActionButton(MovementStatusCard, "OPEN SETTINGS", UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 25), false)
QuickSpeedButton.TextSize = 9
local AboutCard = Card(Overview, "AboutCard", 74, 4)
Label(AboutCard, "QUICK TIP", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(AboutCard, "Right Shift toggles the window. Aimbot locks onto players inside the FOV circle.", UDim2.fromOffset(15, 29), UDim2.new(1, -30, 0, 28), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

-- =================== Visuals ===================
local ESPCard = Card(Visuals, "ESPCard", 112, 2)
Label(ESPCard, "Player Highlight", UDim2.fromOffset(16, 13), UDim2.new(1, -175, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(ESPCard, "Highlight other players' characters in red.", UDim2.fromOffset(17, 41), UDim2.new(1, -34, 0, 22), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})
local ESPButton = ActionButton(ESPCard, "ENABLE ESP", UDim2.new(1, -133, 0, 15), UDim2.fromOffset(116, 34), true)
Label(ESPCard, "Applies to other players only.", UDim2.fromOffset(17, 77), UDim2.new(1, -34, 0, 19), {
    TextSize = 10, Color = Config.Muted,
})

local StyleCard = Card(Visuals, "StyleCard", 145, 3)
Label(StyleCard, "Highlight Appearance", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 23), {
    TextSize = 14, Font = Enum.Font.GothamBold,
})
Label(StyleCard, "Fill transparency (%)", UDim2.fromOffset(17, 43), UDim2.fromOffset(135, 18), {
    TextSize = 10, Color = Config.Muted,
})
Label(StyleCard, "Outline transparency (%)", UDim2.fromOffset(165, 43), UDim2.fromOffset(155, 18), {
    TextSize = 10, Color = Config.Muted,
})
local FillInput = InputBox(StyleCard, "35", "0 - 100", UDim2.fromOffset(17, 65), UDim2.fromOffset(125, 34))
local OutlineInput = InputBox(StyleCard, "0", "0 - 100", UDim2.fromOffset(165, 65), UDim2.fromOffset(135, 34))
local ApplyStyleButton = ActionButton(StyleCard, "APPLY STYLE", UDim2.new(1, -139, 0, 65), UDim2.fromOffset(122, 34), true)
local StyleStatus = Label(StyleCard, "Red fill  •  Red outline", UDim2.fromOffset(17, 108), UDim2.new(1, -34, 0, 20), {
    TextSize = 10, Color = Config.Muted,
})

-- =================== Movement ===================
local SpeedCard = Card(Movement, "SpeedCard", 177, 2)
Label(SpeedCard, "WalkSpeed", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(SpeedCard, "Type a number. The value applies automatically; no multiplier or Apply button.", UDim2.fromOffset(17, 40), UDim2.new(1, -34, 0, 30), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})
local SpeedInput = InputBox(SpeedCard, "16", "Speed value", UDim2.fromOffset(17, 78), UDim2.fromOffset(185, 38))
local ResetSpeedButton = ActionButton(SpeedCard, "RESET SPEED", UDim2.fromOffset(215, 78), UDim2.fromOffset(130, 38), false)
local SpeedStatus = Label(SpeedCard, "Current speed: waiting for character", UDim2.fromOffset(17, 128), UDim2.new(1, -34, 0, 20), {
    TextSize = 11, Color = Config.Muted,
})
local SpeedStateText = Label(SpeedCard, "STATUS: DEFAULT", UDim2.fromOffset(17, 150), UDim2.new(1, -34, 0, 18), {
    TextSize = 10, Color = Config.Muted, Font = Enum.Font.GothamBold,
})

local JumpCard = Card(Movement, "JumpCard", 177, 3)
Label(JumpCard, "Power Jump", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(JumpCard, "Type a numeric jump-power value. Valid values apply automatically.", UDim2.fromOffset(17, 40), UDim2.new(1, -34, 0, 30), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})
local JumpInput = InputBox(JumpCard, "50", "Jump power value", UDim2.fromOffset(17, 78), UDim2.fromOffset(185, 38))
local ResetJumpButton = ActionButton(JumpCard, "RESET JUMP", UDim2.fromOffset(215, 78), UDim2.fromOffset(130, 38), false)
local JumpStatus = Label(JumpCard, "Current jump power: waiting for character", UDim2.fromOffset(17, 128), UDim2.new(1, -34, 0, 20), {
    TextSize = 11, Color = Config.Muted,
})
local JumpStateText = Label(JumpCard, "STATUS: DEFAULT", UDim2.fromOffset(17, 150), UDim2.new(1, -34, 0, 18), {
    TextSize = 10, Color = Config.Muted, Font = Enum.Font.GothamBold,
})

local SpeedInfo = Card(Movement, "SpeedInfo", 79, 4)
Label(SpeedInfo, "HOW IT WORKS", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(SpeedInfo, "Speed and jump values are absolute numbers (not multipliers). Reset restores the captured character defaults.", UDim2.fromOffset(15, 30), UDim2.new(1, -30, 0, 36), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

-- =================== Aim Radar (Aimbot + Hitbox) ===================
local AimbotCard = Card(AimRadar, "AimbotCard", 320, 2)
Label(AimbotCard, "FOV Aimbot", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(AimbotCard, "Locks the camera onto the nearest player inside the FOV circle.", UDim2.fromOffset(17, 39), UDim2.new(1, -34, 0, 20), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

local AimbotToggle = ToggleRow(AimbotCard, "Enable Aimbot", false, function(s)
    State.AimbotEnabled = s
end)
AimbotToggle.Position = UDim2.fromOffset(16, 66)
AimbotToggle.Size = UDim2.new(1, -32, 0, 34)

local ShowFOVToggle = ToggleRow(AimbotCard, "Show FOV Circle", false, function(s)
    State.AimbotShowFOV = s
    FOVCircle.Visible = s
end)
ShowFOVToggle.Position = UDim2.fromOffset(16, 106)
ShowFOVToggle.Size = UDim2.new(1, -32, 0, 34)

local WallBangToggle = ToggleRow(AimbotCard, "Wall Bang (ignore walls)", false, function(s)
    State.AimbotWallBang = s
end)
WallBangToggle.Position = UDim2.fromOffset(16, 146)
WallBangToggle.Size = UDim2.new(1, -32, 0, 34)

local TriggerBotToggle = ToggleRow(AimbotCard, "Trigger Bot (auto-fire)", false, function(s)
    State.AimbotTriggerBot = s
end)
TriggerBotToggle.Position = UDim2.fromOffset(16, 186)
TriggerBotToggle.Size = UDim2.new(1, -32, 0, 34)

Label(AimbotCard, "FOV Radius (px)", UDim2.fromOffset(17, 228), UDim2.fromOffset(180, 18), {
    TextSize = 10, Color = Config.Muted,
})
local FOVInput = InputBox(AimbotCard, "120", "FOV", UDim2.fromOffset(200, 224), UDim2.fromOffset(90, 26))

Label(AimbotCard, "Smooth:", UDim2.fromOffset(17, 268), UDim2.fromOffset(60, 18), {
    TextSize = 10, Color = Config.Muted,
})
local SmoothRow = Create("Frame", {
    Position = UDim2.fromOffset(16, 260),
    Size = UDim2.new(1, -32, 0, 34),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
}, AimbotCard)
Corner(SmoothRow, 8)
Stroke(SmoothRow, Config.Border, 0.15, 1)
DropdownRow(SmoothRow, {"Slow", "Medium", "Fast"}, "Medium", function(val)
    State.AimbotSmoothSpeed = val
end)

Connect(FOVInput:GetPropertyChangedSignal("Text"), function()
    local val = tonumber(FOVInput.Text)
    if val and val > 0 then
        State.AimbotFOVRadius = val
        FOVCircle.Size = UDim2.fromOffset(val * 2, val * 2)
    end
end)

local HitboxCard = Card(AimRadar, "HitboxCard", 178, 3)
Label(HitboxCard, "Hitbox Expander", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(HitboxCard, "Enlarges other players' HumanoidRootPart so shots connect more easily.", UDim2.fromOffset(17, 39), UDim2.new(1, -34, 0, 32), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

local HitboxToggle = ToggleRow(HitboxCard, "Enable Hitbox Expander", false, function(s)
    State.HitboxExpander = s
    if not s then
        for player, original in pairs(State.HitboxOriginalSizes) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = original.Size
                hrp.Transparency = original.Transparency
                hrp.CanCollide = original.CanCollide
            end
        end
        State.HitboxOriginalSizes = {}
    end
end)
HitboxToggle.Position = UDim2.fromOffset(16, 76)
HitboxToggle.Size = UDim2.new(1, -32, 0, 34)

Label(HitboxCard, "Hitbox Size (studs)", UDim2.fromOffset(17, 120), UDim2.fromOffset(180, 18), {
    TextSize = 10, Color = Config.Muted,
})
local HitboxInput = InputBox(HitboxCard, "25", "Size", UDim2.fromOffset(200, 116), UDim2.fromOffset(90, 26))
Connect(HitboxInput:GetPropertyChangedSignal("Text"), function()
    local val = tonumber(HitboxInput.Text)
    if val and val > 0 then
        State.HitboxSize = val
    end
end)

local HitboxStatus = Label(HitboxCard, "Hitbox expander is off.", UDim2.fromOffset(17, 152), UDim2.new(1, -34, 0, 20), {
    TextSize = 10, Color = Config.Muted, Wrapped = true,
})

local AimbotInfo = Card(AimRadar, "AimbotInfo", 100, 4)
Label(AimbotInfo, "HOW IT WORKS", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(AimbotInfo, "Aimbot picks the closest target (Head / Torso / Root) inside the FOV circle. Smooth controls how fast the camera snaps. Wall Bang ignores walls; Trigger Bot auto-fires when a target is locked. Hitbox Expander enlarges players' HRP for easier hits.", UDim2.fromOffset(15, 29), UDim2.new(1, -30, 0, 65), {
    TextSize = 10, Color = Config.Muted, Wrapped = true,
})

-- =================== Helpers ===================
local function GetHumanoid()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

-- =================== ESP ===================
local function RemoveHighlight(player)
    local highlight = State.Highlights[player]
    if highlight then
        highlight:Destroy()
        State.Highlights[player] = nil
    end
end

local function ApplyHighlight(player)
    if not State.ESP or player == LocalPlayer then return end
    local character = player.Character
    if not character then
        RemoveHighlight(player)
        return
    end
    local existing = State.Highlights[player]
    if existing and existing.Parent == character then
        existing.FillColor = Config.Accent
        existing.OutlineColor = Config.Accent
        existing.FillTransparency = State.FillTransparency
        existing.OutlineTransparency = State.OutlineTransparency
        return
    end
    RemoveHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "HassanHubHighlight"
    highlight.Adornee = character
    highlight.FillColor = Config.Accent
    highlight.OutlineColor = Config.Accent
    highlight.FillTransparency = State.FillTransparency
    highlight.OutlineTransparency = State.OutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    State.Highlights[player] = highlight
end

local function RefreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if State.ESP then ApplyHighlight(player) else RemoveHighlight(player) end
        end
    end
end

local function UpdateDashboard()
    OverviewESPStatus.Text = "Player ESP / " .. (State.ESP and "ON" or "OFF")
    OverviewESPStatus.TextColor3 = State.ESP and Config.Accent or Config.Text
    OverviewSpeedStatus.Text = State.Speed and ("Speed / " .. tostring(State.TargetSpeed)) or "Speed / DEFAULT"
    OverviewSpeedStatus.TextColor3 = State.Speed and Config.Accent or Config.Text
    ESPButton.Text = State.ESP and "DISABLE ESP" or "ENABLE ESP"
    ESPButton.BackgroundColor3 = State.ESP and Config.Panel or Config.Accent
    SpeedStateText.Text = State.Speed and "STATUS: CUSTOM SPEED ACTIVE" or "STATUS: DEFAULT SPEED"
    SpeedStateText.TextColor3 = State.Speed and Config.Accent or Config.Muted
    JumpStateText.Text = State.JumpEnabled and "STATUS: CUSTOM JUMP ACTIVE" or "STATUS: DEFAULT JUMP"
    JumpStateText.TextColor3 = State.JumpEnabled and Config.Accent or Config.Muted
end

local function SetESP(enabled)
    State.ESP = enabled
    RefreshESP()
    UpdateDashboard()
end

local function ApplyESPStyle()
    local fillPercent = tonumber(FillInput.Text)
    local outlinePercent = tonumber(OutlineInput.Text)
    if not fillPercent or not outlinePercent
        or fillPercent < 0 or fillPercent > 100
        or outlinePercent < 0 or outlinePercent > 100 then
        StyleStatus.Text = "Enter valid values from 0 to 100."
        StyleStatus.TextColor3 = Config.Accent
        return
    end
    State.FillTransparency = fillPercent / 100
    State.OutlineTransparency = outlinePercent / 100
    RefreshESP()
    StyleStatus.Text = string.format("Fill: %d%%  •  Outline: %d%%", fillPercent, outlinePercent)
    StyleStatus.TextColor3 = Config.Muted
end

local function IsValidSpeed(value)
    return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge and value >= 0
end
local function SetSpeedInputSilently(text)
    State.UpdatingSpeedInput = true
    SpeedInput.Text = text
    State.UpdatingSpeedInput = false
end
local function ApplySpeedFromInput()
    if State.UpdatingSpeedInput then return end
    local raw = SpeedInput.Text:gsub("%s+", "")
    local value = tonumber(raw)
    if not IsValidSpeed(value) then
        SpeedStatus.Text = "Enter a valid number (0 or greater)."
        SpeedStatus.TextColor3 = Config.Accent
        return
    end
    local humanoid = GetHumanoid()
    if not humanoid then
        SpeedStatus.Text = "No active character. Value saved for respawn."
        SpeedStatus.TextColor3 = Config.Muted
        State.TargetSpeed = value
        State.Speed = true
        UpdateDashboard()
        return
    end
    if not State.Speed then State.BaseSpeed = humanoid.WalkSpeed end
    State.TargetSpeed = value
    State.Speed = true
    humanoid.WalkSpeed = value
    SpeedStatus.Text = string.format("Current speed: %g", value)
    SpeedStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end

Connect(ESPButton.Activated, function() SetESP(not State.ESP) end)
Connect(QuickESPButton.Activated, function() ShowPage("Visuals") end)
Connect(QuickSpeedButton.Activated, function() ShowPage("Movement") end)
Connect(ApplyStyleButton.Activated, ApplyESPStyle)
Connect(SpeedInput:GetPropertyChangedSignal("Text"), ApplySpeedFromInput)

Connect(ResetSpeedButton.Activated, function()
    State.Speed = false
    State.TargetSpeed = nil
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = State.BaseSpeed
        SpeedStatus.Text = string.format("Current speed: %g (default)", State.BaseSpeed)
    else
        SpeedStatus.Text = "Default speed will be restored when the character respawns."
    end
    SetSpeedInputSilently(tostring(State.BaseSpeed))
    SpeedStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end)

local function IsValidNonNegativeNumber(value)
    return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge and value >= 0
end
local function SetJumpInputSilently(text)
    State.UpdatingJumpInput = true
    JumpInput.Text = text
    State.UpdatingJumpInput = false
end
local function CaptureBaseJump(humanoid)
    State.BaseJumpPower = humanoid.JumpPower
    State.BaseJumpHeight = humanoid.JumpHeight
    State.BaseUseJumpPower = humanoid.UseJumpPower
end
local function ApplyJumpPower(humanoid, value)
    humanoid.UseJumpPower = true
    humanoid.JumpPower = value
end
local function RestoreBaseJump(humanoid)
    humanoid.UseJumpPower = State.BaseUseJumpPower
    humanoid.JumpPower = State.BaseJumpPower
    humanoid.JumpHeight = State.BaseJumpHeight
end
local function ApplyJumpFromInput()
    if State.UpdatingJumpInput then return end
    local raw = JumpInput.Text:gsub("%s+", "")
    local value = tonumber(raw)
    if not IsValidNonNegativeNumber(value) then
        JumpStatus.Text = "Enter a valid number (0 or greater)."
        JumpStatus.TextColor3 = Config.Accent
        return
    end
    local humanoid = GetHumanoid()
    if not humanoid then
        State.JumpEnabled = true
        State.TargetJumpPower = value
        JumpStatus.Text = "No active character. Value saved for respawn."
        JumpStatus.TextColor3 = Config.Muted
        UpdateDashboard()
        return
    end
    if not State.JumpEnabled then CaptureBaseJump(humanoid) end
    State.TargetJumpPower = value
    State.JumpEnabled = true
    ApplyJumpPower(humanoid, value)
    JumpStatus.Text = string.format("Current jump power: %g", value)
    JumpStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end

Connect(JumpInput:GetPropertyChangedSignal("Text"), ApplyJumpFromInput)

Connect(ResetJumpButton.Activated, function()
    State.JumpEnabled = false
    State.TargetJumpPower = nil
    local humanoid = GetHumanoid()
    if humanoid then
        RestoreBaseJump(humanoid)
        JumpStatus.Text = string.format("Jump power reset: %g", State.BaseJumpPower)
    else
        JumpStatus.Text = "Default jump will be restored when the character respawns."
    end
    SetJumpInputSilently(tostring(State.BaseJumpPower))
    JumpStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end)

local function TrackPlayer(player)
    if player == LocalPlayer then return end
    ConnectPlayer(player, player.CharacterAdded, function()
        task.defer(function()
            if player.Parent == Players and State.ESP then
                ApplyHighlight(player)
            end
        end)
    end)
    ConnectPlayer(player, player.CharacterRemoving, function()
        RemoveHighlight(player)
        State.HitboxOriginalSizes[player] = nil
    end)
    if State.ESP and player.Character then ApplyHighlight(player) end
end

for _, player in ipairs(Players:GetPlayers()) do
    TrackPlayer(player)
end
Connect(Players.PlayerAdded, TrackPlayer)
Connect(Players.PlayerRemoving, function(player)
    RemoveHighlight(player)
    State.HitboxOriginalSizes[player] = nil
    DisconnectPlayer(player)
end)

-- =================== Speed & Jump Enforcer (auss.lua style) ===================
-- يفرض WalkSpeed و JumpPower كل خطوة فيزيائية (Stepped) بدون أي شرط،
-- تماماً كما في auss.lua. هذا يمنع اللعبة من إعادة ضبط القيم.
Connect(RunService.Stepped, function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if State.Speed and State.TargetSpeed then
        hum.WalkSpeed = State.TargetSpeed
    end
    if State.JumpEnabled and State.TargetJumpPower then
        hum.JumpPower = State.TargetJumpPower
        hum.UseJumpPower = true
    end
end)

-- =================== Aimbot logic ===================
local function HasLineOfSight(targetPosition)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPosition - rayOrigin).Unit * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if rayResult then
        local hitPart = rayResult.Instance
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and hitPart:IsDescendantOf(player.Character) then
                return true, hitPart
            end
        end
        return false, nil
    end
    return false, nil
end

local function GetBestAimbotTarget()
    local bestTarget = nil
    local shortestDist = State.AimbotFOVRadius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                for _, partName in ipairs(Config.Aimbot.TargetParts) do
                    local part = player.Character:FindFirstChild(partName)
                    if part then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if distFromCenter <= shortestDist then
                                if State.AimbotWallBang then
                                    shortestDist = distFromCenter
                                    bestTarget = part
                                    break
                                else
                                    local hasLoS = HasLineOfSight(part.Position)
                                    if hasLoS then
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
    return bestTarget
end

RunService:BindToRenderStep(AimbotRenderBindingName, Enum.RenderPriority.Camera.Value + 2, function()
    if State.AimbotShowFOV then
        FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
    end

    if State.AimbotEnabled then
        local targetPart = GetBestAimbotTarget()
        if targetPart then
            local smoothValue = Config.Aimbot.SmoothValues[State.AimbotSmoothSpeed] or 0.15
            local targetPosition = targetPart.Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPosition), smoothValue)
        end
    end

    if State.AimbotTriggerBot then
        local targetPart = GetBestAimbotTarget()
        if targetPart then
            VirtualUser:ClickButton1(Vector2.new())
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if State.HitboxExpander then
                    if not State.HitboxOriginalSizes[player] then
                        State.HitboxOriginalSizes[player] = {
                            Size = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide = hrp.CanCollide,
                        }
                    end
                    hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    local original = State.HitboxOriginalSizes[player]
                    if original then
                        hrp.Size = original.Size
                        hrp.Transparency = original.Transparency
                        hrp.CanCollide = original.CanCollide
                        State.HitboxOriginalSizes[player] = nil
                    end
                end
            end
        end
    end

    if State.HitboxExpander then
        HitboxStatus.Text = "Active — size: " .. tostring(State.HitboxSize)
        HitboxStatus.TextColor3 = Config.Accent
    else
        HitboxStatus.Text = "Hitbox expander is off."
        HitboxStatus.TextColor3 = Config.Muted
    end
end)

-- =================== Character respawn ===================
Connect(LocalPlayer.CharacterAdded, function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or State.Destroyed then return end
        State.BaseSpeed = humanoid.WalkSpeed
        CaptureBaseJump(humanoid)

        if State.Speed and State.TargetSpeed ~= nil then
            humanoid.WalkSpeed = State.TargetSpeed
            SpeedStatus.Text = string.format("Current speed: %g", State.TargetSpeed)
        else
            SetSpeedInputSilently(tostring(State.BaseSpeed))
            SpeedStatus.Text = string.format("Current speed: %g (default)", State.BaseSpeed)
        end

        if State.JumpEnabled and State.TargetJumpPower ~= nil then
            ApplyJumpPower(humanoid, State.TargetJumpPower)
            JumpStatus.Text = string.format("Current jump power: %g", State.TargetJumpPower)
        else
            SetJumpInputSilently(tostring(State.BaseJumpPower))
            JumpStatus.Text = string.format("Jump power: %g (default)", State.BaseJumpPower)
        end
        UpdateDashboard()
    end)
end)

-- =================== Cleanup ===================
local function CleanupConnections()
    CancelWindowTweens()
    pcall(function() RunService:UnbindFromRenderStep(AimbotRenderBindingName) end)

    for _, connection in ipairs(State.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(State.Connections)

    for player, connections in pairs(State.PlayerConnections) do
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        State.PlayerConnections[player] = nil
    end

    for player, highlight in pairs(State.Highlights) do
        if highlight then pcall(function() highlight:Destroy() end) end
        State.Highlights[player] = nil
    end

    for player, original in pairs(State.HitboxOriginalSizes) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            hrp.Size = original.Size
            hrp.Transparency = original.Transparency
            hrp.CanCollide = original.CanCollide
        end
    end
    State.HitboxOriginalSizes = {}
end

local function RestoreCharacterDefaults()
    local humanoid = GetHumanoid()
    if not humanoid then return end
    if State.Speed and State.TargetSpeed ~= nil then
        humanoid.WalkSpeed = State.BaseSpeed
    end
    if State.JumpEnabled and State.TargetJumpPower ~= nil then
        RestoreBaseJump(humanoid)
    end
end

local function Shutdown()
    if State.Destroyed then return end
    RestoreCharacterDefaults()
    State.Destroyed = true
    CleanupConnections()
    if Screen and Screen.Parent then
        Screen:Destroy()
    end
end

Connect(CloseButton.Activated, Shutdown)

Connect(Screen.Destroying, function()
    if State.Destroyed then return end
    RestoreCharacterDefaults()
    State.Destroyed = true
    CleanupConnections()
end)

local initialHumanoid = GetHumanoid()
if initialHumanoid then
    State.BaseSpeed = initialHumanoid.WalkSpeed
    CaptureBaseJump(initialHumanoid)
    SetSpeedInputSilently(tostring(State.BaseSpeed))
    SetJumpInputSilently(tostring(State.BaseJumpPower))
    SpeedStatus.Text = string.format("Current speed: %g (default)", State.BaseSpeed)
    JumpStatus.Text = string.format("Jump power: %g (default)", State.BaseJumpPower)
end

MainContent = Create("CanvasGroup", {
    Name = "MainContent",
    Position = UDim2.fromScale(0, 0),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    GroupTransparency = 0,
    ClipsDescendants = true,
}, Main)

for _, child in ipairs(Main:GetChildren()) do
    if child ~= MainContent
        and child ~= UIScale
        and not child:IsA("UICorner")
        and not child:IsA("UIStroke") then
        child.Parent = MainContent
    end
end

Main.Visible = true
Main.BackgroundTransparency = 1
MainStroke.Transparency = 1
MainContent.GroupTransparency = 1
ExpandedPosition = Main.Position
Main.Position = UDim2.new(
    ExpandedPosition.X.Scale,
    ExpandedPosition.X.Offset,
    ExpandedPosition.Y.Scale,
    ExpandedPosition.Y.Offset + 12
)
UIScale.Scale = ResponsiveScale
WindowTransitioning = true

ShowPage("Overview")
UpdateDashboard()

local introTween = Tween(
    Main,
    0.28,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out,
    {Position = ExpandedPosition, BackgroundTransparency = 0}
)
Tween(MainStroke, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
    Transparency = 0.05,
})
Tween(MainContent, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
    GroupTransparency = 0,
})
LogoScale.Scale = 0.92
Logo.Rotation = 0
Tween(LogoScale, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
    Scale = 1,
})
Tween(Logo, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
    Rotation = 0,
})

task.spawn(function()
    introTween.Completed:Wait()
    if State.Destroyed then return end
    Main.Position = ExpandedPosition
    Main.BackgroundTransparency = 0
    UIScale.Scale = ResponsiveScale
    WindowTransitioning = false
end)
