local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
	Title = "SAML HUB",
	SubTitle = "Fluent UI",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
	Main = Window:AddTab({ Title = "Main", Icon = "home" }),
	Player = Window:AddTab({ Title = "Player", Icon = "user" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

Fluent:Notify({
	Title = "SAML HUB",
	Content = "Carregado com sucesso",
	Duration = 5
})

-- MAIN TAB
Tabs.Main:AddParagraph({
	Title = "Status",
	Content = "Hub rodando normalmente"
})

Tabs.Main:AddButton({
	Title = "Testar botão",
	Description = "Botão de teste",
	Callback = function()
		print("Botão clicado")
	end
})

Tabs.Main:AddToggle("AutoFarm", {
	Title = "Auto Farm",
	Default = false
}):OnChanged(function()
	print("AutoFarm:", Options.AutoFarm.Value)
end)

Tabs.Main:AddSlider("Speed", {
	Title = "Speed",
	Min = 16,
	Max = 200,
	Default = 16,
	Rounding = 0,
	Callback = function(Value)
		local lp = game.Players.LocalPlayer
		if lp.Character and lp.Character:FindFirstChild("Humanoid") then
			lp.Character.Humanoid.WalkSpeed = Value
		end
	end
})

-- PLAYER TAB
Tabs.Player:AddToggle("InfiniteJump", {
	Title = "Infinite Jump",
	Default = false
})

game:GetService("UserInputService").JumpRequest:Connect(function()
	if Options.InfiniteJump.Value then
		local char = game.Players.LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

Tabs.Player:AddButton({
	Title = "Reset Character",
	Callback = function()
		game.Players.LocalPlayer.Character:BreakJoints()
	end
})

-- SETTINGS
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("SAML_HUB")
SaveManager:SetFolder("SAML_HUB/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
	Title = "Fluent",
	Content = "Tudo pronto",
	Duration = 5
})

SaveManager:LoadAutoloadConfig()
