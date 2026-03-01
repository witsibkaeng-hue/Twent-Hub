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
    AutoUpgrade = false,
    AutoPriority = true,
    AutoSkill = false,
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
    if not success or not text then return 0 end
    
    local cleanText = string.gsub(text, "[^%d]", "") -- ลบตัวอักษรทิ้ง เหลือแต่ "17440"
    return tonumber(cleanText) or 0 -- แปลงเป็นตัวเลขปกติ
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
    
    local ProcessedUnits = {
        Upgrade = {},
        Priority = {},
        EquipSkill = {}
    }

    while task.wait(3) do
        if not Config.AutoPlayZombies then continue end
        local uids = GetAllMyUnitUIDs()
        
        local hasLichKing = false -- เอาไว้เช็คว่าต้องยืนยันคาถาไหม

        for _, uid in pairs(uids) do
            -- หาชื่อโมเดลตัวละครจากโฟลเดอร์ UID
            local unitFolder = workspace.Units:FindFirstChild(uid)
            local unitName = ""
            
            if unitFolder then
                for _, child in pairs(unitFolder:GetChildren()) do
                    -- เช็คหาชื่อตัวละครที่เราตั้งเงื่อนไขพิเศษไว้
                    if string.find(child.Name, "Warlord") or 
                       string.find(child.Name, "Koguro") or 
                       string.find(child.Name, "Trash Gamer") or 
                       string.find(child.Name, "Lich King") then
                        unitName = child.Name
                        break
                    end
                end
            end

            -- 1. Auto Upgrade
            if Config.AutoUpgrade and not ProcessedUnits.Upgrade[uid] then
                pcall(function() Networking.Units.AutoUpgradeEvent:FireServer("Toggle", uid) end)
                ProcessedUnits.Upgrade[uid] = true
            end
            
            -- 2. Auto Priority
            if Config.AutoPriority and not ProcessedUnits.Priority[uid] then
                pcall(function()
                    -- ถ้าชื่อมีคำว่า Warlord ให้เป็น Closest ถ้าไม่ใช่ให้เป็น First
                    local targetPriority = string.find(unitName, "Warlord") and "Closest" or "First"
                    Networking.UnitEvent:FireServer("ChangePriority", uid, targetPriority)
                end)
                ProcessedUnits.Priority[uid] = true
            end
            
            -- 3. Auto Skills (เช็คชื่อก่อนยิงสกิล)
            if Config.AutoSkill and unitName ~= "" then
                pcall(function()
                    if string.find(unitName, "Koguro") then
                        -- วนสลับโดเมนให้ Koguro [cite: 1]
                        Networking.Units["Update 6.5"].Koguro_DomainEvent:FireServer("ActivateDomain", KoguroDomains[domainIndex], uid) [cite: 1]
                        
                    elseif string.find(unitName, "Trash Gamer") then
                        -- สวมใส่สกิลให้ Trash Gamer ทำครั้งเดียว [cite: 2]
                        if not ProcessedUnits.EquipSkill[uid] then
                            Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Primary", 3) [cite: 2]
                            Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Secondary", 3) [cite: 2]
                            ProcessedUnits.EquipSkill[uid] = true
                        end
                        
                    elseif string.find(unitName, "Lich King") then
                        hasLichKing = true -- เจอ Lich King แล้ว
                        local wave = GetWave()
                        if wave > 0 and wave % 10 == 0 then
                            -- ใช้สกิลไม้ตายเฉพาะเวฟบอส 
                            Networking.AbilityEvent:FireServer("Activate", uid, "The Goal of All Life is Death") [cite: 3]
                        end
                    end
                end)
            end
            task.wait(0.1)
        end
        
        -- สลับโดเมน Koguro รอบถัดไป
        domainIndex = domainIndex >= 3 and 1 or domainIndex + 1

        -- เซ็ตคาถาเวทมนตร์ให้ Lich King (ทำเมื่อมี Lich King บนบอร์ดเท่านั้น) 
        if Config.AutoSkill and hasLichKing and not Progress.LichSpellsConfirmed then
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
        -- print("Current Wave:", currentWave, "Money:", money)

        -- [ เช็ค Standby รอรีเซ็ตเวฟ และรอให้หน้าจอ EndScreen ขึ้น ]
        if currentWave > 0 and currentWave < 10 and not Progress.FirstRabbitPlaced then
            local endScreen = LocalPlayer.PlayerGui:FindFirstChild("EndScreen")
            if not (endScreen and endScreen.Enabled) then
                task.wait(0.2)
                continue
            end
        end

        -- [ เวฟ 0 ]
        if currentWave == 0 and not Progress.FirstRabbitPlaced then
            TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(1)
            Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
            
            -- นับจำนวนยูนิตก่อนวาง
            local unitsBefore = #workspace.Units:GetChildren()
            PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[1], UnitDatabase["Rabbit Hero (Guts)"])
            task.wait(2) -- รอเซิร์ฟเวอร์ประมวลผลการวาง
            
            -- เช็คว่ายูนิตเพิ่มขึ้นไหม
            if #workspace.Units:GetChildren() > unitsBefore then
                Progress.FirstRabbitPlaced = true
                Networking.SkipWaveEvent:FireServer("Skip"); task.wait(3)
                print("Placed first Rabbit Hero successfully and skipped to wave 1")
            else
                print("Failed to place Rabbit Hero! Retrying in next loop...")
            end
        end

        -- [ ต้นเกม: ตั้งบอร์ด ]
        if currentWave >= 1 and currentWave < 20 then
            if Progress.SprintwagonsPlaced < 3 and money >= 1000 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].ProximityPrompt); task.wait(1)
                
                if money >= 550 then
                    local index = Progress.SprintwagonsPlaced + 1
                    local unitsBefore = #workspace.Units:GetChildren()
                    PlaceUnit("Sprintwagon", 1, SprintwagonCoords[index], UnitDatabase["Sprintwagon"])
                    task.wait(2)
                    
                    if #workspace.Units:GetChildren() > unitsBefore then
                        Progress.SprintwagonsPlaced = index
                        print("Successfully placed Sprintwagon number:", index)
                    else
                        print("Failed to place Sprintwagon number", index, "Retrying...")
                    end
                end
                
            elseif Progress.RabbitsPlaced < 3 and money >= 500 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)
                
                if money >= 1200 then
                    local index = Progress.RabbitsPlaced + 1
                    local unitsBefore = #workspace.Units:GetChildren()
                    PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[index], UnitDatabase["Rabbit Hero (Guts)"])
                    task.wait(2)
                    
                    if #workspace.Units:GetChildren() > unitsBefore then
                        Progress.RabbitsPlaced = index
                        print("Successfully placed Rabbit Hero number:", index)
                    else
                        print("Failed to place Rabbit Hero number", index, "Retrying...")
                    end
                end
                
            elseif not Progress.SprintwagonsMaxed then
                if money > 8000 then Progress.SprintwagonsMaxed = true end
                
            elseif Progress.TakarodaPlaced < 1 then
                TeleportTo(workspace.Map.Interactions.UnitShrine_Takaroda["1"].Position); task.wait(0.5)
                Interact(workspace.Map.Interactions.UnitShrine_Takaroda["1"].ProximityPrompt); task.wait(1)
                
                local unitsBefore = #workspace.Units:GetChildren()
                PlaceUnit("Takaroda", 1, Vector3.new(-22.70, 253.16, 49.12), UnitDatabase["Takaroda"])
                task.wait(2)
                
                if #workspace.Units:GetChildren() > unitsBefore then
                    Progress.TakarodaPlaced = 1
                    print("Successfully placed Takaroda")
                else
                    print("Failed to place Takaroda! Retrying...")
                end
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
                                local unitsBefore = #workspace.Units:GetChildren()
                                PlaceUnit(unitName, i, randomPos, UnitDatabase[unitName])
                                task.wait(1)
                                
                                if #workspace.Units:GetChildren() > unitsBefore then
                                    print("Successfully spam-placed:", unitName)
                                end
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
