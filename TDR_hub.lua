local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LOL = loadstring(game:HttpGet("https://raw.githubusercontent.com/Walter072/LOL/refs/heads/main/library.lua"))()

getgenv().LOL = getgenv().LOL or {}
local State = getgenv().LOL
State.Actions = State.Actions or {}
State.WebhookURL = getgenv().LOL_WEBHOOK or State.WebhookURL or ""
State.WebhookEnabled = getgenv().LOL_WEBHOOK_ENABLED ~= false

getgenv().LOL_WalkSpeed = tonumber(getgenv().LOL_WalkSpeed) or 16
getgenv().LOL_JumpPower = tonumber(getgenv().LOL_JumpPower) or 50
if getgenv().LOL_LockSpeed == nil then getgenv().LOL_LockSpeed = true end
if getgenv().LOL_StudioEditor == nil then getgenv().LOL_StudioEditor = true end

function State.Register(id, fn) State.Actions[id] = fn end
function State.Run(id, ...)
    local fn = State.Actions[id]
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

function State.Webhook(title, description, color)
    if not State.WebhookEnabled then return end
    local url = State.WebhookURL or ""
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

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function applyMovement()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum.WalkSpeed = getgenv().LOL_WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = getgenv().LOL_JumpPower
    end)
end

local antiSlowOn = false
local function applyAntiSlow()
    local hum = getHum()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        if hum.WalkSpeed < getgenv().LOL_WalkSpeed then
            hum.WalkSpeed = getgenv().LOL_WalkSpeed
        end
        if hum.JumpPower < getgenv().LOL_JumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = getgenv().LOL_JumpPower
        end
    end
    if hrp then
        for _, obj in ipairs(hrp:GetChildren()) do
            if obj:IsA("BodyVelocity") and obj.Velocity.Magnitude < 1 then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if getgenv().LOL_LockSpeed then applyMovement() end
end)
RunService.Heartbeat:Connect(function()
    if getgenv().LOL_LockSpeed then applyMovement() end
    if antiSlowOn then applyAntiSlow() end
end)

local speedHook
local function hookHum(hum)
    if speedHook then speedHook:Disconnect() speedHook = nil end
    if not hum then return end
    speedHook = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if getgenv().LOL_LockSpeed and hum.WalkSpeed ~= getgenv().LOL_WalkSpeed then
            hum.WalkSpeed = getgenv().LOL_WalkSpeed
        end
    end)
end
if LocalPlayer.Character then
    hookHum(LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    hookHum(char:FindFirstChildOfClass("Humanoid"))
    if getgenv().LOL_LockSpeed then applyMovement() end
end)

local function setAntiSlow(on) antiSlowOn = on end

local noAnimsOn, noAnimsConn = false, nil
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
    pcall(function() espFolder.Parent = game:GetService("CoreGui") end)
    if not espFolder.Parent then espFolder.Parent = PlayerGui end
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

State.Register("rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
State.Register("walkspeed", function(v)
    getgenv().LOL_WalkSpeed = tonumber(v) or 16
    getgenv().LOL_LockSpeed = true
    applyMovement()
end)
State.Register("jumppower", function(v)
    getgenv().LOL_JumpPower = tonumber(v) or 50
    applyMovement()
end)

local Window = LOL:CreateWindow({
    Name = "LOL Hub",
    Width = 580,
    Height = 400,
})

local MainTab = Window:CreateTab({ Name = "LocalPlayer" })

local PlayerSection = MainTab:CreateSection({ Name = "Player" })

PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Range = { 16, 200 },
    CurrentValue = getgenv().LOL_WalkSpeed,
    Callback = function(v)
        State.Run("walkspeed", v)
        LOL:Notify({ Title = "LOL Hub", Content = "WalkSpeed: " .. tostring(v), Duration = 1.5 })
    end,
})

PlayerSection:CreateSlider({
    Name = "JumpPower",
    Range = { 50, 200 },
    CurrentValue = getgenv().LOL_JumpPower,
    Callback = function(v)
        State.Run("jumppower", v)
    end,
})

PlayerSection:CreateToggle({
    Name = "Lock Speed (force)",
    CurrentValue = getgenv().LOL_LockSpeed ~= false,
    Callback = function(on)
        getgenv().LOL_LockSpeed = on
        if on then applyMovement() end
        LOL:Notify({ Title = "LOL Hub", Content = "Lock Speed: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

PlayerSection:CreateToggle({
    Name = "Anti Slow",
    CurrentValue = false,
    Callback = function(on)
        setAntiSlow(on)
        LOL:Notify({ Title = "LOL Hub", Content = "Anti Slow: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

PlayerSection:CreateToggle({
    Name = "No Animations",
    CurrentValue = false,
    Callback = function(on)
        setNoAnims(on)
        LOL:Notify({ Title = "LOL Hub", Content = "No Anims: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

local VisualsTab = Window:CreateTab({ Name = "Visuals" })

local VisualsSection = VisualsTab:CreateSection({ Name = "Visuals" })

VisualsSection:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(on)
        setESP(on)
        LOL:Notify({ Title = "LOL Hub", Content = "ESP: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

VisualsSection:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(on)
        setFullbright(on)
        LOL:Notify({ Title = "LOL Hub", Content = "Fullbright: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

local WebhookTab = Window:CreateTab({ Name = "Webhook" })

local WebhookSection = WebhookTab:CreateSection({ Name = "Webhook" })

WebhookSection:CreateTextbox({
    Name = "Webhook URL",
    PlaceholderText = "Discord webhook URL...",
    CurrentValue = State.WebhookURL,
    Callback = function(text)
        State.WebhookURL = tostring(text):gsub("%s+", "")
        getgenv().LOL_WEBHOOK = State.WebhookURL
        LOL:Notify({
            Title = "LOL Hub",
            Content = State.WebhookURL ~= "" and "URL saved" or "URL cleared",
            Duration = 1.5,
        })
    end,
})

WebhookSection:CreateToggle({
    Name = "Webhook enabled",
    CurrentValue = State.WebhookEnabled,
    Callback = function(on)
        State.WebhookEnabled = on
    end,
})

WebhookSection:CreateButton({
    Name = "Test webhook",
    Callback = function()
        if State.WebhookURL == "" then
            LOL:Notify({ Title = "LOL Hub", Content = "Set URL first", Duration = 1.5 })
            return
        end
        State.Webhook("Test", "Webhook OK from LOL Hub")
        LOL:Notify({ Title = "LOL Hub", Content = "Sent", Duration = 1.5 })
    end,
})

local SettingsTab = Window:CreateTab({ Name = "Settings" })

local GeneralSection = SettingsTab:CreateSection({ Name = "General" })

GeneralSection:CreateToggle({
    Name = "Studio Editor",
    CurrentValue = getgenv().LOL_StudioEditor ~= false,
    Callback = function(on)
        getgenv().LOL_StudioEditor = on
        LOL:Notify({ Title = "LOL Hub", Content = "Studio Editor: " .. (on and "ON" or "OFF"), Duration = 1.5 })
    end,
})

GeneralSection:CreateButton({
    Name = "Rejoin",
    Callback = function()
        State.Run("rejoin")
    end,
})

GeneralSection:CreateButton({
    Name = "Close Hub",
    Callback = function()
        if getgenv().__LOL_ToggleHub then getgenv().__LOL_ToggleHub() end
    end,
})

task.spawn(function()
    task.wait(0.35)
    if getgenv().LOL_LockSpeed then applyMovement() end
    LOL:Notify({
        Title = "LOL Hub",
        Content = "Cargado correctamente · " .. #State.Actions .. " acciones",
        Duration = 3,
    })
end)

print("[LOL Hub] ready")