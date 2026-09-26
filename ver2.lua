-- TAB ICON SLOT FIX: reserves a permanent 40px area before tab text for future icons.
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TextService = game:GetService("TextService")

-- SCOOPHUB BRANDING
-- Change this one asset ID to update both the header logo and floating open/close icon.
local HUB_LOGO = "rbxassetid://97406911955707"

local Custom = {}
do
	Custom.ColorRGB = Color3.fromRGB(255, 8, 8)
	Custom.ObsidianTop = Color3.fromRGB(15, 14, 22)
	Custom.ObsidianMid = Color3.fromRGB(6, 7, 12)
	Custom.ObsidianLow = Color3.fromRGB(26, 14, 38)
	Custom.Surface = Color3.fromRGB(18, 19, 27)
	Custom.Surface2 = Color3.fromRGB(23, 22, 32)
	Custom.Surface3 = Color3.fromRGB(31, 27, 42)
	Custom.Stroke = Color3.fromRGB(196, 40, 28)
	Custom.Text = Color3.fromRGB(235, 236, 245)
	Custom.Muted = Color3.fromRGB(156, 154, 170)
	Custom.Font = Enum.Font.GothamBold
	Custom.FontBody = Enum.Font.Gotham

	function Custom:Create(Name, Properties, Parent)
		local _instance = Instance.new(Name)

		for i, v in pairs(Properties) do
			_instance[i] = v
		end

		if Parent then
			_instance.Parent = Parent
		end

		return _instance
	end

	function Custom:EnabledAFK()
		Player.Idled:Connect(function()
			VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		end)
	end
end

Custom:EnabledAFK()

local function TrySet(Object, Properties)
	if not Object then
		return false
	end

	local Ok = true
	for Property, Value in pairs(Properties) do
		local Success = pcall(function()
			Object[Property] = Value
		end)
		Ok = Ok and Success
	end

	return Ok
end

local function SafeGet(Object, Property, Fallback)
	if not Object then
		return Fallback
	end

	local Success, Value = pcall(function()
		return Object[Property]
	end)

	if Success then
		return Value
	end

	return Fallback
end

local function SafeTween(Object, Info, Properties)
	if not Object then
		return nil
	end

	local Success, Tween = pcall(function()
		return TweenService:Create(Object, Info, Properties)
	end)

	if Success and Tween then
		local Played = pcall(function()
			Tween:Play()
		end)

		if Played then
			return Tween
		end
	end

	TrySet(Object, Properties)
	return nil
end

local function SafeChildren(Object)
	local Success, Children = pcall(function()
		return Object:GetChildren()
	end)

	return Success and Children or {}
end

local function EstimateWrappedHeight(Text, CharsPerLine, LineHeight, MinLines, MaxLines)
	Text = tostring(Text or "")
	if Text == "" then
		return 0
	end

	CharsPerLine = math.max(8, CharsPerLine or 56)
	LineHeight = LineHeight or 13
	MinLines = MinLines or 1
	MaxLines = MaxLines or 4

	local Lines = 0
	for Segment in (Text .. "\n"):gmatch("(.-)\n") do
		Lines += math.max(1, math.ceil(#Segment / CharsPerLine))
	end

	Lines = math.clamp(Lines, MinLines, MaxLines)
	return Lines * LineHeight
end

local function CompactRowHeight(Content)
	return tostring(Content or "") == "" and 35 or 44
end

-- Auto row-sizing helpers.
-- Geometry is tuned so a single-line description stays 44px (identical to the old fixed rows),
-- while longer descriptions grow the row instead of getting cut off with "...".
local ROW_DESC_LINE = 13
local ROW_BOTTOM_PAD = 10
local ROW_MAX_LINES = 3

-- Measure how many wrapped lines a description needs at its real on-screen width.
-- Falls back to a character estimate when the pixel width isn't resolved yet (first frame).
local function MeasureDescLines(WidthPx, Content, Font, TextSize, MaxLines)
	Content = tostring(Content or "")
	MaxLines = MaxLines or ROW_MAX_LINES
	if Content == "" then
		return 0
	end

	WidthPx = math.floor(tonumber(WidthPx) or 0)
	TextSize = TextSize or 12

	local Lines
	if WidthPx >= 8 then
		local Ok, Bounds = pcall(function()
			return TextService:GetTextSize(Content, TextSize, Font, Vector2.new(WidthPx, 1000000))
		end)
		if Ok and Bounds and Bounds.Y > 0 then
			Lines = math.max(1, math.floor((Bounds.Y / math.max(1, TextSize)) + 0.5))
		end
	end

	if not Lines then
		local CharsPerLine = WidthPx >= 8 and math.max(8, math.floor(WidthPx / (TextSize * 0.55))) or 34
		Lines = 0
		for Segment in (Content .. "\n"):gmatch("(.-)\n") do
			Lines += math.max(1, math.ceil(#Segment / CharsPerLine))
		end
	end

	return math.clamp(Lines, 1, MaxLines)
end

local ROW_TOP_PAD = 7
local ROW_TITLE_LINE = 13
local ROW_GAP = 1
local ROW_TITLE_MAX_LINES = 2

-- Lay out a compact row's (wrapping) title + optional (wrapping) description and return the
-- row height. A single-line title with a single-line description stays 44px, and a single-line
-- title with no description stays 35px (centered) -- identical to the old fixed rows.
local function LayoutCompactRow(TitleLabel, DescLabel, Content, ReservedX)
	Content = tostring(Content or "")
	ReservedX = ReservedX or -180

	local TitleLines = MeasureDescLines(
		TitleLabel.AbsoluteSize.X,
		TitleLabel.Text,
		TitleLabel.Font,
		TitleLabel.TextSize,
		ROW_TITLE_MAX_LINES
	)
	if TitleLines <= 0 then
		TitleLines = 1
	end

	if Content == "" then
		if DescLabel then
			DescLabel.Visible = false
		end
		if TitleLines <= 1 then
			TitleLabel.Size = UDim2.new(1, ReservedX, 0, ROW_TITLE_LINE)
			TitleLabel.Position = UDim2.new(0, 10, 0.5, -7)
			return 35
		end
		TitleLabel.Size = UDim2.new(1, ReservedX, 0, TitleLines * ROW_TITLE_LINE)
		TitleLabel.Position = UDim2.new(0, 10, 0, 11)
		return 11 + TitleLines * ROW_TITLE_LINE + 11
	end

	local DescLines = MeasureDescLines(
		DescLabel.AbsoluteSize.X,
		Content,
		DescLabel.Font,
		DescLabel.TextSize,
		ROW_MAX_LINES
	)
	if DescLines <= 0 then
		DescLines = 1
	end

	local DescTop = ROW_TOP_PAD + TitleLines * ROW_TITLE_LINE + ROW_GAP

	TitleLabel.Position = UDim2.new(0, 10, 0, ROW_TOP_PAD)
	TitleLabel.Size = UDim2.new(1, ReservedX, 0, TitleLines * ROW_TITLE_LINE)
	DescLabel.Visible = true
	DescLabel.Position = UDim2.new(0, 10, 0, DescTop)
	DescLabel.Size = UDim2.new(1, ReservedX, 0, DescLines * ROW_DESC_LINE)

	return DescTop + DescLines * ROW_DESC_LINE + ROW_BOTTOM_PAD
end

-- Wire a description label so the row re-measures whenever its real width first resolves
-- (or changes). Guarded on width so our own height writes don't cause a feedback loop.
local function BindAutoRowHeight(DescLabel, Recompute)
	local LastWidth = -1
	local Connection = DescLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local Width = math.floor(DescLabel.AbsoluteSize.X)
		if Width == LastWidth then
			return
		end
		LastWidth = Width
		Recompute()
	end)
	return Connection
end

local function GetGuiParent()
	local GuiParent

	if RunService:IsStudio() then
		GuiParent = Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui", 5)
	end

	if not GuiParent and type(gethui) == "function" then
		pcall(function()
			GuiParent = gethui()
		end)
	end

	if not GuiParent then
		pcall(function()
			local CoreGui = game:GetService("CoreGui")
			if type(cloneref) == "function" then
				GuiParent = cloneref(CoreGui)
			else
				GuiParent = CoreGui
			end
		end)
	end

	if not GuiParent then
		GuiParent = Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui")
	end

	return GuiParent
end

local function OpenClose()
	local ScreenGui = Custom:Create("ScreenGui", {
		Name = "ScoopHubRuntime",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, GetGuiParent())

	local Close_ImageButton = Custom:Create("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		Position = UDim2.new(0.1021, 0, 0.0743, 0),
		Size = UDim2.new(0, 50, 0, 50),
		Image = "",
		AutoButtonColor = false,
		Visible = true,
		Active = true,
	}, ScreenGui)

	Custom:Create("UICorner", {
		Name = "MainCorner",
		CornerRadius = UDim.new(0, 12),
	}, Close_ImageButton)

	-- Keep the logo smaller than the button so the floating launcher
	-- matches the black rounded-square ScoopHub icon style.
	Custom:Create("ImageLabel", {
		Name = "HubLogo",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		Image = HUB_LOGO,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
	}, Close_ImageButton)

	-- Better drag (same method as big GUI)
	local dragging = false
	local dragStart = Vector2.new()
	local startPos = UDim2.new()
	local hasDragged = false

	Close_ImageButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			hasDragged = false
			dragStart = UserInputService:GetMouseLocation()
			startPos = Close_ImageButton.Position
			Close_ImageButton:SetAttribute("WisDragged", false)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Close_ImageButton:SetAttribute("WisDragged", hasDragged)
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not dragging then return end

		local mouse = UserInputService:GetMouseLocation()
		local delta = mouse - dragStart

		if delta.Magnitude > 5 then
			hasDragged = true
			Close_ImageButton:SetAttribute("WisDragged", true)
		end

		Close_ImageButton.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)

	return Close_ImageButton
end

local Open_Close = OpenClose()

local function MakeDraggable(topbarobject, object)
	local dragging = false
	local dragStart = Vector2.new()
	local startPos = UDim2.new()

	topbarobject.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = UserInputService:GetMouseLocation()
			startPos = object.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not dragging then
			return
		end

		local mouse = UserInputService:GetMouseLocation()
		local delta = mouse - dragStart

		object.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end)
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		pcall(function()
			Button.ClipsDescendants = true
		end)

		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://266543268"
		Circle.ImageColor3 = Color3.fromRGB(130, 130, 130)
		Circle.ImageTransparency = 0.7
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.AnchorPoint = Vector2.new(0.5, 0.5)
		Circle.Position = UDim2.new(0.5, 0, 0.5, 0)
		Circle.Size = UDim2.new(0, 0, 0, 0)
		Circle.Parent = Button

		local Size = 42
		pcall(function()
			Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.2
		end)

		SafeTween(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, Size, 0, Size),
			ImageTransparency = 1,
		})

		task.delay(0.25, function()
			pcall(function()
				Circle:Destroy()
			end)
		end)
	end)
end

local Icons = {
	player = "rbxassetid://12120698352",
	web = "rbxassetid://137601480983962",
	bag = "rbxassetid://8601111810",
	shop = "rbxassetid://4985385964",
	cart = "rbxassetid://128874923961846",
	plug = "rbxassetid://137601480983962",
	settings = "rbxassetid://70386228443175",
	loop = "rbxassetid://122032243989747",
	gps = "rbxassetid://17824309485",
	compas = "rbxassetid://125300760963399",
	gamepad = "rbxassetid://84173963561612",
	boss = "rbxassetid://13132186360",
	scroll = "rbxassetid://114127804740858",
	menu = "rbxassetid://6340513838",
	crosshair = "rbxassetid://12614416478",
	user = "rbxassetid://108483430622128",
	stat = "rbxassetid://12094445329",
	eyes = "rbxassetid://14321059114",
	sword = "rbxassetid://82472368671405",
	discord = "rbxassetid://94434236999817",
	star = "rbxassetid://107005941750079",
	skeleton = "rbxassetid://17313330026",
	payment = "rbxassetid://18747025078",
	scan = "rbxassetid://109869955247116",
	alert = "rbxassetid://73186275216515",
	question = "rbxassetid://17510196486",
	idea = "rbxassetid://16833255748",
	strom = "rbxassetid://13321880293",
	water = "rbxassetid://100076212630732",
	dcs = "rbxassetid://15310731934",
	start = "rbxassetid://108886429866687",
	next = "rbxassetid://12662718374",
	rod = "rbxassetid://103247953194129",
	fish = "rbxassetid://97167558235554",
	mouse_pointer_click = "rbxassetid://7734010488",
}

local DefaultTabIcons = {
	info = "idea",
	farm = "loop",
	shop = "shop",
	pet = "player",
	misc = "menu",
	visual = "eyes",
	config = "settings",
}

local ScoopHub_Library = {}

ScoopHub_Library.Icons = Icons
ScoopHub_Library.DefaultTabIcons = DefaultTabIcons
ScoopHub_Library.Unloaded = false

function ScoopHub_Library:SetNotification(Config)
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
	local Time = Config[5] or Config.Time or 0.5
	local Delay = Config[6] or Config.Delay or 5

	local NotificationGui = Custom:Create("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, GetGuiParent())

	local NotificationLayout = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -30, 1, -30),
		Size = UDim2.new(0, 320, 1, 0),
		Name = "NotificationLayout",
	}, NotificationGui)

	local Count = 0

	NotificationLayout.ChildRemoved:Connect(function()
		Count = 0
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

		for _, v in ipairs(SafeChildren(NotificationLayout)) do
			local NewPOS = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count))
			SafeTween(v, tweenInfo, { Position = NewPOS })
			Count = Count + 1
		end
	end)

	local _Count = 0
	for _, v in ipairs(SafeChildren(NotificationLayout)) do
		_Count = -v.Position.Y.Offset + v.Size.Y.Offset + 12
	end

	local NotificationFrame = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 150),
		Name = "NotificationFrame",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -_Count),
	}, NotificationLayout)

	local NotificationFrameReal = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 400, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Name = "NotificationFrameReal",
	}, NotificationFrame)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}, NotificationFrameReal)

	local DropShadowHolder = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
		Name = "DropShadowHolder",
		Parent = NotificationFrameReal,
	})

	Custom:Create("ImageLabel", {
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 47, 1, 47),
		ZIndex = 0,
		Name = "DropShadow",
		Parent = DropShadowHolder,
	})

	local Top = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Name = "Top",
		Parent = NotificationFrameReal,
	})

	local TextLabel = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = Top,
	})

	Custom:Create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 0.3,
		Parent = TextLabel,
	})

	Custom:Create("UICorner", {
		Parent = Top,
		CornerRadius = UDim.new(0, 5),
	})

	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = Description,
		TextColor3 = Custom.ColorRGB,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, math.clamp(#tostring(Title) * 8, 30, 155) + 15, 0, 0),
		Parent = Top,
	})

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 0.4,
		Parent = TextLabel1,
	})

	local Close = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Close",
		Parent = Top,
	})

	local TextLabel2 = Custom:Create("TextLabel", {
		Font = Custom.FontBody,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Text = Content,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		TextColor3 = Color3.fromRGB(150, 150, 150),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 27),
		Size = UDim2.new(1, -20, 0, 13),
		Parent = NotificationFrameReal,
	})

	local NotificationContentHeight = math.max(13, EstimateWrappedHeight(Content, 42, 13, 1, 5))
	TextLabel2.Size = UDim2.new(1, -20, 0, NotificationContentHeight)
	TextLabel2.TextWrapped = true

	if NotificationContentHeight < 27 then
		NotificationFrame.Size = UDim2.new(1, 0, 0, 65)
	else
		NotificationFrame.Size = UDim2.new(1, 0, 0, NotificationContentHeight + 40)
	end

	local NotifFuncs = {}
	local Waitted = false

	local function CloseNotif()
		if Waitted then
			return
		end
		Waitted = true

		SafeTween(
			NotificationFrameReal,
			TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0, 400, 0, 0) }
		)

		task.delay(tonumber(Time) / 1.2, function()
			pcall(function()
				NotificationFrame:Destroy()
			end)
		end)
	end

	NotifFuncs.Close = CloseNotif

	Close.Activated:Connect(CloseNotif)

	SafeTween(
		NotificationFrameReal,
		TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
		{ Position = UDim2.new(0, 0, 0, 0) }
	)

	task.delay(tonumber(Delay), CloseNotif)

	return NotifFuncs
end

function ScoopHub_Library:CreateWindow(Config)
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	-- Wider compact GUI with a noticeably roomier sidebar/tab area.
	-- These values are intentionally forced so scripts using this library
	-- cannot override the compact layout through CreateWindow(Config).
	local TabWidth = 135
	local SizeUi = UDim2.fromOffset(600, 400)
	local DiscordInvite = Config.Discord or Config[5] or "discord.gg/9czKzA5mVt"
	local DiscordLogo = Config.DiscordIcon or Config[6] or "rbxassetid://94434236999817"
	local HubLogo = Config.Logo or Config.TitleLogo or HUB_LOGO
	local HubLogoSize = Config.LogoSize or 26
	local HubLogoColor = Config.LogoColor or Color3.fromRGB(255, 255, 255)

	local Funcs = {}

	local ScoopHubGui = Custom:Create("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, GetGuiParent())

	local DropShadowHolder = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = SizeUi,
		ZIndex = 0,
		Name = "DropShadowHolder",
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}, ScoopHubGui)

	local DropShadow = Custom:Create("ImageLabel", {
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(5, 5, 9),
		ImageTransparency = 0.52,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		ZIndex = 0,
		Name = "DropShadow",
	}, DropShadowHolder)

	local Main = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.11,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		Name = "Main",
	}, DropShadow)

	Custom:Create("UICorner", {}, Main)

	Custom:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Custom.ObsidianTop),
			ColorSequenceKeypoint.new(0.52, Custom.ObsidianMid),
			ColorSequenceKeypoint.new(1, Custom.ObsidianLow),
		}),
		Rotation = 16,
	}, Main)

	Custom:Create("UIStroke", {
		Color = Custom.Stroke,
		Thickness = 1,
		Transparency = 0.86,
	}, Main)

	local Top = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		Name = "Top",
	}, Main)

	local TextLabel = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = "",
		TextColor3 = Custom.ColorRGB,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
	}, Top)

	Custom:Create("UICorner", {}, Top)

	local LogoImage = Custom:Create("ImageLabel", {
		Image = HubLogo,
		ImageColor3 = HubLogoColor,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 11, 0.5, 0),
		Size = UDim2.new(0, HubLogoSize, 0, HubLogoSize),
		Name = "LogoImage",
	}, Top)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, math.floor(HubLogoSize / 4)),
	}, LogoImage)

	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = Config.HubName or Config.Title,
		TextColor3 = Config.HubNameColor or Color3.fromRGB(255, 60, 60),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 40, 0.5, 0),
		Size = UDim2.new(0, 100, 0, 20),
		Visible = true,
		Name = "HubTitle",
	}, Top)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 0.4,
	}, TextLabel1)

	local DiscordPill = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Custom.Surface3,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 145, 0.5, 0), -- 145 ung new place nya pero pwede edit yan later ang slow kasi ng update
		Size = UDim2.new(0, 150, 0, 22),
		Name = "DiscordPill",
	}, Top)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
	}, DiscordPill)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 1,
		Transparency = 0.62,
	}, DiscordPill)

	local DiscordIcon = Custom:Create("ImageLabel", {
		Image = DiscordLogo,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ScaleType = Enum.ScaleType.Fit,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		Name = "DiscordIcon",
	}, DiscordPill)

	local DiscordText = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = DiscordInvite,
		TextColor3 = Color3.fromRGB(235, 235, 240),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 27, 0, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Name = "DiscordText",
	}, DiscordPill)

	local DiscordTextWidth = math.clamp(#tostring(DiscordInvite) * 7, 40, 170)

	if DiscordLogo == "" then
		DiscordIcon.Visible = false
		DiscordText.Position = UDim2.new(0, 11, 0, 0)
		DiscordText.Size = UDim2.new(1, -16, 1, 0)
		DiscordPill.Size = UDim2.new(0, math.clamp(DiscordTextWidth + 22, 58, 178), 0, 22)
	else
		DiscordPill.Size = UDim2.new(0, math.clamp(DiscordTextWidth + 38, 72, 190), 0, 22)
	end

	local DiscordButton = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "DiscordButton",
	}, DiscordPill)

	DiscordButton.Activated:Connect(function()
		pcall(function()
			if setclipboard then
				setclipboard(DiscordInvite)
			end
		end)
		ScoopHub_Library:SetNotification({
			Title = "ScoopHub",
			Description = "Discord",
			Content = "Copied to clipboard: " .. DiscordInvite,
		})
	end)

	local Close = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Close",
	}, Top)

	local Min = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "-",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Min",
	}, Top)

	local LayersTab = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 9, 0, 50),
		Size = UDim2.new(0, TabWidth, 1, -59),
		Name = "LayersTab",
	}, Main)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 2),
	}, LayersTab)

	local DecideFrame = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Custom.ColorRGB,
		BackgroundTransparency = 0.4,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 1),
		Name = "DecideFrame",
	}, Main)

	Custom:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Custom.ObsidianMid),
			ColorSequenceKeypoint.new(0.5, Custom.ColorRGB),
			ColorSequenceKeypoint.new(1, Custom.ObsidianMid),
		}),
	}, DecideFrame)

	local Layers = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, TabWidth + 18, 0, 50),
		Size = UDim2.new(1, -(TabWidth + 9 + 18), 1, -59),
		Name = "Layers",
	}, Main)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 2),
	}, Layers)

	local NameTab = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 24,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		Name = "NameTab",
	}, Layers)

	local LayersReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, -33),
		Name = "LayersReal",
	}, Layers)

	local LayersFolder = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "LayersFolder",
	}, LayersReal)

	local LayersPageLayout = Custom:Create("UIPageLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Name = "LayersPageLayout",
		TweenTime = 0.1,
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
	}, LayersFolder)

	local ScrollTab = Custom:Create("ScrollingFrame", {
		CanvasSize = UDim2.new(0, 0, 2.10000002, 0),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 1, -44),
		Name = "ScrollTab",
	}, LayersTab)

	local UIListLayout = Custom:Create("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ScrollTab)

	local SearchTab = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Custom.Surface2,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.new(1, -4, 0, 26),
		Name = "SearchTab",
	}, LayersTab)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, SearchTab)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 1,
		Transparency = 0.72,
	}, SearchTab)

	Custom:Create("ImageLabel", {
		Image = "rbxassetid://3926305904",
		ImageRectOffset = Vector2.new(964, 324),
		ImageRectSize = Vector2.new(36, 36),
		ImageColor3 = Color3.fromRGB(170, 170, 178),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 7, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		Name = "SearchIcon",
	}, SearchTab)

	local SearchBox = Custom:Create("TextBox", {
		Font = Custom.Font,
		PlaceholderText = "Search",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 148),
		Text = "",
		TextColor3 = Color3.fromRGB(235, 235, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Name = "SearchBox",
	}, SearchTab)

	local SearchRegistry = {}
	local SearchRows = {}
	local SearchMaxResults = 7
	local SelectSearchEntry = nil
	local RefreshSearchResults = nil

	local SearchResults = Custom:Create("Frame", {
		BackgroundColor3 = Custom.ObsidianMid,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 2, 0, 31),
		Size = UDim2.new(1, -4, 0, 0),
		Visible = false,
		ZIndex = 12,
		Name = "SearchResults",
	}, LayersTab)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, SearchResults)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 1,
		Transparency = 0.62,
	}, SearchResults)

	local SearchResultsList = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 1, -8),
		ZIndex = 13,
		Name = "SearchResultsList",
	}, SearchResults)

	Custom:Create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, SearchResultsList)

	local NoSearchResults = Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = "No results found",
		TextColor3 = Color3.fromRGB(170, 170, 178),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 99,
		Size = UDim2.new(1, -10, 0, 28),
		Visible = false,
		ZIndex = 14,
		Name = "NoSearchResults",
	}, SearchResultsList)

	for Index = 1, SearchMaxResults do
		local Result = Custom:Create("Frame", {
			BackgroundColor3 = Custom.Surface2,
			BackgroundTransparency = 0.16,
			BorderSizePixel = 0,
			LayoutOrder = Index,
			Size = UDim2.new(1, 0, 0, 34),
			Visible = false,
			ZIndex = 14,
			Name = "SearchResult",
		}, SearchResultsList)

		Custom:Create("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}, Result)

		local ResultButton = Custom:Create("TextButton", {
			Font = Custom.Font,
			Text = "",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 16,
			Name = "SearchResultButton",
		}, Result)

		local ResultTitle = Custom:Create("TextLabel", {
			Font = Custom.Font,
			Text = "",
			TextColor3 = Color3.fromRGB(238, 238, 242),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 7, 0, 5),
			Size = UDim2.new(1, -14, 0, 13),
			ZIndex = 15,
			Name = "SearchResultTitle",
		}, Result)

		local ResultMeta = Custom:Create("TextLabel", {
			Font = Custom.FontBody,
			Text = "",
			TextColor3 = Color3.fromRGB(165, 165, 174),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 7, 0, 18),
			Size = UDim2.new(1, -14, 0, 12),
			ZIndex = 15,
			Name = "SearchResultMeta",
		}, Result)

		local RowData = {
			Frame = Result,
			Title = ResultTitle,
			Meta = ResultMeta,
			Entry = nil,
		}

		ResultButton.Activated:Connect(function()
			if RowData.Entry and SelectSearchEntry then
				SelectSearchEntry(RowData.Entry)
			end
		end)

		SearchRows[Index] = RowData
	end

	local function NormalizeSearchText(Text)
		Text = tostring(Text or "")
		Text = Text:gsub("%[", ""):gsub("%]", "")
		Text = Text:gsub("^%s+", ""):gsub("%s+$", "")
		return string.lower(Text)
	end

	local function RegisterSearchEntry(Entry)
		if not Entry or not Entry.Instance then
			return
		end
		Entry.Title = tostring(Entry.Title or "")
		if Entry.Title == "" then
			return
		end
		Entry.Type = tostring(Entry.Type or "")
		Entry.Tab = tostring(Entry.Tab or "")
		Entry.Section = tostring(Entry.Section or "")
		Entry.SearchText =
			NormalizeSearchText(Entry.Title .. " " .. Entry.Type .. " " .. Entry.Tab .. " " .. Entry.Section)
		table.insert(SearchRegistry, Entry)

		if SafeGet(SearchBox, "Text", "") ~= "" and RefreshSearchResults then
			RefreshSearchResults()
		end
	end

	RefreshSearchResults = function()
		local Query = NormalizeSearchText(SafeGet(SearchBox, "Text", ""))
		local HasQuery = Query ~= ""

		SearchResults.Visible = HasQuery
		ScrollTab.Visible = not HasQuery

		if not HasQuery then
			for _, Row in ipairs(SearchRows) do
				Row.Entry = nil
				Row.Frame.Visible = false
			end

			NoSearchResults.Visible = false
			SearchResults.Size = UDim2.new(1, -4, 0, 0)
			return
		end

		local ResultCount = 0

		local function PushResult(Entry)
			if string.find(Entry.SearchText, Query, 1, true) then
				ResultCount += 1

				if ResultCount <= SearchMaxResults then
					local Row = SearchRows[ResultCount]
					Row.Entry = Entry
					Row.Frame.Visible = true
					Row.Title.Text = Entry.Title
					Row.Meta.Text = (Entry.Section ~= "" and Entry.Section or Entry.Tab) .. " - " .. Entry.Type
				end
			end
		end

		for _, Entry in ipairs(SearchRegistry) do
			if Entry.Type ~= "Section" then
				PushResult(Entry)
				if ResultCount >= SearchMaxResults then
					break
				end
			end
		end

		if ResultCount < SearchMaxResults then
			for _, Entry in ipairs(SearchRegistry) do
				if Entry.Type == "Section" then
					PushResult(Entry)
					if ResultCount >= SearchMaxResults then
						break
					end
				end
			end
		end

		for Index = ResultCount + 1, SearchMaxResults do
			local Row = SearchRows[Index]
			Row.Entry = nil
			Row.Frame.Visible = false
		end

		NoSearchResults.Visible = ResultCount == 0
		SearchResults.Size = ResultCount == 0 and UDim2.new(1, -4, 0, 40)
			or UDim2.new(1, -4, 0, (math.min(ResultCount, SearchMaxResults) * 37) + 8)
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshSearchResults)

	Min.Activated:Connect(function()
		CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y)
		DropShadowHolder.Visible = false
	end)

	Open_Close.Activated:Connect(function()
		if Open_Close:GetAttribute("WisDragged") then
			return
		end
		if not DropShadowHolder or not DropShadowHolder.Parent then
			return
		end
		CircleClick(Open_Close, Player:GetMouse().X, Player:GetMouse().Y)
		DropShadowHolder.Visible = not DropShadowHolder.Visible
	end)

	local ConfirmHolder = Custom:Create("Frame", {
		Active = true,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 20,
		Visible = false,
		Name = "ConfirmHolder",
	}, Main)

	Custom:Create("UICorner", {}, ConfirmHolder)

	local ConfirmBox = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Custom.Surface2,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 250, 0, 120),
		ZIndex = 21,
		Name = "ConfirmBox",
	}, ConfirmHolder)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}, ConfirmBox)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 1.5,
		Transparency = 0.15,
	}, ConfirmBox)

	Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = "Close ScoopHub?",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 22,
		Name = "ConfirmTitle",
	}, ConfirmBox)

	Custom:Create("TextLabel", {
		Font = Custom.Font,
		Text = "Are you sure you want to close?",
		TextColor3 = Color3.fromRGB(175, 175, 185),
		TextSize = 13,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 0, 16),
		ZIndex = 22,
		Name = "ConfirmDesc",
	}, ConfirmBox)

	local CancelBtn = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "Cancel",
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextSize = 14,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Custom.Surface3,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.new(0.5, -24, 0, 34),
		ZIndex = 22,
		Name = "CancelBtn",
	}, ConfirmBox)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, CancelBtn)

	local OkBtn = Custom:Create("TextButton", {
		Font = Custom.Font,
		Text = "Close",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Custom.ColorRGB,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0.5, -24, 0, 34),
		ZIndex = 22,
		Name = "OkBtn",
	}, ConfirmBox)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, OkBtn)

	Close.Activated:Connect(function()
		CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y)
		ConfirmHolder.Visible = true
		ConfirmHolder.BackgroundTransparency = 1
		ConfirmBox.Size = UDim2.new(0, 232, 0, 110)
		SafeTween(ConfirmHolder, TweenInfo.new(0.15), { BackgroundTransparency = 0.45 })
		SafeTween(
			ConfirmBox,
			TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 250, 0, 120) }
		)
	end)

	CancelBtn.Activated:Connect(function()
		CircleClick(CancelBtn, Player:GetMouse().X, Player:GetMouse().Y)
		SafeTween(ConfirmHolder, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
		task.wait(0.15)
		ConfirmHolder.Visible = false
	end)

	OkBtn.Activated:Connect(function()
		if Open_Close then
			Open_Close.Visible = false
		end
		if ScoopHubGui then
			ScoopHubGui:Destroy()
		end
		if not ScoopHub_Library.Unloaded then
			ScoopHub_Library.Unloaded = true
		end
	end)

	DropShadowHolder.Size = SizeUi
	MakeDraggable(Top, DropShadowHolder)

	local Tabs = {}
	local CountTab = 0
	local CountDropdown = 0
	local CurrentTab = nil
	local TabStates = {}
	local TabKeys = {}
	local TabOrder = {}
	local ActiveCompactDropdownClose = nil
	local ActiveCompactDropdownPopup = nil
	local ActiveCompactDropdownField = nil

	local ElementRegistry = {}
	local ElementTabOrder = {}
	-- Declaration order of keys per tab. ElementRegistry buckets are hash maps, so
	-- iterating them yields an arbitrary order that changes between traversals —
	-- useless for anything mirroring this window's layout.
	local ElementKeyOrder = {}
	local ElementMeta = setmetatable({}, { __mode = "k" })

	local function ExtractElementTitle(Config)
		if type(Config) == "string" then
			return Config
		end

		if type(Config) ~= "table" then
			return ""
		end

		return tostring(Config[1] or Config.Title or Config.Name or "")
	end

	-- Positional Config layout per element type, mirroring each Add* parser below:
	-- { FieldName, PositionalIndex, DefaultWhenAbsent }. Centralised here so the
	-- registry can publish RENDER HINTS alongside each element. Without these, a
	-- consumer holding only the Funcs table cannot know a Slider's bounds or
	-- whether a Dropdown is multi-select — both are plain locals inside Add*.
	local ElementConfigHints = {
		Toggle = { { "Default", 3, false } },
		Input = { { "Default", 3, "" } },
		Slider = { { "Increment", 3, 1 }, { "Min", 4, 0 }, { "Max", 5, 100 }, { "Default", 6, 50 } },
		Dropdown = { { "Multi", 3, false }, { "Options", 4, {} }, { "Default", 5, {} } },
	}

	local function ExtractElementHints(TypeName, Config)
		local Spec = ElementConfigHints[TypeName]
		if not Spec or type(Config) ~= "table" then
			return nil
		end

		local Hints = {}
		for _, Entry in ipairs(Spec) do
			local Field, Index, Default = Entry[1], Entry[2], Entry[3]
			local Value = Config[Index]
			if Value == nil then
				Value = Config[Field]
			end
			if Value == nil then
				Value = Default
			end
			Hints[Field] = Value
		end

		return Hints
	end

	local function RegisterElement(TabName, SectionTitle, TypeName, Config, Funcs)
		if type(Funcs) ~= "table" then
			return
		end

		local ElementTitle = ExtractElementTitle(Config)
		if ElementTitle == "" then
			return
		end

		local TabBucket = ElementRegistry[TabName]
		if not TabBucket then
			TabBucket = {}
			ElementRegistry[TabName] = TabBucket
			ElementKeyOrder[TabName] = {}
			table.insert(ElementTabOrder, TabName)
		end

		local BaseKey = TypeName .. "_" .. ElementTitle
		local Key, Suffix = BaseKey, 2
		while TabBucket[Key] do
			Key = BaseKey .. " (" .. Suffix .. ")"
			Suffix += 1
		end

		TabBucket[Key] = Funcs
		table.insert(ElementKeyOrder[TabName], Key)
		ElementMeta[Funcs] = {
			Tab = TabName,
			Section = SectionTitle,
			Type = TypeName,
			Title = ElementTitle,
			Key = Key,
			Hints = ExtractElementHints(TypeName, Config),
		}

		return Key
	end

	local function NormalizeTabName(TabName)
		local Text = tostring(TabName or "")
		Text = Text:gsub("%[", ""):gsub("%]", "")
		Text = Text:gsub("^%s+", ""):gsub("%s+$", "")
		return string.lower(Text)
	end

	local PreferredTab = Config.DefaultTab or Config.DefaultTabName or ScoopHub_Library.LastSelectedTab or "Info"
	local PreferredTabKey = NormalizeTabName(PreferredTab)

	local function ResolveTabState(TabName)
		return TabStates[TabName] or TabKeys[NormalizeTabName(TabName)]
	end

	local function ResolveTabIcon(TabName, ExplicitIcon)
		if ExplicitIcon and ExplicitIcon ~= "" then
			return ExplicitIcon
		end

		local IconKey = DefaultTabIcons[NormalizeTabName(TabName)]
		return IconKey and Icons[IconKey] or ""
	end

	local function CloseFloatingState()
		if ActiveCompactDropdownClose then
			ActiveCompactDropdownClose()
		end
	end

	local function IsInputInsideObject(Input, Object)
		if not Object or not Object.Parent then
			return false
		end

		local Position = Input.Position
		local X = Position.X
		local Y = Position.Y
		local Success, AbsolutePosition, AbsoluteSize = pcall(function()
			return Object.AbsolutePosition, Object.AbsoluteSize
		end)

		if not Success then
			return false
		end

		return X >= AbsolutePosition.X
			and X <= AbsolutePosition.X + AbsoluteSize.X
			and Y >= AbsolutePosition.Y
			and Y <= AbsolutePosition.Y + AbsoluteSize.Y
	end

	UserInputService.InputEnded:Connect(function(Input)
		if not ActiveCompactDropdownClose then
			return
		end
		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if
			IsInputInsideObject(Input, ActiveCompactDropdownPopup)
			or IsInputInsideObject(Input, ActiveCompactDropdownField)
		then
			return
		end

		task.defer(function()
			if ActiveCompactDropdownClose then
				ActiveCompactDropdownClose()
			end
		end)
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not ActiveCompactDropdownClose then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		if IsInputInsideObject(Input, ActiveCompactDropdownPopup) then
			return
		end

		ActiveCompactDropdownClose()
	end)

	local function ApplyTabVisual(TabState, IsActive)
		local Tween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TabState.ChooseFrame.Visible = IsActive
		TabState.ChooseFrame.Size = IsActive and UDim2.new(0, 2, 0, 14) or UDim2.new(0, 0, 0, 0)

		SafeTween(TabState.Tab, Tween, {
			BackgroundColor3 = IsActive and Color3.fromRGB(60, 15, 15) or Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = IsActive and 0.12 or 0.999,
		})

		SafeTween(TabState.NameLabel, Tween, {
			TextColor3 = IsActive and Color3.fromRGB(248, 244, 255) or Color3.fromRGB(205, 205, 214),
		})

		SafeTween(TabState.IconLabel, Tween, {
			ImageColor3 = IsActive and Custom.ColorRGB or Color3.fromRGB(150, 150, 160),
			ImageTransparency = TabState.Icon == "" and 1 or (IsActive and 0 or 0.28),
		})
	end

	local function SwitchTab(TabName)
		local TabState = ResolveTabState(TabName)
		if not TabState then
			return false
		end

		CurrentTab = TabState.Name
		Tabs.CurrentTab = CurrentTab
		ScoopHub_Library.LastSelectedTab = CurrentTab
		NameTab.Text = CurrentTab
		CloseFloatingState()

		for _, State in ipairs(TabOrder) do
			local IsActive = State == TabState
			State.Content.Visible = IsActive
			State.Content.Active = IsActive
			State.Content.ScrollingEnabled = IsActive
			ApplyTabVisual(State, IsActive)
		end

		local Jumped = pcall(function()
			LayersPageLayout:JumpTo(TabState.Content)
		end)

		if not Jumped then
			pcall(function()
				LayersPageLayout:JumpToIndex(TabState.Index)
			end)
		end

		return true
	end

	local function HighlightSearchInstance(InstanceFrame)
		if not InstanceFrame or not InstanceFrame.Parent then
			return
		end

		local OriginalColor = InstanceFrame.BackgroundColor3
		local OriginalTransparency = InstanceFrame.BackgroundTransparency
		InstanceFrame.BackgroundColor3 = Custom.ColorRGB
		InstanceFrame.BackgroundTransparency = 0.78

		task.delay(0.55, function()
			if InstanceFrame and InstanceFrame.Parent then
				SafeTween(InstanceFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = OriginalColor,
					BackgroundTransparency = OriginalTransparency,
				})
			end
		end)
	end

	SelectSearchEntry = function(Entry)
		if not Entry then
			return
		end

		TrySet(SearchBox, { Text = "" })
		SearchResults.Visible = false
		ScrollTab.Visible = true
		SwitchTab(Entry.Tab)

		if Entry.OpenSection then
			Entry.OpenSection()
		end

		task.delay(0.12, function()
			if Entry.Scroll and Entry.Instance and Entry.Instance.Parent then
				pcall(function()
					local TargetY = Entry.Instance.AbsolutePosition.Y
						- Entry.Scroll.AbsolutePosition.Y
						+ Entry.Scroll.CanvasPosition.Y
						- 8
					local MaxY = math.max(0, Entry.Scroll.CanvasSize.Y.Offset - Entry.Scroll.AbsoluteSize.Y)
					Entry.Scroll.CanvasPosition = Vector2.new(0, math.clamp(TargetY, 0, MaxY))
				end)
			end

			HighlightSearchInstance(Entry.Instance)
		end)
	end

	function Tabs:SwitchTab(TabName)
		return SwitchTab(TabName)
	end

	function Tabs:GetCurrentTab()
		return CurrentTab
	end

	function Tabs:GetElements(TabName)
		if TabName ~= nil then
			return ElementRegistry[TabName]
		end

		return ElementRegistry
	end

	function Tabs:GetElement(TabNameOrKey, Key)
		if Key ~= nil then
			local TabBucket = ElementRegistry[TabNameOrKey]
			return TabBucket and TabBucket[Key]
		end

		for _, TabName in ipairs(ElementTabOrder) do
			local Found = ElementRegistry[TabName][TabNameOrKey]
			if Found then
				return Found
			end
		end
	end

	function Tabs:GetElementInfo(Element)
		return ElementMeta[Element]
	end

	-- Flat, DECLARATION-ORDERED list of every registered element. Order is stable
	-- across calls, so a consumer can mirror this window's layout from it.
	function Tabs:ListElements()
		local List = {}

		for _, TabName in ipairs(ElementTabOrder) do
			for _, Key in ipairs(ElementKeyOrder[TabName]) do
				local Element = ElementRegistry[TabName][Key]
				local Info = ElementMeta[Element]
				table.insert(List, {
					Tab = TabName,
					Key = Key,
					Type = Info and Info.Type,
					Title = Info and Info.Title,
					Section = Info and Info.Section,
					Hints = Info and Info.Hints,
					Element = Element,
				})
			end
		end

		return List
	end

	function Tabs:CreateTab(Config)
		Config = Config or {}
		local _Name = Config[1] or Config.Name or ""
		local Icon = ResolveTabIcon(_Name, Config[2] or Config.Icon)
		local TabKey = NormalizeTabName(_Name)

		if TabKeys[TabKey] then
			return TabKeys[TabKey].Sections
		end

		local Sections, CountSection = {}, 0

		local ScrolLayers = Custom:Create("ScrollingFrame", {
			ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
			ScrollBarThickness = 0,
			Active = true,
			ClipsDescendants = true,
			ScrollingEnabled = false,
			Visible = false,
			LayoutOrder = CountTab,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "ScrolLayers",
			Parent = LayersFolder,
		})

		local ScrolLayersLayout = Custom:Create("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ScrolLayers,
		})

		ScrolLayers:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if ActiveCompactDropdownClose then
				ActiveCompactDropdownClose()
			end
		end)

		local Tab = Custom:Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = CountTab,
			Size = UDim2.new(1, 0, 0, 30),
			Name = "Tab",
			Parent = ScrollTab,
		})

		Custom:Create("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Parent = Tab,
		})

		local TabButton = Custom:Create("TextButton", {
			Font = Custom.Font,
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "TabButton",
		}, Tab)

		-- Keep a permanent icon slot before every tab name.
		-- Text is aligned closer beside the 16x16 centered icon, matching the reference spacing.
		local TabName = Custom:Create("TextLabel", {
			Font = Custom.Font,
			Text = _Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -34, 1, 0),
			Position = UDim2.new(0, 34, 0, 0),
			Name = "TabName",
		}, Tab)

		local TabIcon = Custom:Create("ImageLabel", {
			Image = Icon,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = Icon == "" and 1 or 0,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Name = "FeatureImg",
		}, Tab)

		local ChooseFrame = Custom:Create("Frame", {
			BackgroundColor3 = Custom.ColorRGB,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 2, 0, 9),
			Size = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Name = "ChooseFrame",
		}, Tab)

		Custom:Create("UIStroke", {
			Color = Custom.ColorRGB,
			Thickness = 1.6,
		}, ChooseFrame)

		Custom:Create("UICorner", {}, ChooseFrame)

		local TabState = {
			Name = _Name,
			Icon = Icon,
			Index = CountTab,
			Tab = Tab,
			Content = ScrolLayers,
			ChooseFrame = ChooseFrame,
			NameLabel = TabName,
			IconLabel = TabIcon,
			Sections = Sections,
		}

		TabStates[_Name] = TabState
		TabKeys[TabKey] = TabState
		table.insert(TabOrder, TabState)

		TabButton.Activated:Connect(function()
			SwitchTab(_Name)
		end)

		if not CurrentTab or TabKey == PreferredTabKey then
			SwitchTab(_Name)
		end

		function Sections:AddSection(Title, OpenSection)
			local Title = Title or ""
			local OpenSection = OpenSection or false
			local ItemGap = 5

			local Section = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.999,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = CountSection,
				Size = UDim2.new(1, 0, 0, 30),
				Name = "Section",
			}, ScrolLayers)

			local SectionReal = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Custom.Surface,
				BackgroundTransparency = 0.12,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 30),
				Name = "SectionReal",
			}, Section)

			Custom:Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}, SectionReal)

			local SectionButton = Custom:Create("TextButton", {
				Font = Custom.Font,
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "SectionButton",
			}, SectionReal)

			local FeatureFrame = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.new(1, -11, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				Name = "FeatureFrame",
			}, SectionReal)

			local FeatureImg = Custom:Create("ImageLabel", {
				Image = "rbxassetid://125609963478878",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = -90,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "FeatureImg",
			}, FeatureFrame)

			local SectionTitle = Custom:Create("TextLabel", {
				Font = Custom.Font,
				Text = Title,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.new(1, -50, 0, 13),
				Name = "SectionTitle",
			}, SectionReal)

			local SectionDecideFrame = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 33),
				Size = UDim2.new(0, 0, 0, 2),
				Name = "SectionDecideFrame",
			}, Section)
			Custom:Create("UICorner", {}, SectionDecideFrame)
			Custom:Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Custom.ObsidianMid),
					ColorSequenceKeypoint.new(0.5, Custom.ColorRGB),
					ColorSequenceKeypoint.new(1, Custom.ObsidianMid),
				}),
			}, SectionDecideFrame)

			local SectionAdd = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 38),
				Size = UDim2.new(1, 0, 0, 100),
				Name = "SectionAdd",
			}, Section)

			Custom:Create("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}, SectionAdd)

			local SectionLayout = Custom:Create("UIListLayout", {
				Padding = UDim.new(0, ItemGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, SectionAdd)

			local UpdateSizeScrollQueued = false
			local function UpdateSizeScroll()
				if UpdateSizeScrollQueued then
					return
				end
				UpdateSizeScrollQueued = true
				task.defer(function()
					UpdateSizeScrollQueued = false
					local ContentSize = SafeGet(ScrolLayersLayout, "AbsoluteContentSize", Vector2.new())
					local OffsetY = ContentSize.Y + ItemGap

					TrySet(ScrolLayers, { CanvasSize = UDim2.new(0, 0, 0, OffsetY) })
				end)
			end

			local UpdateSizeSectionQueued = false
			local function UpdateSizeSection()
				if UpdateSizeSectionQueued then
					return
				end
				UpdateSizeSectionQueued = true
				task.defer(function()
					UpdateSizeSectionQueued = false
					if OpenSection then
						local SectionSizeYWitdh = 38

						local ContentSize = SafeGet(SectionLayout, "AbsoluteContentSize", Vector2.new())
						SectionSizeYWitdh = SectionSizeYWitdh + ContentSize.Y + ItemGap

						TrySet(FeatureFrame, { Rotation = 0 })
						SafeTween(FeatureImg, TweenInfo.new(0.1), { Rotation = 0 })
						SafeTween(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, SectionSizeYWitdh) })
						SafeTween(SectionAdd, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38) })
						SafeTween(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 2) })

						task.delay(0.12, UpdateSizeScroll)
					end
				end)
			end

			local function OpenSearchSection()
				if not OpenSection then
					OpenSection = true
				end

				UpdateSizeSection()
			end

			local function ToggleSection()
				CloseFloatingState()
				CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)

				if OpenSection then
					TrySet(FeatureFrame, { Rotation = 0 })
					SafeTween(FeatureImg, TweenInfo.new(0.1), { Rotation = -90 })
					SafeTween(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 30) })
					SafeTween(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(0, 0, 0, 2) })

					OpenSection = false
					task.wait(0.1)
					UpdateSizeScroll()
				else
					OpenSection = true
					UpdateSizeSection()
				end
			end

			SectionButton.Activated:Connect(ToggleSection)
			SectionAdd.ChildAdded:Connect(UpdateSizeSection)
			SectionAdd.ChildRemoved:Connect(UpdateSizeSection)
			SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSizeSection)

			UpdateSizeScroll()
			CountSection += 1

			local SectionState = {
				Title = Title,
				Tab = _Name,
				Frame = SectionReal,
				Scroll = ScrolLayers,
				Open = OpenSearchSection,
			}

			RegisterSearchEntry({
				Title = Title,
				Type = "Section",
				Tab = _Name,
				Section = Title,
				Instance = SectionReal,
				Scroll = ScrolLayers,
				OpenSection = OpenSearchSection,
			})

			local Item, ItemCount = {}, 0
			function Item:AddParagraph(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local SettingFuncs = {}

				local Paragraph = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Surface,
					BackgroundTransparency = 0.14,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Paragraph",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Paragraph)

				local ParagraphTitle = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 7),
					Size = UDim2.new(1, -16, 0, 13),
					Name = "ParagraphTitle",
				}, Paragraph)

				local ParagraphContent = Custom:Create("TextLabel", {
					Font = Custom.FontBody,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 21),
					Size = UDim2.new(1, -20, 0, 12),
					Name = "ParagraphContent",
				}, Paragraph)

				ParagraphTitle.TextWrapped = true
				local function UpdateParagraphSize()
					local TitleLines = MeasureDescLines(
						ParagraphTitle.AbsoluteSize.X,
						ParagraphTitle.Text,
						ParagraphTitle.Font,
						ParagraphTitle.TextSize,
						3
					)
					if TitleLines <= 0 then
						TitleLines = 1
					end

					local TitleHeight = TitleLines * ROW_TITLE_LINE
					ParagraphTitle.Position = UDim2.new(0, 10, 0, ROW_TOP_PAD)
					ParagraphTitle.Size = UDim2.new(1, -16, 0, TitleHeight)

					local DescLines = MeasureDescLines(
						ParagraphContent.AbsoluteSize.X,
						ParagraphContent.Text,
						ParagraphContent.Font,
						ParagraphContent.TextSize,
						6
					)

					if DescLines <= 0 then
						ParagraphContent.Visible = false
						Paragraph.Size = UDim2.new(1, 0, 0, math.max(35, ROW_TOP_PAD + TitleHeight + 11))
						UpdateSizeSection()
						return
					end

					local DescTop = ROW_TOP_PAD + TitleHeight + ROW_GAP
					local ContentHeight = DescLines * ROW_DESC_LINE

					ParagraphContent.Visible = true
					ParagraphContent.Position = UDim2.new(0, 10, 0, DescTop)
					ParagraphContent.Size = UDim2.new(1, -20, 0, ContentHeight)
					Paragraph.Size = UDim2.new(1, 0, 0, math.max(35, DescTop + ContentHeight + 11))

					UpdateSizeSection()
				end

				UpdateParagraphSize()
				BindAutoRowHeight(ParagraphTitle, UpdateParagraphSize)

				function SettingFuncs:Set(Config)
					local Title = Config[1] or Config.Title or ""
					local Content = Config[2] or Config.Content or ""

					ParagraphTitle.Text = Title
					ParagraphContent.Text = Content

					UpdateParagraphSize()
				end

				ItemCount += 1
				return SettingFuncs
			end

			function Item:AddSubSection(Config)
				local Title = type(Config) == "table" and (Config[1] or Config.Title) or Config
				Title = tostring(Title or ""):gsub("^%s+", ""):gsub("%s+$", "")
				local Sub_Funcs = {}

				if Title == "" then
					function Sub_Funcs:Set() end
					return Sub_Funcs
				end

				local SubSection = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Surface3,
					BackgroundTransparency = 0.26,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Position = UDim2.new(0, 1, 0, 0),
					Size = UDim2.new(1, -2, 0, 27),
					Name = "SubSection",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, SubSection)

				Custom:Create("UIStroke", {
					Color = Custom.Stroke,
					Thickness = 1,
					Transparency = 0.72,
				}, SubSection)

				local SubSectionTitle = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = "- [ " .. Title .. " ] -",
					TextColor3 = Color3.fromRGB(230, 230, 235),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Name = "SubSectionTitle",
				}, SubSection)

				function Sub_Funcs:Set(Config)
					local NewTitle = type(Config) == "table" and (Config[1] or Config.Title) or Config
					NewTitle = tostring(NewTitle or ""):gsub("^%s+", ""):gsub("%s+$", "")
					Title = NewTitle
					SubSectionTitle.Text = NewTitle == "" and "" or "- [ " .. NewTitle .. " ] -"
				end

				ItemCount += 1
				return Sub_Funcs
			end

			function Item:AddSeperator(Config)
				return Item:AddSubSection(Config)
			end

			function Item:AddSeparator(Config)
				return Item:AddSubSection(Config)
			end

			function Item:AddLine()
				local LineFuncs = {}

				local Line = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(90, 90, 90),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 7),
					Name = "Line",
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 3) }, Line)

				Custom:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80)),
					}),
					Rotation = 0,
				}, Line)

				ItemCount += 1
				return LineFuncs
			end

			function Item:AddButton(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Button = {}

				local Button = Custom:Create("Frame", {
					Name = "Button",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.88,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = ItemCount,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, 0, 0, 32),
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Button)

				local ButtonScale = Custom:Create("UIScale", {
					Scale = 1,
				}, Button)

				local ButtonStroke = Custom:Create("UIStroke", {
					Color = Custom.Stroke,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 0,
					Transparency = 1,
				}, Button)

				local ButtonTitle = Custom:Create("TextLabel", {
					Name = "ButtonTitle",
					Font = Custom.Font,
					Text = Title,
					TextColor3 = Color3.fromRGB(232, 232, 238),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
				}, Button)

				local ButtonButton = Custom:Create("TextButton", {
					Name = "ButtonButton",
					Font = Custom.Font,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
				}, Button)

				ButtonButton.MouseEnter:Connect(function()
					SafeTween(
						Button,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 0.82 }
					)
					SafeTween(
						ButtonStroke,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1, Color = Custom.ColorRGB }
					)
				end)

				ButtonButton.MouseLeave:Connect(function()
					SafeTween(
						Button,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 0.88 }
					)
					SafeTween(
						ButtonStroke,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1, Color = Custom.Stroke }
					)
				end)

				ButtonButton.Activated:Connect(function()
					SafeTween(
						Button,
						TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 0.74 }
					)
					SafeTween(
						ButtonScale,
						TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = 0.985 }
					)
					task.delay(0.08, function()
						if Button and Button.Parent then
							SafeTween(
								Button,
								TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ BackgroundTransparency = 0.88 }
							)
							SafeTween(
								ButtonScale,
								TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ Scale = 1 }
							)
						end
					end)

					Callback()
				end)

				function Funcs_Button:Set(Config)
					local NewTitle = Config[1] or Config.Title or Title
					Title = NewTitle
					ButtonTitle.Text = NewTitle
				end

				-- Invoke the button's action without a physical click. Note Set() only
				-- retitles the button, so it is NOT the programmatic equivalent of
				-- pressing it — without this, Callback is reachable only via Activated.
				function Funcs_Button:Fire()
					return Callback()
				end

				RegisterSearchEntry({
					Title = Title,
					Type = "Button",
					Tab = _Name,
					Section = SectionState.Title,
					Instance = Button,
					Scroll = SectionState.Scroll,
					OpenSection = SectionState.Open,
				})

				ItemCount += 1
				return Funcs_Button
			end

			function Item:AddToggle(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or false
				local Callback = Config[4] or Config.Callback or function() end

				local Funcs_Toggle = { Value = Default }
				local RowHeight = CompactRowHeight(Content)

				local Toggle = Custom:Create("Frame", {
					Name = "Toggle",
					BackgroundColor3 = Custom.Surface,
					BackgroundTransparency = 0.14,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, RowHeight),
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Toggle)

				local ToggleTitle = Custom:Create("TextLabel", {
					Name = "ToggleTitle",
					Font = Custom.Font,
					Text = Title,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = Content == "" and UDim2.new(0, 10, 0.5, -7) or UDim2.new(0, 10, 0, 7),
					Size = UDim2.new(1, -100, 0, 13),
				}, Toggle)

				local ToggleContent = Custom:Create("TextLabel", {
					Name = "ToggleContent",
					Font = Custom.FontBody,
					Text = Content,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.6,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 21),
					Size = UDim2.new(1, -100, 0, 12),
					Visible = Content ~= "",
				}, Toggle)

				ToggleTitle.TextWrapped = true
				ToggleContent.TextWrapped = true
				local function UpdateToggleSize()
					RowHeight = LayoutCompactRow(ToggleTitle, ToggleContent, Content, -100)
					Toggle.Size = UDim2.new(1, 0, 0, RowHeight)
					UpdateSizeSection()
				end

				UpdateToggleSize()
				BindAutoRowHeight(ToggleTitle, UpdateToggleSize)

				local ToggleButton = Custom:Create("TextButton", {
					Name = "ToggleButton",
					Font = Custom.Font,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 5,
				}, Toggle)

				local FeatureFrame2 = Custom:Create("Frame", {
					Name = "FeatureFrame2",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(44, 44, 52),
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.new(0, 36, 0, 18),
					ZIndex = 3,
				}, Toggle)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}, FeatureFrame2)

				local UIStroke8 = Custom:Create("UIStroke", {
					Color = Custom.Stroke,
					Thickness = 1,
					Transparency = 0.45,
				}, FeatureFrame2)

				local ToggleCircle = Custom:Create("Frame", {
					Name = "ToggleCircle",
					BackgroundColor3 = Color3.fromRGB(245, 245, 248),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 2, 0, 2),
					ZIndex = 4,
				}, FeatureFrame2)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 15),
				}, ToggleCircle)

				local function ToggleAnimation(isOn)
					isOn = isOn == true
					local TitleColor = isOn and Custom.ColorRGB or Color3.fromRGB(230, 230, 230)
					local CirclePosition = isOn and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
					local StrokeColor = isOn and Custom.ColorRGB or Custom.Stroke
					local StrokeTransparency = isOn and 0.02 or 0.45
					local FrameColor = isOn and Custom.ColorRGB or Color3.fromRGB(44, 44, 52)
					local FrameTransparency = isOn and 0.0 or 0.12
					local CircleColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(245, 245, 248)

					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

					SafeTween(ToggleTitle, tweenInfo, { TextColor3 = TitleColor })
					SafeTween(ToggleCircle, tweenInfo, { Position = CirclePosition, BackgroundColor3 = CircleColor })
					SafeTween(UIStroke8, tweenInfo, { Color = StrokeColor, Transparency = StrokeTransparency })
					SafeTween(
						FeatureFrame2,
						tweenInfo,
						{ BackgroundColor3 = FrameColor, BackgroundTransparency = FrameTransparency }
					)
				end

				ToggleButton.Activated:Connect(function()
					CircleClick(ToggleButton, Player:GetMouse().X, Player:GetMouse().Y)
					Funcs_Toggle.Value = not Funcs_Toggle.Value
					Funcs_Toggle:Set(Funcs_Toggle.Value)
				end)

				function Funcs_Toggle:Set(Value)
					Value = Value == true
					Funcs_Toggle.Value = Value
					-- Paint BEFORE running the callback. Feature callbacks routinely run
					-- their loop inline and never return (auto-farm, ESP, …), and the
					-- repaint used to sit AFTER Callback() — so the switch stayed frozen
					-- in its old position while the feature was actually running. Same
					-- flaw hit the dashboard: no ack until the callback returns.
					ToggleAnimation(Value)
					local Result = Callback(Value)
					-- Callback vetoed it (returned false) -> force off and repaint.
					if Result == false then
						Funcs_Toggle.Value = false
						ToggleAnimation(false)
					end
					return Result
				end

				function Funcs_Toggle:Get()
					return Funcs_Toggle.Value
				end

				Funcs_Toggle:Set(Funcs_Toggle.Value)

				RegisterSearchEntry({
					Title = Title,
					Type = "Toggle",
					Tab = _Name,
					Section = SectionState.Title,
					Instance = Toggle,
					Scroll = SectionState.Scroll,
					OpenSection = SectionState.Open,
				})

				ItemCount += 1
				return Funcs_Toggle
			end

			function Item:AddSlider(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Increment = Config[3] or Config.Increment or 1
				local Min = Config[4] or Config.Min or 0
				local Max = Config[5] or Config.Max or 100
				local Default = Config[6] or Config.Default or 50
				local Callback = Config[7] or Config.Callback or function() end

				local Funcs_Slider = { Value = Default }
				local RowHeight = CompactRowHeight(Content)

				local Slider = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Surface,
					BackgroundTransparency = 0.14,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, RowHeight),
					Name = "Slider",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Slider)

				local SliderTitle = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = Content == "" and UDim2.new(0, 10, 0.5, -7) or UDim2.new(0, 10, 0, 7),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "SliderTitle",
				}, Slider)

				local SliderContent = Custom:Create("TextLabel", {
					Font = Custom.FontBody,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6000000238418579,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 21),
					Size = UDim2.new(1, -180, 0, 12),
					Visible = Content ~= "",
					Name = "SliderContent",
				}, Slider)

				SliderTitle.TextWrapped = true
				SliderContent.TextWrapped = true
				local function UpdateSliderSize()
					RowHeight = LayoutCompactRow(SliderTitle, SliderContent, Content, -180)
					Slider.Size = UDim2.new(1, 0, 0, RowHeight)
					UpdateSizeSection()
				end

				UpdateSliderSize()
				BindAutoRowHeight(SliderTitle, UpdateSliderSize)

				local SliderInput = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.Surface3,
					BackgroundTransparency = 0.08,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -150, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 18),
					Name = "SliderInput",
				}, Slider)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, SliderInput)

				Custom:Create("UIStroke", {
					Color = Custom.ColorRGB,
					Thickness = 1,
					Transparency = 0.35,
				}, SliderInput)

				local TextBox = Custom:Create("TextBox", {
					Font = Custom.Font,
					Text = "90",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextWrapped = false,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, -1, 0, 0),
					Size = UDim2.new(1, 0, 1, 0),
				}, SliderInput)

				local SliderFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(82, 82, 94),
					BackgroundTransparency = 0.35,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -24, 0.5, 0),
					Size = UDim2.new(0, 88, 0, 3),
					Name = "SliderFrame",
				}, Slider)

				Custom:Create("UICorner", {}, SliderFrame)

				local SliderDraggable = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0.899999976, 0, 0, 1),
					Name = "SliderDraggable",
				}, SliderFrame)

				Custom:Create("UICorner", {}, SliderDraggable)

				local SliderCircle = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 4, 0.5, 0),
					Size = UDim2.new(0, 8, 0, 8),
					Name = "SliderCircle",
				}, SliderDraggable)

				Custom:Create("UICorner", {}, SliderCircle)

				Custom:Create("UIStroke", {
					Color = Custom.ColorRGB,
				}, SliderCircle)

				local Dragging = false

				local function Round(Number, Factor)
					local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
					if Result < 0 then
						Result = Result + Factor
					end
					return Result
				end

				function Funcs_Slider:Set(Value, SkipCallback)
					Value = math.clamp(Round(Value, Increment), Min, Max)
					Funcs_Slider.Value = Value
					TrySet(TextBox, { Text = tostring(Value) })

					SafeTween(
						SliderDraggable,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Size = UDim2.fromScale((Value - Min) / (Max - Min), 1) }
					)

					if not SkipCallback then
						Callback(Funcs_Slider.Value)
					end
				end

				function Funcs_Slider:Get()
					return Funcs_Slider.Value
				end

				local _LastX = nil
				local moveConn = nil

				SliderFrame.InputBegan:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						Dragging = true
						if not moveConn then
							moveConn = UserInputService.InputChanged:Connect(function(MoveInput)
								if
									Dragging
									and (
										MoveInput.UserInputType == Enum.UserInputType.MouseMovement
										or MoveInput.UserInputType == Enum.UserInputType.Touch
									)
								then
									local CurrPosX = MoveInput.Position.X
									if CurrPosX ~= _LastX then
										_LastX = CurrPosX
										local Success, SizeScale = pcall(function()
											return math.clamp(
												(CurrPosX - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X,
												0,
												1
											)
										end)

										if Success then
											Funcs_Slider:Set(Min + ((Max - Min) * SizeScale), true)
										end
									end
								end
							end)
						end
					end
				end)

				SliderFrame.InputEnded:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						Dragging = false
						if moveConn then
							moveConn:Disconnect()
							moveConn = nil
						end
						Callback(Funcs_Slider.Value)
					end
				end)

				TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					local CurrentText = tostring(SafeGet(TextBox, "Text", "0"))
					local Valid = CurrentText:gsub("[^%d]", "")
					if Valid ~= "" then
						local ValidNumber = math.min(tonumber(Valid), Max)
						if CurrentText ~= tostring(ValidNumber) then
							TrySet(TextBox, { Text = tostring(ValidNumber) })
						end
					else
						if CurrentText ~= "0" then
							TrySet(TextBox, { Text = "0" })
						end
					end
				end)

				TextBox.FocusLost:Connect(function()
					local CurrentText = tostring(SafeGet(TextBox, "Text", ""))
					if CurrentText ~= "" then
						Funcs_Slider:Set(tonumber(CurrentText) or 0)
					else
						Funcs_Slider:Set(0)
					end
				end)

				Funcs_Slider:Set(tonumber(Default))

				RegisterSearchEntry({
					Title = Title,
					Type = "Slider",
					Tab = _Name,
					Section = SectionState.Title,
					Instance = Slider,
					Scroll = SectionState.Scroll,
					OpenSection = SectionState.Open,
				})

				ItemCount += 1
				return Funcs_Slider
			end

			function Item:AddInput(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or ""
				local Placeholder = Config.Placeholder or Config.PlaceholderText or "Input value"
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Input = { Value = Default }
				local RowHeight = CompactRowHeight(Content)

				local Input = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Surface,
					BackgroundTransparency = 0.14,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, RowHeight),
					Name = "Input",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Input)

				local InputTitle = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = Content == "" and UDim2.new(0, 10, 0.5, -7) or UDim2.new(0, 10, 0, 7),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "InputTitle",
				}, Input)

				local InputContent = Custom:Create("TextLabel", {
					Font = Custom.FontBody,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 21),
					Size = UDim2.new(1, -180, 0, 12),
					Visible = Content ~= "",
					Name = "InputContent",
					Parent = Input,
				})

				InputTitle.TextWrapped = true
				InputContent.TextWrapped = true
				local function UpdateInputSize()
					RowHeight = LayoutCompactRow(InputTitle, InputContent, Content, -180)
					Input.Size = UDim2.new(1, 0, 0, RowHeight)
					UpdateSizeSection()
				end

				UpdateInputSize()
				BindAutoRowHeight(InputTitle, UpdateInputSize)

				local InputFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Custom.Surface3,
					BackgroundTransparency = 0.08,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.new(0, 144, 0, 26),
					Name = "InputFrame",
				}, Input)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, InputFrame)

				Custom:Create("UIStroke", {
					Color = Custom.ColorRGB,
					Thickness = 1,
					Transparency = 0.75,
				}, InputFrame)

				local InputTextBox = Custom:Create("TextBox", {
					CursorPosition = -1,
					Font = Custom.Font,
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					PlaceholderText = Placeholder,
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.new(1, -10, 1, -8),
					Name = "InputTextBox",
				}, InputFrame)

				function Funcs_Input:Set(Value)
					TrySet(InputTextBox, { Text = Value })
					Funcs_Input.Value = Value
					Callback(Value)
				end

				function Funcs_Input:Get()
					return Funcs_Input.Value
				end

				InputTextBox.FocusLost:Connect(function()
					Funcs_Input:Set(SafeGet(InputTextBox, "Text", Funcs_Input.Value))
				end)

				Funcs_Input:Set(Default)

				RegisterSearchEntry({
					Title = Title,
					Type = "Input",
					Tab = _Name,
					Section = SectionState.Title,
					Instance = Input,
					Scroll = SectionState.Scroll,
					OpenSection = SectionState.Open,
				})

				ItemCount += 1
				return Funcs_Input
			end

			function Item:AddDropdown(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Multi = Config[3] or Config.Multi or false
				local Options = Config[4] or Config.Options or {}
				local Default = Config[5] or Config.Default or {}
				local Callback = Config[6] or Config.Callback or function() end

				local function NormalizeDropdownValue(Value)
					if type(Value) == "table" then
						local NewValue = {}
						for _, ItemValue in ipairs(Value) do
							table.insert(NewValue, ItemValue)
						end
						return NewValue
					end

					if Value == nil or Value == "" then
						return {}
					end

					return { Value }
				end

				local Funcs_Dropdown = {
					Value = NormalizeDropdownValue(Default),
					Options = Options,
				}

				local BaseHeight = CompactRowHeight(Content)
				local PopupHeight = 0
				local PopupWidth = 148
				local IsOpen = false
				local Popup, PopupSearch, PopupScroll

				local Dropdown = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Surface,
					BackgroundTransparency = 0.14,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = false,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, BaseHeight),
					Name = "Dropdown",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Dropdown)

				local DropdownButton = Custom:Create("TextButton", {
					Font = Custom.Font,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -7, 0, BaseHeight / 2),
					Size = UDim2.new(0, 148, 0, 30),
					ZIndex = 7,
					Name = "ToggleButton",
				}, Dropdown)

				local DropdownTitle = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = Content == "" and UDim2.new(0, 10, 0.5, -7) or UDim2.new(0, 10, 0, 7),
					Size = UDim2.new(1, -180, 0, 13),
					ZIndex = 3,
					Name = "DropdownTitle",
				}, Dropdown)

				local DropdownContent = Custom:Create("TextLabel", {
					Font = Custom.FontBody,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 21),
					Size = UDim2.new(1, -180, 0, 12),
					Visible = Content ~= "",
					ZIndex = 3,
					Name = "DropdownContent",
				}, Dropdown)

				local SelectOptionsFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Custom.Surface3,
					BackgroundTransparency = 0.08,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -7, 0, BaseHeight / 2),
					Size = UDim2.new(0, 148, 0, 30),
					ZIndex = 4,
					Name = "SelectOptionsFrame",
					LayoutOrder = CountDropdown,
				}, Dropdown)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, SelectOptionsFrame)

				Custom:Create("UIStroke", {
					Color = Custom.Stroke,
					Thickness = 1,
					Transparency = 0.82,
				}, SelectOptionsFrame)

				local OptionSelecting = Custom:Create("TextLabel", {
					Font = Custom.Font,
					Text = "Select Options",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 7, 0.5, 0),
					Size = UDim2.new(1, -32, 1, -8),
					ZIndex = 5,
					Name = "OptionSelecting",
				}, SelectOptionsFrame)

				local OptionImg = Custom:Create("ImageLabel", {
					Image = "rbxassetid://90200523188815",
					ImageColor3 = Color3.fromRGB(231, 231, 231),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -3, 0.5, 0),
					Size = UDim2.new(0, 22, 0, 22),
					ZIndex = 5,
					Name = "OptionImg",
				}, SelectOptionsFrame)

				local function UpdatePopupPosition()
					if not Popup then
						return
					end

					local Success, RootPosition, RootSize, FieldPosition, FieldSize = pcall(function()
						return LayersReal.AbsolutePosition,
							LayersReal.AbsoluteSize,
							SelectOptionsFrame.AbsolutePosition,
							SelectOptionsFrame.AbsoluteSize
					end)

					if not Success then
						Popup.Position = UDim2.new(1, -PopupWidth - 8, 0, 82)
						Popup.Size = UDim2.new(0, PopupWidth, 0, PopupHeight)
						return
					end

					local X = FieldPosition.X - RootPosition.X + FieldSize.X - PopupWidth
					local YBelow = FieldPosition.Y - RootPosition.Y + FieldSize.Y + 6
					local YAbove = FieldPosition.Y - RootPosition.Y - PopupHeight - 6
					local MaxX = math.max(0, RootSize.X - PopupWidth)
					local MaxY = math.max(0, RootSize.Y - PopupHeight)

					X = math.clamp(X, 0, MaxX)

					local Y = YBelow
					if Y > MaxY and YAbove >= 0 then
						Y = YAbove
					else
						Y = math.clamp(Y, 0, MaxY)
					end

					Popup.Position = UDim2.new(0, X, 0, Y)
					Popup.Size = UDim2.new(0, PopupWidth, 0, PopupHeight)
				end

				local function ApplyDropdownSize()
					Dropdown.Size = UDim2.new(1, 0, 0, BaseHeight)
					SelectOptionsFrame.Position = UDim2.new(1, -7, 0, BaseHeight / 2)
					DropdownButton.Position = UDim2.new(1, -7, 0, BaseHeight / 2)
					DropdownButton.Size = UDim2.new(0, 148, 0, 30)

					UpdatePopupPosition()

					UpdateSizeSection()
				end

				DropdownTitle.TextWrapped = true
				DropdownContent.TextWrapped = true
				local function UpdateBaseHeight()
					BaseHeight = LayoutCompactRow(DropdownTitle, DropdownContent, Content, -180)
					ApplyDropdownSize()
				end

				UpdateBaseHeight()
				BindAutoRowHeight(DropdownTitle, UpdateBaseHeight)

				local function SetDisplayText()
					local DisplayText = table.concat(Funcs_Dropdown.Value, ", ")
					OptionSelecting.Text = DisplayText ~= "" and DisplayText or "Select Options"
					OptionSelecting.TextTransparency = DisplayText ~= "" and 0 or 0.6
				end

				local function ClearPopupOptions()
					if not PopupScroll then
						return
					end

					for _, Child in ipairs(SafeChildren(PopupScroll)) do
						if Child:IsA("Frame") then
							Child:Destroy()
						end
					end
				end

				local function UpdatePopupSelectionVisuals()
					if not PopupScroll then
						return
					end

					for _, Option in ipairs(SafeChildren(PopupScroll)) do
						if Option:IsA("Frame") and Option.Name == "Option" then
							local OptionText = Option:FindFirstChild("OptionText")
							local ChooseFrame = Option:FindFirstChild("ChooseFrame")

							if OptionText and ChooseFrame then
								local Selected = table.find(Funcs_Dropdown.Value, OptionText.Text) ~= nil

								SafeTween(
									Option,
									TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{
										BackgroundColor3 = Selected and Color3.fromRGB(60, 15, 15) or Custom.Surface3,
										BackgroundTransparency = Selected and 0.08 or 0.999,
									}
								)

								SafeTween(
									ChooseFrame,
									TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{
										Size = Selected and UDim2.new(0, 2, 0, 14) or UDim2.new(0, 0, 0, 0),
									}
								)
							end
						end
					end
				end

				local function RebuildPopup(FilterText)
					if not PopupScroll then
						return
					end

					ClearPopupOptions()

					local Query = string.lower(tostring(FilterText or ""))
					local VisibleCount = 0
					local MaxTextW = 0

					for _, OptionValue in ipairs(Funcs_Dropdown.Options) do
						local OptionName = tostring(OptionValue)
						local IsVisible = Query == "" or string.find(string.lower(OptionName), Query, 1, true) ~= nil

						if IsVisible then
							VisibleCount += 1
							local _tw = 0; pcall(function() _tw = TextService:GetTextSize(OptionName, 12, Custom.Font, Vector2.new(10000, 100)).X end)
							if _tw > MaxTextW then MaxTextW = _tw end
							local Selected = table.find(Funcs_Dropdown.Value, OptionName) ~= nil

							local Option = Custom:Create("Frame", {
								BackgroundColor3 = Selected and Color3.fromRGB(60, 15, 15) or Custom.Surface3,
								BackgroundTransparency = Selected and 0.08 or 0.999,
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								LayoutOrder = VisibleCount,
								Size = UDim2.new(1, 0, 0, 26),
								ZIndex = 82,
								Name = "Option",
							}, PopupScroll)

							Custom:Create("UICorner", {
								CornerRadius = UDim.new(0, 3),
							}, Option)

							local ChooseFrame = Custom:Create("Frame", {
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundColor3 = Custom.ColorRGB,
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 2, 0.5, 0),
								Size = Selected and UDim2.new(0, 2, 0, 14) or UDim2.new(0, 0, 0, 0),
								ZIndex = 83,
								Name = "ChooseFrame",
							}, Option)

							Custom:Create("UICorner", {}, ChooseFrame)

							local OptionText = Custom:Create("TextLabel", {
								Font = Custom.Font,
								Text = OptionName,
								TextColor3 = Color3.fromRGB(235, 235, 240),
								TextSize = 12,
								TextTruncate = Enum.TextTruncate.AtEnd,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Center,
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.999,
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 12, 0, 0),
								Size = UDim2.new(1, -16, 1, 0),
								ZIndex = 83,
								Name = "OptionText",
							}, Option)

							local OptionButton = Custom:Create("TextButton", {
								Font = Custom.Font,
								Text = "",
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextSize = 12,
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.999,
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Size = UDim2.new(1, 0, 1, 0),
								ZIndex = 84,
								Name = "OptionButton",
							}, Option)

							OptionButton.MouseEnter:Connect(function()
								local IsSelectedNow = table.find(Funcs_Dropdown.Value, OptionName) ~= nil
								SafeTween(Option, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
									BackgroundTransparency = IsSelectedNow and 0.08 or 0.18,
								})
							end)

							OptionButton.MouseLeave:Connect(function()
								local IsSelectedNow = table.find(Funcs_Dropdown.Value, OptionName) ~= nil
								SafeTween(Option, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
									BackgroundTransparency = IsSelectedNow and 0.08 or 0.999,
								})
							end)

							OptionButton.Activated:Connect(function()
								CircleClick(OptionButton, Player:GetMouse().X, Player:GetMouse().Y)

								if Multi then
									local Existing = table.find(Funcs_Dropdown.Value, OptionName)
									if Existing then
										table.remove(Funcs_Dropdown.Value, Existing)
									else
										table.insert(Funcs_Dropdown.Value, OptionName)
									end
								else
									Funcs_Dropdown.Value = { OptionName }
								end

								Funcs_Dropdown:Set(Funcs_Dropdown.Value)
							end)
						end
					end

					if VisibleCount == 0 then
						local Empty = Custom:Create("Frame", {
							BackgroundColor3 = Custom.Surface3,
							BackgroundTransparency = 0.999,
							BorderSizePixel = 0,
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, 26),
							ZIndex = 82,
							Name = "Option",
						}, PopupScroll)

						Custom:Create("TextLabel", {
							Font = Custom.FontBody,
							Text = "No options",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextTransparency = 0.55,
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextYAlignment = Enum.TextYAlignment.Center,
							BackgroundTransparency = 0.999,
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 83,
							Name = "EmptyText",
						}, Empty)
					end

					local MaxPopupW = 300
					local _okw, _pw = pcall(function() return LayersReal.AbsoluteSize.X end)
					if _okw and _pw and _pw > 0 then MaxPopupW = math.clamp(_pw - 12, 148, 320) end
					PopupWidth = math.clamp(math.ceil(MaxTextW) + 32, 148, MaxPopupW)
					local ContentHeight = math.max(28, math.max(VisibleCount, 1) * 28)
					local BodyHeight = math.min(110, ContentHeight)
					PopupScroll.CanvasSize = UDim2.new(0, 0, 0, ContentHeight)
					PopupHeight = 31 + BodyHeight
					ApplyDropdownSize()
				end

				local function CloseDropdown()
					if not IsOpen then
						return
					end

					IsOpen = false
					if ActiveCompactDropdownClose == CloseDropdown then
						ActiveCompactDropdownClose = nil
						ActiveCompactDropdownPopup = nil
						ActiveCompactDropdownField = nil
					end

					if Popup then
						local ClosingPopup = Popup
						Popup = nil
						PopupSearch = nil
						PopupScroll = nil

						SafeTween(ClosingPopup, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, 148, 0, 0),
							BackgroundTransparency = 0.35,
						})

						task.delay(0.09, function()
							if ClosingPopup then
								ClosingPopup:Destroy()
							end
						end)
					end

					SafeTween(OptionImg, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 0,
					})

					ApplyDropdownSize()
				end

				local function OpenDropdown()
					if IsOpen then
						CloseDropdown()
						return
					end

					if ActiveCompactDropdownClose then
						ActiveCompactDropdownClose()
					end

					IsOpen = true
					ActiveCompactDropdownClose = CloseDropdown
					ActiveCompactDropdownField = SelectOptionsFrame

					Popup = Custom:Create("Frame", {
						AnchorPoint = Vector2.new(0, 0),
						BackgroundColor3 = Custom.Surface2,
						BackgroundTransparency = 0.04,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						ClipsDescendants = true,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(0, 148, 0, 0),
						ZIndex = 80,
						Name = "DropdownPopup",
					}, LayersReal)

					ActiveCompactDropdownPopup = Popup

					Custom:Create("UICorner", {
						CornerRadius = UDim.new(0, 4),
					}, Popup)

					Custom:Create("UIStroke", {
						Color = Custom.ColorRGB,
						Thickness = 1,
						Transparency = 0.72,
					}, Popup)

					PopupSearch = Custom:Create("TextBox", {
						ClearTextOnFocus = false,
						Font = Custom.Font,
						PlaceholderText = "Search",
						PlaceholderColor3 = Color3.fromRGB(130, 130, 140),
						Text = "",
						TextColor3 = Color3.fromRGB(245, 245, 245),
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Center,
						BackgroundColor3 = Custom.Surface3,
						BackgroundTransparency = 0.12,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 5, 0, 5),
						Size = UDim2.new(1, -10, 0, 22),
						ZIndex = 81,
						Name = "SearchBar",
					}, Popup)

					Custom:Create("UICorner", {
						CornerRadius = UDim.new(0, 3),
					}, PopupSearch)

					PopupScroll = Custom:Create("ScrollingFrame", {
						CanvasSize = UDim2.new(0, 0, 0, 0),
						ScrollBarImageColor3 = Custom.ColorRGB,
						ScrollBarThickness = 2,
						Active = true,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 5, 0, 31),
						Size = UDim2.new(1, -10, 1, -36),
						ZIndex = 81,
						Name = "PopupScroll",
					}, Popup)

					Custom:Create("UIListLayout", {
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}, PopupScroll)

					PopupSearch:GetPropertyChangedSignal("Text"):Connect(function()
						RebuildPopup(SafeGet(PopupSearch, "Text", ""))
					end)

					SafeTween(OptionImg, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 180,
					})

					RebuildPopup("")
				end

				DropdownButton.Activated:Connect(function()
					CircleClick(DropdownButton, Player:GetMouse().X, Player:GetMouse().Y)
					OpenDropdown()
				end)

				function Funcs_Dropdown:Set(Value)
					Funcs_Dropdown.Value = NormalizeDropdownValue(Value or Funcs_Dropdown.Value)
					SetDisplayText()

					if PopupScroll then
						UpdatePopupSelectionVisuals()
					end

					Callback(Funcs_Dropdown.Value)
				end

				function Funcs_Dropdown:Get()
					return Funcs_Dropdown.Value
				end

				function Funcs_Dropdown:Clear()
					Funcs_Dropdown.Value = {}
					Funcs_Dropdown.Options = {}
					SetDisplayText()

					if PopupScroll then
						RebuildPopup(SafeGet(PopupSearch, "Text", ""))
					end
				end

				function Funcs_Dropdown:AddOption(OptionName)
					table.insert(Funcs_Dropdown.Options, OptionName or "Option")

					if PopupScroll then
						RebuildPopup(SafeGet(PopupSearch, "Text", ""))
					end
				end

				function Funcs_Dropdown:Refresh(RefreshList, Selecting)
					Funcs_Dropdown.Options = RefreshList or {}
					Funcs_Dropdown:Set(NormalizeDropdownValue(Selecting))
				end

				function Funcs_Dropdown:SetValues(RefreshList, Selecting)
					return Funcs_Dropdown:Refresh(RefreshList, Selecting)
				end

				Funcs_Dropdown:Refresh(Funcs_Dropdown.Options, Funcs_Dropdown.Value)

				RegisterSearchEntry({
					Title = Title,
					Type = "Dropdown",
					Tab = _Name,
					Section = SectionState.Title,
					Instance = Dropdown,
					Scroll = SectionState.Scroll,
					OpenSection = SectionState.Open,
				})

				ItemCount += 1
				CountDropdown += 1
				return Funcs_Dropdown
			end

			function Item:AddConfigPanel(Config)
				Config = Config or {}

				local selectedConfig = tostring(Config.Default or Config.Selected or "")
				local currentName = selectedConfig
				local autoLoadEnabled = Config.AutoLoadDefault == true or Config.AutoLoadEnabled == true
				local NameInput, ConfigList

				local function FirstChoice(Value)
					if type(Value) == "table" then
						return tostring(Value[1] or "")
					end

					return tostring(Value or "")
				end

				local function GetSavedList()
					local Getter = Config.GetSaved or Config.GetConfigs
					local List = Getter and Getter() or Config.Saved or Config.Options or {}

					if type(List) ~= "table" then
						return {}
					end

					return List
				end

				local function ResolveName()
					local Value = NameInput and NameInput.Get and NameInput:Get() or currentName
					Value = tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", "")

					if Value ~= "" then
						currentName = Value
					end

					return Value
				end

				local function RefreshList(Selecting)
					local List = GetSavedList()
					local Selected = Selecting or selectedConfig

					if ConfigList and ConfigList.Refresh then
						ConfigList:Refresh(List, Selected ~= "" and { Selected } or {})
					end

					return List
				end

				local function SyncSelected(Name)
					selectedConfig = tostring(Name or "")
					currentName = selectedConfig

					if NameInput and NameInput.Set then
						NameInput:Set(currentName)
					end

					RefreshList(selectedConfig)
				end

				NameInput = Item:AddInput({
					Title = Config.NameTitle or "Config Name",
					Content = Config.NameContent or "Input nama save",
					Placeholder = Config.Placeholder or "Nama config",
					Default = currentName,
					Callback = function(Text)
						currentName = tostring(Text or "")
					end,
				})

				ConfigList = Item:AddDropdown({
					Title = Config.ListTitle or "Saved Configs",
					Content = Config.ListContent or "List saved config",
					Multi = false,
					Options = GetSavedList(),
					Default = selectedConfig ~= "" and { selectedConfig } or {},
					Callback = function(Choice)
						local Picked = FirstChoice(Choice)
						if Picked ~= "" then
							selectedConfig = Picked
							currentName = Picked

							if NameInput and NameInput.Set then
								NameInput:Set(Picked)
							end
						end
					end,
				})

				local function DoSave()
					local Name = ResolveName()
					if Name == "" then
						Name = selectedConfig
					end
					if Name == "" then
						return false
					end

					local Handler = Config.OnSave
						or Config.Save
						or Config.OnSaveAsAutoLoad
						or Config.SaveAsAutoLoad
						or Config.SaveAutoLoad
					local Result

					if Handler then
						Result = Handler(Name)
					else
						if type(Config.Saved) == "table" and not table.find(Config.Saved, Name) then
							table.insert(Config.Saved, Name)
						end
						Result = Name
					end

					if Result ~= false then
						SyncSelected(type(Result) == "string" and Result or Name)
					end

					return Result
				end

				local function ApplyAutoLoad(Enabled, Name)
					autoLoadEnabled = Enabled == true
					Name = Name or (selectedConfig ~= "" and selectedConfig or ResolveName())

					if autoLoadEnabled and Name == "" then
						autoLoadEnabled = false
						return false
					end

					local Handler = Config.OnAutoLoadToggle
						or Config.SetAutoLoad
						or Config.OnAutoLoad
						or Config.AutoLoad
					local Result = Handler and Handler(Name, autoLoadEnabled) or autoLoadEnabled

					if Result ~= false and Name ~= "" then
						SyncSelected(type(Result) == "string" and Result or Name)
					end

					return Result
				end

				local AutoLoadReady = false
				local AutoLoadToggle = Item:AddToggle({
					Title = Config.AutoLoadText or "Auto Load",
					Content = Config.AutoLoadContent or "Load config ini otomatis",
					Default = autoLoadEnabled,
					Callback = function(Enabled)
						autoLoadEnabled = Enabled == true
						if not AutoLoadReady then
							return
						end

						return ApplyAutoLoad(Enabled)
					end,
				})
				AutoLoadReady = true

				Item:AddButton({
					Title = Config.SaveText or "Save",
					Content = Config.SaveContent or "",
					Callback = DoSave,
				})

				Item:AddButton({
					Title = Config.SetAutoLoadText or "Set as Auto Load",
					Content = Config.SetAutoLoadContent or "",
					Callback = function()
						local Saved = DoSave()
						if Saved == false then
							return false
						end

						if AutoLoadToggle and AutoLoadToggle.Set then
							return AutoLoadToggle:Set(true)
						end

						return ApplyAutoLoad(true, type(Saved) == "string" and Saved or selectedConfig)
					end,
				})

				local ConfigPanel = {}

				function ConfigPanel:Refresh(Selecting)
					return RefreshList(Selecting)
				end

				function ConfigPanel:GetName()
					return ResolveName()
				end

				function ConfigPanel:GetSelected()
					return selectedConfig
				end

				function ConfigPanel:GetAutoLoad()
					return autoLoadEnabled
				end

				function ConfigPanel:SetName(Name)
					SyncSelected(Name)
				end

				function ConfigPanel:SetSelected(Name)
					SyncSelected(Name)
				end

				function ConfigPanel:SetAutoLoad(Enabled)
					if AutoLoadToggle and AutoLoadToggle.Set then
						AutoLoadToggle:Set(Enabled == true)
					end
				end

				return ConfigPanel
			end

			function Item:AddConfig(Config)
				return self:AddConfigPanel(Config)
			end

			local RegisterableItems = {
				AddButton = "Button",
				AddToggle = "Toggle",
				AddSlider = "Slider",
				AddInput = "Input",
				AddDropdown = "Dropdown",
				AddParagraph = "Paragraph",
				AddConfigPanel = "Config",
				AddSubSection = "SubSection",
			}

			for MethodName, TypeName in pairs(RegisterableItems) do
				local Original = Item[MethodName]
				if Original then
					Item[MethodName] = function(SelfItem, Config, ...)
						local Funcs = Original(SelfItem, Config, ...)
						RegisterElement(_Name, Title, TypeName, Config, Funcs)
						return Funcs
					end
				end
			end

			ItemCount += 1
			return Item
		end

		CountTab += 1
		return Sections
	end

	return Tabs
end

return ScoopHub_Library

-- might be good now
--
-- update 2
