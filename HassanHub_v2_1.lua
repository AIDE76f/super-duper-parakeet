local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    Version = "2.1",
    Background = Color3.fromRGB(15, 16, 21),
    Sidebar = Color3.fromRGB(20, 21, 28),
    Panel = Color3.fromRGB(27, 28, 36),
    PanelHover = Color3.fromRGB(37, 38, 48),
    Accent = Color3.fromRGB(239, 49, 68),
    AccentDark = Color3.fromRGB(168, 30, 49),
    Text = Color3.fromRGB(245, 245, 250),
    Muted = Color3.fromRGB(151, 154, 171),
    Border = Color3.fromRGB(53, 54, 66),
}

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
Stroke(Main, Config.Border, 0.05, 1)

local UIScale = Create("UIScale", {Scale = 1}, Main)
local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    UIScale.Scale = math.clamp(math.min((viewport.X - 24) / 780, (viewport.Y - 24) / 520), 0.42, 1)
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
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
    Text = "H",
    TextColor3 = Config.Text,
    TextSize = 24,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
}, Header)
Corner(Logo, 12)
Create("UIGradient", {Color = ColorSequence.new(Config.Accent, Config.AccentDark), Rotation = 45}, Logo)

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

-- The floating H is the same logo design. Both — and × minimize to this icon;
-- the icon or Right Shift brings the window back.
local Floating = Create("TextButton", {
    Name = "FloatingH",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 18, 0.5, 0),
    Size = UDim2.fromOffset(56, 54),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
    Text = "H",
    TextColor3 = Config.Text,
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    Visible = false,
    AutoButtonColor = false,
    ZIndex = 50,
}, Screen)
Corner(Floating, 16)
Stroke(Floating, Color3.fromRGB(255, 100, 115), 0.1, 1.4)
Create("UIGradient", {Color = ColorSequence.new(Config.Accent, Config.AccentDark), Rotation = 45}, Floating)

local function SetVisible(visible)
    if State.Destroyed then return end
    Main.Visible = visible
    Floating.Visible = not visible
end
Connect(MinimizeButton.Activated, function() SetVisible(false) end)
Connect(CloseButton.Activated, function() SetVisible(false) end)
Connect(Floating.Activated, function() SetVisible(true) end)
Connect(Logo.Activated, function() SetVisible(false) end)
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
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
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
Label(Sidebar, "HASSAN HUB  /  " .. Config.Version, UDim2.new(0, 12, 1, -34), UDim2.new(1, -24, 0, 18), {
    TextSize = 9,
    Color = Config.Muted,
    Font = Enum.Font.GothamBold,
    Align = Enum.TextXAlignment.Center,
})

local function ShowPage(key)
    State.CurrentPage = key
    for pageKey, page in pairs(Pages) do
        page.Visible = pageKey == key
    end
    for navKey, data in pairs(NavButtons) do
        local active = navKey == key
        data.Indicator.Visible = active
        TweenService:Create(data.Button, TweenInfo.new(0.15), {
            BackgroundColor3 = active and Config.Panel or Config.Sidebar,
        }):Play()
        local textLabel = data.Button:FindFirstChildWhichIsA("TextLabel")
        if textLabel then
            textLabel.TextColor3 = active and Config.Text or Config.Muted
        end
    end
end

for key, data in pairs(NavButtons) do
    local pageKey = key
    Connect(data.Button.Activated, function() ShowPage(pageKey) end)
end

local Overview = CreatePage("Overview", "Overview", "Your features and current session at a glance.")
local Visuals = CreatePage("Visuals", "Player ESP", "Configure character highlighting and visual options.")
local Movement = CreatePage("Movement", "Movement", "Set an exact WalkSpeed value while typing.")

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
Label(AboutCard, "Right Shift hides or restores this interface.", UDim2.fromOffset(15, 29), UDim2.new(1, -30, 0, 28), {
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

local SpeedInfo = Card(Movement, "SpeedInfo", 79, 3)
Label(SpeedInfo, "HOW IT WORKS", UDim2.fromOffset(15, 10), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(SpeedInfo, "Reset Speed restores the character's captured default WalkSpeed. Negative or non-numeric values are rejected.", UDim2.fromOffset(15, 30), UDim2.new(1, -30, 0, 36), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

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

Connect(LocalPlayer.CharacterAdded, function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or State.Destroyed then return end

        -- Each new character gets its own baseline speed.
        State.BaseSpeed = humanoid.WalkSpeed
        if State.Speed and State.TargetSpeed ~= nil then
            humanoid.WalkSpeed = State.TargetSpeed
            SpeedStatus.Text = string.format("Current speed: %g", State.TargetSpeed)
        else
            SetSpeedInputSilently(tostring(State.BaseSpeed))
            SpeedStatus.Text = string.format("Current speed: %g (default)", State.BaseSpeed)
        end
        UpdateDashboard()
    end)
end)

Connect(Screen.Destroying, function()
    if State.Destroyed then return end
    State.Destroyed = true
    local humanoid = GetHumanoid()
    if humanoid and State.Speed then
        humanoid.WalkSpeed = State.BaseSpeed
    end
    for _, connection in ipairs(State.Connections) do
        connection:Disconnect()
    end
    for player, connections in pairs(State.PlayerConnections) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        State.PlayerConnections[player] = nil
    end
    for player, highlight in pairs(State.Highlights) do
        if highlight then highlight:Destroy() end
        State.Highlights[player] = nil
    end
end)

local initialHumanoid = GetHumanoid()
if initialHumanoid then
    State.BaseSpeed = initialHumanoid.WalkSpeed
    SetSpeedInputSilently(tostring(State.BaseSpeed))
    SpeedStatus.Text = string.format("Current speed: %g (default)", State.BaseSpeed)
end

ShowPage("Overview")
UpdateDashboard()
