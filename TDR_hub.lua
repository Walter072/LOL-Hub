local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("LOLHub")
if old then old:Destroy() end

getgenv().LOL = getgenv().LOL or {}
local LOL = getgenv().LOL
LOL.Actions = LOL.Actions or {}
LOL.WebhookURL = getgenv().LOL_WEBHOOK or LOL.WebhookURL or ""
LOL.WebhookEnabled = getgenv().LOL_WEBHOOK_ENABLED ~= false

function LOL.Register(id, fn) LOL.Actions[id] = fn end
function LOL.Run(id, ...)
    local fn = LOL.Actions[id]
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[LOL]", id, err) end
    end
end

local function requestHttp(opts)
    if syn and syn.request then return syn.request(opts) end
    if http and http.request then return http.request(opts) end
    if request then return request(opts) end
    return nil
end

function LOL.Webhook(title, description, color)
    if not LOL.WebhookEnabled then return end
    local url = LOL.WebhookURL or ""
    if url == "" then return end
    local body = HttpService:JSONEncode({
        username = "LOL Hub",
        embeds = {{
            title = title or "LOL Hub",
            description = description or "",
            color = color or 1402531,
            footer = { text = "LOL Hub" },
        }},
    })
    task.spawn(function()
        pcall(function()
            requestHttp({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
    end)
end

--========== FULLBRIGHT ==========
local fbOn, fbConn, fbBackup = false, nil, nil
local function setFullbright(on)
    fbOn = on
    if on then
        fbBackup = fbBackup or {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
        }
        if fbConn then fbConn:Disconnect() end
        fbConn = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 9e9
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        end)
    else
        if fbConn then fbConn:Disconnect() fbConn = nil end
        if fbBackup then
            Lighting.Brightness = fbBackup.Brightness
            Lighting.ClockTime = fbBackup.ClockTime
            Lighting.FogEnd = fbBackup.FogEnd
            Lighting.GlobalShadows = fbBackup.GlobalShadows
            Lighting.Ambient = fbBackup.Ambient
        end
    end
end

--========== ESP ==========
local espOn, espFolder, espConns = false, nil, {}
local function clearESP()
    for _, c in pairs(espConns) do pcall(function() c:Disconnect() end) end
    table.clear(espConns)
    if espFolder then espFolder:Destroy() espFolder = nil end
end
local function addEsp(plr, char)
    if not espOn or not char or plr == LocalPlayer or not espFolder then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not hrp then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(140, 25, 35)
    hl.OutlineColor = Color3.fromRGB(255, 220, 100)
    hl.FillTransparency = 0.55
    hl.Parent = espFolder
    local bb = Instance.new("BillboardGui")
    bb.Adornee = hrp
    bb.Size = UDim2.fromOffset(120, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espFolder
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.fromScale(1, 1)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 12
    lab.TextColor3 = Color3.new(1, 1, 1)
    lab.TextStrokeTransparency = 0.5
    lab.Text = plr.Name
    lab.Parent = bb
end
local function setESP(on)
    espOn = on
    clearESP()
    if not on then return end
    espFolder = Instance.new("Folder")
    espFolder.Name = "LOLESP"
    espFolder.Parent = game:GetService("CoreGui")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then addEsp(plr, plr.Character) end
        table.insert(espConns, plr.CharacterAdded:Connect(function(c)
            task.wait(0.4)
            if espOn then addEsp(plr, c) end
        end))
    end
    table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
        table.insert(espConns, plr.CharacterAdded:Connect(function(c)
            task.wait(0.4)
            if espOn then addEsp(plr, c) end
        end))
    end))
end

--========== NO ANIMS ==========
local noAnimsOn = false
local noAnimsConn = nil
local function stripAnims(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop(0) end)
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
        end
    end
    local animate = char:FindFirstChild("Animate")
    if animate then pcall(function() animate.Disabled = true end) end
end
local function setNoAnims(on)
    noAnimsOn = on
    if noAnimsConn then noAnimsConn:Disconnect() noAnimsConn = nil end
    if on then
        if LocalPlayer.Character then stripAnims(LocalPlayer.Character) end
        noAnimsConn = RunService.Heartbeat:Connect(function()
            if noAnimsOn and LocalPlayer.Character then stripAnims(LocalPlayer.Character) end
        end)
    else
        local a = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Animate")
        if a then a.Disabled = false end
    end
end

--========== ANTI SLOW ==========
local antiSlowOn = false
local antiSlowConn = nil
local TARGET_SPEED = 16
local TARGET_JUMP = 50
local function applyAntiSlow()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        if hum.WalkSpeed < TARGET_SPEED then hum.WalkSpeed = TARGET_SPEED end
        hum.UseJumpPower = true
        if hum.JumpPower < TARGET_JUMP then hum.JumpPower = TARGET_JUMP end
    end
    if hrp then
        for _, obj in ipairs(hrp:GetChildren()) do
            if obj:IsA("BodyVelocity") and obj.Velocity.Magnitude < 1 then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end
local function setAntiSlow(on)
    antiSlowOn = on
    if antiSlowConn then antiSlowConn:Disconnect() antiSlowConn = nil end
    if on then
        antiSlowConn = RunService.Heartbeat:Connect(function()
            if antiSlowOn then applyAntiSlow() end
        end)
    end
end

LOL.Register("rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
LOL.Register("walkspeed", function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
    TARGET_SPEED = v -- anti-slow usa este valor
end)
LOL.Register("jumppower", function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true hum.JumpPower = v end
    TARGET_JUMP = v
end)

--========== UI ==========
local C = {
    win = Color3.fromRGB(18, 20, 26),
    sidebar = Color3.fromRGB(12, 14, 18),
    card = Color3.fromRGB(28, 30, 38),
    card2 = Color3.fromRGB(22, 24, 30),
    accent = Color3.fromRGB(140, 25, 35),
    accent2 = Color3.fromRGB(200, 160, 40),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(140, 145, 155),
    barBg = Color3.fromRGB(45, 48, 58),
    field = Color3.fromRGB(40, 42, 52),
    checkOn = Color3.fromRGB(230, 190, 50),
    checkOff = Color3.fromRGB(55, 58, 68),
    bar = Color3.fromRGB(80, 220, 120),
}
getgenv().LOL_StudioEditor = getgenv().LOL_StudioEditor ~= false

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local gui = Instance.new("ScreenGui")
gui.Name = "LOLHub"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local loadFrame = Instance.new("Frame")
loadFrame.Size = UDim2.fromOffset(300, 140)
loadFrame.Position = UDim2.fromScale(0.5, 0.5)
loadFrame.AnchorPoint = Vector2.new(0.5, 0.5)
loadFrame.BackgroundColor3 = C.win
loadFrame.BackgroundTransparency = 0.15
loadFrame.Parent = gui
corner(loadFrame, 12)
local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Position = UDim2.fromOffset(0, 20)
loadTitle.BackgroundTransparency = 1
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 18
loadTitle.TextColor3 = C.accent2
loadTitle.Text = "LOL Hub"
loadTitle.Parent = loadFrame
local loadInfo = Instance.new("TextLabel")
loadInfo.Size = UDim2.new(1, 0, 0, 24)
loadInfo.Position = UDim2.fromOffset(0, 70)
loadInfo.BackgroundTransparency = 1
loadInfo.Font = Enum.Font.Gotham
loadInfo.TextSize = 13
loadInfo.TextColor3 = C.textDim
loadInfo.Text = "Loading..."
loadInfo.Parent = loadFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(52, 52)
toggleBtn.Position = UDim2.new(1, -68, 1, -68)
toggleBtn.BackgroundColor3 = C.accent
toggleBtn.Text = "LOL"
toggleBtn.TextColor3 = C.text
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Visible = false
toggleBtn.Parent = gui
corner(toggleBtn, 10)

do
    local dragging, dragStart, startPos, moved
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = toggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        if moved then return end
        if getgenv().__LOL_ToggleHub then getgenv().__LOL_ToggleHub() end
    end)
end

local hub = Instance.new("Frame")
hub.Size = UDim2.fromOffset(560, 360)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.BackgroundColor3 = C.win
hub.BackgroundTransparency = 0.4
hub.Visible = false
hub.Parent = gui
corner(hub, 10)

do
    local dragging, start, startPos
    hub.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = hub.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - start
            hub.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = C.sidebar
header.BackgroundTransparency = 0.4
header.Parent = hub
corner(header, 10)
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -16, 1, 0)
headerTitle.Position = UDim2.fromOffset(14, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 15
headerTitle.TextColor3 = C.accent2
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Text = "LOL Hub"
headerTitle.Parent = header

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -12, 1, -50)
body.Position = UDim2.fromOffset(6, 46)
body.BackgroundTransparency = 1
body.Parent = hub

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BackgroundTransparency = 0.3
sidebar.Parent = body
corner(sidebar, 8)

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1, -8, 1, -10)
tabScroll.Position = UDim2.fromOffset(4, 6)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 3
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabScroll.CanvasSize = UDim2.new()
tabScroll.Parent = sidebar
local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabScroll

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -158, 1, 0)
content.Position = UDim2.fromOffset(156, 0)
content.BackgroundColor3 = C.card2
content.BackgroundTransparency = 0.35
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = body
corner(content, 8)
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content
local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 10)
contentPad.PaddingBottom = UDim.new(0, 10)
contentPad.PaddingLeft = UDim.new(0, 10)
contentPad.PaddingRight = UDim.new(0, 10)
contentPad.Parent = content

local contentOrder = 0
local tabButtons, tabBuilders = {}, {}

local function notify(title, msg, sec)
    sec = sec or 2
    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(220, 52)
    f.Position = UDim2.new(1, -240, 1, -90)
    f.BackgroundColor3 = C.card
    f.Parent = gui
    corner(f, 8)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -12, 0, 18)
    t.Position = UDim2.fromOffset(8, 6)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 13
    t.TextColor3 = C.accent2
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = f
    local m = Instance.new("TextLabel")
    m.Size = UDim2.new(1, -12, 0, 20)
    m.Position = UDim2.fromOffset(8, 26)
    m.BackgroundTransparency = 1
    m.Font = Enum.Font.Gotham
    m.TextSize = 12
    m.TextColor3 = C.textDim
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.Text = msg
    m.Parent = f
    task.delay(sec, function() if f.Parent then f:Destroy() end end)
end

local function clearContent()
    contentOrder = 0
    for _, ch in ipairs(content:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
    end
end

local function sectionTitle(text)
    contentOrder += 1
    local t = Instance.new("TextLabel")
    t.LayoutOrder = contentOrder
    t.Size = UDim2.new(1, 0, 0, 22)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = text
    t.Parent = content
end

local function card()
    contentOrder += 1
    local f = Instance.new("Frame")
    f.LayoutOrder = contentOrder
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = C.card
    f.BackgroundTransparency = 0.2
    f.Parent = content
    corner(f, 8)
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.Parent = f
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = f
    return f
end

local function addToggle(parent, text, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local state = default and true or false
    local box = Instance.new("TextButton")
    box.Size = UDim2.fromOffset(22, 22)
    box.Position = UDim2.new(1, -22, 0.5, -11)
    box.BackgroundColor3 = state and C.checkOn or C.checkOff
    box.Text = state and "✓" or ""
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.TextColor3 = C.win
    box.Parent = row
    corner(box, 4)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, -30, 1, 0)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 13
    lab.TextColor3 = C.text
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Text = text
    lab.Parent = row
    box.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and C.checkOn or C.checkOff
        box.Text = state and "✓" or ""
        if callback then callback(state) end
    end)
end

local function addSlider(parent, name, min, max, default, onChange)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 54)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent
    local value = default
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Gotham
    title.TextSize = 12
    title.TextColor3 = C.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.format("%s %d", name, value)
    title.Parent = wrap
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 10)
    barBg.Position = UDim2.fromOffset(0, 26)
    barBg.BackgroundColor3 = C.barBg
    barBg.Parent = wrap
    corner(barBg, 4)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.Parent = barBg
    corner(fill, 4)
    local function apply(v)
        value = math.clamp(math.floor(v + 0.5), min, max)
        fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
        title.Text = string.format("%s %d", name, value)
        if onChange then onChange(value) end
    end
    local dragging = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
            apply(min + (max - min) * rel)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
            apply(min + (max - min) * rel)
        end
    end)
end

local function addButton(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = C.accent
    b.BackgroundTransparency = 0.1
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = C.text
    b.Text = text
    b.Parent = parent
    corner(b, 6)
    b.MouseButton1Click:Connect(function()
        if type(cb) == "string" then LOL.Run(cb) elseif type(cb) == "function" then cb() end
    end)
end

local function addTextbox(parent, placeholder, defaultText, onLost)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 32)
    box.BackgroundColor3 = C.field
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = C.textDim
    box.Text = defaultText or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = C.text
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = parent
    corner(box, 6)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = box
    box.FocusLost:Connect(function()
        if onLost then onLost(box.Text) end
    end)
end

local function showTab(name)
    for n, btn in pairs(tabButtons) do
        local on = n == name
        btn.BackgroundTransparency = on and 0 or 1
        btn.BackgroundColor3 = C.accent
        btn.TextColor3 = on and C.text or C.textDim
    end
    clearContent()
    if tabBuilders[name] then tabBuilders[name]() end
end

local function addTab(name, builder)
    tabBuilders[name] = builder
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 28)
    b.BackgroundColor3 = C.accent
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextColor3 = C.textDim
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = "  " .. name
    b.Parent = tabScroll
    corner(b, 6)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() showTab(name) end)
end

-- TABS
addTab("LocalPlayer", function()
    sectionTitle("LocalPlayer")
    local c = card()
    addSlider(c, "WalkSpeed", 16, 200, TARGET_SPEED, function(v)
        LOL.Run("walkspeed", v)
    end)
    addSlider(c, "JumpPower", 50, 200, TARGET_JUMP, function(v)
        LOL.Run("jumppower", v)
    end)
    addToggle(c, "Anti Slow", antiSlowOn, function(on)
        setAntiSlow(on)
        notify("LOL Hub", "Anti Slow: " .. (on and "ON" or "OFF"))
    end)
    addToggle(c, "No Animations", noAnimsOn, function(on)
        setNoAnims(on)
        notify("LOL Hub", "No Anims: " .. (on and "ON" or "OFF"))
    end)
end)

addTab("Visuals", function()
    sectionTitle("Visuals")
    local c = card()
    addToggle(c, "Player ESP", espOn, function(on)
        setESP(on)
        notify("LOL Hub", "ESP: " .. (on and "ON" or "OFF"))
    end)
    addToggle(c, "Fullbright", fbOn, function(on)
        setFullbright(on)
        notify("LOL Hub", "Fullbright: " .. (on and "ON" or "OFF"))
    end)
end)

addTab("Webhook", function()
    sectionTitle("Webhook")
    local c = card()
    addTextbox(c, "Discord webhook URL...", LOL.WebhookURL, function(text)
        LOL.WebhookURL = tostring(text):gsub("%s+", "")
        getgenv().LOL_WEBHOOK = LOL.WebhookURL
        notify("LOL Hub", LOL.WebhookURL ~= "" and "URL saved" or "URL cleared")
    end)
    addToggle(c, "Webhook enabled", LOL.WebhookEnabled, function(on)
        LOL.WebhookEnabled = on
    end)
    addButton(c, "Test webhook", function()
        if LOL.WebhookURL == "" then
            notify("LOL Hub", "Set URL first")
            return
        end
        LOL.Webhook("Test", "Webhook OK from LOL Hub")
        notify("LOL Hub", "Sent")
    end)
end)

local hubOpen = false
getgenv().__LOL_ToggleHub = function()
    hubOpen = not hubOpen
    hub.Visible = hubOpen
end

task.spawn(function()
    task.wait(0.4)
    loadFrame.Visible = false
    toggleBtn.Visible = true
    showTab("LocalPlayer")
end)

print("[LOL Hub] ready")