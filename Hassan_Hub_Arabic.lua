local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    Name = "HassanHubArabic",
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
    MaxMultiplier = 10,
}

local State = {
    ESP = false,
    Speed = false,
    Multiplier = 2,
    BaseSpeed = 16,
    FillTransparency = 0.35,
    OutlineTransparency = 0,
    Highlights = {},
    Connections = {},
    PlayerConnections = {},
    CurrentPage = "الرئيسية",
    Destroyed = false,
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

local function SetRTL(object, enabled)
    if enabled then
        pcall(function()
            object.TextDirection = Enum.TextDirection.RightToLeft
        end)
    end
end

local function Label(parent, text, position, size, options)
    options = options or {}
    local object = Create("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = options.Color or Config.Text,
        TextSize = options.TextSize or 13,
        Font = options.Font or Enum.Font.GothamBold,
        TextXAlignment = options.Align or Enum.TextXAlignment.Right,
        TextYAlignment = options.VerticalAlign or Enum.TextYAlignment.Center,
        TextWrapped = options.Wrapped or false,
        TextTruncate = options.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
    }, parent)
    if options.RTL ~= false then SetRTL(object, true) end
    return object
end

local function ActionButton(parent, text, position, size, primary, centered)
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
        TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Center,
        AutoButtonColor = false,
    }, parent)
    SetRTL(button, true)
    Corner(button, 9)
    Connect(button.MouseEnter, function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
    end)
    Connect(button.MouseLeave, function()
        local activeColor = button:GetAttribute("Active") and Config.Accent or baseColor
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = activeColor}):Play()
    end)
    return button
end

local function InputBox(parent, text, placeholder, position, size)
    local input = Create("TextBox", {
        Position = position,
        Size = size,
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        Text = text or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Config.Muted,
        TextColor3 = Config.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
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
    Name = Config.Name,
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

local Logo = Create("Frame", {
    Position = UDim2.fromOffset(18, 12),
    Size = UDim2.fromOffset(40, 40),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
}, Header)
Corner(Logo, 12)
Create("UIGradient", {
    Color = ColorSequence.new(Config.Accent, Config.AccentDark),
    Rotation = 45,
}, Logo)
Label(Logo, "H", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), {
    TextSize = 24, Font = Enum.Font.GothamBlack,
    Align = Enum.TextXAlignment.Center, RTL = false,
})
Label(Header, "حسن هَب", UDim2.fromOffset(70, 8), UDim2.fromOffset(220, 30), {
    TextSize = 20, Font = Enum.Font.GothamBlack,
})
Label(Header, "مركز التحكم  •  الإصدار " .. Config.Version,
    UDim2.fromOffset(71, 36), UDim2.fromOffset(260, 17), {
        TextSize = 10, Color = Config.Muted,
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
Label(SessionBadge, "جلسة محلية", UDim2.fromOffset(22, 0), UDim2.new(1, -25, 1, 0), {
    TextSize = 10, Color = Config.Muted,
})

local MinimizeButton = ActionButton(Header, "—", UDim2.new(1, -82, 0, 16), UDim2.fromOffset(30, 30), false, true)
local CloseButton = ActionButton(Header, "×", UDim2.new(1, -43, 0, 16), UDim2.fromOffset(30, 30), true, true)
MinimizeButton.TextSize = 17
CloseButton.TextSize = 22

local Floating = Create("TextButton", {
    Name = "أيقونة_فتح_حسن_هب",
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
Create("UIGradient", {
    Color = ColorSequence.new(Config.Accent, Config.AccentDark),
    Rotation = 45,
}, Floating)

local function SetVisible(visible)
    if State.Destroyed then return end
    Main.Visible = visible
    Floating.Visible = not visible
end

-- زر الإغلاق (×) يخفي النافذة فقط ولا يدمّر الواجهة؛ تبقى الأيقونة العائمة لإعادة فتحها.
Connect(MinimizeButton.Activated, function() SetVisible(false) end)
Connect(CloseButton.Activated, function() SetVisible(false) end)
Connect(Floating.Activated, function() SetVisible(true) end)
Connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        SetVisible(not Main.Visible)
    end
end)

local dragging, dragStart, startPosition = false, nil, nil
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local Sidebar = Create("Frame", {
    Name = "القائمة_الجانبية",
    Position = UDim2.fromOffset(12, 77),
    Size = UDim2.new(0, 164, 1, -89),
    BackgroundColor3 = Config.Sidebar,
    BorderSizePixel = 0,
}, Main)
Corner(Sidebar, 12)
Stroke(Sidebar, Config.Border, 0.5, 1)
Label(Sidebar, "القائمة الرئيسية", UDim2.fromOffset(12, 15), UDim2.new(1, -24, 0, 20), {
    TextSize = 10, Color = Config.Muted,
})

local PageHost = Create("Frame", {
    Name = "محتوى_الصفحات",
    Position = UDim2.fromOffset(188, 77),
    Size = UDim2.new(1, -200, 1, -89),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Main)

local Pages, NavButtons = {}, {}

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
        TextSize = 22, Font = Enum.Font.GothamBlack,
    })
    Label(intro, subtitle, UDim2.fromOffset(4, 29), UDim2.new(1, -8, 0, 19), {
        TextSize = 11, Color = Config.Muted,
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
        Position = UDim2.fromOffset(8, 43 + (order - 1) * 49),
        Size = UDim2.new(1, -16, 0, 41),
        BackgroundColor3 = Config.Sidebar,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, Sidebar)
    Corner(button, 9)
    local indicator = Create("Frame", {
        Position = UDim2.new(1, -3, 0, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, button)
    Corner(indicator, 3)
    Label(button, symbol, UDim2.fromOffset(8, 0), UDim2.fromOffset(27, 41), {
        TextSize = 15, Color = Config.Muted, Align = Enum.TextXAlignment.Center, RTL = false,
    })
    Label(button, title, UDim2.fromOffset(39, 0), UDim2.new(1, -46, 1, 0), {
        TextSize = 12, Font = Enum.Font.GothamBold, Color = Config.Muted,
    })
    NavButtons[key] = {Button = button, Indicator = indicator}
    return button
end

local Overview = CreatePage("الرئيسية", "نظرة عامة", "ملخص سريع للميزات وحالة الجلسة.")
local Visuals = CreatePage("كشف_اللاعبين", "كشف اللاعبين", "تخصيص تمييز الشخصيات وإعدادات المظهر.")
local Movement = CreatePage("الحركة", "التحكم بالحركة", "ضبط سرعة حركة شخصيتك محليًا.")

CreateNav("الرئيسية", "الرئيسية", "◈", 1)
CreateNav("كشف_اللاعبين", "كشف اللاعبين", "◎", 2)
CreateNav("الحركة", "السرعة والحركة", "↗", 3)
Label(Sidebar, "حسن هَب  /  " .. Config.Version, UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 18), {
    TextSize = 9, Color = Config.Muted, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Center,
})

local function ShowPage(key)
    State.CurrentPage = key
    for pageKey, page in pairs(Pages) do page.Visible = pageKey == key end
    for navKey, data in pairs(NavButtons) do
        local active = navKey == key
        data.Indicator.Visible = active
        TweenService:Create(data.Button, TweenInfo.new(0.15), {
            BackgroundColor3 = active and Config.Panel or Config.Sidebar,
        }):Play()
        local textLabel = data.Button:FindFirstChildWhichIsA("TextLabel")
        if textLabel then textLabel.TextColor3 = active and Config.Text or Config.Muted end
    end
end
for key, data in pairs(NavButtons) do
    local pageKey = key
    Connect(data.Button.Activated, function() ShowPage(pageKey) end)
end

local Hero = Card(Overview, "بطاقة_الترحيب", 136, 2)
Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(73, 23, 36)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(40, 25, 37)),
        ColorSequenceKeypoint.new(1, Config.Panel),
    }),
    Rotation = 12,
}, Hero)
Label(Hero, "أهلًا بعودتك", UDim2.fromOffset(18, 13), UDim2.new(1, -35, 0, 17), {
    TextSize = 10, Color = Color3.fromRGB(255, 132, 145),
})
Label(Hero, "حسن هَب", UDim2.fromOffset(17, 34), UDim2.new(1, -35, 0, 36), {
    TextSize = 27, Font = Enum.Font.GothamBlack,
})
Label(Hero, "واجهة تحكم أنيقة وسهلة الاستخدام.", UDim2.fromOffset(19, 76), UDim2.new(1, -35, 0, 22), {
    TextSize = 12, Color = Config.Muted,
})

local StatusGrid = Create("Frame", {
    Name = "بطاقات_الحالة",
    Size = UDim2.new(1, 0, 0, 104),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
}, Overview)
local VisualStatusCard = Card(StatusGrid, "حالة_الكشف", 104, 1)
VisualStatusCard.Size = UDim2.new(0.5, -6, 1, 0)
VisualStatusCard.Position = UDim2.fromOffset(0, 0)
local MovementStatusCard = Card(StatusGrid, "حالة_السرعة", 104, 2)
MovementStatusCard.Size = UDim2.new(0.5, -6, 1, 0)
MovementStatusCard.Position = UDim2.new(0.5, 6, 0, 0)

Label(VisualStatusCard, "نظام كشف اللاعبين", UDim2.fromOffset(13, 9), UDim2.new(1, -26, 0, 17), {
    TextSize = 10, Color = Config.Muted,
})
local OverviewESPStatus = Label(VisualStatusCard, "الكشف: متوقف", UDim2.fromOffset(13, 29), UDim2.new(1, -20, 0, 20), {
    TextSize = 12, Font = Enum.Font.GothamBold,
})
local QuickESPButton = ActionButton(VisualStatusCard, "إعدادات الكشف", UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 25), false, true)
QuickESPButton.TextSize = 10

Label(MovementStatusCard, "نظام الحركة", UDim2.fromOffset(13, 9), UDim2.new(1, -26, 0, 17), {
    TextSize = 10, Color = Config.Muted,
})
local OverviewSpeedStatus = Label(MovementStatusCard, "السرعة: أساسية", UDim2.fromOffset(13, 29), UDim2.new(1, -20, 0, 20), {
    TextSize = 12, Font = Enum.Font.GothamBold,
})
local QuickSpeedButton = ActionButton(MovementStatusCard, "إعدادات السرعة", UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 25), false, true)
QuickSpeedButton.TextSize = 10

local AboutCard = Card(Overview, "نصيحة", 74, 4)
Label(AboutCard, "اختصار سريع", UDim2.fromOffset(15, 8), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(AboutCard, "اضغط Right Shift لإخفاء الواجهة أو إظهارها من جديد.", UDim2.fromOffset(15, 28), UDim2.new(1, -30, 0, 28), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})

local ESPCard = Card(Visuals, "بطاقة_كشف_اللاعبين", 112, 2)
Label(ESPCard, "تمييز اللاعبين", UDim2.fromOffset(16, 10), UDim2.new(1, -175, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBlack,
})
Label(ESPCard, "تمييز شخصيات اللاعبين الآخرين باللون الأحمر.", UDim2.fromOffset(17, 39), UDim2.new(1, -34, 0, 24), {
    TextSize = 11, Color = Config.Muted, Wrapped = true,
})
local ESPButton = ActionButton(ESPCard, "تشغيل الكشف", UDim2.new(1, -133, 0, 13), UDim2.fromOffset(116, 34), true, true)
Label(ESPCard, "لا يشمل شخصيتك أنت.", UDim2.fromOffset(17, 76), UDim2.new(1, -34, 0, 19), {
    TextSize = 10, Color = Config.Muted,
})

local StyleCard = Card(Visuals, "بطاقة_المظهر", 145, 3)
Label(StyleCard, "مظهر التحديد", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 23), {
    TextSize = 14, Font = Enum.Font.GothamBlack,
})
Label(StyleCard, "شفافية التعبئة (%)", UDim2.fromOffset(17, 39), UDim2.fromOffset(135, 18), {
    TextSize = 10, Color = Config.Muted,
})
Label(StyleCard, "شفافية المحيط (%)", UDim2.fromOffset(165, 39), UDim2.fromOffset(135, 18), {
    TextSize = 10, Color = Config.Muted,
})
local FillInput = InputBox(StyleCard, "35", "0 - 100", UDim2.fromOffset(17, 61), UDim2.fromOffset(125, 34))
local OutlineInput = InputBox(StyleCard, "0", "0 - 100", UDim2.fromOffset(165, 61), UDim2.fromOffset(135, 34))
local ApplyStyleButton = ActionButton(StyleCard, "تطبيق المظهر", UDim2.new(1, -139, 0, 61), UDim2.fromOffset(122, 34), true, true)
ApplyStyleButton.TextSize = 10
local StyleStatus = Label(StyleCard, "التعبئة والمحيط باللون الأحمر", UDim2.fromOffset(17, 105), UDim2.new(1, -34, 0, 22), {
    TextSize = 10, Color = Config.Muted,
})

local SpeedCard = Card(Movement, "بطاقة_السرعة", 193, 2)
Label(SpeedCard, "مضاعف السرعة", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 24), {
    TextSize = 15, Font = Enum.Font.GothamBlack,
})
Label(SpeedCard, "أدخل قيمة من 1x إلى 10x.", UDim2.fromOffset(17, 37), UDim2.new(1, -34, 0, 19), {
    TextSize = 11, Color = Config.Muted,
})
local SpeedInput = InputBox(SpeedCard, "2x", "2x / 5x / 10x", UDim2.fromOffset(17, 67), UDim2.fromOffset(145, 38))
local ApplySpeedButton = ActionButton(SpeedCard, "تطبيق السرعة", UDim2.fromOffset(174, 67), UDim2.fromOffset(130, 38), true, true)
ApplySpeedButton.TextSize = 10
local ResetSpeedButton = ActionButton(SpeedCard, "إعادة ضبط", UDim2.fromOffset(316, 67), UDim2.fromOffset(91, 38), false, true)
ResetSpeedButton.TextSize = 10
local SpeedStatus = Label(SpeedCard, "السرعة الحالية: بانتظار الشخصية", UDim2.fromOffset(17, 113), UDim2.new(1, -34, 0, 20), {
    TextSize = 11, Color = Config.Muted,
})
local SpeedStateButton = ActionButton(SpeedCard, "السرعة: متوقفة", UDim2.fromOffset(17, 146), UDim2.fromOffset(145, 29), false, true)
SpeedStateButton.TextSize = 10

local SpeedInfo = Card(Movement, "معلومات_السرعة", 79, 3)
Label(SpeedInfo, "معلومة", UDim2.fromOffset(15, 8), UDim2.new(1, -30, 0, 16), {
    TextSize = 10, Font = Enum.Font.GothamBold, Color = Config.Accent,
})
Label(SpeedInfo, "تُحسب السرعة من قيمة WalkSpeed الأساسية للشخصية.", UDim2.fromOffset(15, 28), UDim2.new(1, -30, 0, 32), {
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
    OverviewESPStatus.Text = State.ESP and "الكشف: يعمل" or "الكشف: متوقف"
    OverviewESPStatus.TextColor3 = State.ESP and Config.Accent or Config.Text
    OverviewSpeedStatus.Text = State.Speed
        and string.format("السرعة: %gx", State.Multiplier)
        or "السرعة: أساسية"
    OverviewSpeedStatus.TextColor3 = State.Speed and Config.Accent or Config.Text

    ESPButton.Text = State.ESP and "إيقاف الكشف" or "تشغيل الكشف"
    ESPButton.BackgroundColor3 = State.ESP and Config.Panel or Config.Accent
    ESPButton:SetAttribute("Active", State.ESP)

    SpeedStateButton.Text = State.Speed and "السرعة: تعمل" or "السرعة: متوقفة"
    SpeedStateButton.BackgroundColor3 = State.Speed and Config.Accent or Config.Panel
    SpeedStateButton:SetAttribute("Active", State.Speed)
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
        StyleStatus.Text = "أدخل قيمًا من 0 إلى 100."
        StyleStatus.TextColor3 = Config.Accent
        return
    end

    State.FillTransparency = fillPercent / 100
    State.OutlineTransparency = outlinePercent / 100
    RefreshESP()
    StyleStatus.Text = string.format("التعبئة: %d%%  •  المحيط: %d%%", fillPercent, outlinePercent)
    StyleStatus.TextColor3 = Config.Muted
end

local function UpdateSpeed()
    local humanoid = GetHumanoid()
    if not humanoid then
        SpeedStatus.Text = "السرعة الحالية: بانتظار الشخصية"
        return
    end

    local multiplier = State.Speed and State.Multiplier or 1
    local targetSpeed = State.BaseSpeed * multiplier
    humanoid.WalkSpeed = targetSpeed
    SpeedStatus.Text = string.format("السرعة الحالية: %g  •  الأساسية: %g", targetSpeed, State.BaseSpeed)
    SpeedStatus.TextColor3 = Config.Muted
    UpdateDashboard()
end

local function ParseMultiplier()
    local raw = SpeedInput.Text:lower():gsub("%s+", "")
    raw = raw:gsub("x$", "")
    local value = tonumber(raw)
    if not value or value ~= value or value == math.huge or value == -math.huge
        or value < 1 or value > Config.MaxMultiplier then
        return nil
    end
    return value
end

local function ToggleSpeed()
    if State.Speed then
        State.Speed = false
        UpdateSpeed()
        return
    end

    local humanoid = GetHumanoid()
    if not humanoid then
        SpeedStatus.Text = "لا توجد شخصية جاهزة."
        return
    end

    local multiplier = ParseMultiplier()
    if not multiplier then
        SpeedStatus.Text = "قيمة غير صالحة. استخدم 1x إلى 10x."
        SpeedStatus.TextColor3 = Config.Accent
        return
    end

    State.BaseSpeed = humanoid.WalkSpeed
    State.Multiplier = multiplier
    State.Speed = true
    UpdateSpeed()
end

Connect(ESPButton.Activated, function() SetESP(not State.ESP) end)
Connect(QuickESPButton.Activated, function() ShowPage("كشف_اللاعبين") end)
Connect(QuickSpeedButton.Activated, function() ShowPage("الحركة") end)
Connect(ApplyStyleButton.Activated, ApplyESPStyle)

Connect(ApplySpeedButton.Activated, function()
    local humanoid = GetHumanoid()
    if not humanoid then
        SpeedStatus.Text = "لا توجد شخصية جاهزة."
        return
    end

    local multiplier = ParseMultiplier()
    if not multiplier then
        SpeedStatus.Text = "قيمة غير صالحة. استخدم 1x إلى 10x."
        SpeedStatus.TextColor3 = Config.Accent
        return
    end

    if not State.Speed then State.BaseSpeed = humanoid.WalkSpeed end
    State.Multiplier = multiplier
    State.Speed = true
    UpdateSpeed()
end)

Connect(ResetSpeedButton.Activated, function()
    State.Speed = false
    State.Multiplier = 1
    SpeedInput.Text = "1x"
    UpdateSpeed()
end)

Connect(SpeedStateButton.Activated, ToggleSpeed)

local function TrackPlayer(player)
    if player == LocalPlayer then return end
    ConnectPlayer(player, player.CharacterAdded, function()
        task.defer(function()
            if player.Parent == Players and State.ESP then ApplyHighlight(player) end
        end)
    end)
    ConnectPlayer(player, player.CharacterRemoving, function()
        RemoveHighlight(player)
    end)
    if State.ESP and player.Character then ApplyHighlight(player) end
end

for _, player in ipairs(Players:GetPlayers()) do TrackPlayer(player) end
Connect(Players.PlayerAdded, TrackPlayer)
Connect(Players.PlayerRemoving, function(player)
    RemoveHighlight(player)
    DisconnectPlayer(player)
end)

Connect(LocalPlayer.CharacterAdded, function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or State.Destroyed then return end
        if not State.Speed then State.BaseSpeed = humanoid.WalkSpeed end
        UpdateSpeed()
    end)
end)

if LocalPlayer.Character then
    local humanoid = GetHumanoid()
    if humanoid then State.BaseSpeed = humanoid.WalkSpeed end
end

-- التهيئة النهائية
ShowPage("الرئيسية")
UpdateDashboard()
if not State.Speed then
    local humanoid = GetHumanoid()
    if humanoid then
        SpeedStatus.Text = string.format("السرعة الحالية: %g  •  الأساسية: %g", humanoid.WalkSpeed, State.BaseSpeed)
    end
end
