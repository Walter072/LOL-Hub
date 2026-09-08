local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("LOLKaitunManager")
if old then old:Destroy() end

getgenv().LOL_Kaituns = getgenv().LOL_Kaituns or {
    {
        id = "final_remedy",
        name = "Final Remedy",
        npc = "Final Remedy",
        pos = Vector3.new(-1409.3359375, 1339.1600341796875, -978.4904174804688),
        mode = "follow", 
        hover = 14,
        weapon = "",
    },
}

local function getActionRemote()
    local ok, remote = pcall(function()
        return ReplicatedStorage.rbxts_include.node_modules["@rbxts"].remo.src.container["player.input.action"]
    end)
    return ok and remote or nil
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function equipWeapon(weaponName)
    if not weaponName or weaponName == "" then return end
    local char = LocalPlayer.Character
    local hum = getHum()
    if not char or not hum then return end
    if char:FindFirstChild(weaponName) then return end
    local bag = LocalPlayer:FindFirstChild("Backpack")
    local tool = bag and bag:FindFirstChild(weaponName)
    if tool then pcall(function() hum:EquipTool(tool) end) end
end

local function attackOnce(weaponName)
    equipWeapon(weaponName)
    local remote = getActionRemote()
    if not remote then return end
    pcall(function()
        remote:FireServer("usePrimary", Enum.UserInputState.Begin, "keyboard")
    end)
    task.defer(function()
        pcall(function()
            remote:FireServer("usePrimary", Enum.UserInputState.End, "keyboard")
        end)
    end)
end

local function findNPC(npcName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == npcName then
            if obj:IsA("Model") then
                local part = obj:FindFirstChild("HumanoidRootPart")
                    or obj:FindFirstChild("Head")
                    or obj.PrimaryPart
                    or obj:FindFirstChildWhichIsA("BasePart")
                if part then return obj, part end
            elseif obj:IsA("BasePart") then
                return obj, obj
            end
        end
    end
    return nil, nil
end

local function isDead(model)
    if not model or not model.Parent then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function farmCF(pos)
    return CFrame.lookAt(pos, pos + Vector3.new(0, -50, 0.15))
end

local running = false
local activeKaitun = nil
local lockConn = nil
local statusText = nil

local function setStatus(t)
    if statusText then statusText.Text = t end
end

local function stopKaitun(msg)
    running = false
    activeKaitun = nil
    if lockConn then
        lockConn:Disconnect()
        lockConn = nil
    end
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    setStatus(msg or "Idle")
end

local function startKaitun(data)
    if running then stopKaitun("Stopped") end
    running = true
    activeKaitun = data
    setStatus("Killing (" .. data.npc .. ")")

    local hover = data.hover or 14
    local mode = data.mode or "follow"
    local fixed = data.pos
    local weapon = data.weapon or ""

    local hrp = getHRP()
    if hrp and fixed then
        hrp.CFrame = farmCF(fixed + Vector3.new(0, hover, 0))
    end

    lockConn = RunService.Heartbeat:Connect(function()
        if not running then return end
        local h = getHRP()
        local hum = getHum()
        if not h then return end
        if hum then
            hum.PlatformStand = true
            hum.AutoRotate = false
        end
        local target = fixed + Vector3.new(0, hover, 0)
        if mode == "follow" then
            local model, part = findNPC(data.npc)
            if part then
                target = part.Position + Vector3.new(0, hover, 0)
            end
        end
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        h.CFrame = farmCF(target)
    end)

    task.spawn(function()
        local seen = false
        local gone = 0
        while running do
            attackOnce(weapon)
            local model = select(1, findNPC(data.npc))
            if model then
                seen = true
                gone = 0
                setStatus("Killing (" .. data.npc .. ")")
                if isDead(model) then
                    stopKaitun("Killed (" .. data.npc .. ")")
                    return
                end
            elseif seen then
                gone += 1
                if gone >= 8 then
                    stopKaitun("Killed (" .. data.npc .. ")")
                    return
                end
            else
                setStatus("Waiting (" .. data.npc .. ")")
            end
            task.wait(0.12)
        end
    end)
end

local C = {
    bg = Color3.fromRGB(18, 20, 26),
    card = Color3.fromRGB(28, 30, 38),
    accent = Color3.fromRGB(140, 25, 35),
    gold = Color3.fromRGB(200, 160, 40),
    text = Color3.fromRGB(235, 235, 240),
    dim = Color3.fromRGB(140, 145, 155),
    field = Color3.fromRGB(40, 42, 52),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local gui = Instance.new("ScreenGui")
gui.Name = "LOLKaitunManager"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(420, 380)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 0.35
main.Parent = gui
corner(main, 10)

do
    local dragging, start, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - start
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = C.bg
header.BackgroundTransparency = 0.45
header.Parent = main
corner(header, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = C.gold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "LOL Hub · TDR Kaitun"
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = C.accent
closeBtn.Text = "X"
closeBtn.TextColor3 = C.text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = header
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function()
    stopKaitun()
    gui:Destroy()
end)

statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 0, 24)
statusText.Position = UDim2.fromOffset(10, 44)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 13
statusText.TextColor3 = C.dim
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Text = "Idle"
statusText.Parent = main

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -180)
list.Position = UDim2.fromOffset(10, 72)
list.BackgroundColor3 = C.card
list.BackgroundTransparency = 0.35
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = main
corner(list, 8)

local listLay = Instance.new("UIListLayout")
listLay.Padding = UDim.new(0, 6)
listLay.SortOrder = Enum.SortOrder.LayoutOrder
listLay.Parent = list

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 8)
listPad.PaddingBottom = UDim.new(0, 8)
listPad.PaddingLeft = UDim.new(0, 8)
listPad.PaddingRight = UDim.new(0, 8)
listPad.Parent = list

local function refreshList()
    for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    for i, data in ipairs(getgenv().LOL_Kaituns) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = C.field
        row.BackgroundTransparency = 0.2
        row.Parent = list
        corner(row, 6)

        local lab = Instance.new("TextLabel")
        lab.Size = UDim2.new(1, -140, 1, 0)
        lab.Position = UDim2.fromOffset(10, 0)
        lab.BackgroundTransparency = 1
        lab.Font = Enum.Font.GothamBold
        lab.TextSize = 13
        lab.TextColor3 = C.text
        lab.TextXAlignment = Enum.TextXAlignment.Left
        lab.Text = data.name .. "  [" .. (data.mode or "follow") .. "]"
        lab.Parent = row

        local startBtn = Instance.new("TextButton")
        startBtn.Size = UDim2.fromOffset(60, 26)
        startBtn.Position = UDim2.new(1, -130, 0.5, -13)
        startBtn.BackgroundColor3 = C.accent
        startBtn.Text = "Start"
        startBtn.TextColor3 = C.text
        startBtn.Font = Enum.Font.GothamBold
        startBtn.TextSize = 12
        startBtn.Parent = row
        corner(startBtn, 5)
        startBtn.MouseButton1Click:Connect(function()
            startKaitun(data)
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.fromOffset(54, 26)
        delBtn.Position = UDim2.new(1, -62, 0.5, -13)
        delBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        delBtn.Text = "Del"
        delBtn.TextColor3 = C.text
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 12
        delBtn.Parent = row
        corner(delBtn, 5)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(getgenv().LOL_Kaituns, i)
            if activeKaitun == data then stopKaitun("Idle") end
            refreshList()
        end)
    end
end

-- Add form (template Final Remedy)
local form = Instance.new("Frame")
form.Size = UDim2.new(1, -20, 0, 96)
form.Position = UDim2.new(0, 10, 1, -100)
form.BackgroundColor3 = C.card
form.BackgroundTransparency = 0.35
form.Parent = main
corner(form, 8)

local function field(parent, ph, x, w)
    local b = Instance.new("TextBox")
    b.Size = UDim2.fromOffset(w, 26)
    b.Position = UDim2.fromOffset(x, 8)
    b.BackgroundColor3 = C.field
    b.PlaceholderText = ph
    b.PlaceholderColor3 = C.dim
    b.Text = ""
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextColor3 = C.text
    b.ClearTextOnFocus = false
    b.Parent = parent
    corner(b, 5)
    return b
end

local nameBox = field(form, "Display name", 8, 120)
local npcBox = field(form, "NPC name", 134, 120)
local weaponBox = field(form, "Weapon (optional)", 260, 130)

local posLabel = Instance.new("TextLabel")
posLabel.Size = UDim2.new(1, -90, 0, 20)
posLabel.Position = UDim2.fromOffset(8, 40)
posLabel.BackgroundTransparency = 1
posLabel.Font = Enum.Font.Gotham
posLabel.TextSize = 11
posLabel.TextColor3 = C.dim
posLabel.TextXAlignment = Enum.TextXAlignment.Left
posLabel.Text = "Pos: (use current HRP or FR template)"
posLabel.Parent = form

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.fromOffset(70, 26)
addBtn.Position = UDim2.new(1, -78, 1, -34)
addBtn.BackgroundColor3 = C.accent
addBtn.Text = "Add"
addBtn.TextColor3 = C.text
addBtn.Font = Enum.Font.GothamBold
addBtn.TextSize = 12
addBtn.Parent = form
corner(addBtn, 5)

local usePosBtn = Instance.new("TextButton")
usePosBtn.Size = UDim2.fromOffset(100, 26)
usePosBtn.Position = UDim2.fromOffset(8, 62)
usePosBtn.BackgroundColor3 = C.field
usePosBtn.Text = "Use my pos"
usePosBtn.TextColor3 = C.gold
usePosBtn.Font = Enum.Font.GothamBold
usePosBtn.TextSize = 11
usePosBtn.Parent = form
corner(usePosBtn, 5)

local useTemplateBtn = Instance.new("TextButton")
useTemplateBtn.Size = UDim2.fromOffset(110, 26)
useTemplateBtn.Position = UDim2.fromOffset(114, 62)
useTemplateBtn.BackgroundColor3 = C.field
useTemplateBtn.Text = "FR template"
useTemplateBtn.TextColor3 = C.gold
useTemplateBtn.Font = Enum.Font.GothamBold
useTemplateBtn.TextSize = 11
useTemplateBtn.Parent = form
corner(useTemplateBtn, 5)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.fromOffset(70, 26)
stopBtn.Position = UDim2.new(1, -160, 1, -34)
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
stopBtn.Text = "Stop"
stopBtn.TextColor3 = C.text
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12
stopBtn.Parent = form
corner(stopBtn, 5)
stopBtn.MouseButton1Click:Connect(function()
    stopKaitun("Idle")
end)

local pendingPos = Vector3.new(-1409.3359375, 1339.1600341796875, -978.4904174804688)

usePosBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if hrp then
        pendingPos = hrp.Position
        posLabel.Text = string.format("Pos: %.1f, %.1f, %.1f", pendingPos.X, pendingPos.Y, pendingPos.Z)
    end
end)

useTemplateBtn.MouseButton1Click:Connect(function()
    nameBox.Text = "Final Remedy"
    npcBox.Text = "Final Remedy"
    pendingPos = Vector3.new(-1409.3359375, 1339.1600341796875, -978.4904174804688)
    posLabel.Text = "Pos: FR template"
end)

addBtn.MouseButton1Click:Connect(function()
    local n = nameBox.Text ~= "" and nameBox.Text or "New Kaitun"
    local npc = npcBox.Text ~= "" and npcBox.Text or n
    table.insert(getgenv().LOL_Kaituns, {
        id = tostring(os.clock()),
        name = n,
        npc = npc,
        pos = pendingPos,
        mode = "follow",
        hover = 14,
        weapon = weaponBox.Text or "",
    })
    nameBox.Text = ""
    npcBox.Text = ""
    weaponBox.Text = ""
    refreshList()
    setStatus("Added " .. n)
end)

refreshList()
print("[LOL] TDR Kaitun Ready")