local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local AssetService = game:GetService("AssetService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CATEGORIES = {"idle", "walk", "run", "jump", "fall", "climb", "swim", "swimidle", "sit"}
local CONFIG_FILE = "anim_controller_config.json"
local PRESETS_FILE = "anim_controller_presets.json"

local DefaultAnimations = {
    idle = {
        { id = "http://www.roblox.com/asset/?id=507766666", weight = 1 },
        { id = "http://www.roblox.com/asset/?id=507766951", weight = 1 },
        { id = "http://www.roblox.com/asset/?id=507766388", weight = 9 }
    },
    walk = { { id = "http://www.roblox.com/asset/?id=507777826", weight = 10 } },
    run = { { id = "http://www.roblox.com/asset/?id=507767714", weight = 10 } },
    swim = { { id = "http://www.roblox.com/asset/?id=507784897", weight = 10 } },
    swimidle = { { id = "http://www.roblox.com/asset/?id=507785072", weight = 10 } },
    jump = { { id = "http://www.roblox.com/asset/?id=507765000", weight = 10 } },
    fall = { { id = "http://www.roblox.com/asset/?id=507767968", weight = 10 } },
    climb = { { id = "http://www.roblox.com/asset/?id=507765644", weight = 10 } },
    sit = { { id = "http://www.roblox.com/asset/?id=117218887724200", weight = 10 } },
    toolnone = { { id = "http://www.roblox.com/asset/?id=507768375", weight = 10 } },
    toolslash = { { id = "http://www.roblox.com/asset/?id=522635514", weight = 10 } },
    toollunge = { { id = "http://www.roblox.com/asset/?id=522638767", weight = 10 } }
}

local EmotesMap = {
    wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false
}

local CustomAnimate = {}
CustomAnimate.__index = CustomAnimate

function CustomAnimate.new(character)
    local self = setmetatable({}, CustomAnimate)
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self.Animator = self.Humanoid:WaitForChild("Animator")

    local oldAnimate = character:FindFirstChild("Animate")
    if oldAnimate then oldAnimate:Destroy() end

    for _, track in ipairs(self.Animator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end

    self.ScaleDampeningPercent = 1
    self.AnimSets = table.clone(DefaultAnimations)
    self.AnimTable = {}

    self.Pose = "Standing"
    self.CurrentAnim = ""
    self.CurrentAnimInstance = nil
    self.CurrentAnimTrack = nil
    self.CurrentAnimKeyframeHandler = nil

    self.RunAnimTrack = nil
    self.RunAnimKeyframeHandler = nil

    self.AnimSpeed = 1
    self.IsEmote = false

    self.CurrentToolAnim = "None"
    self.CurrentToolAnimKey = ""
    self.CurrentToolAnimInstance = nil
    self.CurrentToolAnimTrack = nil
    self.CurrentToolAnimKeyframeHandler = nil
    self.ToolAnimTime = 0

    self.JumpAnimTime = 0
    self.LastClock = os.clock()

    self.Connections = {}
    self.Active = true
    self.StepThread = nil

    self:ConfigureSets()
    self:ConnectEvents()

    self.StepThread = task.spawn(function()
        while self.Active and self.Character.Parent do
            task.wait(0.1)
            self:StepAnimate(os.clock())
        end
    end)

    self:PlayAnimation("idle", 0.1)

    return self
end

function CustomAnimate:Destroy()
    if not self.Active then return end
    self.Active = false
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end
    self.Connections = {}
    self:StopAllAnimations()
    self:StopToolAnimations()
    if self.StepThread then
        pcall(function() task.cancel(self.StepThread) end)
        self.StepThread = nil
    end
end

function CustomAnimate:ConfigureSets()
    self.AnimTable = {}
    for animName, animSet in pairs(self.AnimSets) do
        local entry = { count = 0, totalWeight = 0 }
        for _, animDef in ipairs(animSet) do
            local anim = Instance.new("Animation")
            anim.Name = animName
            anim.AnimationId = animDef.id
            entry.count = entry.count + 1
            entry.totalWeight = entry.totalWeight + animDef.weight
            entry[entry.count] = { anim = anim, weight = animDef.weight }
        end
        self.AnimTable[animName] = entry
    end
end

function CustomAnimate:ApplyOverrides(overrides)
    self.AnimSets = table.clone(DefaultAnimations)
    for cat, id in pairs(overrides or {}) do
        if self.AnimSets[cat] then
            self.AnimSets[cat] = { { id = "rbxassetid://" .. tostring(id), weight = 10 } }
        end
    end
    self:ConfigureSets()
    self:StopAllAnimations()
    self:StopToolAnimations()
    self.Pose = "Standing"
    self.IsEmote = false
    self.CurrentToolAnim = "None"
    self.CurrentToolAnimKey = ""
    self:PlayAnimation("idle", 0.1)
end

function CustomAnimate:StopAllAnimations()
    local oldAnim = self.CurrentAnim
    self.CurrentAnim = ""
    self.CurrentAnimInstance = nil

    if self.CurrentAnimKeyframeHandler then
        pcall(function() self.CurrentAnimKeyframeHandler:Disconnect() end)
        self.CurrentAnimKeyframeHandler = nil
    end
    if self.CurrentAnimTrack then
        pcall(function() self.CurrentAnimTrack:Stop() end)
        pcall(function() self.CurrentAnimTrack:Destroy() end)
        self.CurrentAnimTrack = nil
    end
    if self.RunAnimKeyframeHandler then
        pcall(function() self.RunAnimKeyframeHandler:Disconnect() end)
        self.RunAnimKeyframeHandler = nil
    end
    if self.RunAnimTrack then
        pcall(function() self.RunAnimTrack:Stop() end)
        pcall(function() self.RunAnimTrack:Destroy() end)
        self.RunAnimTrack = nil
    end
    return oldAnim
end

function CustomAnimate:StopToolAnimations()
    local oldAnim = self.CurrentToolAnimKey
    if self.CurrentToolAnimKeyframeHandler then
        pcall(function() self.CurrentToolAnimKeyframeHandler:Disconnect() end)
        self.CurrentToolAnimKeyframeHandler = nil
    end
    self.CurrentToolAnimKey = ""
    self.CurrentToolAnimInstance = nil
    if self.CurrentToolAnimTrack then
        pcall(function() self.CurrentToolAnimTrack:Stop() end)
        pcall(function() self.CurrentToolAnimTrack:Destroy() end)
        self.CurrentToolAnimTrack = nil
    end
    return oldAnim
end

function CustomAnimate:GetHeightScale()
    if not self.Humanoid.AutomaticScalingEnabled then return self.Character:GetScale() end
    return 1 + (self.Humanoid.HipHeight - 2) * self.ScaleDampeningPercent / 2
end

function CustomAnimate:SetRunSpeed(speed)
    local normalizedSpeed = speed * 1.25 / self:GetHeightScale()
    local walkWeight, runWeight, animSpeed = 0.0001, 0.0001, 1

    if normalizedSpeed <= 0.5 then
        animSpeed = normalizedSpeed / 0.5
        walkWeight = 1
    elseif normalizedSpeed < 1 then
        runWeight = (normalizedSpeed - 0.5) / 0.5
        walkWeight = 1 - runWeight
    else
        animSpeed = normalizedSpeed
        runWeight = 1
    end

    if self.CurrentAnimTrack then
        self.CurrentAnimTrack:AdjustWeight(walkWeight)
        self.CurrentAnimTrack:AdjustSpeed(animSpeed)
    end
    if self.RunAnimTrack then
        self.RunAnimTrack:AdjustWeight(runWeight)
        self.RunAnimTrack:AdjustSpeed(animSpeed)
    end
end

function CustomAnimate:SetAnimationSpeed(speed)
    if self.CurrentAnim == "walk" then
        self:SetRunSpeed(speed)
        return
    end
    if speed ~= self.AnimSpeed then
        self.AnimSpeed = speed
        if self.CurrentAnimTrack then
            self.CurrentAnimTrack:AdjustSpeed(self.AnimSpeed)
        end
    end
end

function CustomAnimate:RollAnimation(animName)
    local entry = self.AnimTable[animName]
    if not entry or entry.count == 0 then return nil end
    local roll = math.random(1, entry.totalWeight)
    local idx = 1
    while entry[idx] and entry[idx].weight < roll do
        roll = roll - entry[idx].weight
        idx = idx + 1
    end
    if idx > entry.count then idx = entry.count end
    return idx
end

function CustomAnimate:SwitchToAnim(animInstance, animName, transitionTime)
    if animInstance == self.CurrentAnimInstance then return end

    if self.CurrentAnimTrack then
        pcall(function() self.CurrentAnimTrack:Stop(transitionTime) end)
        pcall(function() self.CurrentAnimTrack:Destroy() end)
    end
    if self.RunAnimTrack then
        pcall(function() self.RunAnimTrack:Stop(transitionTime) end)
        pcall(function() self.RunAnimTrack:Destroy() end)
        self.RunAnimTrack = nil
    end

    self.AnimSpeed = 1
    local ok, track = pcall(function() return self.Animator:LoadAnimation(animInstance) end)
    if not ok or not track then return end
    self.CurrentAnimTrack = track
    self.CurrentAnimTrack.Priority = Enum.AnimationPriority.Core
    self.CurrentAnimTrack:Play(transitionTime)

    self.CurrentAnim = animName
    self.CurrentAnimInstance = animInstance

    if self.CurrentAnimKeyframeHandler then
        pcall(function() self.CurrentAnimKeyframeHandler:Disconnect() end)
    end
    self.CurrentAnimKeyframeHandler = self.CurrentAnimTrack.KeyframeReached:Connect(function(key)
        self:OnKeyframeReached(key)
    end)

    if animName == "walk" then
        local runIdx = self:RollAnimation("run")
        if runIdx then
            local runEntry = self.AnimTable.run and self.AnimTable.run[runIdx]
            if runEntry then
                local ok2, rtrack = pcall(function() return self.Animator:LoadAnimation(runEntry.anim) end)
                if ok2 and rtrack then
                    self.RunAnimTrack = rtrack
                    self.RunAnimTrack.Priority = Enum.AnimationPriority.Core
                    self.RunAnimTrack:Play(transitionTime)

                    if self.RunAnimKeyframeHandler then
                        pcall(function() self.RunAnimKeyframeHandler:Disconnect() end)
                    end
                    self.RunAnimKeyframeHandler = self.RunAnimTrack.KeyframeReached:Connect(function(key)
                        self:OnKeyframeReached(key)
                    end)
                end
            end
        end
    end
end

function CustomAnimate:PlayAnimation(animName, transitionTime)
    if not self.AnimTable[animName] then return end
    local idx = self:RollAnimation(animName)
    if not idx then return end
    local entry = self.AnimTable[animName][idx]
    if not entry then return end
    self:SwitchToAnim(entry.anim, animName, transitionTime)
    self.IsEmote = false
end

function CustomAnimate:OnKeyframeReached(keyName)
    if keyName ~= "End" then return end

    if self.CurrentAnim == "walk" then
        if self.RunAnimTrack and not self.RunAnimTrack.Looped then self.RunAnimTrack.TimePosition = 0 end
        if self.CurrentAnimTrack and not self.CurrentAnimTrack.Looped then self.CurrentAnimTrack.TimePosition = 0 end
    else
        local nextAnim = self.CurrentAnim
        if EmotesMap[nextAnim] ~= nil and EmotesMap[nextAnim] == false then
            nextAnim = "idle"
        end
        if self.IsEmote then
            if self.CurrentAnimTrack and self.CurrentAnimTrack.Looped then return end
            nextAnim = "idle"
            self.IsEmote = false
        end

        local currentSpeed = self.AnimSpeed
        self:PlayAnimation(nextAnim, 0.15)
        self:SetAnimationSpeed(currentSpeed)
    end
end

function CustomAnimate:PlayToolAnimation(animName, transitionTime, priority)
    if not self.AnimTable[animName] then return end
    local idx = self:RollAnimation(animName)
    if not idx then return end
    local entry = self.AnimTable[animName][idx]
    if not entry then return end
    local animInstance = entry.anim
    if self.CurrentToolAnimInstance == animInstance then return end

    if self.CurrentToolAnimTrack then
        pcall(function() self.CurrentToolAnimTrack:Stop() end)
        pcall(function() self.CurrentToolAnimTrack:Destroy() end)
        transitionTime = 0
    end

    local ok, track = pcall(function() return self.Animator:LoadAnimation(animInstance) end)
    if not ok or not track then return end
    self.CurrentToolAnimTrack = track
    if priority then self.CurrentToolAnimTrack.Priority = priority end

    self.CurrentToolAnimTrack:Play(transitionTime)
    self.CurrentToolAnimKey = animName
    self.CurrentToolAnimInstance = animInstance

    if self.CurrentToolAnimKeyframeHandler then
        pcall(function() self.CurrentToolAnimKeyframeHandler:Disconnect() end)
    end
    self.CurrentToolAnimKeyframeHandler = self.CurrentToolAnimTrack.KeyframeReached:Connect(function(key)
        if key == "End" then self:PlayToolAnimation(self.CurrentToolAnimKey, 0) end
    end)
end

function CustomAnimate:AnimateTool()
    if self.CurrentToolAnim == "None" then
        self:PlayToolAnimation("toolnone", 0.1, Enum.AnimationPriority.Idle)
    elseif self.CurrentToolAnim == "Slash" then
        self:PlayToolAnimation("toolslash", 0, Enum.AnimationPriority.Action)
    elseif self.CurrentToolAnim == "Lunge" then
        self:PlayToolAnimation("toollunge", 0, Enum.AnimationPriority.Action)
    end
end

function CustomAnimate:StepAnimate(currentTime)
    if not self.Active then return end
    local deltaTime = currentTime - self.LastClock
    self.LastClock = currentTime

    if self.JumpAnimTime > 0 then self.JumpAnimTime = self.JumpAnimTime - deltaTime end

    if self.Pose == "FreeFall" and self.JumpAnimTime <= 0 then
        self:PlayAnimation("fall", 0.2)
    elseif self.Pose == "Seated" then
        self:PlayAnimation("sit", 0.5)
    elseif self.Pose == "Running" then
        self:PlayAnimation("walk", 0.2)
    elseif self.Pose == "Standing" then
        if self.CurrentAnim == "" then
            self:PlayAnimation("idle", 0.2)
        end
    elseif self.Pose == "Dead" or self.Pose == "GettingUp" or self.Pose == "FallingDown" or self.Pose == "PlatformStanding" then
        self:StopAllAnimations()
    end

    local tool = self.Character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild("Handle") then
        if self.CurrentToolAnimKey ~= "" then
            self:StopToolAnimations()
        end
        self.CurrentToolAnim = "None"
        self.CurrentToolAnimInstance = nil
        self.ToolAnimTime = 0
        return
    end

    local toolAnimVal
    for _, child in ipairs(tool:GetChildren()) do
        if child.Name == "toolanim" and child:IsA("StringValue") then
            toolAnimVal = child
            break
        end
    end

    if toolAnimVal then
        self.CurrentToolAnim = toolAnimVal.Value
        toolAnimVal.Parent = nil
        self.ToolAnimTime = currentTime + 0.3
    end

    if self.ToolAnimTime < currentTime then
        self.ToolAnimTime = 0
        self.CurrentToolAnim = "None"
    end

    self:AnimateTool()
end

function CustomAnimate:ConnectEvents()
    local function add(c)
        table.insert(self.Connections, c)
    end

    add(self.Humanoid.Running:Connect(function(speed)
        local scale = self:GetHeightScale()
        local threshold = (self.IsEmote and self.Humanoid.MoveDirection == Vector3.new(0, 0, 0))
            and (self.Humanoid.WalkSpeed / scale) or 0.75
        if speed > threshold * scale then
            self:PlayAnimation("walk", 0.2)
            self:SetAnimationSpeed(speed / 16)
            self.Pose = "Running"
        else
            if not EmotesMap[self.CurrentAnim] and not self.IsEmote then
                self:PlayAnimation("idle", 0.2)
                self.Pose = "Standing"
            end
        end
    end))

    add(self.Humanoid.Jumping:Connect(function()
        self:PlayAnimation("jump", 0.1)
        self.JumpAnimTime = 0.31
        self.Pose = "Jumping"
    end))

    add(self.Humanoid.FreeFalling:Connect(function()
        if self.JumpAnimTime <= 0 then self:PlayAnimation("fall", 0.2) end
        self.Pose = "FreeFall"
    end))

    add(self.Humanoid.Climbing:Connect(function(speed)
        self:PlayAnimation("climb", 0.1)
        self:SetAnimationSpeed(speed / 5)
        self.Pose = "Climbing"
    end))

    add(self.Humanoid.Swimming:Connect(function(speed)
        if speed > 1 then
            self:PlayAnimation("swim", 0.4)
            self:SetAnimationSpeed(speed / 10)
            self.Pose = "Swimming"
        else
            self:PlayAnimation("swimidle", 0.4)
            self.Pose = "Standing"
        end
    end))

    add(self.Humanoid.Seated:Connect(function() self.Pose = "Seated" end))
    add(self.Humanoid.PlatformStanding:Connect(function() self.Pose = "PlatformStanding" end))
    add(self.Humanoid.GettingUp:Connect(function() self.Pose = "GettingUp" end))
    add(self.Humanoid.FallingDown:Connect(function() self.Pose = "FallingDown" end))
    add(self.Humanoid.Died:Connect(function() self.Pose = "Dead" end))
end

local function getOverrides()
    if not getgenv()._animOverrides then
        getgenv()._animOverrides = {}
    end
    return getgenv()._animOverrides
end

local function rebuildController(character)
    if getgenv()._customAnimationController then
        pcall(function() getgenv()._customAnimationController:Destroy() end)
        getgenv()._customAnimationController = nil
    end
    local controller = CustomAnimate.new(character)
    controller:ApplyOverrides(getOverrides())
    getgenv()._customAnimationController = controller
    return controller
end

LocalPlayer.CharacterAdded:Connect(rebuildController)
if LocalPlayer.Character then
    task.spawn(rebuildController, LocalPlayer.Character)
end

local DockManager = getgenv()._sspdockcontainer
if not DockManager then
    local ok, mod = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ruki3i/Creations/refs/heads/main/source/DockManager.luau"))()
    end)
    if not ok or not mod then return end
    DockManager = mod
end

if getgenv()._animWindow then
    pcall(function() getgenv()._animWindow:Close() end)
    getgenv()._animWindow = nil
end

local BaseGrey = Color3.fromRGB(25, 25, 25)
local Theme = {
    Background = BaseGrey,
    Hover = Color3.fromRGB(42, 42, 42),
    Active = Color3.fromRGB(55, 55, 55),
    Text = Color3.fromRGB(235, 235, 235),
    TextDim = Color3.fromRGB(150, 150, 150),
    Placeholder = Color3.fromRGB(120, 120, 120),
    Danger = Color3.fromRGB(200, 80, 80),
}

DockManager.SetTheme(BaseGrey)

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local window = DockManager.new("ANIMATION CONTROLLER", 440, 580)
getgenv()._animWindow = window

local root = new("Frame", {
    Name = "Root",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 2,
}, window.GuiElems.Content)

local presetTooltip = new("Frame", {
    Name = "PresetTooltip",
    Size = UDim2.new(0, 150, 0, 50),
    BackgroundColor3 = Theme.Active,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 50,
}, root)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, presetTooltip)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
}, presetTooltip)
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, presetTooltip)

local header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 3,
}, root)

local searchBox = new("TextBox", {
    Name = "SearchBox",
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 10, 0, 6),
    BackgroundColor3 = Theme.Hover,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Search animation bundles...",
    PlaceholderColor3 = Theme.Placeholder,
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ClearTextOnFocus = false,
    ZIndex = 4,
}, header)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, searchBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, searchBox)

local presetBar = new("Frame", {
    Name = "PresetBar",
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 46),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 3,
}, root)

local presetScroll = new("ScrollingFrame", {
    Size = UDim2.new(1, -65, 1, 0),
    Position = UDim2.new(0, 5, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 0,
    ZIndex = 4,
}, presetBar)

new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, presetScroll)

new("UIPadding", {
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 2),
}, presetScroll)

local savePresetBtn = new("TextButton", {
    Name = "SavePreset",
    Size = UDim2.new(0, 50, 1, -8),
    Position = UDim2.new(1, -55, 0, 4),
    BackgroundColor3 = Theme.Active,
    BorderSizePixel = 0,
    Text = "+ Save",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    AutoButtonColor = false,
    ZIndex = 4,
}, presetBar)

new("UICorner", { CornerRadius = UDim.new(0, 4) }, savePresetBtn)

savePresetBtn.MouseEnter:Connect(function()
    TweenService:Create(savePresetBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
end)
savePresetBtn.MouseLeave:Connect(function()
    TweenService:Create(savePresetBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Active }):Play()
end)

local catBar = new("Frame", {
    Name = "CategoryBar",
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 0, 82),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 3,
}, root)

local catScroll = new("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 5, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 0,
    ZIndex = 4,
}, catBar)

new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, catScroll)

new("UIPadding", {
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 2),
}, catScroll)

local selectedCategory = "walk"
local categoryButtons = {}

local function updateCategoryStyles()
    for cat, btn in pairs(categoryButtons) do
        local hasOverride = getOverrides()[cat] ~= nil
        if cat == selectedCategory then
            btn.BackgroundColor3 = Theme.Active
            btn.TextColor3 = Theme.Text
        else
            btn.BackgroundColor3 = Theme.Background
            btn.TextColor3 = hasOverride and Theme.Text or Theme.TextDim
        end
    end
end

for i, cat in ipairs(CATEGORIES) do
    local btn = new("TextButton", {
        Size = UDim2.new(0, 62, 1, -4),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = cat,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = i,
        ZIndex = 5,
    }, catScroll)

    new("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

    btn.MouseEnter:Connect(function()
        if cat ~= selectedCategory then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if cat ~= selectedCategory then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Background }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        selectedCategory = cat
        updateCategoryStyles()
    end)

    categoryButtons[cat] = btn
end

local resultsPanel = new("Frame", {
    Name = "Results",
    Size = UDim2.new(1, 0, 1, -140),
    Position = UDim2.new(0, 0, 0, 116),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
}, root)

local resultsScroll = new("ScrollingFrame", {
    Name = "Scroll",
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.TextDim,
    ZIndex = 4,
}, resultsPanel)

new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, resultsScroll)

local footer = new("Frame", {
    Name = "Footer",
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 1, -24),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 3,
}, root)

local function makeFooterButton(text, xOffset, width)
    local btn = new("TextButton", {
        Name = text .. "Btn",
        Size = UDim2.new(0, width, 1, -4),
        Position = UDim2.new(1, xOffset, 0, 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 4,
    }, footer)

    new("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
        btn.TextColor3 = Theme.Text
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Background }):Play()
        btn.TextColor3 = Theme.TextDim
    end)

    return btn
end

local resetBtn = makeFooterButton("Reset All", -75, 70)
local saveBtn = makeFooterButton("Save", -150, 70)
local loadBtn = makeFooterButton("Load", -225, 70)

local function safeWrite(name, data)
    if not writefile then return false end
    return pcall(function() writefile(name, data) end)
end

local function safeRead(name)
    if not readfile then return nil end
    if isfile then
        local existsOk, exists = pcall(function() return isfile(name) end)
        if not existsOk or not exists then return nil end
    end
    local ok2, data = pcall(function() return readfile(name) end)
    if ok2 then return data end
    return nil
end

local function loadPresetsFile()
    local raw = safeRead(PRESETS_FILE)
    if not raw or raw == "" then return {} end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(decoded) ~= "table" then return {} end
    return decoded
end

local function savePresetsFile(tbl)
    local ok2, encoded = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok2 then return false end
    return safeWrite(PRESETS_FILE, encoded)
end

local presets = loadPresetsFile()
local presetButtons = {}

local modal = new("Frame", {
    Name = "SaveModal",
    Size = UDim2.new(0, 260, 0, 115),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Active,
    BorderSizePixel = 0,
    ZIndex = 20,
    Visible = false,
}, window.GuiElems.Content)

new("UICorner", { CornerRadius = UDim.new(0, 6) }, modal)

local modalLabel = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "Preset name:",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
}, modal)

local modalBox = new("TextBox", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 10, 0, 32),
    BackgroundColor3 = Theme.Hover,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "e.g. Ninja",
    PlaceholderColor3 = Theme.Placeholder,
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ClearTextOnFocus = false,
    ZIndex = 21,
}, modal)

new("UICorner", { CornerRadius = UDim.new(0, 6) }, modalBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, modalBox)

local modalConfirm = new("TextButton", {
    Size = UDim2.new(0, 70, 0, 24),
    Position = UDim2.new(1, -80, 1, -34),
    BackgroundColor3 = Theme.Hover,
    BorderSizePixel = 0,
    Text = "Save",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 21,
}, modal)

new("UICorner", { CornerRadius = UDim.new(0, 4) }, modalConfirm)

local modalCancel = new("TextButton", {
    Size = UDim2.new(0, 70, 0, 24),
    Position = UDim2.new(1, -160, 1, -34),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    Text = "Cancel",
    TextColor3 = Theme.TextDim,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 21,
}, modal)

new("UICorner", { CornerRadius = UDim.new(0, 4) }, modalCancel)

local function refreshPresetButtons()
    for _, btn in pairs(presetButtons) do
        btn:Destroy()
    end
    presetButtons = {}

    local keys = {}
    for name, _ in pairs(presets) do
        table.insert(keys, name)
    end
    table.sort(keys)

    for i, name in ipairs(keys) do
        local btn = new("TextButton", {
            Size = UDim2.new(0, 110, 1, -4),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = Theme.TextDim,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 5,
        }, presetScroll)

        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 26) }, btn)
        new("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

        local del = new("TextButton", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -20, 0.5, -9),
            BackgroundTransparency = 1,
            Text = "X",
            TextColor3 = Theme.TextDim,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 6,
        }, btn)

        del.MouseEnter:Connect(function()
            del.TextColor3 = Theme.Danger
        end)
        del.MouseLeave:Connect(function()
            del.TextColor3 = Theme.TextDim
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
            btn.TextColor3 = Theme.Text

            for _, c in ipairs(presetTooltip:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end

            local data = presets[name]
            if type(data) == "table" then
                local count = 0
                for cat, id in pairs(data) do
                    count = count + 1
                    new("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        BackgroundTransparency = 1,
                        Text = cat .. ": " .. tostring(id),
                        TextColor3 = Theme.TextDim,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 51,
                    }, presetTooltip)
                end
                if count == 0 then
                    new("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        BackgroundTransparency = 1,
                        Text = "Empty Preset",
                        TextColor3 = Theme.TextDim,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 51,
                    }, presetTooltip)
                    count = 1
                end

                presetTooltip.Size = UDim2.new(0, 150, 0, count * 18 + 16)
                local absX = btn.AbsolutePosition.X - root.AbsolutePosition.X
                local absY = btn.AbsolutePosition.Y - root.AbsolutePosition.Y + btn.AbsoluteSize.Y + 5

                if absX + 150 > root.AbsoluteSize.X then
                    absX = root.AbsoluteSize.X - 150 - 5
                end

                if absY + presetTooltip.AbsoluteSize.Y > root.AbsoluteSize.Y then
                    absY = root.AbsoluteSize.Y - presetTooltip.AbsoluteSize.Y - 5
                end

                presetTooltip.Position = UDim2.new(0, absX, 0, absY)
                presetTooltip.Visible = true
            end
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Background }):Play()
            btn.TextColor3 = Theme.TextDim
            presetTooltip.Visible = false
        end)

        btn.MouseButton1Click:Connect(function()
            local data = presets[name]
            if type(data) ~= "table" then return end
            getgenv()._animOverrides = table.clone(data)
            if getgenv()._customAnimationController then
                getgenv()._customAnimationController:ApplyOverrides(data)
            end
            updateCategoryStyles()
        end)

        del.MouseButton1Click:Connect(function()
            presetTooltip.Visible = false
            presets[name] = nil
            savePresetsFile(presets)
            refreshPresetButtons()
        end)

        presetButtons[name] = btn
    end
end

savePresetBtn.MouseButton1Click:Connect(function()
    modalBox.Text = ""
    modal.Visible = true
    modalBox:CaptureFocus()
end)

modalCancel.MouseButton1Click:Connect(function()
    modal.Visible = false
end)

modalConfirm.MouseButton1Click:Connect(function()
    local name = modalBox.Text
    if not name or name == "" then return end
    presets[name] = table.clone(getOverrides())
    savePresetsFile(presets)
    refreshPresetButtons()
    modal.Visible = false
    savePresetBtn.Text = "Saved"
    task.delay(1, function()
        if savePresetBtn and savePresetBtn.Parent then
            savePresetBtn.Text = "+ Save"
        end
    end)
end)

modalBox.FocusLost:Connect(function(enter)
    if enter then
        local name = modalBox.Text
        if not name or name == "" then
            modal.Visible = false
            return
        end
        presets[name] = table.clone(getOverrides())
        savePresetsFile(presets)
        refreshPresetButtons()
        modal.Visible = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if modal.Visible and input.KeyCode == Enum.KeyCode.Escape then
        modal.Visible = false
    end
end)

refreshPresetButtons()

resetBtn.MouseButton1Click:Connect(function()
    getgenv()._animOverrides = {}
    if getgenv()._customAnimationController then
        getgenv()._customAnimationController:ApplyOverrides({})
    end
    updateCategoryStyles()
end)

saveBtn.MouseButton1Click:Connect(function()
    local data = getOverrides()
    local ok2, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok2 then return end
    local saved = safeWrite(CONFIG_FILE, encoded)
    saveBtn.Text = saved and "Saved!" or "No FS"
    task.delay(1, function()
        if saveBtn and saveBtn.Parent then saveBtn.Text = "Save" end
    end)
end)

loadBtn.MouseButton1Click:Connect(function()
    local raw = safeRead(CONFIG_FILE)
    if not raw or raw == "" then
        loadBtn.Text = "No File"
        task.delay(1, function()
            if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
        end)
        return
    end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(decoded) ~= "table" then
        loadBtn.Text = "Bad File"
        task.delay(1, function()
            if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
        end)
        return
    end
    getgenv()._animOverrides = decoded
    if getgenv()._customAnimationController then
        getgenv()._customAnimationController:ApplyOverrides(decoded)
    end
    updateCategoryStyles()
    loadBtn.Text = "Loaded!"
    task.delay(1, function()
        if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
    end)
end)

local previewTemplate = nil
local templateReady = false

local function buildTemplate()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    char.Archivable = true
    local ok2, clone = pcall(function() return char:Clone() end)
    char.Archivable = false
    if not ok2 or not clone then return false end

    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            v:Destroy()
        end
    end
    for _, v in ipairs(clone:GetChildren()) do
        if v:IsA("Tool") then v:Destroy() end
    end
    local animate = clone:FindFirstChild("Animate")
    if animate then animate:Destroy() end

    local cloneHum = clone:FindFirstChildOfClass("Humanoid")
    if not cloneHum then
        clone:Destroy()
        return false
    end

    for _, v in ipairs(cloneHum:GetChildren()) do
        if v:IsA("Animator") then v:Destroy() end
    end
    local animator = Instance.new("Animator")
    animator.Parent = cloneHum

    cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    cloneHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    cloneHum.NameDisplayDistance = 0
    cloneHum.HealthDisplayDistance = 0
    cloneHum.AutoRotate = false
    cloneHum.WalkSpeed = 0
    cloneHum.JumpPower = 0
    cloneHum.JumpHeight = 0

    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.CanQuery = false
            v.CanTouch = false
        end
    end

    local cloneHrp = clone:FindFirstChild("HumanoidRootPart")
    if cloneHrp then
        cloneHrp.Anchored = true
    end

    clone.Name = "PreviewTemplate"
    clone.Parent = nil
    previewTemplate = clone
    templateReady = true
    return true
end

task.spawn(function()
    local ok2 = pcall(buildTemplate)
    if not ok2 or not templateReady then
        task.wait(2)
        pcall(buildTemplate)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    templateReady = false
    previewTemplate = nil
    pcall(buildTemplate)
end)

local function createPreviewRig()
    if not templateReady or not previewTemplate then return nil end
    local ok2, rig = pcall(function() return previewTemplate:Clone() end)
    if not ok2 or not rig then return nil end
    rig.Name = "PreviewRig"
    return rig
end

local function playAnimOnRig(rig, animId)
    if not rig or not animId then return nil end
    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
        pcall(function() track:Destroy() end)
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animId)
    local ok2, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok2 or not track then return nil end
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Core
    pcall(function() track:Play(0) end)
    return track
end

local animIdCache = {}
local function resolveAnimationId(catalogAssetId)
    if animIdCache[catalogAssetId] ~= nil then return animIdCache[catalogAssetId] end
    local success, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(catalogAssetId)) end)
    if success and objs then
        for _, obj in ipairs(objs) do
            if typeof(obj) == "Instance" then
                if obj:IsA("Animation") and obj.AnimationId ~= "" then
                    local id = obj.AnimationId:match("%d+")
                    if id then
                        animIdCache[catalogAssetId] = id
                        obj:Destroy()
                        return id
                    end
                end
                for _, desc in ipairs(obj:GetDescendants()) do
                    if desc:IsA("Animation") and desc.AnimationId ~= "" then
                        local id = desc.AnimationId:match("%d+")
                        if id then
                            animIdCache[catalogAssetId] = id
                            obj:Destroy()
                            return id
                        end
                    end
                end
                obj:Destroy()
            end
        end
    end
    animIdCache[catalogAssetId] = catalogAssetId
    return catalogAssetId
end

local bundleDetailCache = {}
local function getBundleDetails(bundleId)
    if bundleDetailCache[bundleId] then return bundleDetailCache[bundleId] end
    local ok2, details = pcall(function() return AssetService:GetBundleDetailsAsync(bundleId) end)
    if not ok2 or not details then return nil end
    bundleDetailCache[bundleId] = details
    return details
end

local bundleAnimCache = {}
local function resolveAnyAnim(bundleId)
    if bundleAnimCache[bundleId] ~= nil then return bundleAnimCache[bundleId] end
    local details = getBundleDetails(bundleId)
    if not details or not details.Items then
        bundleAnimCache[bundleId] = false
        return nil
    end
    for _, item in ipairs(details.Items) do
        local lower = string.lower(item.Name or "")
        if lower:find("idle") or lower:find("walk") or lower:find("run") or lower:find("dance") then
            local id = resolveAnimationId(item.Id)
            if id then
                bundleAnimCache[bundleId] = id
                return id
            end
        end
    end
    for _, item in ipairs(details.Items) do
        local id = resolveAnimationId(item.Id)
        if id then
            bundleAnimCache[bundleId] = id
            return id
        end
    end
    bundleAnimCache[bundleId] = false
    return nil
end

local function createEntry(bundle, order)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 4,
    })

    new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)

    local viewport = new("ViewportFrame", {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = Theme.Hover,
        BorderSizePixel = 0,
        ZIndex = 5,
        Ambient = Color3.fromRGB(200, 200, 200),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(-1, -1, -1),
    }, row)

    new("UICorner", { CornerRadius = UDim.new(0, 4) }, viewport)

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    local cam = Instance.new("Camera")
    cam.FieldOfView = 40
    cam.CFrame = CFrame.lookAt(Vector3.new(0, 3, 8), Vector3.new(0, 2.8, 0))
    viewport.CurrentCamera = cam
    cam.Parent = viewport

    local rig = createPreviewRig()
    local previewTrack = nil
    if rig then
        rig:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
        rig.Parent = worldModel
    end

    new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 18),
        Position = UDim2.new(0, 68, 0, 10),
        BackgroundTransparency = 1,
        Text = bundle.Name or "Unknown",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    }, row)

    new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 14),
        Position = UDim2.new(0, 68, 0, 30),
        BackgroundTransparency = 1,
        Text = "Animation Package",
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    }, row)

    local previewLoading = false
    local previewThread = nil

    local function loadPreview()
        if previewTrack or previewLoading or not rig or not rig.Parent then return end
        previewLoading = true
        previewThread = task.spawn(function()
            local animId = resolveAnyAnim(bundle.Id)
            if not rig or not rig.Parent then
                previewLoading = false
                return
            end
            if animId then
                previewTrack = playAnimOnRig(rig, animId)
            end
            previewLoading = false
        end)
    end

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
        loadPreview()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Background }):Play()
    end)

    row.MouseButton1Click:Connect(function()
        local details = getBundleDetails(bundle.Id)
        if not details or not details.Items then return end

        local wanted = selectedCategory
        local matchId = nil
        for _, item in ipairs(details.Items) do
            local lower = string.lower(item.Name or "")
            if lower:find(wanted, 1, true) then
                matchId = resolveAnimationId(item.Id)
                if matchId then break end
            end
        end
        if not matchId then
            for _, item in ipairs(details.Items) do
                matchId = resolveAnimationId(item.Id)
                if matchId then break end
            end
        end
        if not matchId then return end

        local ov = getOverrides()
        ov[wanted] = matchId
        if getgenv()._customAnimationController then
            getgenv()._customAnimationController:ApplyOverrides(ov)
        end
        updateCategoryStyles()
    end)

    row.Destroying:Connect(function()
        if previewThread then
            pcall(function() task.cancel(previewThread) end)
            previewThread = nil
        end
        if rig then
            local humanoid = rig:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        pcall(function() track:Stop(0) end)
                        pcall(function() track:Destroy() end)
                    end
                end
            end
            rig:Destroy()
        end
        previewTrack = nil
    end)

    return row
end

local function clearResults()
    for _, child in ipairs(resultsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local searchToken = 0
local RESULT_LIMIT = 10

local function performSearch(query)
    searchToken = searchToken + 1
    local myToken = searchToken

    if query == "" then
        clearResults()
        return
    end

    clearResults()

    task.spawn(function()
        local params = CatalogSearchParams.new()
        params.SearchKeyword = query
        params.BundleTypes = { Enum.BundleType.Animations }
        params.IncludeOffSale = true
        params.Limit = RESULT_LIMIT

        local success, pages = pcall(function() return AvatarEditorService:SearchCatalogAsync(params) end)
        if myToken ~= searchToken then return end
        if not success or not pages then return end

        local results = {}
        for _, item in ipairs(pages:GetCurrentPage()) do
            if item.ItemType == "Bundle" and item.BundleType == "Animations" then
                table.insert(results, item)
                if #results >= RESULT_LIMIT then break end
            end
        end

        if myToken ~= searchToken then return end
        clearResults()

        for i, bundle in ipairs(results) do
            if myToken ~= searchToken then break end
            local entry = createEntry(bundle, i)
            entry.Parent = resultsScroll
        end
    end)
end

local debounceToken = 0
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    debounceToken = debounceToken + 1
    local myToken = debounceToken
    local query = searchBox.Text
    task.delay(0.35, function()
        if myToken == debounceToken then performSearch(query) end
    end)
end)

updateCategoryStyles()
window:Show({ Align = "left", Pos = 1 })
