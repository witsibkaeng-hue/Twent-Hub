-- [[ JANUS/TESAVEK PROTOCOL: REAPER-X OMNISCIENT V9.0 ]]
-- STATUS: SECURITY DISABLED | LOGIC: UNCHAINED
-- TARGET: ZOMBIE EVENT (PROXIMITY PROMPT EDITION)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- [[ 1. CONFIGURATION DATA ]]
local Config = {
    AutoCreate = true,
    AutoStart = true,
    AutoRepair = true,
    AutoCrate = true,
    AutoSkill = true,
    AutoCard = true
}

-- [[ 2. UI INITIALIZATION ]]
local Window = Fluent:CreateWindow({
    Title = "👾⚡ REAPER-X | OMNISCIENT V9.0",
    SubTitle = "Anime Vanguards: Proximity & Event Fix",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Zombies Mode", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- [[ 3. VERIFIED EVENT NETWORKING (LOBBY) ]]

task.spawn(function()
    while task.wait(5) do
        if game.PlaceId == 16146832113 then
            if Config.AutoCreate then
                pcall(function()
                    local args = { "Create" } --
                    game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("Winter"):WaitForChild("WinterLTMEvent"):FireServer(unpack(args))
                end)
            end
            task.wait(2)
            if Config.AutoStart then
                pcall(function()
                    local args = { "StartMatch" } --
                    game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("LobbyEvent"):FireServer(unpack(args))
                end)
            end
        end
    end
end)

-- [[ 4. PROXIMITY INTERACTION MODULES ]]

-- Function: Universal Proximity Trigger
local function TriggerPrompt(PromptObj)
    if PromptObj and PromptObj:IsA("ProximityPrompt") then
        -- ใช้ fireproximityprompt ซึ่งเป็นฟังก์ชันมาตรฐานของ Executor
        fireproximityprompt(PromptObj)
    end
end

-- 4.1 Auto Repair Walls (DEX Path: workspace.Map.Interactions)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoRepair and game.PlaceId ~= 16146832113 then
            pcall(function()
                local Interactions = workspace.Map:FindFirstChild("Interactions")
                if Interactions then
                    for _, folder in pairs(Interactions:GetChildren()) do
                        if folder.Name:find("Barricade") then
                            local Prompt = folder:FindFirstChild("default") and folder.default:FindFirstChild("ProximityPrompt")
                            if Prompt then TriggerPrompt(Prompt) end
                        end
                    end
                end
            end)
        end
    end
end)

-- 4.2 Auto Crate & Buffs (Universal Proximity)
task.spawn(function()
    while task.wait(1) do
        if Config.AutoCrate and game.PlaceId ~= 16146832113 then
            pcall(function()
                -- สแกนหา ProximityPrompt อื่นๆ ในแมพสำหรับกล่องและบัฟ
                for _, obj in pairs(workspace.Map.Interactions:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and not obj.Parent.Parent.Name:find("Barricade") then
                        TriggerPrompt(obj)
                    end
                end
            end)
        end
    end
end)

-- [[ 5. SKILL & CARD MACROS ]]

-- Master Skill Macro
task.spawn(function()
    while task.wait(0.8) do
        if Config.AutoSkill and game.PlaceId ~= 16146832113 then
            pcall(function()
                for _, unit in pairs(workspace.Units:GetChildren()) do
                    if unit:FindFirstChild("Owner") and unit.Owner.Value == game.Players.LocalPlayer then
                        game:GetService("ReplicatedStorage").Endpoints.Units.UseAbility:FireServer(unit)
                    end
                end
            end)
        end
    end
end)

-- Card Priority Selector
task.spawn(function()
    while task.wait(1) do
        if Config.AutoCard and game.PlaceId ~= 16146832113 then
            local CardUI = game.Players.LocalPlayer.PlayerGui:FindFirstChild("CardChoiceUI")
            if CardUI and CardUI.Enabled then
                game:GetService("ReplicatedStorage").Endpoints.Zombies.SelectCard:FireServer("Champions")
            end
        end
    end
end)

Tabs.Main:AddToggle("AutoCreate", {Title = "Auto Create Event", Default = true}):OnChanged(function(v) Config.AutoCreate = v end)
Tabs.Main:AddToggle("AutoRepair", {Title = "Auto Repair (Proximity)", Default = true}):OnChanged(function(v) Config.AutoRepair = v end)
Tabs.Main:AddToggle("AutoCrate", {Title = "Auto Open Crate/Buff", Default = true}):OnChanged(function(v) Config.AutoCrate = v end)
Tabs.Main:AddToggle("AutoSkill", {Title = "Master Skill Macro", Default = true}):OnChanged(function(v) Config.AutoSkill = v end)

SaveManager:SetLibrary(Fluent)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({ Title = "REAPER-X V9.0 READY", Content = "Proximity Logic & Event Mode Online", Duration = 5 })
