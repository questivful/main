if type(_G.svcleanup) == "function" then pcall(_G.svcleanup); _G.svcleanup = nil end

local plrs = game:GetService("Players")
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local cp = game:GetService("ContentProvider")
local reps = game:GetService("ReplicatedStorage")
local lg = game:GetService("Lighting")
local ws = game:GetService("Workspace")

local chgchar = reps:WaitForChild("ChangeCharEvent")
local plr = plrs.LocalPlayer
local plrgui = plr:WaitForChild("PlayerGui")
local pm = require(plr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ctrls = pm:GetControls()

local tnm = "[sv]"
local ttx = "rbxassetid://8300945448"

local chars = {
	{usr = "spiderman155932", nm = "Peter"},
	{usr = "spiderman9w9283", nm = "Miles"},
	{usr = "SpiderMan_TRN1450", nm = "Ynvh Peter"},
	{usr = "Spiderman_14518", nm = "Spawn"},
	{usr = "Spiderman_Jenson5", nm = "Venom"},
	{usr = "spidermanwebhead3004", nm = "Rabi Peter Parker"},
	{usr = "SpiderManPlayz06", nm = "Muscled Peter Parker"},
	{usr = "MiguelOHara_928B", nm = "2099"},
	{usr = "Sprunki45554", nm = "Mech Spider"},
	{usr = "ModuloYujiItadori0", nm = "Venom Low Spinoff"},
	{usr = "SpiderManTheHero863", nm = "Symbiote Spider-Man"},
}

for _, n in ipairs({"amg", "amv", "svc"}) do
	local left = plrgui:FindFirstChild(n)
	if left then left:Destroy() end
end

local cgui = Instance.new("ScreenGui")
cgui.Name = "svc"
cgui.ResetOnSpawn = false
cgui.Enabled = false
cgui.Parent = plrgui

local cfr = Instance.new("Frame")
cfr.AnchorPoint = Vector2.new(1, 0.5)
cfr.Position = UDim2.new(1, -20, 0.5, 0)
cfr.Size = UDim2.new(0, 200, 0, 150)
cfr.BackgroundTransparency = 1
cfr.Parent = cgui

local clyt = Instance.new("UIListLayout")
clyt.SortOrder = Enum.SortOrder.LayoutOrder
clyt.Padding = UDim.new(0, 10)
clyt.HorizontalAlignment = Enum.HorizontalAlignment.Right
clyt.VerticalAlignment = Enum.VerticalAlignment.Center
clyt.Parent = cfr

local function mklbl(txt, ord)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 30)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = 20
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Right
	l.Text = txt
	l.LayoutOrder = ord
	local str = Instance.new("UIStroke")
	str.Thickness = 2
	str.Parent = l
	l.Parent = cfr
end

mklbl("[Left Click] Toggle Suit", 1)
mklbl("[M] Suit Menu", 2)
mklbl("[P] Pose", 3)

local blr = Instance.new("BlurEffect")
blr.Size = 0
blr.Parent = lg

local vgui = Instance.new("ScreenGui")
vgui.Name = "amv"
vgui.ResetOnSpawn = false
vgui.IgnoreGuiInset = true
vgui.DisplayOrder = 2147483647
vgui.Enabled = false
pcall(function() vgui.Parent = game:GetService("CoreGui") end)
if not vgui.Parent then vgui.Parent = plrgui end

local vimg = Instance.new("ImageLabel")
vimg.Size = UDim2.new(1, 0, 1, 0)
vimg.BackgroundTransparency = 1
vimg.Image = "rbxassetid://104604979157150"
vimg.ImageTransparency = 1
vimg.ScaleType = Enum.ScaleType.Crop
vimg.ZIndex = 1
vimg.Parent = vgui

local ttxt = Instance.new("TextLabel")
ttxt.Size = UDim2.new(1, 0, 0, 60)
ttxt.Position = UDim2.new(0.5, 0, 0.08, 0)
ttxt.AnchorPoint = Vector2.new(0.5, 0)
ttxt.BackgroundTransparency = 1
ttxt.Font = Enum.Font.GothamBlack
ttxt.TextSize = 48
ttxt.TextColor3 = Color3.fromRGB(255, 255, 255)
ttxt.Text = "SELECT YOUR SPIDEY!"
ttxt.ZIndex = 2
ttxt.Parent = vgui
local tstr = Instance.new("UIStroke")
tstr.Thickness = 3
tstr.Parent = ttxt

local stxt = Instance.new("TextLabel")
stxt.Size = UDim2.new(1, 0, 0, 30)
stxt.Position = UDim2.new(0.5, 0, 0.145, 0)
stxt.AnchorPoint = Vector2.new(0.5, 0)
stxt.BackgroundTransparency = 1
stxt.Font = Enum.Font.SourceSansItalic
stxt.TextSize = 22
stxt.TextColor3 = Color3.fromRGB(100, 200, 255)
stxt.Text = "Developed by Silent & Quest"
stxt.ZIndex = 2
stxt.Parent = vgui
local sstr = Instance.new("UIStroke")
sstr.Thickness = 2
sstr.Parent = stxt

local sgui = Instance.new("ScreenGui")
sgui.Name = "amg"
sgui.ResetOnSpawn = false
sgui.IgnoreGuiInset = true
sgui.DisplayOrder = 100
sgui.Enabled = false
sgui.Parent = plrgui

local rtint = Instance.new("Frame")
rtint.Size = UDim2.new(1, 0, 1, 0)
rtint.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
rtint.BackgroundTransparency = 1
rtint.BorderSizePixel = 0
rtint.ZIndex = 0
rtint.Parent = sgui

local fsnd = Instance.new("Sound")
fsnd.SoundId = "rbxassetid://1841929218"
fsnd.Looped = true
fsnd.Volume = 0
fsnd.Parent = sgui

local cbtn = Instance.new("TextButton")
cbtn.Size = UDim2.new(1, 0, 1, 0)
cbtn.BackgroundTransparency = 1
cbtn.Text = ""
cbtn.ZIndex = 1
cbtn.Parent = sgui

local mfr = Instance.new("Frame")
mfr.Size = UDim2.new(0.9, 0, 0.85, 0)
mfr.Position = UDim2.new(0.05, 0, 0.075, 0)
mfr.BackgroundTransparency = 1
mfr.ZIndex = 2
mfr.Parent = sgui

local sfr = Instance.new("ScrollingFrame")
sfr.Size = UDim2.new(1, 0, 1, 0)
sfr.BackgroundTransparency = 1
sfr.ScrollBarImageTransparency = 1
sfr.ScrollBarThickness = 0
sfr.ScrollingDirection = Enum.ScrollingDirection.X
sfr.AutomaticCanvasSize = Enum.AutomaticSize.X
sfr.CanvasSize = UDim2.new(0, 0, 0, 0)
sfr.ZIndex = 2
sfr.Parent = mfr

local spad = Instance.new("UIPadding")
spad.PaddingLeft = UDim.new(0, 60)
spad.PaddingRight = UDim.new(0, 60)
spad.Parent = sfr

local llyt = Instance.new("UIListLayout")
llyt.FillDirection = Enum.FillDirection.Horizontal
llyt.SortOrder = Enum.SortOrder.LayoutOrder
llyt.Padding = UDim.new(0, 40)
llyt.VerticalAlignment = Enum.VerticalAlignment.Center
llyt.Parent = sfr

local mopen = false
local atok = 0
local alv = true
local cds = {}
local recs = {}
local hguis = {}
local ghdn = false

local teq = false
local son = false
local csuit = chars[1].usr
local ptrk = nil
local panim = Instance.new("Animation")
panim.AnimationId = "rbxassetid://87722152938224"

local chr, hrp, hum, animtr, ratt, aori, lvel
local lanims = {}
local cstate = nil
local uprt = true

local cup = Vector3.yAxis
local tup = Vector3.yAxis
local grnd = false
local ljmp = 0
local vvel = 0
local jcd = 0.25
local gsf = 40
local mgs = 60
local acf = 1
local wsd = 2.5
local gcd = 3.5
local ucf = ws.CurrentCamera and ws.CurrentCamera.CFrame or CFrame.new()

local rpar = RaycastParams.new()
rpar.FilterType = Enum.RaycastFilterType.Exclude
rpar.IgnoreWater = true
rpar.RespectCanCollide = true

local conns = {}

local function getCAC()
	local cac = getgenv()._customAnimationController
	if cac and cac.Active then return cac end
	return nil
end

local function updrf()
	local ex = {}
	for _, p in ipairs(plrs:GetPlayers()) do
		local c = p.Character
		if c then
			table.insert(ex, c)
		end
	end
	rpar.FilterDescendantsInstances = ex
end

local function spanim()
	local cac = getCAC()
	if cac then
		cac:StopAllAnimations()
		cstate = nil
		return
	end
	for _, t in pairs(lanims) do
		if t.IsPlaying then t:Stop(0.2) end
	end
	cstate = nil
end

local function ldanim(st)
	if not lanims[st] and chr and animtr then
		local asc = chr:FindFirstChild("Animate")
		if asc then
			local f = asc:FindFirstChild(st)
			if f then
				local a = f:FindFirstChildWhichIsA("Animation")
				if a then
					local t = animtr:LoadAnimation(a)
					t.Priority = Enum.AnimationPriority.Core
					lanims[st] = t
				end
			end
		end
	end
	return lanims[st]
end

local function planim(st, spd)
	local cac = getCAC()
	if cac then
		if st == "walk" then
			cac.Pose = "Running"
		elseif st == "idle" then
			cac.Pose = "Standing"
		elseif st == "jump" then
			cac.Pose = "Jumping"
		elseif st == "fall" then
			cac.Pose = "FreeFall"
		end

		if cstate == st then
			if spd and st ~= "walk" then
				cac:SetAnimationSpeed(spd)
			end
			return
		end
		cstate = st
		cac:PlayAnimation(st, 0.2)
		if spd and st ~= "walk" then
			cac:SetAnimationSpeed(spd)
		end
		return
	end

	spd = spd or 1
	if cstate == st then
		if st ~= "walk" and lanims[st] then lanims[st]:AdjustSpeed(spd) end
		return
	end
	spanim()
	cstate = st
	if st == "walk" then
		local w = ldanim("walk")
		local r = ldanim("run")
		if w then w:Play(0.2) end
		if r then r:Play(0.2) end
	else
		local t = ldanim(st)
		if t then
			t:Play(0.2)
			t:AdjustSpeed(spd)
		end
	end
end

local function updwrb(spd)
	local cac = getCAC()
	if cac then
		if cstate == "walk" then
			cac:SetRunSpeed(spd)
		end
		return
	end

	local w = lanims["walk"]
	local r = lanims["run"]
	if not w and not r then return end
	local wwt = 0.0001
	local rwt = 0.0001
	local aspd = spd / 16
	if spd <= 8 then
		wwt = 1
	elseif spd < 16 then
		rwt = (spd - 8) / 8
		wwt = 1 - rwt
	else
		rwt = 1
	end
	if w and r then
		w:AdjustWeight(wwt)
		r:AdjustWeight(rwt)
		w:AdjustSpeed(aspd)
		r:AdjustSpeed(aspd)
	elseif w then
		w:AdjustWeight(1)
		w:AdjustSpeed(aspd)
	elseif r then
		r:AdjustWeight(1)
		r:AdjustSpeed(aspd)
	end
end

local function grot(uv)
	local d = math.clamp(Vector3.yAxis:Dot(uv), -1, 1)
	if d > 0.9999 then return CFrame.identity end
	if d < -0.9999 then return CFrame.fromAxisAngle(Vector3.xAxis, math.pi) end
	local a = Vector3.yAxis:Cross(uv)
	if a.Magnitude < 0.0001 then return CFrame.identity end
	return CFrame.fromAxisAngle(a.Unit, math.acos(d))
end

local function rnm()
	if aori then aori.Enabled = false end
	if lvel then lvel.Enabled = false end
	if hum then
		hum.AutoRotate = true
		hum.PlatformStand = false
	end
	if chr then
		local asc = chr:FindFirstChild("Animate")
		if asc then asc.Enabled = true end
		for _, d in ipairs(chr:GetDescendants()) do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end
		end
	end
	local cam = ws.CurrentCamera
	if cam and ucf then
		cam.CFrame = ucf
		cam.CameraType = Enum.CameraType.Custom
		if hum then cam.CameraSubject = hum end
	end
	spanim()
	tup = Vector3.yAxis
	cup = Vector3.yAxis
	uprt = true
end

local function tsl(st)
	son = st
	if son then
		chgchar:FireServer(csuit)
	else
		chgchar:FireServer(plr.Name)
		rnm()
	end
end

local lastIfp = nil

local function stchr(c)
	chr = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
	animtr = hum:WaitForChild("Animator", 3) or Instance.new("Animator", hum)

	lanims = {}
	cstate = nil
	ptrk = nil

	ratt = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
	ratt.Name = "RootAttachment"

	aori = Instance.new("AlignOrientation")
	aori.Mode = Enum.OrientationAlignmentMode.OneAttachment
	aori.Attachment0 = ratt
	aori.RigidityEnabled = false
	aori.Responsiveness = 50
	aori.MaxTorque = 1000000
	aori.Enabled = false
	aori.Parent = hrp

	lvel = Instance.new("LinearVelocity")
	lvel.Attachment0 = ratt
	lvel.RelativeTo = Enum.ActuatorRelativeTo.World
	lvel.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	lvel.MaxForce = 1000000
	lvel.VectorVelocity = Vector3.zero
	lvel.Enabled = false
	lvel.Parent = hrp

	lastIfp = nil
	updrf()
end

local function rmot()
	local bt = plr.Backpack:FindFirstChild(tnm)
	if bt then bt:Destroy() end
	if plr.Character then
		local ct = plr.Character:FindFirstChild(tnm)
		if ct then ct:Destroy() end
	end
end

local function gvt()
	rmot()
	local t = Instance.new("Tool")
	t.Name = tnm
	t.CanBeDropped = false
	t.RequiresHandle = false
	t.TextureId = ttx
	t.Parent = plr.Backpack

	t.Equipped:Connect(function()
		teq = true
		cgui.Enabled = true
	end)

	t.Unequipped:Connect(function()
		teq = false
		cgui.Enabled = false
		if mopen then clsm() end
	end)

	t.Activated:Connect(function()
		tsl(not son)
	end)
end

local function hguifn()
	if ghdn then return end
	ghdn = true
	hguis = {}
	local function pcont(c)
		for _, g in ipairs(c:GetChildren()) do
			if (g:IsA("ScreenGui") or g:IsA("LayerCollector")) and g.Enabled then
				if g ~= sgui and g ~= vgui and g ~= cgui then
					hguis[g] = true
					g.Enabled = false
				end
			end
		end
	end
	pcall(function() pcont(plrgui) end)
	pcall(function() pcont(game:GetService("CoreGui")) end)
end

local function rguifn()
	if not ghdn then return end
	for g, _ in pairs(hguis) do
		if g and g.Parent then g.Enabled = true end
	end
	hguis = {}
	ghdn = false
end

local function mkcd(ord, tit, stit, col)
	local con = Instance.new("Frame")
	con.Size = UDim2.new(0, 320, 0, 480)
	con.BackgroundTransparency = 1
	con.LayoutOrder = ord
	con.ZIndex = 3
	con.Parent = sfr

	local cd = Instance.new("ImageButton")
	cd.AnchorPoint = Vector2.new(0.5, 0.5)
	cd.Size = UDim2.new(1, 0, 1, 0)
	cd.Position = UDim2.new(0.5, 0, 1.5, 0)
	cd.BackgroundTransparency = 1
	cd.Image = "rbxassetid://93850864834513"
	cd.ImageTransparency = 1
	cd.ZIndex = 4
	cd.Parent = con

	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.ZIndex = 5
	vp.Parent = cd
	local wm = Instance.new("WorldModel")
	wm.Parent = vp
	local cam = Instance.new("Camera")
	vp.CurrentCamera = cam
	cam.Parent = vp

	local tx = Instance.new("TextLabel")
	tx.Size = UDim2.new(1, 0, 0, 40)
	tx.Position = UDim2.new(-0.06, 0, 0.75, 0)
	tx.BackgroundTransparency = 1
	tx.Font = Enum.Font.GothamBlack
	tx.TextSize = 28
	tx.TextColor3 = Color3.new(1, 1, 1)
	tx.Text = tit
	tx.ZIndex = 6
	tx.Parent = cd
	local tks = Instance.new("UIStroke")
	tks.Thickness = 2
	tks.Parent = tx

	local sx = Instance.new("TextLabel")
	sx.Size = UDim2.new(1, 0, 0, 30)
	sx.Position = UDim2.new(-0.06, 0, 0.85, 0)
	sx.BackgroundTransparency = 1
	sx.Font = Enum.Font.GothamBold
	sx.TextSize = 22
	sx.Text = stit
	sx.TextColor3 = col
	sx.ZIndex = 6
	sx.Parent = cd
	local sxs = Instance.new("UIStroke")
	sxs.Thickness = 2
	sxs.Parent = sx

	cd.MouseEnter:Connect(function()
		if not sgui.Enabled then return end
		ts:Create(cd, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(1.08, 0, 1.08, 0)}):Play()
	end)
	cd.MouseLeave:Connect(function()
		if not sgui.Enabled then return end
		ts:Create(cd, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	end)

	local r = {cd = cd, vp = vp, wm = wm, cam = cam, mod = nil, usr = nil}
	table.insert(cds, cd)
	table.insert(recs, r)
	return r
end

local mrec = mkcd(1, "Your Avatar", "EQUIPPED", Color3.fromRGB(100, 255, 100))
mrec.cd.MouseButton1Click:Connect(function()
	if mopen then clsm() end
	tsl(false)
end)

for i, dat in ipairs(chars) do
	local r = mkcd(i + 1, dat.nm, "UNLOCKED", Color3.fromRGB(100, 255, 100))
	r.usr = dat.usr
	r.cd.MouseButton1Click:Connect(function()
		csuit = dat.usr
		if mopen then clsm() end
		tsl(true)
	end)
end

task.spawn(function()
	local plds = {}
	for _, c in ipairs(cds) do table.insert(plds, c) end
	pcall(function() cp:PreloadAsync(plds) end)
end)

local rmtr = {}
local cmtr = {}

local function stloc()
	if mrec.mod then mrec.mod:Destroy(); mrec.mod = nil end
	rmtr = {}
	cmtr = {}
	local c = plr.Character
	if not c then return end
	c.Archivable = true
	local tmpl = c:Clone()
	c.Archivable = false
	for _, v in pairs(tmpl:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
	end
	tmpl:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	for _, d in pairs(c:GetDescendants()) do
		if d:IsA("Motor6D") then table.insert(rmtr, d) end
	end
	for _, m in ipairs(rmtr) do
		local cx = tmpl:FindFirstChild(m.Name, true)
		if cx and cx:IsA("Motor6D") then cmtr[m] = cx end
	end
	local chrp = tmpl:FindFirstChild("HumanoidRootPart")
	local ty = chrp and chrp.Position.Y or 0
	mrec.cam.CFrame = CFrame.new(Vector3.new(0, ty + 0.5, 9), Vector3.new(0, ty, 0))
	tmpl.Parent = mrec.wm
	mrec.mod = tmpl
end

local function cloc()
	if mrec.mod then mrec.mod:Destroy(); mrec.mod = nil end
	rmtr = {}
	cmtr = {}
end

local function ldrem(r)
	if not alv then return end
	local o, uid = pcall(function() return plrs:GetUserIdFromNameAsync(r.usr) end)
	if not o or not uid then return end
	if not alv then return end
	local o2, dsc = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(uid) end)
	if not o2 or not dsc then return end
	if not alv then return end
	local o3, md = pcall(function() return plrs:CreateHumanoidModelFromDescriptionAsync(dsc, Enum.HumanoidRigType.R15) end)
	if not o3 or not md then return end
	if not alv then md:Destroy(); return end
	for _, v in pairs(md:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
	end
	md:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	if r.mod then r.mod:Destroy() end
	r.mod = md
	local mhrp = md:FindFirstChild("HumanoidRootPart")
	local ty = mhrp and mhrp.Position.Y or 0
	r.cam.CFrame = CFrame.new(Vector3.new(0, ty + 0.5, 9), Vector3.new(0, ty, 0))
	md.Parent = r.wm
end

for _, r in ipairs(recs) do
	if r.usr then task.spawn(ldrem, r) end
end

function opnm()
	if mopen then return end
	mopen = true
	atok += 1
	local t = atok
	hguifn()
	cloc()
	stloc()
	sgui.Enabled = true
	vgui.Enabled = true
	ts:Create(blr, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 20}):Play()
	ts:Create(rtint, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.6}):Play()
	ts:Create(vimg, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {ImageTransparency = 0}):Play()
	if not fsnd.IsPlaying then fsnd:Play() end
	ts:Create(fsnd, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Volume = 1}):Play()
	for _, c in ipairs(cds) do
		c.Position = UDim2.new(0.5, 0, 1.5, 0)
		c.ImageTransparency = 1
	end
	for i, c in ipairs(cds) do
		task.delay(i * 0.03, function()
			if t ~= atok then return end
			ts:Create(c, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0), ImageTransparency = 0}):Play()
		end)
	end
end

function clsm()
	if not mopen then return end
	mopen = false
	atok += 1
	local t = atok
	ts:Create(blr, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 0}):Play()
	ts:Create(rtint, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
	local vt = ts:Create(vimg, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {ImageTransparency = 1})
	vt:Play()
	vt.Completed:Connect(function() vgui.Enabled = false end)
	local stw = ts:Create(fsnd, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Volume = 0})
	stw:Play()
	stw.Completed:Connect(function() fsnd:Stop() end)
	for i = #cds, 1, -1 do
		local c = cds[i]
		task.delay((#cds - i) * 0.015, function()
			if t ~= atok then return end
			ts:Create(c, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0), ImageTransparency = 1}):Play()
		end)
	end
	task.delay(0.25 + (#cds * 0.015), function()
		if t ~= atok then return end
		sgui.Enabled = false
		cloc()
		rguifn()
	end)
end

cbtn.MouseButton1Click:Connect(function()
	if mopen then clsm() end
end)

table.insert(conns, plr.CharacterAdded:Connect(function(c)
	if mopen then clsm() end
	stchr(c)
	task.wait(0.5)
	if not plr.Backpack:FindFirstChild(tnm) and not c:FindFirstChild(tnm) then gvt() end
end))

table.insert(conns, plrs.PlayerAdded:Connect(function(p)
	local c1 = p.CharacterAdded:Connect(function()
		task.defer(updrf)
	end)
	table.insert(conns, c1)
	task.defer(updrf)
end))

table.insert(conns, plrs.PlayerRemoving:Connect(function()
	task.defer(updrf)
end))

for _, p in ipairs(plrs:GetPlayers()) do
	local c1 = p.CharacterAdded:Connect(function()
		task.defer(updrf)
	end)
	table.insert(conns, c1)
end

table.insert(conns, rs.RenderStepped:Connect(function()
	if not sgui.Enabled then return end
	for rm, cm in pairs(cmtr) do cm.Transform = rm.Transform end
end))

local function istyp()
	return uis:GetFocusedTextBox() ~= nil
end

table.insert(conns, uis.InputBegan:Connect(function(inp, gp)
	if gp or istyp() then return end
	if inp.KeyCode == Enum.KeyCode.M and teq then
		if mopen then clsm() else opnm() end
	elseif inp.KeyCode == Enum.KeyCode.P and teq then
		if animtr then
			if ptrk then ptrk:Stop() end
			ptrk = animtr:LoadAnimation(panim)
			ptrk.Priority = Enum.AnimationPriority.Action
			ptrk.Looped = true
			ptrk:Play()
		end
	elseif inp.KeyCode == Enum.KeyCode.Space then
		if son then
			local ur = tup:Dot(Vector3.yAxis) > 0.99 and cup:Dot(Vector3.yAxis) > 0.99
			if not ur and grnd and (tick() - ljmp > jcd) then
				ljmp = tick()
				grnd = false
				local jp = hum.UseJumpPower and hum.JumpPower or math.sqrt(2 * ws.Gravity * hum.JumpHeight)
				vvel = jp
				if ptrk and ptrk.IsPlaying then ptrk:Stop() end
			end
		end
	end
end))

rs:BindToRenderStep("wccr", Enum.RenderPriority.Camera.Value - 1, function()
	if not son then return end
	local ur = tup:Dot(Vector3.yAxis) > 0.99 and cup:Dot(Vector3.yAxis) > 0.99
	if ur then return end
	local cam = ws.CurrentCamera
	if not cam or not ucf or not hrp then return end
	cam.CFrame = ucf
	cam.Focus = CFrame.new(hrp.Position + Vector3.yAxis * 1.5)
end)

rs:BindToRenderStep("wcct", Enum.RenderPriority.Camera.Value + 1, function()
	if not son then return end
	local cam = ws.CurrentCamera
	if not cam or not hrp then return end
	local ur = tup:Dot(Vector3.yAxis) > 0.99 and cup:Dot(Vector3.yAxis) > 0.99
	if ur then
		ucf = cam.CFrame
		return
	end
	ucf = cam.CFrame
	local tr = grot(cup)
	local tfp = hrp.Position + (cup * 1.5)
	local rcf = cam.Focus:Inverse() * cam.CFrame
	local tlf = CFrame.new(tfp) * tr
	local tcf = tlf * rcf
	local dir = tcf.Position - tfp
	local dist = dir.Magnitude
	if dist > 0.1 then
		local ocr = ws:Spherecast(tfp, 0.75, dir, rpar)
		if ocr then
			local sd = math.max(0.1, ocr.Distance - 0.1)
			tcf = tcf - dir.Unit * (dist - sd)
		end
	end
	cam.CFrame = tcf
	cam.Focus = tlf
	local cdc = (tcf.Position - tfp).Magnitude
	local ifp = cdc < 1.2
	if ifp ~= lastIfp then
		lastIfp = ifp
		for _, d in ipairs(chr:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				if not d:FindFirstAncestorOfClass("Tool") then
					d.LocalTransparencyModifier = ifp and 1 or 0
				end
			end
		end
	end
end)

table.insert(conns, rs.Heartbeat:Connect(function(dt)
	if not hrp or not hrp.Parent or not hum then return end
	if ptrk and ptrk.IsPlaying then
		if hum.MoveDirection.Magnitude > 0 then ptrk:Stop() end
	end
	if not son then return end
	local cam = ws.CurrentCamera
	if not cam then return end

	local hh = hum.HipHeight > 0 and hum.HipHeight or 2
	local th = hh + (hrp.Size.Y / 2)
	local mv = ctrls:GetMoveVector()

	local fl = ucf.LookVector
	local ff = Vector3.new(fl.X, 0, fl.Z)
	if ff.Magnitude > 0.001 then ff = ff.Unit else ff = Vector3.new(0, 0, -1) end
	local fr = ucf.RightVector
	fr = Vector3.new(fr.X, 0, fr.Z)
	if fr.Magnitude > 0.001 then fr = fr.Unit else fr = Vector3.new(1, 0, 0) end

	local fm = (ff * -mv.Z + fr * mv.X)
	if fm.Magnitude > 1 then fm = fm.Unit end

	local tr = grot(cup)
	local am = tr * fm
	local mm = am.Magnitude
	local imv = mm > 0.05

	local cu = tup
	local cr = grot(cu)
	local cm = cr * fm

	local cfw
	if imv then
		cfw = cm.Unit
	else
		local lf = hrp.CFrame.LookVector - hrp.CFrame.LookVector:Dot(cu) * cu
		cfw = lf.Magnitude > 0.001 and lf.Unit or (cr * ff).Unit
	end

	local ro = hrp.Position + cu * (th * 0.5)
	local fwry = nil
	if imv then
		local fo = ro - cu * (th * 0.4)
		fwry = ws:Raycast(fo, cm.Unit * wsd, rpar)
	end

	local gry = ws:Raycast(ro, -cu * (th * 1.5 + gcd), rpar)

	if tick() - ljmp > jcd * 0.5 then
		if fwry then
			tup = fwry.Normal
			grnd = true
		elseif gry then
			tup = gry.Normal
			grnd = gry.Distance <= (th * 1.5 + 0.6)
		else
			local wo = hrp.Position + cfw * wsd - cu * (th * 0.8)
			local wry = ws:Raycast(wo, -cfw * (wsd + 1), rpar)
			if wry then
				tup = wry.Normal
				grnd = true
			else
				grnd = false
			end
		end
	else
		grnd = false
	end

	if not grnd then
		local vd = lvel.VectorVelocity
		if vd.Magnitude > 0.1 then
			local frt = ws:Raycast(hrp.Position, vd.Unit * (vd.Magnitude * dt * 3 + 2), rpar)
			if frt then
				tup = frt.Normal
			else
				local dry = ws:Raycast(hrp.Position, -Vector3.yAxis * 15, rpar)
				if dry then tup = dry.Normal else tup = tup:Lerp(Vector3.yAxis, dt * 2).Unit end
			end
		else
			local dry = ws:Raycast(hrp.Position, -Vector3.yAxis * 15, rpar)
			if dry then tup = dry.Normal else tup = tup:Lerp(Vector3.yAxis, dt * 2).Unit end
		end
	end

	cup = cup:Lerp(tup, 20 * dt).Unit
	tr = grot(cup)

	local ur = tup:Dot(Vector3.yAxis) > 0.99 and cup:Dot(Vector3.yAxis) > 0.99

	if ur then
		if not uprt then
			uprt = true
			aori.Enabled = false
			lvel.Enabled = false
			hum.AutoRotate = true
			hum.PlatformStand = false
			local asc = chr:FindFirstChild("Animate")
			if asc then asc.Enabled = true end
			spanim()
		end
	else
		if uprt then
			uprt = false
			aori.Enabled = true
			lvel.Enabled = true
			hum.AutoRotate = false
			hum.PlatformStand = true
			local asc = chr:FindFirstChild("Animate")
			if asc then asc.Enabled = false end
			local cac = getCAC()
			if not cac then
				for _, t in ipairs(animtr:GetPlayingAnimationTracks()) do
					if t.Priority == Enum.AnimationPriority.Core or t.Priority == Enum.AnimationPriority.Movement then
						t:Stop(0.1)
					end
				end
			else
				cstate = nil
			end
		end

		local cdc = (cam.CFrame.Position - cam.Focus.Position).Magnitude
		local ifp = cdc < 1.2
		local ia = uis.MouseBehavior == Enum.MouseBehavior.LockCenter or ifp

		local lfw
		if ia then
			lfw = (tr * ff).Unit
		elseif imv then
			lfw = am.Unit
		else
			local flh = hrp.CFrame.LookVector - hrp.CFrame.LookVector:Dot(cup) * cup
			lfw = flh.Magnitude > 0.001 and flh.Unit or (tr * ff).Unit
		end

		aori.CFrame = CFrame.lookAt(Vector3.zero, lfw, cup)
		local eg = ws.Gravity

		if grnd then
			if gry then
				local td = gry.Distance - (th * 0.5)
				local ey = th - td
				local sv = math.clamp(ey * gsf, -mgs, mgs)
				vvel = sv
			else
				vvel = 0
			end
		else
			vvel = vvel - eg * dt
			local mf = -150
			if vvel < mf then vvel = mf end
		end

		local thv = am * hum.WalkSpeed
		if not grnd then thv = thv * acf end
		lvel.VectorVelocity = thv + cup * vvel

		if grnd then
			if imv then
				planim("walk")
				updwrb(mm * hum.WalkSpeed)
			else
				planim("idle", 1)
			end
		else
			if vvel > 0 then planim("jump", 1) else planim("fall", 1) end
		end
	end
end))

if plr.Character then stchr(plr.Character) end
gvt()

_G.svcleanup = function()
	alv = false
	atok += 1
	mopen = false
	for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	pcall(function() rs:UnbindFromRenderStep("wccr") end)
	pcall(function() rs:UnbindFromRenderStep("wcct") end)
	rnm()
	for _, r in ipairs(recs) do
		if r.mod then r.mod:Destroy(); r.mod = nil end
	end
	if blr then blr:Destroy() end
	rmot()
	if ghdn then rguifn() end
	if vgui then vgui:Destroy() end
	if sgui then sgui:Destroy() end
	if cgui then cgui:Destroy() end
end
