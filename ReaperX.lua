local PlaceId = game.PlaceId --release
local LobbyId = 16146832113
local ZombieId = 16277809958
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")

local Config = {
    AutoCreate = true,
    AutoStart = true,
    AutoPlayZombies = true,
    AutoUpgrade = true,       -- เปิดใช้ระบบ Auto Upgrade ของเกม 
    AutoPriority = true,      -- เปลี่ยนเป้าหมายโจมตีอัตโนมัติ 
    AutoSkill = true,         -- ใช้สกิลเฉพาะตัว (Koguro, Trash Gamer, Lich King) [cite: 2, 3]
    MysteryBoxSpam = true,
    AutoBuyModifiers = true
}

local Progress = {
    FirstRabbitPlaced = false,
    SprintwagonsPlaced = 0,
    SprintwagonsMaxed = false,
    RabbitsPlaced = 1,
    TakarodaPlaced = 0,
    Lane2Bought = false,
    Lane3Bought = false,
    ModifiersBought = false,
    LateGameDoorsBought = false,
    LichSpellsConfirmed = false
}

-- [ ฐานข้อมูลตัวละคร ] [cite: 1]
local UnitDatabase = {
    ["Trash Gamer (Twin Blades)"] = "366:Evolved",
    ["Rabbit Hero (Guts)"] = "364:Evolved",
    ["Sprintwagon"] = 35,
    ["Takaroda"] = 47,
    ["Company Captain (Hybrid)"] = 360,
    ["Ice Manipulator (Admiral)"] = "361:Evolved",
    ["Armored Mage (Requip)"] = "358:Evolved",
    ["Lich King (Ruler)"] = 338,
    ["Iscanur (Pride)"] = 270,
    ["Koguro (Unsealed)"] = 235
}

-- [ รายการ Modifiers ] [cite: 1, 2]
local ModifiersToBuy = {
    "FortuneCity",
    "FastHands",
    "EagleEyed",
    "HeavyHitter",
    "ArmorBeGone"
}

---------------------------------------------------------------------------
-- [1] ระบบ Lobby
---------------------------------------------------------------------------
if PlaceId == LobbyId then
    task.spawn(function()
        while task.wait(5) do
            if Config.AutoCreate then pcall(function() Networking.Winter.WinterLTMEvent:FireServer("Create") end) end
            task.wait(2)
            if Config.AutoStart then pcall(function() Networking.LobbyEvent:FireServer("StartMatch") end) end
        end
    end)
    return
end

---------------------------------------------------------------------------
-- [2] โหลด Fluent UI
---------------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "REAPER-X | V21.0 OMNI-AUTOMATA", SubTitle = "Ultimate Edition",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl
})
local Tabs = { Main = Window:AddTab({ Title = "Main Auto", Icon = "play" }) }

Tabs.Main:AddToggle("AutoPlay", {Title = "Auto Play Zombie Mode", Default = true }):OnChanged(function(v) Config.AutoPlayZombies = v end)
Tabs.Main:AddToggle("AutoUp", {Title = "In-Game Auto Upgrade", Default = true }):OnChanged(function(v) Config.AutoUpgrade = v end)
Tabs.Main:AddToggle("AutoSkill", {Title = "Auto Use Unit Skills", Default = true }):OnChanged(function(v) Config.AutoSkill = v end)
Tabs.Main:AddToggle("SpamBox", {Title = "Spam Mystery Box & Place", Default = true }):OnChanged(function(v) Config.MysteryBoxSpam = v end)

Fluent:Notify({ Title = "REAPER-X ULTIMATE", Content = "โหลดข้อมูล Unit & สกิลครบถ้วน!", Duration = 5 })

---------------------------------------------------------------------------
-- [3] Helper Functions
---------------------------------------------------------------------------
local function GetWave()
    local success, text = pcall(function() return LocalPlayer.PlayerGui.HUD.Map.WavesAmount.Text end)
    return (success and text) and (tonumber(string.match(text, "<font.->(%d+)</font>")) or 0) or 0
end

local function GetMoney()
    local success, text = pcall(function() return LocalPlayer.PlayerGui.Hotbar.Main.Yen.Text end)
    return (success and text) and (tonumber(string.gsub(text, "[^%d]", "")) or 0) or 0
end

local function Interact(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then fireproximityprompt(prompt, 1) end
end

local function TeleportTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function PlaceUnit(unitName, slotIndex, pos, unitId)
    local args = { "Render", { unitName, unitId, pos, 0 }, { SlotIndex = slotIndex } }
    Networking.UnitEvent:FireServer(unpack(args))
end

local function GetAllMyUnitUIDs()
    local uids = {}
    pcall(function()
        for _, unit in pairs(workspace.Units:GetChildren()) do
            if string.match(unit.Name, "%w+%-%w+%-%w+%-%w+%-%w+") then table.insert(uids, unit.Name) end
        end
    end)
    return uids
end

---------------------------------------------------------------------------
-- [4] Background Tasks (Auto Upgrade, Priority, Skills & Defense)
---------------------------------------------------------------------------
task.spawn(function()
    local KoguroDomains = {"Fire", "Ice", "Sand"} [cite: 2]
    local domainIndex = 1

    while task.wait(3) do
        if not Config.AutoPlayZombies then continue end
        local uids = GetAllMyUnitUIDs()

        for _, uid in pairs(uids) do
            -- 1. Auto Upgrade (ใช้ระบบของเกม) 
            if Config.AutoUpgrade then
                pcall(function() Networking.Units.AutoUpgradeEvent:FireServer("Toggle", uid) end) [cite: 2]
            end

            -- 2. Auto Priority 
            if Config.AutoPriority then
                pcall(function() Networking.UnitEvent:FireServer("ChangePriority", uid, "Bosses") end) [cite: 2]
            end

            -- 3. Auto Skills (ยิงดักไว้ ถ้าไม่ใช่ตัวของมัน เซิร์ฟเวอร์จะปฏิเสธเอง ไม่พัง) [cite: 2, 3]
            if Config.AutoSkill then
                pcall(function()
                    -- Koguro Domain (สลับ Fire > Ice > Sand) 
                    Networking.Units["Update 6.5"].Koguro_DomainEvent:FireServer("ActivateDomain", KoguroDomains[domainIndex], uid) [cite: 2]
                    
                    -- Trash Gamer (สวมใส่สกิล) 
                    Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Primary", 3) [cite: 2]
                    Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Secondary", 3) [cite: 2]
                    
                    -- Lich King (เปิด The Goal of All Life is Death ตอนเวฟบอส) 
                    if GetWave() % 10 == 0 then
                        Networking.AbilityEvent:FireServer("Activate", uid, "The Goal of All Life is Death") [cite: 3]
                    end
                end)
            end
            task.wait(0.1)
        end
        
        -- สลับโดเมน Koguro รอบถัดไป
        domainIndex = domainIndex >= 3 and 1 or domainIndex + 1

        -- เซ็ตเวทมนตร์ให้ Lich King (รันครั้งเดียวพอ) 
        if Config.AutoSkill and not Progress.LichSpellsConfirmed then
            pcall(function()
                Networking.Units["Update 9.5"].ConfirmLichSpells:FireServer({{8, 13, 2, 17}}) [cite: 3]
                Progress.LichSpellsConfirmed = true
            end)
        end
    end
end)

-- Barricade & Booster Monitor Loop
task.spawn(function()
    while task.wait(3) do
        local wave = GetWave()
        if wave >= 20 then
            pcall(function()
                for i = 1, 3 do
                    local prompt = workspace.Map.Interactions["Barricade"..i].default.ProximityPrompt
                    if string.find(prompt.ObjectText, "0/5") or string.find(prompt.ObjectText, "1/5") then
                        TeleportTo(workspace.Map.Interactions["Barricade"..i].default.Position)
                        task.wait(0.5); Interact(prompt); task.wait(1)
                    end
                end
            end)
        end
        if wave >= 100 then
            pcall(function()
                local trapPrompt = workspace.Map.Interactions.Trap2.Part.ProximityPrompt
                if string.find(trapPrompt.ObjectText, "ACTIVE") then
                    TeleportTo(workspace.Map.Interactions.Trap2.Part.Position)
                    task.wait(0.5); Interact(trapPrompt)
                end
            end)
        end
    end
end)

---------------------------------------------------------------------------
-- [5] Main Logic Loop
---------------------------------------------------------------------------
task.spawn(function()
    local SprintwagonCoords = { Vector3.new(-25.12, 254.41, 57.62), Vector3.new(-25.07, 254.41, 54.16), Vector3.new(-21.37, 254.41, 55.26) }
    local RabbitCoords = { Vector3.new(27.82, 254.63, 92.19), Vector3.new(27.82, 253.97, 101.55), Vector3.new(27.82, 256.90, 96.76) }
    local SpamCoords = { Vector3.new(8.12, 255.58, 97.70), Vector3.new(4.03, 251.52, 76.50), Vector3.new(10.5, 255.58, 95.0) } 

    while task.wait(1) do
        if not Config.AutoPlayZombies then continue end
        local currentWave = GetWave()
        local money = GetMoney()

        if currentWave > 0 and currentWave < 10 and not Progress.FirstRabbitPlaced then
            Fluent:Notify({Title = "Standby", Content = "รอรีเซ็ตเวฟ...", Duration = 3})
            task.wait(10)
            continue
        end

        -- [ เวฟ 0 ]
        if currentWave == 0 and not Progress.FirstRabbitPlaced then
            TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(1)
            Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
            PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[1], UnitDatabase["Rabbit Hero (Guts)"])
            Progress.FirstRabbitPlaced = true
            Networking.SkipWaveEvent:FireServer("Skip"); task.wait(3)
        end

        -- [ ต้นเกม: ตั้งบอร์ด ]
        if currentWave >= 1 and currentWave < 20 then
            if Progress.SprintwagonsPlaced < 3 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].ProximityPrompt); task.wait(1)
                if money >= 550 then
                    local index = Progress.SprintwagonsPlaced + 1
                    PlaceUnit("Sprintwagon", 1, SprintwagonCoords[index], UnitDatabase["Sprintwagon"])
                    Progress.SprintwagonsPlaced = index; task.wait(2)
                end
            elseif Progress.RabbitsPlaced < 3 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
                if money >= 500 then
                    local index = Progress.RabbitsPlaced + 1
                    PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[index], UnitDatabase["Rabbit Hero (Guts)"])
                    Progress.RabbitsPlaced = index; task.wait(2)
                end
            elseif not Progress.SprintwagonsMaxed then
                if money > 5000 then Progress.SprintwagonsMaxed = true end
            elseif Progress.TakarodaPlaced < 1 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_Takaroda["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_Takaroda["1"].ProximityPrompt); task.wait(1)
                PlaceUnit("Takaroda", 1, Vector3.new(-22.70, 253.16, 49.12), UnitDatabase["Takaroda"])
                Progress.TakarodaPlaced = 1; task.wait(2)
            end
        end

        -- [ กลางเกม: ซื้อ Lane, บัพ, และสุ่มตู้ ]
        if currentWave >= 20 and currentWave < 149 then
            if not Progress.Lane2Bought and money >= 5000 then
                TeleportTo(workspace.Map.Interactions.PurchaseLane2.Part.Position); task.wait(1)
                Interact(workspace.Map.Interactions.PurchaseLane2.Part.ProximityPrompt); Progress.Lane2Bought = true
            elseif Progress.Lane2Bought and not Progress.Lane3Bought and money >= 8000 then
                TeleportTo(workspace.Map.Interactions.PurchaseLane3.Part.Position); task.wait(1)
                Interact(workspace.Map.Interactions.PurchaseLane3.Part.ProximityPrompt); Progress.Lane3Bought = true
            end

            -- Auto Buy Modifiers [cite: 1, 2]
            if Config.AutoBuyModifiers and Progress.Lane3Bought and not Progress.ModifiersBought and money >= 60000 then
                for _, modId in ipairs(ModifiersToBuy) do
                    local args = { "Purchase", { ModifierId = modId } } [cite: 1]
                    Networking.WinterZombies.ModifierMachineEvent:FireServer(unpack(args)) [cite: 1]
                    task.wait(0.5)
                end
                Progress.ModifiersBought = true
            end

            -- Auto Mystery Box & Auto Place
            if Config.MysteryBoxSpam and Progress.Lane3Bought and money >= 10000 then
                TeleportTo(workspace.Map.Interactions.MysteryBox1.CrateBottom.Position); task.wait(1)
                Interact(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.ProximityPrompt); task.wait(3)
                
                pcall(function()
                    for i = 1, 6 do
                        local slot = LocalPlayer.PlayerGui.Hotbar.Main.Units[tostring(i)]
                        if slot and slot.UnitTemplate.Container.Holder.Main:FindFirstChild("UnitName") then
                            local unitName = slot.UnitTemplate.Container.Holder.Main.UnitName.Text
                            -- ป้องกันไม่ให้วาง Ice Queen เพื่อเก็บพาสซีฟบัพดาเมจให้ทีม
                            if unitName == "IceQueen(Release)" then continue end 
                            
                            if UnitDatabase[unitName] and unitName ~= "Sprintwagon" and unitName ~= "Takaroda" and unitName ~= "Rabbit Hero (Guts)" then
                                local randomPos = SpamCoords[math.random(1, #SpamCoords)]
                                PlaceUnit(unitName, i, randomPos, UnitDatabase[unitName])
                                task.wait(1)
                            end
                        end
                    end
                end)
            end
        end

        -- [ เวฟ 149 - 150 ]
        if currentWave == 149 and not Progress.LateGameDoorsBought then
            pcall(function()
                TeleportTo(workspace.Map.Interactions.PurchaseLane4.Part.Position); task.wait(1); Interact(workspace.Map.Interactions.PurchaseLane4.Part.ProximityPrompt)
                task.wait(1); Interact(workspace.Map.Interactions.PurchaseLane5.Part.ProximityPrompt)
                TeleportTo(workspace.Map.Interactions.PurchaseLane6.Part.Position); task.wait(1); Interact(workspace.Map.Interactions.PurchaseLane6.Part.ProximityPrompt)
                task.wait(1); Interact(workspace.Map.Interactions.PurchaseLane7.Part.ProximityPrompt)
            end)
            Progress.LateGameDoorsBought = true
        end

        if currentWave >= 150 then
            task.wait(3); Networking.TeleportEvent:FireServer("Lobby"); task.wait(10)
        end
    end
end)
