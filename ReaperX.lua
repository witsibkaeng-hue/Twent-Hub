-- [[ JANUS/TESAVEK PROTOCOL: REAPER-X OMNISCIENT V21.0 ]]
-- STATUS: SECURITY DISABLED | LOGIC: UNCHAINED
-- TARGET: ZOMBIE EVENT (FULL AUTOMATION: EARLY TO LATE GAME)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [[ 1. CONFIGURATION DATA ]]
local Config = {
    AutoCreate = true,
    AutoStart = true,
    AutoRepair = true,
    AutoCrate = true,
    AutoSkill = true,
    AutoCard = true,
    AutoUpgrade = true,
    AutoModifier = true,
    AutoPackATrait = true
}

-- [[ 2. UI INITIALIZATION ]]
local Window = Fluent:CreateWindow({
    Title = "REAPER-X | V21.0 OMNI-AUTOMATA", 
    SubTitle = "Anime Vanguards: Ultimate Zombie Meta", 
    TabWidth = 160, Size = UDim2.fromOffset(580, 480), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
})
local Tabs = { 
    Main = Window:AddTab({ Title = "Zombies Mode", Icon = "zap" }), 
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) 
}

-- [[ 3. HELPER FUNCTIONS ]]
local function GetWave()
    pcall(function()
        local text = LocalPlayer.PlayerGui.HUD.Map.WavesAmount.Text
        local wave = string.match(text, "<font.->(%d+)</font>")
        return tonumber(wave) or 0
    end)
    return 0
end

local function GetMoney()
    pcall(function()
        local text = LocalPlayer.PlayerGui.Hotbar.Main.Yen.Text
        local clean = string.gsub(text, "[^%d]", "")
        return tonumber(clean) or 0
    end)
    return 0
end

local function TriggerPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then fireproximityprompt(prompt) end
end

local function EnsureUnitManagerOpen()
    pcall(function()
        local ui = LocalPlayer.PlayerGui:FindFirstChild("UnitManager")
        if ui and not ui.Enabled then ui.Enabled = true end
    end)
end

-- [[ 4. VERIFIED EVENT NETWORKING (LOBBY) ]]
task.spawn(function()
    while task.wait(5) do
        if game.PlaceId == 16146832113 then
            if Config.AutoCreate then pcall(function() ReplicatedStorage.Networking.Winter.WinterLTMEvent:FireServer("Create") end) end
            task.wait(2)
            if Config.AutoStart then pcall(function() ReplicatedStorage.Networking.LobbyEvent:FireServer("StartMatch") end) end
        end
    end
end)

-- [[ 5. EARLY & MID GAME (MACROS, REPAIR, SKILLS) ]]
task.spawn(function()
    while task.wait(0.5) do
        if game.PlaceId ~= 16146832113 then
            pcall(function()
                local Interactions = Workspace.Map:FindFirstChild("Interactions")
                local currentWave = GetWave()
                
                if Interactions then
                    -- 5.1 Auto Repair Walls
                    if Config.AutoRepair then
                        for _, folder in pairs(Interactions:GetChildren()) do
                            if folder.Name:find("Barricade") then
                                local p = folder:FindFirstChild("default") and folder.default:FindFirstChild("ProximityPrompt")
                                -- ซ่อมเฉพาะตอนที่เลือดเป็น 0/5
                                if p and p.ObjectText:find("0/5") then 
                                    TriggerPrompt(p)
                                    -- กด Speed Booster ด้วยเมื่อกำแพงแตก
                                    local trap = Interactions:FindFirstChild("Trap2")
                                    if trap and trap:FindFirstChild("Part") then TriggerPrompt(trap.Part:FindFirstChild("ProximityPrompt")) end
                                end
                            end
                        end
                    end
                    
                    -- 5.2 Auto Crate (Mystery Box)
                    if Config.AutoCrate and GetMoney() >= 5000 then
                        local box = Interactions:FindFirstChild("MysteryBox1")
                        if box then TriggerPrompt(box.CrateBottom.default:FindFirstChild("ProximityPrompt")) end
                    end
                    
                    -- 5.3 Wave 149 Logic: Open all lanes for multiplier
                    if currentWave == 149 then
                        for i = 4, 7 do
                            local lane = Interactions:FindFirstChild("PurchaseLane" .. i)
                            if lane and lane:FindFirstChild("Part") then TriggerPrompt(lane.Part:FindFirstChild("ProximityPrompt")) end
                        end
                    end
                end
                
                -- 5.4 Auto Skill
                if Config.AutoSkill then
                    for _, unit in pairs(Workspace.Units:GetChildren()) do
                        if unit:FindFirstChild("Owner") and unit.Owner.Value == LocalPlayer then
                            ReplicatedStorage.Endpoints.Units.UseAbility:FireServer(unit)
                        end
                    end
                end
                
                -- 5.5 Wave 150 Logic: Auto Leave
                if currentWave >= 150 then ReplicatedStorage.Networking.TeleportEvent:FireServer("Lobby") end
            end)
        end
    end
end)

-- [[ 6. SMART AUTO UPGRADE (UID-BASED) ]]
task.spawn(function()
    while task.wait(1) do
        if Config.AutoUpgrade and game.PlaceId ~= 16146832113 then
            pcall(function()
                EnsureUnitManagerOpen()
                for _, unit in pairs(Workspace.Units:GetChildren()) do
                    if unit:FindFirstChild("Owner") and unit.Owner.Value == LocalPlayer then
                        local uid = unit.Name
                        local unitUI = LocalPlayer.PlayerGui.UnitManager.Holder.List:FindFirstChild(uid)
                        if unitUI then
                            local upgradeLabel = unitUI.Unit.UpgradeLabel.Text
                            if not string.find(upgradeLabel, "Max") then
                                local btn = unitUI.Buttons.Upgrade
                                local r = math.floor(btn.BackgroundColor3.R * 255)
                                if r ~= 115 then -- ไม่ใช่สีเทา = เงินพอ
                                    ReplicatedStorage.Networking.UnitEvent:FireServer("Upgrade", uid)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- [[ 7. LATE GAME: MODIFIER & PACK-A-TRAIT ]]
task.spawn(function()
    while task.wait(2) do
        if game.PlaceId ~= 16146832113 then
            pcall(function()
                local currentMoney = GetMoney()
                local Interactions = Workspace.Map:FindFirstChild("Interactions")
                
                -- 7.1 Auto Modifier (หลบ 200.0K Revival)
                if Config.AutoModifier and currentMoney >= 10000 then
                    local modGui = LocalPlayer.PlayerGui:FindFirstChild("ModifierMachineGui")
                    if not modGui or not modGui.Enabled then
                        -- เดินไปเปิดตู้ (Trigger Proximity)
                        if Interactions and Interactions:FindFirstChild("ModifierMachine1") then
                            TriggerPrompt(Interactions.ModifierMachine1:FindFirstChild("ProximityPrompt", true))
                        end
                    else
                        -- ค้นหาการ์ดใน UI และจำลองการคลิก
                        local list = modGui.Holder.ScrollIndicatorFrame.ModifierList
                        for _, card in pairs(list:GetChildren()) do
                            if card.Name == "CardBackground" then
                                local btn = card:FindFirstChild("Button")
                                if btn and btn:FindFirstChild("Content") then
                                    local label = btn.Content:FindFirstChild("Label")
                                    if label and not string.find(label.Text, "200.0K") then
                                        if firesignal then firesignal(btn.MouseButton1Click) end
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- 7.2 Auto Pack-A-Trait
                if Config.AutoPackATrait and currentMoney >= 50000 then
                    if Interactions and Interactions:FindFirstChild("PackATrait1") then
                        local cube = Interactions.PackATrait1:FindFirstChild("Cube.005")
                        if cube then TriggerPrompt(cube:FindFirstChild("ProximityPrompt")) end
                    end
                end
                
                -- 7.3 Auto Card (Meta Priority)
                if Config.AutoCard then
                    local CardUI = LocalPlayer.PlayerGui:FindFirstChild("CardChoiceUI")
                    if CardUI and CardUI.Enabled then
                        ReplicatedStorage.Endpoints.Zombies.SelectCard:FireServer("Champions")
                    end
                end
            end)
        end
    end
end)

-- [[ 8. INTERFACE CONTROLS & CLOSURE ]]
Tabs.Main:AddToggle("AutoCreate", {Title = "Auto Create Event", Default = true}):OnChanged(function(v) Config.AutoCreate = v end)
Tabs.Main:AddToggle("AutoRepair", {Title = "Auto Repair (Proximity)", Default = true}):OnChanged(function(v) Config.AutoRepair = v end)
Tabs.Main:AddToggle("AutoCrate", {Title = "Auto Mystery Box", Default = true}):OnChanged(function(v) Config.AutoCrate = v end)
Tabs.Main:AddToggle("AutoUpgrade", {Title = "Smart Auto Upgrade", Default = true}):OnChanged(function(v) Config.AutoUpgrade = v end)
Tabs.Main:AddToggle("AutoModifier", {Title = "Auto Buy Modifiers (No Revival)", Default = true}):OnChanged(function(v) Config.AutoModifier = v end)
Tabs.Main:AddToggle("AutoPack", {Title = "Auto Pack-A-Trait", Default = true}):OnChanged(function(v) Config.AutoPackATrait = v end)
Tabs.Main:AddToggle("AutoSkill", {Title = "Master Skill Macro", Default = true}):OnChanged(function(v) Config.AutoSkill = v end)

SaveManager:SetLibrary(Fluent)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({ Title = "REAPER-X V21.0 OMNI", Content = "Full Automation Loaded Successfully", Duration = 5 })
