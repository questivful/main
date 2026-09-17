local plr = game:GetService("Players").LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("MainRemotes"):WaitForChild("Loadout")

local char, pack
local defer = task.defer

local infAmmo = {
    active = false,
    queries = {},
    matchAll = false,
    states = {},
    conns = {}
}

local function matches(name)
    if not infAmmo.active then return false end
    if infAmmo.matchAll then return true end
    if #infAmmo.queries == 0 then return false end
    local nl = name:lower()
    for _, q in ipairs(infAmmo.queries) do
        if nl:find(q, 1, true) then return true end
    end
    return false
end

local function newState()
    return {main = nil, hide = nil, busy = false, timer = nil, hooks = {}}
end

local function equip(tool)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        tool.Parent = pack
        hum:EquipTool(tool)
    else
        tool.Parent = char
    end
end

local function fetch(name, st)
    if st.busy or st.hide then return end
    st.busy = true
    pcall(function() remote:FireServer({name, "None", "None", "None"}) end)
    if st.timer then task.cancel(st.timer) end
    st.timer = task.delay(1.5, function() st.busy = false end)
end

local hook

local function swap(name, old, st)
    if not st.hide then return false end
    local rep = st.hide
    st.hide = nil
    st.main = rep
    for k, v in pairs(old:GetAttributes()) do
        rep:SetAttribute(k, v)
    end
    local wasEquipped = old.Parent == char
    old:Destroy()
    if wasEquipped then equip(rep) end
    hook(name, rep, st)
    fetch(name, st)
    return true
end

hook = function(name, tool, st)
    if not tool then return end
    local ammo = tool:WaitForChild("Ammo", 3)
    if not ammo then return end
    local function isReloading()
        local c = plr.Character
        if not c then return false end
        local be = c:FindFirstChild("BodyEffects")
        if not be then return false end
        local r = be:FindFirstChild("Reload")
        return r and r.Value == true
    end
    local function check()
        if st.main ~= tool then return end
        if tool.Parent ~= char and tool.Parent ~= pack then return end
        if isReloading() then return end
        local val = ammo.Value
        if val <= 0 then
            if not swap(name, tool, st) then
                fetch(name, st)
            end
        elseif val == 1 then
            fetch(name, st)
        end
    end
    table.insert(st.hooks, ammo:GetPropertyChangedSignal("Value"):Connect(check))
    check()
end

local function catch(child)
    if not child:IsA("Tool") then return end
    if not infAmmo.active then return end
    if not matches(child.Name) then return end
    local name = child.Name
    local st = infAmmo.states[name]
    if not st then
        st = newState()
        infAmmo.states[name] = st
    end
    if child == st.main or child == st.hide then return end
    defer(function()
        if child == st.main or child == st.hide then return end
        if st.timer then task.cancel(st.timer) end
        st.busy = false
        if not st.main or (st.main.Parent ~= char and st.main.Parent ~= pack) then
            st.main = child
            hook(name, st.main, st)
        elseif not st.hide then
            st.hide = child
            child.Parent = nil
            if st.main then
                local a = st.main:FindFirstChild("Ammo")
                if a and a.Value <= 0 then
                    swap(name, st.main, st)
                end
            end
        else
            child:Destroy()
        end
    end)
end

local function onRemoved(child)
    if not child:IsA("Tool") then return end
    local st = infAmmo.states[child.Name]
    if not st or st.main ~= child then return end
    defer(function()
        if st.main == child and st.main.Parent ~= char and st.main.Parent ~= pack then
            st.main = nil
            if st.hide then
                st.main = st.hide
                st.hide = nil
                hook(child.Name, st.main, st)
            end
            fetch(child.Name, st)
        end
    end)
end

local function clearState(st)
    if st.hooks then
        for _, c in ipairs(st.hooks) do pcall(function() c:Disconnect() end) end
        st.hooks = {}
    end
    if st.timer then pcall(function() task.cancel(st.timer) end) st.timer = nil end
    if st.hide then pcall(function() st.hide:Destroy() end) st.hide = nil end
    st.main = nil
    st.busy = false
end

local function stopAll()
    for _, st in pairs(infAmmo.states) do
        clearState(st)
    end
    infAmmo.states = {}
    for _, c in ipairs(infAmmo.conns) do pcall(function() c:Disconnect() end) end
    infAmmo.conns = {}
    infAmmo.active = false
    infAmmo.queries = {}
    infAmmo.matchAll = false
end

local function rescan()
    if char then for _, c in ipairs(char:GetChildren()) do catch(c) end end
    if pack then for _, c in ipairs(pack:GetChildren()) do catch(c) end end
end

local function attachChar(body)
    char = body
    table.insert(infAmmo.conns, char.ChildAdded:Connect(catch))
    table.insert(infAmmo.conns, char.ChildRemoved:Connect(onRemoved))
    for _, c in ipairs(char:GetChildren()) do catch(c) end
end

local function start(query)
    stopAll()
    infAmmo.active = true
    if query and query ~= "" and query ~= "all" then
        table.insert(infAmmo.queries, query:lower())
    else
        infAmmo.matchAll = true
    end

    pack = plr:WaitForChild("Backpack")
    table.insert(infAmmo.conns, pack.ChildAdded:Connect(catch))
    table.insert(infAmmo.conns, plr.CharacterAdded:Connect(function(body) defer(attachChar, body) end))
    if plr.Character then attachChar(plr.Character) end
    for _, c in ipairs(pack:GetChildren()) do catch(c) end
end

local function addQuery(query)
    if not infAmmo.active then return start(query) end
    if query == "all" then
        infAmmo.matchAll = true
    else
        query = query:lower()
        local exists = false
        for _, q in ipairs(infAmmo.queries) do
            if q == query then exists = true break end
        end
        if not exists then table.insert(infAmmo.queries, query) end
    end
    rescan()
end

local url = "https://raw.githubusercontent.com/ruki3i/Creations/refs/heads/main/source/DockManager.luau"
local dock = loadstring(game:HttpGet(url))()

dock.SetTheme(Color3.fromRGB(25, 25, 25))

local win = dock.new("Sriptink (v1)", 450, 300)

local pane = win.ContentPane

local log = Instance.new("ScrollingFrame")
log.Name = "Log"
log.Size = UDim2.new(1, -10, 1, -40)
log.Position = UDim2.new(0, 5, 0, 5)
log.BackgroundTransparency = 1
log.BorderSizePixel = 0
log.ScrollBarThickness = 4
log.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
log.CanvasSize = UDim2.new(0, 0, 0, 0)
log.AutomaticCanvasSize = Enum.AutomaticSize.Y
log.Parent = pane

local lay = Instance.new("UIListLayout")
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Padding = UDim.new(0, 3)
lay.Parent = log

local box = Instance.new("TextBox")
box.Name = "Input"
box.Size = UDim2.new(1, 0, 0, 25)
box.Position = UDim2.new(0, 0, 1, -25)
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(200, 255, 200)
box.TextTransparency = 1
box.Font = Enum.Font.Code
box.TextSize = 14
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
box.PlaceholderText = "type a command..."
box.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
box.Parent = pane

local ghostLbl = Instance.new("TextLabel")
ghostLbl.Name = "Ghost"
ghostLbl.Size = UDim2.new(1, 0, 0, 25)
ghostLbl.Position = UDim2.new(0, 0, 1, -25)
ghostLbl.BackgroundTransparency = 1
ghostLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
ghostLbl.Font = Enum.Font.Code
ghostLbl.TextSize = 14
ghostLbl.TextXAlignment = Enum.TextXAlignment.Left
ghostLbl.Text = ""
ghostLbl.Parent = pane

local ghostPad = Instance.new("UIPadding")
ghostPad.PaddingLeft = UDim.new(0, 12)
ghostPad.PaddingRight = UDim.new(0, 12)
ghostPad.Parent = ghostLbl

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = box

local hideLbl = Instance.new("TextLabel")
hideLbl.Size = UDim2.new(1, 0, 0, 25)
hideLbl.Position = UDim2.new(0, 0, 1, -25)
hideLbl.BackgroundTransparency = 1
hideLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
hideLbl.Font = Enum.Font.Code
hideLbl.TextSize = 14
hideLbl.Text = "{ .. }"
hideLbl.ZIndex = 5
hideLbl.Parent = pane

local suggFrame = Instance.new("ScrollingFrame")
suggFrame.Size = UDim2.new(1, 0, 0, 0)
suggFrame.Position = UDim2.new(0, 0, 1, -25)
suggFrame.AnchorPoint = Vector2.new(0, 1)
suggFrame.BackgroundTransparency = 1
suggFrame.BorderSizePixel = 0
suggFrame.ScrollBarThickness = 0
suggFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
suggFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
suggFrame.ScrollingDirection = Enum.ScrollingDirection.X
suggFrame.ClipsDescendants = true
suggFrame.Parent = pane

local suggList = Instance.new("UIListLayout")
suggList.FillDirection = Enum.FillDirection.Horizontal
suggList.SortOrder = Enum.SortOrder.LayoutOrder
suggList.Padding = UDim.new(0, 5)
suggList.Parent = suggFrame

local suggPad = Instance.new("UIPadding")
suggPad.PaddingLeft = UDim.new(0, 10)
suggPad.PaddingRight = UDim.new(0, 10)
suggPad.PaddingTop = UDim.new(0, 5)
suggPad.PaddingBottom = UDim.new(0, 5)
suggPad.Parent = suggFrame

local isBoxFocused = false
local ts = game:GetService("TweenService")

box.MouseEnter:Connect(function()
    if box.Text == "" then
        box.TextTransparency = 0
        box.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
        hideLbl.TextTransparency = 1
    end
end)

box.MouseLeave:Connect(function()
    if not isBoxFocused and box.Text == "" then
        box.TextTransparency = 1
        box.PlaceholderColor3 = Color3.new(1, 1, 1)
        hideLbl.TextTransparency = 0
    end
end)

box.Focused:Connect(function()
    isBoxFocused = true
    box.TextTransparency = 0
    hideLbl.TextTransparency = 1
end)

box.FocusLost:Connect(function()
    isBoxFocused = false
    if box.Text == "" then
        box.TextTransparency = 1
        hideLbl.TextTransparency = 0
    end
    ts:Create(suggFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
end)

local function clearSuggestions()
    for _, c in ipairs(suggFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function addSuggestion(plrData, order, cmdStr)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 30, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.Parent = suggFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = f

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, -4, 1, -4)
    img.Position = UDim2.new(0, 2, 0, 2)
    img.BackgroundTransparency = 1
    img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plrData.UserId .. "&w=48&h=48"
    img.Parent = f

    local icorner = Instance.new("UICorner")
    icorner.CornerRadius = UDim.new(0, 4)
    icorner.Parent = img

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f

    btn.MouseButton1Click:Connect(function()
        box.Text = cmdStr .. " " .. plrData.Name
        box:CaptureFocus()
        box.CursorPosition = #box.Text + 1
    end)
end

local uis = game:GetService("UserInputService")
uis.InputBegan:Connect(function(input, gp)
    if isBoxFocused and input.KeyCode == Enum.KeyCode.Tab then
        if ghostLbl.Text ~= "" and ghostLbl.Text ~= box.Text then
            task.delay(0, function()
                box.Text = ghostLbl.Text
                box:CaptureFocus()
                box.CursorPosition = #box.Text + 1
            end)
        end
    end
end)

local playerCmds = {
    ["kill"] = true, ["goto"] = true, ["tpto"] = true, ["bring"] = true, 
    ["freeze"] = true, ["thaw"] = true, ["loopkill"] = true
}

local cmdUsages = {
    ["help"] = "help",
    ["clear"] = "clear",
    ["echo"] = "echo [text]",
    ["time"] = "time",
    ["whoami"] = "whoami",
    ["kill"] = "kill [player]",
    ["killall"] = "killall",
    ["loopkill"] = "loopkill [player]",
    ["unloopkill"] = "unloopkill",
    ["goto"] = "goto [player]",
    ["tpto"] = "tpto [player]",
    ["bring"] = "bring [player]",
    ["tp"] = "tp [x] [y] [z]",
    ["speed"] = "speed [number]",
    ["jump"] = "jump [number]",
    ["hip"] = "hip [number]",
    ["noclip"] = "noclip",
    ["fly"] = "fly",
    ["respawn"] = "respawn",
    ["freeze"] = "freeze [player]",
    ["thaw"] = "thaw [player]",
    ["god"] = "god",
    ["invisible"] = "invisible",
    ["esp"] = "esp [hex1] [hex2]",
    ["infammo"] = "infammo [name/all]",
    ["uninfammo"] = "uninfammo",
    ["reflect"] = "reflect [on/off]",
    ["deflect"] = "deflect [on/off]",
    ["deflectaim"] = "deflectaim [on/off]",
    ["ws"] = "ws [number]",
    ["jp"] = "jp [number]",
    ["automask"] = "automask",
    ["spiderverse"] = "spiderverse"
}

box:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = box.Text
    local args = string.split(txt, " ")
    local cmd = args[1] and args[1]:lower() or ""
    
    local ghostText = ""
    
    if txt == "" then
        ghostLbl.Text = ""
        box.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        local matched = false
        for cname, usage in pairs(cmdUsages) do
            if string.sub(cname, 1, #cmd) == cmd then
                matched = true
                if #args == 1 then
                    ghostText = cname .. string.sub(usage, #cname + 1)
                else
                    if playerCmds[cname] and args[2] then
                        local q = table.concat(args, " ", 2):lower()
                        local firstMatchPlayer = nil
                        local ps = game:GetService("Players")
                        for _, p in ipairs(ps:GetPlayers()) do
                            if q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                                firstMatchPlayer = p
                                break
                            end
                        end
                        if firstMatchPlayer then
                            if firstMatchPlayer.Name:lower():sub(1, #q) == q then
                                ghostText = txt .. string.sub(firstMatchPlayer.Name, #q + 1)
                            elseif firstMatchPlayer.DisplayName:lower():sub(1, #q) == q then
                                ghostText = txt .. string.sub(firstMatchPlayer.DisplayName, #q + 1)
                            else
                                ghostText = args[1] .. " " .. firstMatchPlayer.Name
                            end
                        else
                            ghostText = txt .. string.sub(usage, #txt + 1)
                        end
                    else
                        ghostText = txt .. string.sub(usage, #txt + 1)
                    end
                end
                break
            end
        end
        if not matched then
            ghostText = ""
        end
        
        ghostLbl.Text = ghostText
        
        if cmdUsages[cmd] then
            box.TextColor3 = Color3.fromRGB(150, 255, 150)
        else
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    if playerCmds[cmd] and args[2] then
        local q = table.concat(args, " ", 2):lower()
        clearSuggestions()
        local count = 0
        local ps = game:GetService("Players")
        for _, p in ipairs(ps:GetPlayers()) do
            if q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                count = count + 1
                addSuggestion(p, count, args[1])
            end
        end
        if count > 0 then
            ts:Create(suggFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 40)}):Play()
        else
            ts:Create(suggFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        end
    else
        ts:Create(suggFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        clearSuggestions()
    end
end)

local count = 0
local function out(text, color)
    count = count + 1
    local m = Instance.new("TextLabel")
    m.Size = UDim2.new(1, 0, 0, 0)
    m.AutomaticSize = Enum.AutomaticSize.Y
    m.BackgroundTransparency = 1
    m.TextColor3 = color or Color3.fromRGB(220, 220, 220)
    m.Font = Enum.Font.Code
    m.TextSize = 13
    m.TextWrapped = true
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.Text = text
    m.LayoutOrder = count
    m.Parent = log
    task.spawn(function()
        game:GetService("RunService").RenderStepped:Wait()
        log.CanvasPosition = Vector2.new(0, log.AbsoluteCanvasSize.Y)
    end)
end

local BLOCKED_ANIM_IDS = {
    ["118053438037780"] = true,
    ["122596405294275"] = true,
    ["76057573689324"] = true,
}

local ps = game:GetService("Players")
local lp = ps.LocalPlayer

local animBlockActive = false
local animCharConn = nil
local animatorConn = nil

local function killTrack(track)
    local anim = track.Animation
    if not anim or not anim.AnimationId then return end
    local id = string.match(anim.AnimationId, "%d+")
    if not id or not BLOCKED_ANIM_IDS[id] then return end
    pcall(function()
        track:Stop(0)
        track:AdjustSpeed(0)
    end)
end

local function hookAnimator(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local animator = humanoid:WaitForChild("Animator", 5)
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        killTrack(track)
    end

    if animatorConn then
        animatorConn:Disconnect()
    end
    animatorConn = animator.AnimationPlayed:Connect(function(track)
        if not animBlockActive then return end
        killTrack(track)
    end)
end

local function startAnimBlock()
    animBlockActive = true
    if lp.Character then task.spawn(hookAnimator, lp.Character) end
    if animCharConn then animCharConn:Disconnect() end
    animCharConn = lp.CharacterAdded:Connect(function(c)
        if animBlockActive then task.spawn(hookAnimator, c) end
    end)
end

local function stopAnimBlock()
    animBlockActive = false
    if animatorConn then animatorConn:Disconnect() animatorConn = nil end
    if animCharConn then animCharConn:Disconnect() animCharConn = nil end
end

local cmds = {}

cmds.help = function(a)
    out("commands:", Color3.fromRGB(150, 255, 150))
    out(" help - list commands", Color3.fromRGB(180, 180, 180))
    out(" clear - clear log", Color3.fromRGB(180, 180, 180))
    out(" echo - repeat text", Color3.fromRGB(180, 180, 180))
    out(" time - show time", Color3.fromRGB(180, 180, 180))
    out(" whoami - show your name", Color3.fromRGB(180, 180, 180))
    out(" kill - kill a player", Color3.fromRGB(180, 180, 180))
    out(" killall - kill everyone", Color3.fromRGB(180, 180, 180))
    out(" loopkill - toggle loopkill on player", Color3.fromRGB(180, 180, 180))
    out(" unloopkill - stop loopkill", Color3.fromRGB(180, 180, 180))
    out(" goto - teleport to a player", Color3.fromRGB(180, 180, 180))
    out(" tpto - teleport a player to you", Color3.fromRGB(180, 180, 180))
    out(" bring - bring a player to you", Color3.fromRGB(180, 180, 180))
    out(" tp - teleport to coords x y z", Color3.fromRGB(180, 180, 180))
    out(" speed - set walkspeed", Color3.fromRGB(180, 180, 180))
    out(" jump - set jumppower", Color3.fromRGB(180, 180, 180))
    out(" hip - set hipheight", Color3.fromRGB(180, 180, 180))
    out(" noclip - toggle noclip", Color3.fromRGB(180, 180, 180))
    out(" fly - toggle fly", Color3.fromRGB(180, 180, 180))
    out(" respawn - respawn your character", Color3.fromRGB(180, 180, 180))
    out(" freeze - freeze a player", Color3.fromRGB(180, 180, 180))
    out(" thaw - unfreeze a player", Color3.fromRGB(180, 180, 180))
    out(" god - toggle godmode", Color3.fromRGB(180, 180, 180))
    out(" invisible - toggle invisibility", Color3.fromRGB(180, 180, 180))
    out(" esp - toggle ESP (optional hex1 hex2)", Color3.fromRGB(180, 180, 180))
    out(" infammo - infinite ammo (name/all)", Color3.fromRGB(180, 180, 180))
    out(" uninfammo - remove infinite ammo", Color3.fromRGB(180, 180, 180))
    out(" reflect - auto-reflect shooters (on/off)", Color3.fromRGB(180, 180, 180))
    out(" deflect - alias for reflect", Color3.fromRGB(180, 180, 180))
    out(" deflectaim - auto-kill aimers (on/off)", Color3.fromRGB(180, 180, 180))
    out(" automask - auto-buy and equip mask", Color3.fromRGB(180, 180, 180))
    out(" spiderverse - load spiderverse script", Color3.fromRGB(180, 180, 180))
    out(" ws - alias for speed", Color3.fromRGB(180, 180, 180))
    out(" jp - alias for jump", Color3.fromRGB(180, 180, 180))
end

cmds.clear = function(a)
    for _, c in ipairs(log:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    count = 0
    out("cleared.", Color3.fromRGB(150, 255, 150))
end

cmds.echo = function(a)
    if #a == 0 then out("usage: echo ", Color3.fromRGB(255, 150, 150)) return end
    out(table.concat(a, " "))
end

cmds.time = function(a) out("time: " .. os.date("%X"), Color3.fromRGB(255, 255, 150)) end

cmds.whoami = function(a)
    out("you: " .. lp.Name .. " (@" .. lp.DisplayName .. ")", Color3.fromRGB(150, 200, 255))
end

local function find(q)
    q = q:lower()
    for _, p in ipairs(ps:GetPlayers()) do
        if p.Name:lower() == q then return p end
        if p.DisplayName:lower() == q then return p end
        if tostring(p.UserId) == q then return p end
    end
    for _, p in ipairs(ps:GetPlayers()) do
        if p.Name:lower():find(q, 1, true) then return p end
        if p.DisplayName:lower():find(q, 1, true) then return p end
    end
    return nil
end

local function mychar() return lp.Character or lp.CharacterAdded:Wait() end
local function myhrp()
    local c = mychar()
    return c:WaitForChild("HumanoidRootPart", 5)
end
local function myhum()
    local c = mychar()
    return c:FindFirstChildOfClass("Humanoid")
end

cmds.goto = function(a)
    if #a == 0 then out("usage: goto ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    local tc = tp.Character
    if not tc then out("target has no character.", Color3.fromRGB(255, 100, 100)) return end
    local thr = tc:FindFirstChild("HumanoidRootPart")
    if not thr then out("target has no hrp.", Color3.fromRGB(255, 100, 100)) return end
    local hr = myhrp()
    if not hr then out("you have no hrp.", Color3.fromRGB(255, 100, 100)) return end
    hr.CFrame = thr.CFrame + Vector3.new(0, 3, 0)
    out("teleported to " .. tp.Name, Color3.fromRGB(150, 255, 150))
end

cmds.tpto = function(a)
    if #a == 0 then out("usage: tpto ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    local tc = tp.Character
    if not tc then out("target has no character.", Color3.fromRGB(255, 100, 100)) return end
    local thr = tc:FindFirstChild("HumanoidRootPart")
    if not thr then out("target has no hrp.", Color3.fromRGB(255, 100, 100)) return end
    local hr = myhrp()
    if not hr then out("you have no hrp.", Color3.fromRGB(255, 100, 100)) return end
    thr.CFrame = hr.CFrame + Vector3.new(0, 3, 0)
    out("teleported " .. tp.Name .. " to you", Color3.fromRGB(150, 255, 150))
end

cmds.bring = cmds.tpto

cmds.tp = function(a)
    if #a < 3 then out("usage: tp x y z", Color3.fromRGB(255, 150, 150)) return end
    local x = tonumber(a[1])
    local y = tonumber(a[2])
    local z = tonumber(a[3])
    if not x or not y or not z then out("invalid coords.", Color3.fromRGB(255, 100, 100)) return end
    local hr = myhrp()
    if not hr then out("you have no hrp.", Color3.fromRGB(255, 100, 100)) return end
    hr.CFrame = CFrame.new(x, y, z)
    out("teleported to " .. x .. ", " .. y .. ", " .. z, Color3.fromRGB(150, 255, 150))
end

cmds.speed = function(a)
    if #a == 0 then out("usage: speed ", Color3.fromRGB(255, 150, 150)) return end
    local n = tonumber(a[1])
    if not n then out("invalid number.", Color3.fromRGB(255, 100, 100)) return end
    local h = myhum()
    if not h then out("no humanoid.", Color3.fromRGB(255, 100, 100)) return end
    h.WalkSpeed = n
    out("speed set to " .. n, Color3.fromRGB(150, 255, 150))
end

cmds.ws = cmds.speed

cmds.jump = function(a)
    if #a == 0 then out("usage: jump ", Color3.fromRGB(255, 150, 150)) return end
    local n = tonumber(a[1])
    if not n then out("invalid number.", Color3.fromRGB(255, 100, 100)) return end
    local h = myhum()
    if not h then out("no humanoid.", Color3.fromRGB(255, 100, 100)) return end
    h.UseJumpPower = true
    h.JumpPower = n
    out("jump set to " .. n, Color3.fromRGB(150, 255, 150))
end

cmds.jp = cmds.jump

cmds.hip = function(a)
    if #a == 0 then out("usage: hip ", Color3.fromRGB(255, 150, 150)) return end
    local n = tonumber(a[1])
    if not n then out("invalid number.", Color3.fromRGB(255, 100, 100)) return end
    local h = myhum()
    if not h then out("no humanoid.", Color3.fromRGB(255, 100, 100)) return end
    h.HipHeight = n
    out("hipheight set to " .. n, Color3.fromRGB(150, 255, 150))
end

local noclip = false
local noclipconn = nil

cmds.noclip = function(a)
    noclip = not noclip
    if noclip then
        noclipconn = game:GetService("RunService").Stepped:Connect(function()
            local c = lp.Character
            if c then
                for _, v in ipairs(c:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
        out("noclip on", Color3.fromRGB(150, 255, 150))
    else
        if noclipconn then noclipconn:Disconnect() noclipconn = nil end
        out("noclip off", Color3.fromRGB(255, 200, 100))
    end
end

local fly = false
local flyconn = nil
local flybg = nil
local flybv = nil

cmds.fly = function(a)
    fly = not fly
    if fly then
        local hr = myhrp()
        local h = myhum()
        if not hr or not h then
            out("no character.", Color3.fromRGB(255, 100, 100))
            fly = false
            return
        end
        flybg = Instance.new("BodyGyro")
        flybg.P = 9e4
        flybg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flybg.CFrame = hr.CFrame
        flybg.Parent = hr

        flybv = Instance.new("BodyVelocity")
        flybv.Velocity = Vector3.new(0, 0, 0)
        flybv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flybv.Parent = hr

        local uis = game:GetService("UserInputService")
        local cam = workspace.CurrentCamera
        local speed = 50

        flyconn = game:GetService("RunService").RenderStepped:Connect(function()
            if not fly then return end
            local dir = Vector3.new(0, 0, 0)
            if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            if flybv then flybv.Velocity = dir * speed end
            if flybg and hr then flybg.CFrame = cam.CFrame end
        end)
        out("fly on", Color3.fromRGB(150, 255, 150))
    else
        if flyconn then flyconn:Disconnect() flyconn = nil end
        if flybg then flybg:Destroy() flybg = nil end
        if flybv then flybv:Destroy() flybv = nil end
        out("fly off", Color3.fromRGB(255, 200, 100))
    end
end

cmds.respawn = function(a)
    lp:LoadCharacter()
    out("respawned.", Color3.fromRGB(150, 255, 150))
end

local frozen = {}

cmds.freeze = function(a)
    if #a == 0 then out("usage: freeze ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    local tc = tp.Character
    if not tc then out("no character.", Color3.fromRGB(255, 100, 100)) return end
    local hr = tc:FindFirstChild("HumanoidRootPart")
    if not hr then out("no hrp.", Color3.fromRGB(255, 100, 100)) return end
    if frozen[tp] then frozen[tp]:Destroy() end
    local anchor = Instance.new("Part")
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.Anchored = true
    anchor.CFrame = hr.CFrame
    anchor.Parent = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hr
    weld.Part1 = anchor
    weld.Parent = anchor
    frozen[tp] = anchor
    out("froze " .. tp.Name, Color3.fromRGB(150, 255, 150))
end

cmds.thaw = function(a)
    if #a == 0 then out("usage: thaw ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    if frozen[tp] then
        frozen[tp]:Destroy()
        frozen[tp] = nil
        out("thawed " .. tp.Name, Color3.fromRGB(150, 255, 150))
    else
        out(tp.Name .. " is not frozen.", Color3.fromRGB(255, 200, 100))
    end
end

local god = false

cmds.god = function(a)
    god = not god
    local h = myhum()
    if not h then out("no humanoid.", Color3.fromRGB(255, 100, 100)) return end
    if god then
        h.MaxHealth = math.huge
        h.Health = math.huge
        out("god on", Color3.fromRGB(150, 255, 150))
    else
        h.MaxHealth = 100
        h.Health = 100
        out("god off", Color3.fromRGB(255, 200, 100))
    end
end

local invis = false

cmds.invisible = function(a)
    invis = not invis
    local c = lp.Character
    if not c then out("no character.", Color3.fromRGB(255, 100, 100)) return end
    for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = invis and 1 or 0
            if v:IsA("MeshPart") or v:IsA("Part") then
                v.LocalTransparencyModifier = invis and 1 or 0
            end
        end
        if v:IsA("Decal") then v.Transparency = invis and 1 or 0 end
    end
    out("invisible " .. (invis and "on" or "off"), Color3.fromRGB(150, 255, 150))
end

local espActive = false
local espConnections = {}
local espData = {}
local espColor1 = Color3.fromRGB(0, 150, 255)
local espColor2 = Color3.fromRGB(240, 250, 255)
local ESP_MAX_DISTANCE = 500
local ESP_MIN_DISTANCE = 8

local espEdges = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8}
}

local function hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        return Color3.fromRGB(
            tonumber(hex:sub(1, 2), 16),
            tonumber(hex:sub(3, 4), 16),
            tonumber(hex:sub(5, 6), 16)
        )
    end
    return nil
end

local function espAddConnection(conn)
    table.insert(espConnections, conn)
    return conn
end

local function espCreate(player)
    if player == lp then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local folder = Instance.new("Folder")
    folder.Name = "DiamondESP_" .. player.Name
    folder.Parent = workspace

    local lines = {}
    for i = 1, 12 do
        local line = Instance.new("LineHandleAdornment")
        line.AlwaysOnTop = true
        line.ZIndex = 5
        line.Adornee = hrp
        line.Parent = folder
        table.insert(lines, line)
    end

    espData[player] = {
        folder = folder,
        lines = lines,
        character = character
    }
end

local function espRemove(player)
    if espData[player] then
        if espData[player].folder then espData[player].folder:Destroy() end
        espData[player] = nil
    end
end

local function espSetupPlayer(player)
    if player == lp then return end

    espAddConnection(player.CharacterAdded:Connect(function()
        espRemove(player)
        task.wait(0.3)
        if espActive then espCreate(player) end
    end))

    espAddConnection(player.CharacterRemoving:Connect(function()
        espRemove(player)
    end))

    if player.Character and espActive then
        espCreate(player)
    end
end

local function espStop()
    for _, conn in ipairs(espConnections) do conn:Disconnect() end
    espConnections = {}
    for _, data in pairs(espData) do
        if data.folder then data.folder:Destroy() end
    end
    espData = {}
end

local function espStart()
    espStop()
    espAddConnection(ps.PlayerAdded:Connect(espSetupPlayer))
    espAddConnection(ps.PlayerRemoving:Connect(espRemove))
    for _, p in ipairs(ps:GetPlayers()) do espSetupPlayer(p) end

    espAddConnection(game:GetService("RunService").RenderStepped:Connect(function()
        local myChar = lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

        local t = os.clock()
        local lerpAlpha = (math.sin(t * 3) + 1) / 2
        local frostyColor = espColor1:Lerp(espColor2, lerpAlpha)
        local thickness = 2.5 + math.sin(t * 6) * 1

        local shakeX = math.noise(t * 15, 0, 0) * 0.15
        local shakeY = math.noise(0, t * 15, 0) * 0.15
        local shakeZ = math.noise(0, 0, t * 15) * 0.15
        local shakeVec = Vector3.new(shakeX, shakeY, shakeZ)

        for player, data in pairs(espData) do
            local character = player.Character
            if character and data.folder then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = 0
                    if myHRP then
                        distance = (myHRP.Position - hrp.Position).Magnitude
                    end

                    local visible = distance >= ESP_MIN_DISTANCE and distance <= ESP_MAX_DISTANCE

                    if visible then
                        local cf, size = character:GetBoundingBox()
                        cf = cf + shakeVec

                        local sx, sy, sz = (size.X / 2) + 0.1, (size.Y / 2) + 0.1, (size.Z / 2) + 0.1

                        local corners = {
                            cf * Vector3.new(sx, sy, sz),
                            cf * Vector3.new(-sx, sy, sz),
                            cf * Vector3.new(-sx, sy, -sz),
                            cf * Vector3.new(sx, sy, -sz),
                            cf * Vector3.new(sx, -sy, sz),
                            cf * Vector3.new(-sx, -sy, sz),
                            cf * Vector3.new(-sx, -sy, -sz),
                            cf * Vector3.new(sx, -sy, -sz)
                        }

                        local hrpCF = hrp.CFrame

                        for i, edgeInfo in ipairs(espEdges) do
                            local p1 = hrpCF:PointToObjectSpace(corners[edgeInfo[1]])
                            local p2 = hrpCF:PointToObjectSpace(corners[edgeInfo[2]])
                            local line = data.lines[i]

                            local dist = (p2 - p1).Magnitude
                            if dist > 0.001 then
                                line.Color3 = frostyColor
                                line.Thickness = thickness
                                line.CFrame = CFrame.lookAt(p1, p2)
                                line.Length = dist
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        end
                    else
                        for _, line in ipairs(data.lines) do
                            line.Visible = false
                        end
                    end
                end
            end
        end
    end))
end

cmds.esp = function(a)
    if espActive then
        espActive = false
        espStop()
        out("esp off", Color3.fromRGB(255, 200, 100))
        return
    end

    if #a >= 2 then
        local c1 = hexToColor(a[1])
        local c2 = hexToColor(a[2])
        if c1 and c2 then
            espColor1 = c1
            espColor2 = c2
        else
            out("invalid hex colors, using defaults.", Color3.fromRGB(255, 200, 100))
            espColor1 = Color3.fromRGB(0, 150, 255)
            espColor2 = Color3.fromRGB(240, 250, 255)
        end
    else
        espColor1 = Color3.fromRGB(0, 150, 255)
        espColor2 = Color3.fromRGB(240, 250, 255)
    end

    espActive = true
    espStart()
    out("esp on", Color3.fromRGB(150, 255, 150))
end

local loopkillActive = false
local loopkillTarget = nil
local loopkillThread = nil

local gripMap = {}

local killAnimBlockCount = 0

local GunHandler = require(game:GetService("ReplicatedStorage").Modules.GunHandler)

local function collectGuns(c)
    local guns = {}
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") and v:FindFirstChild("Damage") and v:FindFirstChild("Range") then
            table.insert(guns, v)
        end
    end
    for _, v in ipairs(lp.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") and v:FindFirstChild("Damage") and v:FindFirstChild("Range") then
            table.insert(guns, v)
        end
    end
    return guns
end

local function reloadGun(gun, c, rem)
    local am = gun:FindFirstChild("Ammo")
    local mx = gun:FindFirstChild("MaxAmmo")
    if not am then return end
    local need = mx and mx.Value or 30
    if am.Value >= need then return end
    local function isReloading()
        local be = c:FindFirstChild("BodyEffects")
        if not be then return false end
        local r = be:FindFirstChild("Reload")
        return r and r.Value == true
    end
    if isReloading() then
        while isReloading() do task.wait(0.05) end
    end
    rem:FireServer("Reload", gun:FindFirstChild("Handle"))
    local to = tick() + 3
    while isReloading() and tick() < to do task.wait(0.05) end
end

local function shootGun(gun, c, thrp, rem)
    if not gun or not gun:FindFirstChild("Handle") or not gun:FindFirstChild("Damage") or not gun:FindFirstChild("Range") then return end
    if gun.Parent ~= c then gun.Parent = c end
    local handle = gun.Handle
    local dmg = gun.Damage
    local range = gun.Range
    local targetPos = thrp.Position
    local origin = targetPos + Vector3.new(0, -80, 0)
    local isShotgun = gun.Name:find("Shotgun") or gun.Name:find("SG")
    if isShotgun then
        local t = {}
        for i = 1, 5 do
            table.insert(t, {
                AimPosition = targetPos,
                RawAimPosition = targetPos,
                Result1 = targetPos,
                Result2 = thrp,
                Result3 = Vector3.new(0, 1, 0),
                AimLockPart = thrp,
            })
        end
        pcall(function()
            GunHandler.Shoot({
                Shooter = c,
                Handle = handle,
                ForcedOrigin = origin,
                AimPosition = targetPos,
                AimLockPart = thrp,
                Hit = thrp,
                Normal = Vector3.new(0, 1, 0),
                Range = range.Value,
            })
        end)
        rem:FireServer("ShootGun", handle, origin, t, nil, nil, nil, range.Value, dmg.Value)
    else
        pcall(function()
            GunHandler.Shoot({
                Shooter = c,
                Handle = handle,
                ForcedOrigin = origin,
                AimPosition = targetPos,
                AimLockPart = thrp,
                Hit = thrp,
                Normal = Vector3.new(0, 1, 0),
                Range = range.Value,
            })
        end)
        for i = 1, 8 do
            rem:FireServer("ShootGun", handle, origin, nil, targetPos, thrp, Vector3.new(0, 1, 0), range.Value, dmg.Value, targetPos, thrp)
        end
    end
end

local hb = 200

local function isfx(o)
    return o:IsA("ParticleEmitter")
        or o:IsA("BillboardGui")
        or o:IsA("SurfaceGui")
        or o:IsA("Beam")
        or o:IsA("Trail")
        or o:IsA("Fire")
        or o:IsA("Smoke")
        or o:IsA("Sparkles")
        or o:IsA("Decal")
        or o:IsA("Texture")
        or o:IsA("Light")
end

local function moveFx(hrp, ch, o, origData, movedData)
    if not o or not o.Parent or not origData[hrp] then return end
    if not isfx(o) then return end
    if movedData[o] then return end
    local direct = o.Parent == hrp
    local ad = (o:IsA("BillboardGui") or o:IsA("SurfaceGui")) and o.Adornee == hrp
    if direct or ad then
        movedData[o] = {
            Parent = o.Parent,
            Adornee = (o:IsA("BillboardGui") or o:IsA("SurfaceGui")) and o.Adornee or nil,
        }
        local t = ch:FindFirstChild("UpperTorso")
            or ch:FindFirstChild("Torso")
            or ch:FindFirstChild("LowerTorso")
            or ch:FindFirstChild("Head")
            or hrp
        if direct then o.Parent = t end
        if ad then o.Adornee = t end
    end
end

local function applyHitbox(ch, hrp, origData, movedData)
    if not hrp or origData[hrp] then return end
    local sz = hrp.Size
    local tr = hrp.Transparency
    local cc = hrp.CanCollide
    local co = hrp.Color
    if sz.X > 5 or sz.Y > 5 or sz.Z > 5 then
        sz = Vector3.new(2, 2, 1)
        tr = 1
        cc = false
        co = Color3.fromRGB(163, 162, 165)
    end
    origData[hrp] = {
        Size = sz,
        Transparency = tr,
        Color = co,
        CanCollide = cc,
        Connections = {},
        Character = ch,
    }
    local c1 = hrp.ChildAdded:Connect(function(o)
        task.defer(function() moveFx(hrp, ch, o, origData, movedData) end)
    end)
    table.insert(origData[hrp].Connections, c1)
    local c2 = ch.DescendantAdded:Connect(function(o)
        task.defer(function() moveFx(hrp, ch, o, origData, movedData) end)
    end)
    table.insert(origData[hrp].Connections, c2)
    for _, o in ipairs(ch:GetDescendants()) do
        moveFx(hrp, ch, o, origData, movedData)
    end
    hrp.Size = Vector3.new(hb, hb, hb)
    hrp.Transparency = 1
    hrp.CanCollide = false
end

local function revertHitbox(hrp, origData, movedData)
    if not hrp or not origData[hrp] then return end
    local d = origData[hrp]
    if d.Connections then
        for _, c1 in ipairs(d.Connections) do c1:Disconnect() end
    end
    for o, s in pairs(movedData) do
        if o and o.Parent then
            o.Parent = s.Parent
            if o:IsA("BillboardGui") or o:IsA("SurfaceGui") then
                o.Adornee = s.Adornee
            end
        end
    end
    hrp.Size = d.Size
    hrp.Transparency = d.Transparency
    hrp.Color = d.Color
    hrp.CanCollide = d.CanCollide
    origData[hrp] = nil
end

local function killPlayer(tp, silent)
    if tp == lp then
        if not silent then out("cant kill yourself.", Color3.fromRGB(255, 100, 100)) end
        return false
    end

    local tc = tp.Character
    if not tc then
        if not silent then out("no character for " .. tp.Name, Color3.fromRGB(255, 100, 100)) end
        return false
    end

    local thrp = tc:FindFirstChild("HumanoidRootPart")
    if not thrp then
        if not silent then out("no hrp for " .. tp.Name, Color3.fromRGB(255, 100, 100)) end
        return false
    end

    local c = lp.Character
    if not c then
        if not silent then out("you have no character.", Color3.fromRGB(255, 100, 100)) end
        return false
    end

    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then
        if not silent then out("no humanoid.", Color3.fromRGB(255, 100, 100)) end
        return false
    end

    killAnimBlockCount = killAnimBlockCount + 1
    if not animBlockActive then
        startAnimBlock()
    end

    local rs = game:GetService("ReplicatedStorage")
    local rem = rs.MainRemotes.MainRemoteEvent

    local guns = collectGuns(c)

    if #guns == 0 then
        if not silent then out("no guns found.", Color3.fromRGB(255, 100, 100)) end
        killAnimBlockCount = killAnimBlockCount - 1
        if killAnimBlockCount <= 0 then
            killAnimBlockCount = 0
            stopAnimBlock()
        end
        return false
    end

    local origData = {}
    local movedData = {}
    applyHitbox(tc, thrp, origData, movedData)

    local savedGrips = {}
    for _, gun in ipairs(guns) do
        if not gripMap[gun] then
            gripMap[gun] = gun.GripPos
        end
        savedGrips[gun] = gripMap[gun]
    end

    for _, gun in ipairs(guns) do
        if not thrp or not thrp.Parent then break end
        local be = tc:FindFirstChild("BodyEffects")
        if be and be:FindFirstChild("K.O") and be["K.O"].Value == true then break end
        pcall(function()
            if gun.Parent ~= c then gun.Parent = c end
            h:EquipTool(gun)
            gun.GripPos = Vector3.new(0, 10000, 0)
            local am = gun:FindFirstChild("Ammo")
            if am and am.Value < 1 then
                reloadGun(gun, c, rem)
            end
            shootGun(gun, c, thrp, rem)
        end)
    end

    task.delay(0.5, function()
        pcall(function()
            revertHitbox(thrp, origData, movedData)
            for _, gun in ipairs(guns) do
                if savedGrips[gun] then
                    gun.GripPos = savedGrips[gun]
                end
            end
            h:UnequipTools()
            local curH = c and c:FindFirstChildOfClass("Humanoid")
            if curH then
                pcall(function()
                    curH:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
        end)
        killAnimBlockCount = killAnimBlockCount - 1
        if killAnimBlockCount <= 0 then
            killAnimBlockCount = 0
            stopAnimBlock()
        end
    end)

    return true
end

cmds.kill = function(a)
    if #a == 0 then out("usage: kill ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    out("found: " .. tp.Name .. " (@" .. tp.DisplayName .. ")", Color3.fromRGB(150, 255, 150))
    task.spawn(function() pcall(function() killPlayer(tp, false) end) end)
end

cmds.killall = function(a)
    out("killing everyone...", Color3.fromRGB(255, 200, 100))
    task.spawn(function()
        for _, p in ipairs(ps:GetPlayers()) do
            if p ~= lp then
                pcall(function() killPlayer(p, true) end)
                task.wait(0.1)
            end
        end
        out("killall complete.", Color3.fromRGB(150, 255, 150))
    end)
end

cmds.loopkill = function(a)
    if #a == 0 then out("usage: loopkill ", Color3.fromRGB(255, 150, 150)) return end
    local q = table.concat(a, " ")
    local tp = find(q)
    if not tp then out("not found: " .. q, Color3.fromRGB(255, 100, 100)) return end
    if loopkillActive then
        out("already loopkilling " .. (loopkillTarget and loopkillTarget.Name or "?"), Color3.fromRGB(255, 200, 100))
        return
    end
    loopkillActive = true
    loopkillTarget = tp
    out("loopkill started on " .. tp.Name, Color3.fromRGB(150, 255, 150))
    if not infAmmo.active then
        start(nil)
        out("infammo auto-enabled for loopkill", Color3.fromRGB(150, 255, 150))
    end
    loopkillThread = task.spawn(function()
        while loopkillActive do
            if not loopkillTarget or not loopkillTarget.Parent then
                out("target left the game, stopping loopkill.", Color3.fromRGB(255, 200, 100))
                loopkillActive = false
                break
            end
            local tc = loopkillTarget.Character
            if tc then
                local be = tc:FindFirstChild("BodyEffects")
                local ko = be and be:FindFirstChild("K.O")
                if ko and ko.Value == false then
                    local c = lp.Character
                    if c then
                        local rem = game:GetService("ReplicatedStorage").MainRemotes.MainRemoteEvent
                        local guns = collectGuns(c)
                        for _, gun in ipairs(guns) do
                            pcall(function()
                                local am = gun:FindFirstChild("Ammo")
                                if am and am.Value < 1 then
                                    reloadGun(gun, c, rem)
                                end
                            end)
                        end
                    end
                    pcall(function() killPlayer(loopkillTarget, true) end)
                end
            end
            task.wait(0.5)
        end
    end)
end

cmds.unloopkill = function(a)
    if not loopkillActive then out("loopkill is not active.", Color3.fromRGB(255, 200, 100)) return end
    loopkillActive = false
    loopkillTarget = nil
    out("loopkill stopped.", Color3.fromRGB(255, 200, 100))
end

cmds.infammo = function(a)
    local q = nil
    if #a > 0 then
        local first = a[1]:lower()
        if first ~= "all" then q = first end
    end
    if infAmmo.active then
        if q then
            addQuery(q)
            out("infammo added: '" .. q .. "'", Color3.fromRGB(150, 255, 150))
        else
            addQuery("all")
            out("infammo now matching all guns", Color3.fromRGB(150, 255, 150))
        end
    else
        start(q)
        if q then
            out("infammo on for '" .. q .. "'", Color3.fromRGB(150, 255, 150))
        else
            out("infammo on for all guns", Color3.fromRGB(150, 255, 150))
        end
    end
end

cmds.uninfammo = function(a)
    if not infAmmo.active then
        out("infammo not active.", Color3.fromRGB(255, 200, 100))
        return
    end
    stopAll()
    out("infammo off", Color3.fromRGB(255, 200, 100))
end

cmds.uninf = cmds.uninfammo

local autoMask = {
    active = false,
    conn = nil,
    isBuying = false,
    spoofing = false,
    savedCF = CFrame.new(),
    targetCF = CFrame.new(),
    clickCD = nil,
    hrpRef = nil,
    preSim = nil,
    postSim = nil
}

local function hasMaskTool()
    local char = lp.Character
    if char and char:FindFirstChild("[Mask]") then return true end
    if lp.Backpack and lp.Backpack:FindFirstChild("[Mask]") then return true end
    return false
end

local function getMaskTarget()
    local ignored = workspace:FindFirstChild("Ignored")
    if not ignored then return nil end
    local shop = ignored:FindFirstChild("Shop")
    if not shop then return nil end
    for _, model in ipairs(shop:GetChildren()) do
        if model:IsA("Model") and (model.Name:lower():find("mask") or model.Name:lower():find("surgeon")) then
            local cd = model:FindFirstChildOfClass("ClickDetector") or model:FindFirstChild("ClickDetector", true)
            if cd then
                local head = model:FindFirstChild("Head") or model:FindFirstChild("Head", true)
                if head then return head, cd end
            end
        end
    end
    return nil
end

local function slot0(tool)
    if not tool then return end
    local backpack = lp:FindFirstChild("Backpack")
    local char = lp.Character
    if not backpack or not char then return end
    
    tool.Parent = nil
    task.wait(0.05)
    
    local currentTools = {}
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and v ~= tool then
            table.insert(currentTools, v)
        end
    end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v ~= tool then
            table.insert(currentTools, v)
        end
    end
    
    local numDummiesNeeded = 9 - #currentTools
    local dummies = {}
    
    if numDummiesNeeded > 0 then
        for i = 1, numDummiesNeeded do
            local dummy = Instance.new("Tool")
            dummy.Name = "DummySlot" .. i
            dummy.RequiresHandle = false
            table.insert(dummies, dummy)
            dummy.Parent = backpack
        end
    end
    
    task.wait(0.05)
    tool.Parent = backpack
    task.wait(0.05)
    
    for _, dummy in ipairs(dummies) do
        dummy:Destroy()
    end
end

local function executeMaskBuy()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local head, cd = getMaskTarget()
    if not head or not cd then return end

    local maxDist = cd.MaxActivationDistance
    if maxDist <= 0 then maxDist = 32 end

    if (hrp.Position - head.Position).Magnitude > maxDist then
        pcall(function() hrp:SetNetworkOwner(lp) end)
        autoMask.hrpRef = hrp
        autoMask.clickCD = cd
        autoMask.savedCF = hrp.CFrame
        autoMask.targetCF = head.CFrame + Vector3.new(0, 2.5, 0)
        autoMask.spoofing = true

        local deadline = os.clock() + 1.5
        while autoMask.active and not hasMaskTool() and os.clock() < deadline and lp.Character == char do
            game:GetService("RunService").Heartbeat:Wait()
        end

        autoMask.spoofing = false

        if hrp.Parent then
            hrp.CFrame = autoMask.savedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    else
        for _ = 1, 25 do
            pcall(fireclickdetector, cd, 0)
        end
        local deadline = os.clock() + 1.5
        while autoMask.active and not hasMaskTool() and os.clock() < deadline and lp.Character == char do
            game:GetService("RunService").Heartbeat:Wait()
        end
    end
    
    task.wait(0.1)
    
    local maskTool = char:FindFirstChild("[Mask]") or lp.Backpack:FindFirstChild("[Mask]")
    if maskTool then
        slot0(maskTool)
        hum:EquipTool(maskTool)
        task.wait(0.2)
        maskTool:Activate()
        task.wait(0.2)
        hum:UnequipTools()
        maskTool.Parent = lp.Backpack
    end
end

local function stopAutoMask()
    autoMask.active = false
    if autoMask.conn then pcall(function() task.cancel(autoMask.conn) end) autoMask.conn = nil end
    if autoMask.preSim then pcall(function() autoMask.preSim:Disconnect() end) autoMask.preSim = nil end
    if autoMask.postSim then pcall(function() autoMask.postSim:Disconnect() end) autoMask.postSim = nil end
    pcall(function() game:GetService("RunService"):UnbindFromRenderStep("HideSpoof") end)
    autoMask.spoofing = false
end

local function startAutoMask()
    if autoMask.active then return end
    autoMask.active = true
    autoMask.isBuying = false

    if not getgenv()._ACAntiKickSpoofed then
        pcall(function()
            local a
            for _, c in pairs(getgc(true)) do
                if typeof(c) ~= "table" then continue end
                local d = rawget(c, "indexInstance")
                if d and typeof(d) == "table" and (d[1] or "") == "kick" then
                    a = c
                    break
                end
            end
            if a then
                for _, g in pairs(a) do
                    if type(g[2]) == "function" then
                        hookfunction(g[2], function() return false end)
                    end
                end
            end
        end)
        getgenv()._ACAntiKickSpoofed = true
    end

    local rs = game:GetService("RunService")
    
    autoMask.preSim = rs.PreSimulation:Connect(function()
        if not autoMask.spoofing or not autoMask.hrpRef or not autoMask.hrpRef.Parent then return end
        autoMask.hrpRef.CFrame = autoMask.targetCF
        autoMask.hrpRef.AssemblyLinearVelocity = Vector3.zero
        autoMask.hrpRef.AssemblyAngularVelocity = Vector3.zero
    end)
    
    autoMask.postSim = rs.PostSimulation:Connect(function()
        if not autoMask.spoofing or not autoMask.hrpRef or not autoMask.hrpRef.Parent then return end
        if autoMask.clickCD then
            for _ = 1, 15 do
                pcall(fireclickdetector, autoMask.clickCD, 0)
            end
        end
        autoMask.hrpRef.AssemblyLinearVelocity = Vector3.zero
        autoMask.hrpRef.AssemblyAngularVelocity = Vector3.zero
    end)
    
    rs:BindToRenderStep("HideSpoof", Enum.RenderPriority.Camera.Value - 1, function()
        if not autoMask.spoofing or not autoMask.hrpRef or not autoMask.hrpRef.Parent then return end
        autoMask.hrpRef.CFrame = autoMask.savedCF
    end)

    autoMask.conn = task.spawn(function()
        while autoMask.active do
            task.wait(0.5)
            if not autoMask.isBuying and not hasMaskTool() then
                autoMask.isBuying = true
                pcall(executeMaskBuy)
                if autoMask.active then autoMask.isBuying = false end
            end
        end
    end)
end

cmds.automask = function(a)
    if autoMask.active then
        stopAutoMask()
        out("automask off", Color3.fromRGB(255, 200, 100))
    else
        startAutoMask()
        out("automask on", Color3.fromRGB(150, 255, 150))
    end
end

cmds.spiderverse = function(a)
    out("loading spiderverse...", Color3.fromRGB(150, 255, 150))
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/questivful/main/refs/heads/main/extras/SpiderVerse.luau"))()
    end)
end

local reflect = {
    active = false,
    conn = nil,
    charConns = {},
    busy = false,
    cooldowns = {},
    sirenFolder = nil
}

local deflectAim = {
    active = false,
    conn = nil,
    busy = false,
    cooldowns = {},
    aimStates = {}
}

local function reflectClearCharConns()
    for _, c in ipairs(reflect.charConns) do pcall(function() c:Disconnect() end) end
    reflect.charConns = {}
end

local function myParts(c)
    local t = {}
    if c then
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") then
                t[v] = true
            end
        end
    end
    return t
end

local function onTargetMouse(mousePos, parts)
    for part in pairs(parts) do
        if part.Parent and (part.Position - mousePos).Magnitude < 3 then
            return true
        end
    end
    local ray = workspace:Raycast(mousePos + Vector3.new(0, 50, 0), Vector3.new(0, -500, 0))
    if ray and parts[ray.Instance] then
        return true
    end
    return false
end

local function rayThreatensUs(child)
    local c = lp.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local origin = child.CFrame.Position
    local dir = child.CFrame.LookVector
    local hp = hrp.Position
    local toUs = hp - origin
    local along = toUs:Dot(dir)
    if along < -15 or along > 1000 then return false end
    local closest = origin + dir * math.clamp(along, 0, 1000)
    return (hp - closest).Magnitude < 25
end

local function reflectKill(shooter, busyTable)
    if not shooter or not shooter.Parent then return end
    if not shooter.Character then return end
    if shooter == lp then return end
    busyTable.busy = true
    task.spawn(function()
        local wasActive = infAmmo.active
        local ok, err = pcall(function()
            if not wasActive then
                start(nil)
            end
            killPlayer(shooter, false)
        end)
        if not ok then
            out("reflect error: " .. tostring(err), Color3.fromRGB(255, 100, 100))
        end
        if not wasActive then
            task.delay(1.5, function()
                pcall(stopAll)
            end)
        end
        busyTable.busy = false
    end)
end

local function reflectStart()
    if reflect.active then return end
    reflect.active = true
    reflectClearCharConns()

    local ignored = workspace:FindFirstChild("Ignored")
    if not ignored then
        out("deflect: ignored folder not found.", Color3.fromRGB(255, 100, 100))
        reflect.active = false
        return
    end
    local siren = ignored:FindFirstChild("Siren")
    if not siren then
        out("deflect: siren not found.", Color3.fromRGB(255, 100, 100))
        reflect.active = false
        return
    end
    local radius = siren:FindFirstChild("Radius")
    if not radius then
        out("deflect: radius not found.", Color3.fromRGB(255, 100, 100))
        reflect.active = false
        return
    end
    reflect.sirenFolder = radius

    reflect.conn = radius.ChildAdded:Connect(function(child)
        if not reflect.active then return end
        if child.Name ~= "BULLET_RAYS" then return end
        local ownerName = child:GetAttribute("OwnerCharacter")
        if not ownerName or ownerName == lp.Name then return end
        if not rayThreatensUs(child) then return end
        local shooter = nil
        for _, p in ipairs(ps:GetPlayers()) do
            if p.Name == ownerName then shooter = p break end
        end
        if not shooter or shooter == lp then return end
        if not shooter.Character then return end
        local now = tick()
        if reflect.cooldowns[shooter] and now - reflect.cooldowns[shooter] < 0.3 then return end
        reflect.cooldowns[shooter] = now
        if reflect.busy then return end
        out("deflected " .. shooter.Name .. " (bullet)", Color3.fromRGB(255, 150, 50))
        reflectKill(shooter, reflect)
    end)
end

local function reflectStop()
    reflect.active = false
    reflect.busy = false
    if reflect.conn then pcall(function() reflect.conn:Disconnect() end) reflect.conn = nil end
    reflect.sirenFolder = nil
    reflectClearCharConns()
    reflect.cooldowns = {}
end

local function reflectCmd(a)
    local sub = a[1] and a[1]:lower() or nil
    if sub == "on" then
        if reflect.active then out("deflect already on.", Color3.fromRGB(255, 200, 100)) return end
        reflectStart()
        if reflect.active then out("deflect on", Color3.fromRGB(150, 255, 150)) end
    elseif sub == "off" then
        if not reflect.active then out("deflect already off.", Color3.fromRGB(255, 200, 100)) return end
        reflectStop()
        out("deflect off", Color3.fromRGB(255, 200, 100))
    else
        if reflect.active then
            reflectStop()
            out("deflect off", Color3.fromRGB(255, 200, 100))
        else
            reflectStart()
            if reflect.active then out("deflect on", Color3.fromRGB(150, 255, 150)) end
        end
    end
end

cmds.reflect = reflectCmd
cmds.deflect = reflectCmd

local function deflectAimStart()
    if deflectAim.active then return end
    deflectAim.active = true
    deflectAim.aimStates = {}
    deflectAim.cooldowns = {}

    deflectAim.conn = game:GetService("RunService").RenderStepped:Connect(function()
        if not deflectAim.active then return end
        local myChar = lp.Character
        if not myChar then return end
        local parts = myParts(myChar)
        for _, p in ipairs(ps:GetPlayers()) do
            if p ~= lp and p.Character then
                local be = p.Character:FindFirstChild("BodyEffects")
                local mp = be and be:FindFirstChild("MousePos")
                if mp and typeof(mp.Value) == "Vector3" then
                    local aiming = onTargetMouse(mp.Value, parts)
                    if deflectAim.aimStates[p] == nil then deflectAim.aimStates[p] = false end
                    if aiming and not deflectAim.aimStates[p] then
                        deflectAim.aimStates[p] = true
                        if not deflectAim.busy then
                            local now = tick()
                            if not deflectAim.cooldowns[p] or now - deflectAim.cooldowns[p] >= 0.3 then
                                deflectAim.cooldowns[p] = now
                                out("deflected " .. p.Name .. " (aim)", Color3.fromRGB(255, 100, 200))
                                reflectKill(p, deflectAim)
                            end
                        end
                    elseif not aiming and deflectAim.aimStates[p] then
                        deflectAim.aimStates[p] = false
                    end
                end
            end
        end
    end)
end

local function deflectAimStop()
    deflectAim.active = false
    deflectAim.busy = false
    if deflectAim.conn then pcall(function() deflectAim.conn:Disconnect() end) deflectAim.conn = nil end
    deflectAim.cooldowns = {}
    deflectAim.aimStates = {}
end

local function deflectAimCmd(a)
    local sub = a[1] and a[1]:lower() or nil
    if sub == "on" then
        if deflectAim.active then out("deflectaim already on.", Color3.fromRGB(255, 200, 100)) return end
        deflectAimStart()
        out("deflectaim on", Color3.fromRGB(150, 255, 150))
    elseif sub == "off" then
        if not deflectAim.active then out("deflectaim already off.", Color3.fromRGB(255, 200, 100)) return end
        deflectAimStop()
        out("deflectaim off", Color3.fromRGB(255, 200, 100))
    else
        if deflectAim.active then
            deflectAimStop()
            out("deflectaim off", Color3.fromRGB(255, 200, 100))
        else
            deflectAimStart()
            out("deflectaim on", Color3.fromRGB(150, 255, 150))
        end
    end
end

cmds.deflectaim = deflectAimCmd

local userTouched = false

box.Focused:Connect(function() userTouched = true end)

box.FocusLost:Connect(function(enter)
    if enter then
        local txt = box.Text
        box.Text = ""
        if txt:gsub("%s+", "") ~= "" then
            out("> " .. txt, Color3.fromRGB(100, 200, 255))
            local a = string.split(txt, " ")
            local name = string.lower(table.remove(a, 1))
            if cmds[name] then
                pcall(function() cmds[name](a) end)
            else
                out("unknown: '" .. name .. "'. type 'help'.", Color3.fromRGB(255, 100, 100))
            end
        end
    end
end)

win:Show()

task.defer(function()
    task.wait(0.1)
    pcall(function()
        win.AnchorPoint = Vector2.new(0.5, 0.5)
        win.Position = UDim2.new(0.5, 0, 0.5, 0)
    end)
    pcall(function()
        if win.Main and win.Main.AnchorPoint ~= nil then
            win.Main.AnchorPoint = Vector2.new(0.5, 0.5)
            win.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
    end)
    pcall(function()
        if win.Frame and win.Frame.AnchorPoint ~= nil then
            win.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
            win.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
    end)
end)

out("@Questivful on discord / heavily inspired by vets panel.", Color3.fromRGB(200, 200, 200))
out("type 'help' for commands.", Color3.fromRGB(200, 200, 200))
