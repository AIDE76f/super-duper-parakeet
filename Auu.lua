local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
    AimTargetTag = "HassanAimTarget",
    AimRanges = {Close = 120, Medium = 500, Far = 1500},
}

local AimRenderBindingName = "HassanHubAimLock_" .. tostring(LocalPlayer.UserId)

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

    AimEnabled = false,
    AimHolding = false,
    AimRangeMode = "Close",
    AimSmoothness = 65,
    AimSliderDragging = false,
    CurrentAimTarget = nil,
    AimTargetCounts = {Close = 0, Medium = 0, Far = 0},
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

-- Remove an older copy first. Multiple copies of the UI can overlap and
-- make the red icon look washed out or darker than its real color.
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
    -- Keep native 1:1 UI rendering whenever possible to avoid fractional-scale text blur.
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

-- The same H button becomes the draggable floating icon.
-- A solid opaque fill is used: no UIGradient is placed over the icon,
-- because a gradient tints the white letter and can make it look faded.
local LogoGradient = Logo:FindFirstChildOfClass("UIGradient")
if LogoGradient then
    LogoGradient:Destroy()
end

local LogoOutline = Stroke(Logo, Color3.fromRGB(255, 245, 246), 0, 1.75)
-- Keep the icon at its final size; animate only its UIScale. This prevents
-- a tiny, weak-looking red button from appearing at the start of minimizing.
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
    -- Save the floating location before moving the exact same button back.
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

    -- Opening the window. The floating H is the actual header logo,
    -- so it returns to the exact original title-bar position.
    if visible then
        if not IsMinimized and Main.Visible then
            return
        end

        WindowTransitioning = true
        if IsMinimized then
            RestoreHeaderLogo()
        end
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
        if MainContent then
            MainContent.GroupTransparency = 1
        end

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

    -- Minimize / close: fade and shrink the window while the logo pops out.
    if IsMinimized or not Main.Visible then
        return
    end

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
        if MainContent then
            MainContent.GroupTransparency = 0
        end
        WindowTransitioning = false
    end)
end

Connect(MinimizeButton.Activated, function()
    SetVisible(false)
end)

-- The H inside the title bar is a logo, not a second minimize button.
-- It only opens the window when the same button has become the floating icon.
Connect(Logo.Activated, function()
    if IconDragged then
        IconDragged = false
        return
    end

    if IsMinimized then
        SetVisible(true)
    end
end)

Connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        SetVisible(not Main.Visible)
    end
end)

-- Make the minimized H icon draggable with the mouse (and touch where supported).
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
    if not IsMinimized or not IconDragging or not IconDragInput then
        return
    end

    local shouldMove =
        (IconDragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        or (IconDragInput.UserInputType == Enum.UserInputType.Touch
            and input == IconDragInput)

    if not shouldMove then return end

    local delta = input.Position - IconDragStart
    if delta.Magnitude > 4 then
        IconDragged = true
    end

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
CreateNav("AimRadar", "Aim Radar", "◎", 4)
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
local AimRadar = CreatePage("AimRadar", "Aim Radar", "Practice aim assist for tagged NPCs in your own Roblox experience.")

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
Label(AboutCard, "Right Shift toggles the window. Aim Radar locks onto real players and tagged NPCs in front of you.", UDim2.fromOffset(15, 29), UDim2.new(1, -30, 0, 28), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

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

local AimSwitchCard = Card(AimRadar, "AimSwitchCard", 122, 2)
Label(AimSwitchCard, "Aim Assist", UDim2.fromOffset(16, 13), UDim2.new(1, -175, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBold,
})
Label(AimSwitchCard, "Automatically locks the camera onto a real player or tagged training dummy in front of you.", UDim2.fromOffset(17, 41), UDim2.new(1, -165, 0, 34), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})
local AimToggleButton = ActionButton(AimSwitchCard, "ENABLE AIM", UDim2.new(1, -133, 0, 15), UDim2.fromOffset(116, 34), true)
Label(AimSwitchCard, "Only targets in front of the camera and not hidden by walls.", UDim2.fromOffset(17, 88), UDim2.new(1, -34, 0, 18), {
    TextSize = 10, Color = Config.Muted,
})

local RadarGrid = Create("Frame", {
    Name = "RadarGrid",
    Size = UDim2.new(1, 0, 0, 102),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
}, AimRadar)
local RadarGridLayout = Create("UIGridLayout", {
    CellPadding = UDim2.fromOffset(8, 0),
    CellSize = UDim2.new(1/3, -6, 1, 0),
    FillDirectionMaxCells = 3,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, RadarGrid)
local RadarButtons = {}
local RadarCountLabels = {}
local RadarModes = {
    {Key = "Close", Title = "CLOSE", Range = "0–120 studs", Order = 1},
    {Key = "Medium", Title = "MEDIUM", Range = ">120–500 studs", Order = 2},
    {Key = "Far", Title = "FAR", Range = ">500–1500 studs", Order = 3},
}
for _, mode in ipairs(RadarModes) do
    local radarCard = Create("Frame", {
        Name = mode.Key .. "Radar",
        BackgroundColor3 = Config.Panel,
        BorderSizePixel = 0,
        LayoutOrder = mode.Order,
    }, RadarGrid)
    Corner(radarCard, 10)
    Stroke(radarCard, Config.Border, 0.35, 1)
    local radarButton = Create("TextButton", {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.new(1, -8, 0, 45),
        BackgroundColor3 = Config.Sidebar,
        BorderSizePixel = 0,
        Text = mode.Title,
        TextColor3 = Config.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, radarCard)
    Corner(radarButton, 8)
    local countLabel = Label(radarCard, "0 targets", UDim2.new(0, 2, 1, -30), UDim2.new(1, -4, 0, 23), {
        TextSize = 10, Color = Config.Muted, Align = Enum.TextXAlignment.Center,
    })
    Label(radarCard, mode.Range, UDim2.new(0, 2, 1, -48), UDim2.new(1, -4, 0, 16), {
        TextSize = 10, Color = Config.Muted, Align = Enum.TextXAlignment.Center,
    })
    RadarButtons[mode.Key] = radarButton
    RadarCountLabels[mode.Key] = countLabel
end

local AimTargetCard = Card(AimRadar, "AimTargetCard", 84, 4)
Label(AimTargetCard, "TARGET STATUS", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
local AimTargetStatus = Label(AimTargetCard, "Target lock is off.", UDim2.fromOffset(15, 31), UDim2.new(1, -30, 0, 20), {
    TextSize = 12, Font = Enum.Font.GothamMedium, Color = Config.Muted,
})
Label(AimTargetCard, "Targets behind walls or behind your camera are ignored.", UDim2.fromOffset(15, 53), UDim2.new(1, -30, 0, 20), {
    TextSize = 10, Color = Config.Muted,
})

local AimSetupCard = Card(AimRadar, "AimSetupCard", 92, 5)
Label(AimSetupCard, "SETUP", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(AimSetupCard, "Real players are targeted automatically. For NPCs/dummies, tag training Models with HassanAimTarget. Targets must be in front of the camera and visible (not blocked by walls). NPCs need a living Humanoid and Head/PrimaryPart.", UDim2.fromOffset(15, 29), UDim2.new(1, -30, 0, 55), {
    TextSize = 10, Color = Config.Muted, Wrapped = true,
})

local SmoothCard = Card(AimRadar, "SmoothCard", 112, 6)
Label(SmoothCard, "CAMERA SMOOTHNESS", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 18), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(SmoothCard, "Move left for slower tracking; move right for faster or instant lock.", UDim2.fromOffset(15, 30), UDim2.new(1, -30, 0, 18), {
    TextSize = 10, Color = Config.Muted, Wrapped = true,
})
local SmoothValueLabel = Label(SmoothCard, "65 / 100  •  FAST", UDim2.new(1, -132, 0, 9), UDim2.fromOffset(116, 20), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Text, Align = Enum.TextXAlignment.Right,
})
local SmoothTrack = Create("TextButton", {
    Name = "SmoothnessTrack",
    Position = UDim2.fromOffset(17, 66),
    Size = UDim2.new(1, -34, 0, 12),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
}, SmoothCard)
Corner(SmoothTrack, 6)
Stroke(SmoothTrack, Config.Border, 0.1, 1)
local SmoothFill = Create("Frame", {
    Name = "Fill",
    Size = UDim2.new(State.AimSmoothness / 100, 0, 1, 0),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
}, SmoothTrack)
Corner(SmoothFill, 6)
local SmoothKnob = Create("Frame", {
    Name = "Knob",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(State.AimSmoothness / 100, 0, 0.5, 0),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0,
    ZIndex = 3,
}, SmoothTrack)
Corner(SmoothKnob, 9)
Stroke(SmoothKnob, Config.Accent, 0, 2)
Label(SmoothCard, "SLOW", UDim2.fromOffset(17, 83), UDim2.fromOffset(60, 17), {
    TextSize = 9, Color = Config.Muted, Font = Enum.Font.GothamBold,
})
Label(SmoothCard, "INSTANT", UDim2.new(1, -77, 0, 83), UDim2.fromOffset(60, 17), {
    TextSize = 9, Color = Config.Muted, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Right,
})

local function SetAimSmoothnessFromX(screenX)
    local width = SmoothTrack.AbsoluteSize.X
    if width <= 0 then return end
    local value = math.clamp((screenX - SmoothTrack.AbsolutePosition.X) / width, 0, 1)
    State.AimSmoothness = math.floor(value * 100 + 0.5)
    SmoothFill.Size = UDim2.new(State.AimSmoothness / 100, 0, 1, 0)
    SmoothKnob.Position = UDim2.new(State.AimSmoothness / 100, 0, 0.5, 0)
    local description
    if State.AimSmoothness <= 20 then
        description = "SLOW"
    elseif State.AimSmoothness < 75 then
        description = "SMOOTH"
    elseif State.AimSmoothness < 100 then
        description = "FAST"
    else
        description = "INSTANT"
    end
    SmoothValueLabel.Text = string.format("%d / 100  •  %s", State.AimSmoothness, description)
end

Connect(SmoothTrack.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        State.AimSliderDragging = true
        SetAimSmoothnessFromX(input.Position.X)
    end
end)
Connect(UserInputService.InputChanged, function(input)
    if State.AimSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        SetAimSmoothnessFromX(input.Position.X)
    end
end)
Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        State.AimSliderDragging = false
    end
end)

local function GetHumanoid()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

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
    AimToggleButton.Text = State.AimEnabled and "DISABLE AIM" or "ENABLE AIM"
    AimToggleButton.BackgroundColor3 = State.AimEnabled and Config.Panel or Config.Accent
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

    if not State.Speed then
        State.BaseSpeed = humanoid.WalkSpeed
    end

    State.TargetSpeed = value
    State.Speed = true
    humanoid.WalkSpeed = value

    SpeedStatus.Text = string.format("Current speed: %g", value)
    SpeedStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end

Connect(ESPButton.Activated, function()
    SetESP(not State.ESP)
end)
Connect(QuickESPButton.Activated, function()
    ShowPage("Visuals")
end)
Connect(QuickSpeedButton.Activated, function()
    ShowPage("Movement")
end)
Connect(ApplyStyleButton.Activated, ApplyESPStyle)

-- Speed now applies as soon as a valid numeric value is entered.
-- The value is an absolute WalkSpeed, not a multiplier.
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
    -- The UI's number always means JumpPower. While enabled, use that Roblox mode;
    -- Reset restores the previous UseJumpPower mode and both original properties.
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

    if not State.JumpEnabled then
        CaptureBaseJump(humanoid)
    end

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
    end)
    if State.ESP and player.Character then ApplyHighlight(player) end
end

for _, player in ipairs(Players:GetPlayers()) do
    TrackPlayer(player)
end
Connect(Players.PlayerAdded, TrackPlayer)
Connect(Players.PlayerRemoving, function(player)
    RemoveHighlight(player)
    DisconnectPlayer(player)
end)

-- Aim radar: targets both tagged NPC/dummy Models AND real player characters.
-- The local player is always excluded. Targets must be in front of the camera
-- and not blocked by world geometry.
local function ResolveTaggedModel(instance)
    if not instance then return nil end
    if instance:IsA("Model") then return instance end
    return instance:FindFirstAncestorOfClass("Model")
end

local function GetAimPart(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
end

-- A model is a valid aim target if it has a living Humanoid and an aim part,
-- and it is either a real player's character or a tagged training model.
-- The local player is always excluded.
local function IsValidAimTarget(model)
    if not model or not model:IsA("Model") then return false end
    local ownerPlayer = Players:GetPlayerFromCharacter(model)
    if ownerPlayer == LocalPlayer then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local aimPart = GetAimPart(model)
    if not humanoid or humanoid.Health <= 0 or not aimPart then return false end

    -- Real players are always eligible. Non-player models need the tag.
    if ownerPlayer ~= nil then
        return true
    end
    return CollectionService:HasTag(model, Config.AimTargetTag)
end

-- Collect every candidate model once: tagged NPCs + real player characters.
local function CollectAimCandidates()
    local candidates = {}
    local seen = {}

    -- Tagged training dummies / NPCs
    for _, instance in ipairs(CollectionService:GetTagged(Config.AimTargetTag)) do
        local model = ResolveTaggedModel(instance)
        if model and not seen[model] then
            seen[model] = true
            table.insert(candidates, model)
        end
    end

    -- Real players (everyone except the local player)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and not seen[char] then
                seen[char] = true
                table.insert(candidates, char)
            end
        end
    end

    return candidates
end

local function GetAimBand(distance)
    if distance <= Config.AimRanges.Close then
        return "Close"
    elseif distance <= Config.AimRanges.Medium then
        return "Medium"
    elseif distance <= Config.AimRanges.Far then
        return "Far"
    end
    return nil
end

local function RefreshRadarCounts()
    local counts = {Close = 0, Medium = 0, Far = 0}
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, model in ipairs(CollectAimCandidates()) do
            if IsValidAimTarget(model) then
                local part = GetAimPart(model)
                if part then
                    local band = GetAimBand((part.Position - root.Position).Magnitude)
                    if band then counts[band] = counts[band] + 1 end
                end
            end
        end
    end

    State.AimTargetCounts = counts
    for key, label in pairs(RadarCountLabels) do
        label.Text = tostring(counts[key]) .. (counts[key] == 1 and " target" or " targets")
    end
end

local function UpdateRadarSelection()
    for key, button in pairs(RadarButtons) do
        local selected = key == State.AimRangeMode
        button.BackgroundColor3 = selected and Config.Accent or Config.Sidebar
        button.TextColor3 = selected and Config.Text or Config.Muted
    end
end

local function SetAimEnabled(enabled)
    State.AimEnabled = enabled
    if not enabled then
        State.AimHolding = false
        State.CurrentAimTarget = nil
        AimTargetStatus.Text = "Target lock is off."
        AimTargetStatus.TextColor3 = Config.Muted
    else
        AimTargetStatus.Text = "Target lock active — scanning selected range."
        AimTargetStatus.TextColor3 = Config.Accent
    end
    UpdateDashboard()
end

for key, button in pairs(RadarButtons) do
    local selectedMode = key
    Connect(button.Activated, function()
        State.AimRangeMode = selectedMode
        State.CurrentAimTarget = nil
        UpdateRadarSelection()
    end)
end
Connect(AimToggleButton.Activated, function()
    SetAimEnabled(not State.AimEnabled)
end)
Connect(UserInputService.InputBegan, function(input, processed)
    -- Aiming is automatic while enabled for tagged training NPCs; RMB is not required.
end)
Connect(UserInputService.InputEnded, function(input)
    -- No mouse hold state is needed for training target lock.
end)

local aimUpdateElapsed = 0
RunService:BindToRenderStep(AimRenderBindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    aimUpdateElapsed = aimUpdateElapsed + deltaTime
    if aimUpdateElapsed >= 0.25 then
        aimUpdateElapsed = 0
        RefreshRadarCounts()
    end

    if not State.AimEnabled then return end

    local camera = workspace.CurrentCamera
    local character = LocalPlayer.Character
    local localRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not camera or not localRoot then return end

    local viewport = camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local cameraPos = camera.CFrame.Position
    local cameraLook = camera.CFrame.LookVector

    local bestModel, bestPart
    local bestScreenDistance = math.huge
    local bestWorldDistance = math.huge

    for _, model in ipairs(CollectAimCandidates()) do
        if IsValidAimTarget(model) then
            local part = GetAimPart(model)
            if part then
                local worldDistance = (part.Position - localRoot.Position).Magnitude

                if GetAimBand(worldDistance) == State.AimRangeMode then
                    -- ① Front-of-camera check (dot product against look vector).
                    local toTarget = part.Position - cameraPos
                    local distanceToTarget = toTarget.Magnitude

                    if distanceToTarget > 0.5 then
                        local dot = toTarget.Unit:Dot(cameraLook)

                        -- dot > 0 means in front; larger = more centered.
                        -- Require a healthy cone so we never snap to anything
                        -- behind or directly beside the player.
                        if dot > 0.15 then
                            local projected, onScreen = camera:WorldToViewportPoint(part.Position)

                            if onScreen and projected.Z > 0 then
                                local screenDistance =
                                    (Vector2.new(projected.X, projected.Y) - screenCenter).Magnitude

                                if screenDistance < bestScreenDistance then
                                    -- ② Wall check: ray from camera to target.
                                    local params = RaycastParams.new()
                                    params.FilterType = Enum.RaycastFilterType.Exclude
                                    params.FilterDescendantsInstances = {character}
                                    params.IgnoreWater = true
                                    params.RespectCanCollide = false

                                    local hit = workspace:Raycast(cameraPos, toTarget, params)
                                    local visible = hit == nil
                                        or model:IsAncestorOf(hit.Instance)
                                        or hit.Instance:IsDescendantOf(model)

                                    if visible then
                                        bestModel = model
                                        bestPart = part
                                        bestScreenDistance = screenDistance
                                        bestWorldDistance = worldDistance
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    State.CurrentAimTarget = bestModel
    if bestModel and bestPart then
        AimTargetStatus.Text = string.format("%s  •  %d studs", bestModel.Name, math.floor(bestWorldDistance + 0.5))
        AimTargetStatus.TextColor3 = Config.Accent

        local targetCFrame = CFrame.lookAt(camera.CFrame.Position, bestPart.Position)
        -- Slider 0-99 controls frame-rate independent smoothing; 100 is immediate.
        if State.AimSmoothness >= 100 then
            camera.CFrame = targetCFrame
        else
            local normalized = State.AimSmoothness / 100
            local perFrameAlpha = 0.015 + (normalized * normalized * 0.42)
            local alpha = 1 - math.pow(1 - perFrameAlpha, math.max(deltaTime, 0) * 60)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, math.clamp(alpha, 0.001, 0.98))
        end
    else
        AimTargetStatus.Text = "No visible target in " .. State.AimRangeMode:lower() .. " range."
        AimTargetStatus.TextColor3 = Config.Muted
    end
end)

Connect(CollectionService:GetInstanceAddedSignal(Config.AimTargetTag), function()
    RefreshRadarCounts()
end)
Connect(CollectionService:GetInstanceRemovedSignal(Config.AimTargetTag), function()
    RefreshRadarCounts()
end)

Connect(LocalPlayer.CharacterAdded, function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or State.Destroyed then return end

        -- Each new character gets fresh defaults before any saved overrides are applied.
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

local function CleanupConnections()
    CancelWindowTweens()
    pcall(function() RunService:UnbindFromRenderStep(AimRenderBindingName) end)

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

    -- X is a real close: restore changed character values, disconnect all events,
    -- cancel animations, remove highlights, and destroy the entire GUI including H.
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

-- Put the existing window content into a CanvasGroup so transitions can
-- fade all controls together instead of only fading the empty frame behind them.
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

-- Initial entrance animation.
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
UpdateRadarSelection()
RefreshRadarCounts()

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
