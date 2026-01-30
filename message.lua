--[[
    YankuizaOnTop - Fluent Edition
    Consolidado: Bypasses + Physics + Reach + Macros
]]

--// Loaded Check
if getgenv().gamesense and getgenv().gamesense.loaded then
	return
end
getgenv().gamesense = {loaded = true}

--// Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

--// Libraries
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

--// Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local Dump = { BallPrediction = {} }
local _BALLS = {}
local NO_FOLDER = false
local IS_LEGACY = false
local IS_4ASIDE = false
local MainModule = nil

--// Ball & Module Detection
local function UpdateDetection()
	local BallsFolder = workspace:FindFirstChild("Balls", true)
	if not BallsFolder then
		NO_FOLDER = true
		_BALLS = {}
		for _, Ball in pairs(workspace:GetChildren()) do
			if table.find({"fakeBaIlExpIoiter", "fakeBall", "MPS", "TPS", "CSF"}, Ball.Name) or Ball.Name:find("il") then
				table.insert(_BALLS, Ball)
			end
		end
	end

	if LocalPlayer.Backpack:FindFirstChild("ToolManagment") then
		IS_LEGACY = true
		MainModule = LocalPlayer.Backpack.ToolManagment
	elseif LocalPlayer.Backpack:FindFirstChild("module") then
		IS_4ASIDE = true
		MainModule = LocalPlayer.Backpack.module
	end
end
UpdateDetection()

--// Physics Math (Part 1 Original)
local function quadraticSolver(a, b, c)
	local x1 = (-b + math.sqrt((b*b) -4 * a * c)) / (2 * a)
	local x2 = (-b - math.sqrt((b*b) -4 * a * c)) / (2 * a)
	return x2 > x1 and x2 or x1
end

local function findLandingPosition(Vo, startingPosition, acc, max)
	local seconds = quadraticSolver((0.5 * -acc), Vo.Y, startingPosition.Y)
	local lastPos = startingPosition
	for i = 1, max do
		local t = seconds * (1/max * i)
		local height = Vo.Y * t + 0.5 * -acc * (t*t)
		lastPos = startingPosition + Vector3.new(Vo.X * t, height, Vo.Z * t)
	end
	return lastPos
end

--// Bypasses (Part 2 Original)
local function ApplyBypasses()
	pcall(function()
		for _, f in pairs(getgc(true)) do
			if typeof(f) == "function" then
				local n = debug.info(f, "n")
				if n == "reachcheck" or n == "touchingcheck" then
					hookfunction(f, function() return false end)
				elseif n == "IsBallBoundingHitbox" then
					hookfunction(f, function() return true end)
				end
			end
		end
	end)
end
ApplyBypasses()

--// UI Setup
local Window = Fluent:CreateWindow({
	Title = "yankuizaOnTop",
	SubTitle = "BETA - Fluent",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = true,
	Theme = "Dark"
})

local Tabs = {
	Reach = Window:AddTab({ Title = "Reach", Icon = "footprints" }),
	Ball = Window:AddTab({ Title = "Ball", Icon = "volleyball" }),
	Char = Window:AddTab({ Title = "Character", Icon = "user" }),
	Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

--// Reach Tab Elements
Tabs.Reach:AddToggle("ReachEnabled", {Title = "Master Toggle", Default = false})
Tabs.Reach:AddToggle("ReachVisualizer", {Title = "Show Hitbox", Default = false})
Tabs.Reach:AddColorpicker("ReachColor", {Title = "Hitbox Color", Default = Color3.fromRGB(255, 255, 255)})
Tabs.Reach:AddSlider("ReachSize", {Title = "Reach Size", Min = 0, Max = 50, Default = 10, Rounding = 1})
Tabs.Reach:AddSlider("ReachOffsetZ", {Title = "Forward Offset", Min = -10, Max = 10, Default = 0})

--// Ball Tab Elements
Tabs.Ball:AddToggle("BallPred", {Title = "Ball Prediction", Default = false})
Tabs.Ball:AddColorpicker("PredColor", {Title = "Trail Color", Default = Color3.fromRGB(0, 255, 140)})
Tabs.Ball:AddSlider("PredAccuracy", {Title = "Accuracy Steps", Min = 1, Max = 10, Default = 5})

Tabs.Ball:AddDivider()
Tabs.Ball:AddToggle("Hombolo", {Title = "Hombolo Macro (P)", Default = false})

--// Char Tab Elements
Tabs.Char:AddToggle("SpeedEnabled", {Title = "CFrame Speed", Default = false})
Tabs.Char:AddSlider("SpeedValue", {Title = "Speed", Min = 0, Max = 10, Default = 2})
Tabs.Char:AddDivider()
Tabs.Char:AddToggle("InsanePower", {Title = "Insane Power (G)", Default = false})
Tabs.Char:AddSlider("PowerForce", {Title = "Force", Min = 100, Max = 1000, Default = 250})

--// --- LOGIC SYSTEMS ---

-- Reach Visualizer Part
local ReachPart = Instance.new("Part")
ReachPart.Anchored = true
ReachPart.CanCollide = false
ReachPart.Material = Enum.Material.SmoothPlastic
ReachPart.Parent = workspace

RunService.RenderStepped:Connect(function()
	if Options.ReachEnabled.Value and HRP then
		ReachPart.Size = Vector3.new(Options.ReachSize.Value, Options.ReachSize.Value, Options.ReachSize.Value)
		ReachPart.CFrame = HRP.CFrame * CFrame.new(0, 0, -Options.ReachOffsetZ.Value)
		ReachPart.Color = Options.ReachColor.Value
		ReachPart.Transparency = Options.ReachVisualizer.Value and 0.8 or 1

		local Balls = NO_FOLDER and _BALLS or workspace:FindFirstChild("Balls", true):GetChildren()
		for _, ball in pairs(Balls) do
			if ball:IsA("BasePart") and (ball.Position - ReachPart.Position).Magnitude < (Options.ReachSize.Value / 1.5) then
				for _, limb in pairs(Character:GetChildren()) do
					if limb:IsA("BasePart") then
						firetouchinterest(limb, ball, 0)
						firetouchinterest(limb, ball, 1)
					end
				end
			end
		end
	else
		ReachPart.Transparency = 1
	end
end)

-- Ball Prediction Loop
task.spawn(function()
	while task.wait(0.1) do
		for _, v in pairs(Dump.BallPrediction) do v:Destroy() end
		Dump.BallPrediction = {}

		if Options.BallPred.Value then
			local Balls = NO_FOLDER and _BALLS or workspace:FindFirstChild("Balls", true):GetChildren()
			for _, ball in pairs(Balls) do
				if ball.AssemblyLinearVelocity.Magnitude > 20 then
					local landing = findLandingPosition(ball.AssemblyLinearVelocity, ball.Position, workspace.Gravity, Options.PredAccuracy.Value)

					local att0 = Instance.new("Attachment", workspace.Terrain)
					att0.WorldPosition = ball.Position
					local att1 = Instance.new("Attachment", workspace.Terrain)
					att1.WorldPosition = landing

					local beam = Instance.new("Beam", ball)
					beam.Attachment0 = att0
					beam.Attachment1 = att1
					beam.Color = ColorSequence.new(Options.PredColor.Value)
					beam.Width0 = 0.15

					table.insert(Dump.BallPrediction, att0)
					table.insert(Dump.BallPrediction, att1)
					table.insert(Dump.BallPrediction, beam)
				end
			end
		end
	end
end)

-- Insane Power Shoot (G) - Logic Part 2
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G and Options.InsanePower.Value and MainModule then
		local mod = require(MainModule)
		pcall(function()
			local rlCF = CFrame.new(0.5, -1.5, -1) * CFrame.Angles(0.35, 0, 0)
			local raCF = CFrame.new(1.5, 0.5, 0.5) * CFrame.Angles(-math.pi, 4, 4)
			mod.EditWeld("Right Leg", rlCF)
			mod.EditWeld("Right Arm", raCF)
		end)

		local conn
		conn = Character["Right Leg"].Touched:Connect(function(ball)
			if ball.Name:find("Ball") or ball.Parent.Name == "Balls" then
				local force = HRP.CFrame.LookVector * Options.PowerForce.Value + Vector3.new(0, 15, 0)
				if IS_4ASIDE then
					mod.shoot(ball, force, Vector3.new(9e9,9e9,9e9), false)
				else
					mod.ApplyForce(ball, Vector3.new(9e9,9e9,9e9), force, "Right Leg")
				end
				conn:Disconnect()
			end
		end)

		task.wait(0.5)
		if conn then conn:Disconnect() end
		pcall(function() mod.ResetWelds() end)
	end
end)

-- Hombolo Macro Logic
local AlignPos, Att0, Att1
Options.Hombolo:OnChanged(function()
	if Options.Hombolo.Value then
		local Balls = NO_FOLDER and _BALLS or workspace:FindFirstChild("Balls", true):GetChildren()
		if #Balls > 0 then
			local target = Balls[1]
			Att0 = Instance.new("Attachment", target)
			Att1 = Instance.new("Attachment", Character.Head)
			AlignPos = Instance.new("AlignPosition", target)
			AlignPos.Attachment0 = Att0
			AlignPos.Attachment1 = Att1
			AlignPos.MaxAxesForce = Vector3.new(9e9, 0, 9e9) -- Apenas X e Z
			AlignPos.Responsiveness = 200
		end
	else
		if AlignPos then AlignPos:Destroy() end
		if Att0 then Att0:Destroy() end
		if Att1 then Att1:Destroy() end
	end
end)

-- Final Character Speed
RunService.Heartbeat:Connect(function(dt)
	if Options.SpeedEnabled.Value and Humanoid.MoveDirection.Magnitude > 0 then
		HRP.CFrame = HRP.CFrame + (Humanoid.MoveDirection * Options.SpeedValue.Value * dt * 10)
	end
end)

-- Load Configurations
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("YankuizaFluent")
SaveManager:SetFolder("YankuizaFluent/MPS")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({Title = "YankuizaOnTop", Content = "Script carregado com sucesso!", Duration = 5})