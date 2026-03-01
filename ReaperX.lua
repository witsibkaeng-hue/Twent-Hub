local PlaceId = game.PlaceId
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
    AutoUpgrade = true,
    AutoPriority = true,
    AutoSkill = true,
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
-- [2] โหลด Fluent UI แบบ Safe Load
---------------------------------------------------------------------------
local function LoadUI()
    local success, result = pcall(function()
        return game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
    end)
    if not success or type(result) ~= "string" then return nil end
    local uiFunc, loadErr = loadstring(result)
    if type(uiFunc) ~= "function" then return nil end
    return uiFunc()
end

local Fluent = LoadUI()
if not Fluent then
    game.StarterGui:SetCore("SendNotification", { Title = "REAPER-X ERROR", Text = "โหลด UI ไม่สำเร็จ", Duration = 10 })
    return
end

local Window = Fluent:CreateWindow({
    Title = "REAPER-X | V21.0 OMNI-AUTOMATA", SubTitle = "Ultimate Edition",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl
})
local Tabs = { Main = Window:AddTab({ Title = "Main Auto", Icon = "play" }) }

Tabs.Main:AddToggle("AutoPlay", {Title = "Auto Play Zombie Mode", Default = true }):OnChanged(function(v) Config.AutoPlayZombies = v end)
Tabs.Main:AddToggle("AutoUp", {Title = "In-Game Auto Upgrade", Default = true }):OnChanged(function(v) Config.AutoUpgrade = v end)
Tabs.Main:AddToggle("AutoSkill", {Title = "Auto Use Unit Skills", Default = true }):OnChanged(function(v) Config.AutoSkill = v end)
Tabs.Main:AddToggle("SpamBox", {Title = "Spam Mystery Box & Place", Default = true }):OnChanged(function(v) Config.MysteryBoxSpam = v end)

Fluent:Notify({ Title = "REAPER-X ULTIMATE", Content = "ระบบพร้อมทำงาน!", Duration = 5 })

---------------------------------------------------------------------------
-- [3] Helper Functions
---------------------------------------------------------------------------
local function GetWave()
    local success, text = pcall(function() return LocalPlayer.PlayerGui.HUD.Map.WavesAmount.Text end)
    return (success and text) and (tonumber(string.match(text, "<font.->(%d+)</font>")) or 0) or 0
end

local function GetMoney()
    local success, text = pcall(function() return LocalPlayer.PlayerGui.Hotbar.Main.Yen.Text end)
    print("Raw Money Text:", text) -- Debug: ดูข้อความดิบที่ได้มา
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
    local KoguroDomains = {"Fire", "Ice", "Sand"}
    local domainIndex = 1
    
    -- ระบบความจำ: จดจำ UID ที่เคยเซ็ตค่าไปแล้ว จะได้ไม่กดซ้ำ
    local ProcessedUnits = {
        Upgrade = {},
        Priority = {},
        EquipSkill = {}
    }

    while task.wait(3) do
        if not Config.AutoPlayZombies then continue end
        local uids = GetAllMyUnitUIDs()

        for _, uid in pairs(uids) do
            -- 1. Auto Upgrade (กด Toggle แค่ครั้งเดียวต่อ 1 ตัวละคร)
            if Config.AutoUpgrade and not ProcessedUnits.Upgrade[uid] then
                pcall(function() Networking.Units.AutoUpgradeEvent:FireServer("Toggle", uid) end)
                ProcessedUnits.Upgrade[uid] = true -- จำไว้ว่าเคยกดแล้ว
            end
            
            -- 2. Auto Priority (กดเปลี่ยนเป้าหมายแค่ครั้งเดียว)
            if Config.AutoPriority and not ProcessedUnits.Priority[uid] then
                pcall(function() Networking.UnitEvent:FireServer("ChangePriority", uid, "Bosses") end)
                ProcessedUnits.Priority[uid] = true -- จำไว้ว่าเคยกดแล้ว
            end
            
            -- 3. Auto Skills
            if Config.AutoSkill then
                pcall(function()
                    -- Koguro Domain (สลับเรื่อยๆ ไม่ต้องล็อกเพราะต้องวนโดเมน)
                    Networking.Units["Update 6.5"].Koguro_DomainEvent:FireServer("ActivateDomain", KoguroDomains[domainIndex], uid)
                    
                    -- Trash Gamer (สวมใส่สกิล ทำแค่ครั้งเดียวพอ)
                    if not ProcessedUnits.EquipSkill[uid] then
                        Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Primary", 3)
                        Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Secondary", 3)
                        ProcessedUnits.EquipSkill[uid] = true
                    end
                    
                    -- Lich King (เปิด The Goal of All Life is Death ตอนเวฟบอส)
                    local wave = GetWave()
                    if wave > 0 and wave % 10 == 0 then
                        Networking.AbilityEvent:FireServer("Activate", uid, "The Goal of All Life is Death")
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
                Networking.Units["Update 9.5"].ConfirmLichSpells:FireServer({{8, 13, 2, 17}})
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
        print("Current Wave:", currentWave, "Money:", money)
        -- [ เช็ค Standby รอรีเซ็ตเวฟ และรอให้หน้าจอ EndScreen ขึ้น ]
        if currentWave > 0 and currentWave < 10 and not Progress.FirstRabbitPlaced then
            local endScreen = LocalPlayer.PlayerGui:FindFirstChild("EndScreen")
            -- ถ้า EndScreen ยังไม่โหลด หรือยังไม่ Enabled ให้วนลูปรอต่อไป
            if not (endScreen and endScreen.Enabled) then
                task.wait(0.2)
                continue
            end
        end

        -- [ เวฟ 0 ]
        if currentWave == 0 and not Progress.FirstRabbitPlaced then
            TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(1)
            Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
            PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[1], UnitDatabase["Rabbit Hero (Guts)"])
            Progress.FirstRabbitPlaced = true
            Networking.SkipWaveEvent:FireServer("Skip"); task.wait(3)
            print("Placed first Rabbit Hero and skipped to wave 1")
        end

        -- [ ต้นเกม: ตั้งบอร์ด (อัปเดตลอจิกใหม่จากคุณ) ]
        if currentWave >= 1 and currentWave < 20 then
            if Progress.SprintwagonsPlaced < 3 and money >= 1000 then
                print("Attempting to place Sprintwagon. Currently placed:", Progress.SprintwagonsPlaced)
                TeleportTo(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].ProximityPrompt); task.wait(1)
                if money >= 550 then
                    local index = Progress.SprintwagonsPlaced + 1
                    PlaceUnit("Sprintwagon", 1, SprintwagonCoords[index], UnitDatabase["Sprintwagon"])
                    Progress.SprintwagonsPlaced = index; task.wait(2)
                    print("Placed Sprintwagon number:", index)
                end
            elseif Progress.RabbitsPlaced < 3 and money >= 500 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
                if money >= 1200 then
                    local index = Progress.RabbitsPlaced + 1
                    PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[index], UnitDatabase["Rabbit Hero (Guts)"])
                    Progress.RabbitsPlaced = index; task.wait(2)
                end
            elseif not Progress.SprintwagonsMaxed then
                if money > 8000 then Progress.SprintwagonsMaxed = true end
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

            if Config.AutoBuyModifiers and Progress.Lane3Bought and not Progress.ModifiersBought and money >= 60000 then
                for _, modId in ipairs(ModifiersToBuy) do
                    local args = { "Purchase", { ModifierId = modId } }
                    Networking.WinterZombies.ModifierMachineEvent:FireServer(unpack(args))
                    task.wait(0.5)
                end
                Progress.ModifiersBought = true
            end

            if Config.MysteryBoxSpam and Progress.Lane3Bought and money >= 10000 then
                TeleportTo(workspace.Map.Interactions.MysteryBox1.CrateBottom.Position); task.wait(1)
                Interact(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.ProximityPrompt); task.wait(3)
                
                pcall(function()
                    for i = 1, 6 do
                        local slot = LocalPlayer.PlayerGui.Hotbar.Main.Units[tostring(i)]
                        if slot and slot.UnitTemplate.Container.Holder.Main:FindFirstChild("UnitName") then
                            local unitName = slot.UnitTemplate.Container.Holder.Main.UnitName.Text
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
