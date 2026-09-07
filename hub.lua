local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local old = PlayerGui:FindFirstChild("LOLHub")
if old then old:Destroy() end

getgenv().LOL = getgenv().LOL or {}
local LOL = getgenv().LOL
LOL.Actions = LOL.Actions or {}

function LOL.Register(id, fn)
    LOL.Actions[id] = fn
end

function LOL.Run(id, ...)
    local fn = LOL.Actions[id]
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[LOL] Action error:", id, err) end
        return ok
    end
    warn("[LOL] Unknown action:", id)
    return false
end

LOL.WebhookURL = getgenv().LOL_WEBHOOK or LOL.WebhookURL or ""
LOL.WebhookEnabled = getgenv().LOL_WEBHOOK_ENABLED ~= false

local function requestHttp(opts)
    if syn and syn.request then return syn.request(opts) end
    if http and http.request then return http.request(opts) end
    if request then return request(opts) end
    if fluxus and fluxus.request then return fluxus.request(opts) end
    return nil
end

function LOL.Webhook(title, description, color)
    if not LOL.WebhookEnabled then return end
    local url = LOL.WebhookURL or getgenv().LOL_WEBHOOK or ""
    if url == "" then return end
    color = color or 1402531
    local body = HttpService:JSONEncode({
        username = "LOL Hub",
        embeds = {{
            title = title or "LOL Hub",
            description = description or "",
            color = color,
            footer = { text = "LOL Hub · webhook beta" },
            timestamp = DateTime.now():ToIsoDate(),
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

function LOL.AnnounceFruit(fruitName)
    LOL.Webhook("Fruit", "You just got **" .. tostring(fruitName) .. "**", 16753920)
end

function LOL.Announce(msg)
    LOL.Webhook("LOL Hub", tostring(msg), 1402531)
end

--==================== FULLBRIGHT ====================
local fbOn = false
local fbConn = nil
local fbBackup = nil

local function setFullbright(on)
    fbOn = on
    if on then
        if not fbBackup then
            fbBackup = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
            }
        end
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

--==================== ESP ====================
local espOn = false
local espFolder = nil
local espConns = {}

local function clearESP()
    for _, c in pairs(espConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(espConns)
    if espFolder then
        espFolder:Destroy()
        espFolder = nil
    end
end

local function addEspToChar(plr, char)
    if not espOn or not char or plr == LocalPlayer then return end
    if not espFolder then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not hrp then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name .. "_HL"
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(140, 25, 35)
    highlight.OutlineColor = Color3.fromRGB(255, 220, 100)
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Parent = espFolder

    local bb = Instance.new("BillboardGui")
    bb.Name = plr.Name .. "_BB"
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
    lab.TextColor3 = Color3.fromRGB(255, 255, 255)
    lab.TextStrokeTransparency = 0.5
    lab.Text = plr.Name
    lab.Parent = bb
end

local function refreshESP()
    clearESP()
    if not espOn then return end
    espFolder = Instance.new("Folder")
    espFolder.Name = "LOLESP"
    espFolder.Parent = game:GetService("CoreGui")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            addEspToChar(plr, plr.Character)
        end
        espConns[#espConns + 1] = plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if espOn then addEspToChar(plr, char) end
        end)
    end
    espConns[#espConns + 1] = Players.PlayerAdded:Connect(function(plr)
        espConns[#espConns + 1] = plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if espOn then addEspToChar(plr, char) end
        end)
    end)
end

local function setESP(on)
    espOn = on
    if on then refreshESP() else clearESP() end
end

--==================== ACTIONS ====================
LOL.Register("rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

LOL.Register("test_fruit", function()
    LOL.AnnounceFruit("Flame Fruit")
end)

LOL.Register("walkspeed", function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)

LOL.Register("jumppower", function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end)

--==================== UI ====================
local C = {
    win = Color3.fromRGB(18, 20, 26),
    sidebar = Color3.fromRGB(12, 14, 18),
    card = Color3.fromRGB(28, 30, 38),
    card2 = Color3.fromRGB(22, 24, 30),
    accent = Color3.fromRGB(140, 25, 35),
    accent2 = Color3.fromRGB(200, 160, 40),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(140, 145, 155),
    stroke = Color3.fromRGB(0, 0, 0),
    bar = Color3.fromRGB(80, 220, 120),
    barBg = Color3.fromRGB(45, 48, 58),
    field = Color3.fromRGB(40, 42, 52),
    checkOn = Color3.fromRGB(230, 190, 50),
    checkOff = Color3.fromRGB(55, 58, 68),
}

getgenv().LOL_StudioEditor = getgenv().LOL_StudioEditor ~= false

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.stroke
    s.Thickness = th or 1
    s.Transparency = tr or 0.35
    s.Parent = p
end

local gui = Instance.new("ScreenGui")
gui.Name = "LOLHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local loadFrame = Instance.new("Frame")
loadFrame.Size = UDim2.fromOffset(300, 160)
loadFrame.Position = UDim2.fromScale(0.5, 0.5)
loadFrame.AnchorPoint = Vector2.new(0.5, 0.5)
loadFrame.BackgroundColor3 = C.win
loadFrame.BackgroundTransparency = 0.15
loadFrame.Parent = gui
corner(loadFrame, 12)
stroke(loadFrame, C.stroke, 2, 0.2)

local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 28)
loadTitle.Position = UDim2.fromOffset(0, 12)
loadTitle.BackgroundTransparency = 1
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 18
loadTitle.TextColor3 = C.accent2
loadTitle.Text = "LOL Hub"
loadTitle.Parent = loadFrame

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(1, -40, 0, 16)
loadBarBg.Position = UDim2.fromOffset(20, 50)
loadBarBg.BackgroundColor3 = C.barBg
loadBarBg.Parent = loadFrame
corner(loadBarBg, 6)

local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = C.bar
loadBar.Parent = loadBarBg
corner(loadBar, 6)

local loadPct = Instance.new("TextLabel")
loadPct.Size = UDim2.new(1, 0, 1, 0)
loadPct.BackgroundTransparency = 1
loadPct.Font = Enum.Font.GothamBold
loadPct.TextSize = 11
loadPct.TextColor3 = C.win
loadPct.Text = "0%"
loadPct.Parent = loadBarBg

local loadInfo = Instance.new("TextLabel")
loadInfo.Size = UDim2.new(1, -40, 0, 50)
loadInfo.Position = UDim2.fromOffset(20, 80)
loadInfo.BackgroundColor3 = C.card
loadInfo.BackgroundTransparency = 0.25
loadInfo.Font = Enum.Font.Gotham
loadInfo.TextSize = 12
loadInfo.TextColor3 = C.textDim
loadInfo.Text = "Starting..."
loadInfo.TextWrapped = true
loadInfo.Parent = loadFrame
corner(loadInfo, 8)

local function setLoad(pct, msg)
    pct = math.clamp(pct, 0, 100)
    TweenService:Create(loadBar, TweenInfo.new(0.2), { Size = UDim2.new(pct / 100, 0, 1, 0) }):Play()
    loadPct.Text = math.floor(pct) .. "%"
    if msg then loadInfo.Text = msg end
end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.fromOffset(52, 52)
toggleBtn.Position = UDim2.new(1, -68, 1, -68)
toggleBtn.BackgroundColor3 = C.accent
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = C.text
toggleBtn.Text = "LOL"
toggleBtn.Visible = false
toggleBtn.Parent = gui
corner(toggleBtn, 10)
stroke(toggleBtn, C.stroke, 2, 0.2)

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
hub.Name = "Main"
hub.Size = UDim2.fromOffset(560, 360)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.BackgroundColor3 = C.win
hub.BackgroundTransparency = 0.4
hub.Visible = false
hub.Parent = gui
corner(hub, 10)
stroke(hub, Color3.fromRGB(80, 90, 110), 1, 0.3)

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

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = C.sidebar
headerFix.BackgroundTransparency = 0.4
headerFix.BorderSizePixel = 0
headerFix.Parent = header

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

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -12, 0, 26)
searchBox.Position = UDim2.fromOffset(6, 6)
searchBox.BackgroundColor3 = C.field
searchBox.BackgroundTransparency = 0.15
searchBox.PlaceholderText = "Search..."
searchBox.PlaceholderColor3 = C.textDim
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextColor3 = C.text
searchBox.ClearTextOnFocus = false
searchBox.Parent = sidebar
corner(searchBox, 6)

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1, -8, 1, -40)
tabScroll.Position = UDim2.fromOffset(4, 36)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 3
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabScroll.CanvasSize = UDim2.new()
tabScroll.Parent = sidebar

Instance.new("UIListLayout", tabScroll).Padding = UDim.new(0, 3)
tabScroll:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder

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

local studio = Instance.new("Frame")
studio.Name = "StudioPanel"
studio.Size = UDim2.fromOffset(220, 200)
studio.Position = UDim2.new(1, -240, 0.5, -100)
studio.AnchorPoint = Vector2.new(0, 0.5)
studio.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
studio.BackgroundTransparency = 0.1
studio.Visible = false
studio.ZIndex = 30
studio.Parent = gui
corner(studio, 6)

local studioTitle = Instance.new("TextLabel")
studioTitle.Size = UDim2.new(1, -36, 0, 28)
studioTitle.Position = UDim2.fromOffset(10, 4)
studioTitle.BackgroundTransparency = 1
studioTitle.Font = Enum.Font.GothamBold
studioTitle.TextSize = 13
studioTitle.TextColor3 = C.text
studioTitle.TextXAlignment = Enum.TextXAlignment.Left
studioTitle.Text = "Properties"
studioTitle.ZIndex = 31
studioTitle.Parent = studio

local studioClose = Instance.new("TextButton")
studioClose.Size = UDim2.fromOffset(24, 24)
studioClose.Position = UDim2.new(1, -28, 0, 6)
studioClose.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
studioClose.Text = "X"
studioClose.Font = Enum.Font.GothamBold
studioClose.TextSize = 12
studioClose.TextColor3 = C.text
studioClose.ZIndex = 32
studioClose.Parent = studio
corner(studioClose, 5)
studioClose.MouseButton1Click:Connect(function() studio.Visible = false end)

local studioList = Instance.new("ScrollingFrame")
studioList.Size = UDim2.new(1, -12, 1, -40)
studioList.Position = UDim2.fromOffset(6, 34)
studioList.BackgroundTransparency = 1
studioList.BorderSizePixel = 0
studioList.ScrollBarThickness = 3
studioList.AutomaticCanvasSize = Enum.AutomaticSize.Y
studioList.CanvasSize = UDim2.new()
studioList.ZIndex = 31
studioList.Parent = studio

local studioLay = Instance.new("UIListLayout")
studioLay.Padding = UDim.new(0, 4)
studioLay.SortOrder = Enum.SortOrder.LayoutOrder
studioLay.Parent = studioList

local function clearStudio()
    for _, ch in ipairs(studioList:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
end

local function studioRow(label, value, onSubmit)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    row.BackgroundTransparency = 0.2
    row.ZIndex = 32
    row.Parent = studioList
    corner(row, 4)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, -8, 0, 14)
    lab.Position = UDim2.fromOffset(6, 2)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 10
    lab.TextColor3 = C.textDim
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Text = label
    lab.ZIndex = 33
    lab.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 18)
    box.Position = UDim2.fromOffset(6, 18)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = C.text
    box.Text = tostring(value)
    box.ClearTextOnFocus = false
    box.ZIndex = 33
    box.Parent = row
    corner(box, 3)
    box.FocusLost:Connect(function()
        if onSubmit then onSubmit(box.Text) end
    end)
end

local function openStudio(props)
    if not getgenv().LOL_StudioEditor then return end
    clearStudio()
    for _, p in ipairs(props) do
        studioRow(p.name, p.value, function(text)
            local n = tonumber(text)
            if n ~= nil and p.apply then p.apply(n) p.value = n
            elseif p.apply then p.apply(text) p.value = text end
        end)
    end
    studio.Visible = true
end

local tabButtons, tabBuilders = {}, {}

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
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = f
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = f
    return f
end

local function notify(title, msg, seconds)
    seconds = seconds or 3
    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(230, 58)
    f.Position = UDim2.new(1, -250, 1, -90)
    f.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
    f.Parent = gui
    corner(f, 8)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -12, 0, 20)
    t.Position = UDim2.fromOffset(8, 6)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 13
    t.TextColor3 = C.accent2
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = f
    local m = Instance.new("TextLabel")
    m.Size = UDim2.new(1, -12, 0, 24)
    m.Position = UDim2.fromOffset(8, 26)
    m.BackgroundTransparency = 1
    m.Font = Enum.Font.Gotham
    m.TextSize = 12
    m.TextColor3 = C.textDim
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.Text = msg
    m.Parent = f
    task.delay(seconds, function() if f.Parent then f:Destroy() end end)
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
    wrap.Size = UDim2.new(1, 0, 0, 70)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent
    local value = default
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Gotham
    title.TextSize = 12
    title.TextColor3 = C.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.format("Slider %s %d", name, value)
    title.Parent = wrap
    local cfgBtn = Instance.new("TextButton")
    cfgBtn.Size = UDim2.fromOffset(84, 20)
    cfgBtn.Position = UDim2.new(1, -84, 0, 0)
    cfgBtn.BackgroundColor3 = C.field
    cfgBtn.Font = Enum.Font.GothamBold
    cfgBtn.TextSize = 11
    cfgBtn.TextColor3 = C.accent2
    cfgBtn.Text = "Configure"
    cfgBtn.Parent = wrap
    corner(cfgBtn, 5)
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 10)
    barBg.Position = UDim2.fromOffset(0, 28)
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
        title.Text = string.format("Slider %s %d", name, value)
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
    cfgBtn.MouseButton1Click:Connect(function()
        openStudio({
            { name = name, value = value, apply = function(n) apply(n) end },
            { name = "Min", value = min, apply = function() end },
            { name = "Max", value = max, apply = function() end },
        })
    end)
    return apply
end

local function addSliderWithPresets(parent, name, min, max, default, presets, onChange)
    local apply = addSlider(parent, name, min, max, default, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding = UDim.new(0, 6)
    lay.Parent = row
    for _, n in ipairs(presets) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(44, 22)
        b.BackgroundColor3 = C.field
        b.Text = tostring(n)
        b.TextColor3 = C.text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.Parent = row
        corner(b, 5)
        b.MouseButton1Click:Connect(function()
            if apply then apply(n) end
            notify("LOL Hub", name .. " = " .. tostring(n), 2)
        end)
    end
end

local function addButton(parent, text, callbackOrActionId)
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
        if type(callbackOrActionId) == "string" then
            LOL.Run(callbackOrActionId)
        elseif type(callbackOrActionId) == "function" then
            callbackOrActionId()
        end
    end)
end

local function addTextbox(parent, placeholder, defaultText, onFocusLost)
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
        if onFocusLost then onFocusLost(box.Text) end
    end)
    return box
end

local function showTab(name)
    for n, btn in pairs(tabButtons) do
        local on = (n == name)
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

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(searchBox.Text)
    for name, btn in pairs(tabButtons) do
        btn.Visible = (q == "" or string.find(string.lower(name), q, 1, true) ~= nil)
    end
end)

-- TABS
addTab("LocalPlayer", function()
    sectionTitle("LocalPlayer")
    local c = card()
    addToggle(c, "Inf Jump", false, function(on)
        notify("LOL Hub", "Inf Jump: " .. (on and "ON" or "OFF"), 2)
    end)
    addSliderWithPresets(c, "WalkSpeed", 16, 200, 16, {16, 50, 100, 200}, function(v)
        LOL.Run("walkspeed", v)
    end)
    addSliderWithPresets(c, "JumpPower", 50, 200, 50, {50, 75, 100, 150}, function(v)
        LOL.Run("jumppower", v)
    end)
end)

addTab("Visuals", function()
    sectionTitle("Visuals")
    local c = card()
    addToggle(c, "Player ESP", espOn, function(on)
        setESP(on)
        notify("LOL Hub", "ESP: " .. (on and "ON" or "OFF"), 2)
    end)
    addToggle(c, "Fullbright", fbOn, function(on)
        setFullbright(on)
        notify("LOL Hub", "Fullbright: " .. (on and "ON" or "OFF"), 2)
    end)
end)

addTab("Webhook", function()
    sectionTitle("Webhook (beta)")
    local c = card()

    addTextbox(c, "Paste Discord webhook URL...", LOL.WebhookURL or "", function(text)
        local url = tostring(text or ""):gsub("%s+", "")
        LOL.WebhookURL = url
        getgenv().LOL_WEBHOOK = url
        notify("LOL Hub", url ~= "" and "Webhook URL saved" or "Webhook URL cleared", 2)
    end)

    addToggle(c, "Webhook enabled", LOL.WebhookEnabled, function(on)
        LOL.WebhookEnabled = on
        getgenv().LOL_WEBHOOK_ENABLED = on
        notify("LOL Hub", "Webhook: " .. (on and "ON" or "OFF"), 2)
    end)

    addButton(c, "Test: Flame Fruit", function()
        if (LOL.WebhookURL or "") == "" then
            notify("LOL Hub", "Set webhook URL first", 3)
            return
        end
        LOL.AnnounceFruit("Flame Fruit")
        notify("LOL Hub", "Sent: Flame Fruit", 2)
    end)

    addButton(c, "Test: custom message", function()
        if (LOL.WebhookURL or "") == "" then
            notify("LOL Hub", "Set webhook URL first", 3)
            return
        end
        LOL.Announce("Webhook beta is working")
        notify("LOL Hub", "Sent custom message", 2)
    end)
end)

addTab("Settings", function()
    sectionTitle("Settings")
    local c = card()
    addToggle(c, "Studio editor (Configure)", getgenv().LOL_StudioEditor ~= false, function(on)
        getgenv().LOL_StudioEditor = on
        if not on then studio.Visible = false end
    end)
end)

addTab("Misc", function()
    sectionTitle("Misc")
    local c = card()
    addButton(c, "Rejoin", "rejoin")
end)

addTab("Credits", function()
    sectionTitle("Credits")
    local c = card()
    addButton(c, "LOL Hub", function()
        notify("LOL Hub", "Made for friends", 2)
    end)
end)

local hubOpen = false
getgenv().__LOL_ToggleHub = function()
    hubOpen = not hubOpen
    hub.Visible = hubOpen
end

task.spawn(function()
    setLoad(20, "Preparing LOL Hub...")
    task.wait(0.3)
    setLoad(55, "Loading UI...")
    task.wait(0.3)
    setLoad(100, "Ready")
    task.wait(0.25)
    loadFrame.Visible = false
    toggleBtn.Visible = true
    showTab("LocalPlayer")
end)

print("[LOL Hub] UI ready | ESP + Fullbright + Webhook textbox")