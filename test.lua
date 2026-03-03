local PlaceId = game.PlaceId
local LobbyId = 16146832113
local ZombieId = 16277809958
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local FileName = "ReaperX_Config.json" -- ชื่อไฟล์ที่จะเซฟลงในเครื่อง
---------------------------------------------------------------------------
-- [ Anti-AFK & Auto Reconnect ]
---------------------------------------------------------------------------
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("Anti-AFK ทำงาน")
end)

local Config = {
    AutoCreate = true,
    AutoStart = true,
    AutoPlayZombies = true,
    AutoUpgrade = true,
    AutoPriority = true,
    AutoSkill = true,
    MysteryBoxSpam = true,
    AutoBuyModifiers = true,
    AutoReconnect = true,
    WebhookURL = ""
}

-- ระบบ Auto Reconnect (ทำงานเมื่อหน้าจอหลุดการเชื่อมต่อ)
GuiService.ErrorMessageChanged:Connect(function()
    if Config.AutoReconnect then
        task.wait(2)
        TeleportService:Teleport(LobbyId, LocalPlayer)
    end
end)
-- 2. ฟังก์ชันโหลดค่าที่เคยเซฟไว้
local function LoadConfig()
    -- เช็คว่ามีไฟล์นี้อยู่ในเครื่องไหม
    if isfile and isfile(FileName) then
        local success, decoded = pcall(function()
            -- อ่านไฟล์และแปลง JSON กลับมาเป็นตาราง
            return HttpService:JSONDecode(readfile(FileName))
        end)
        
        -- ถ้าโหลดสำเร็จ ให้นำค่าที่โหลดมา ทับค่าเริ่มต้น
        if success and type(decoded) == "table" then
            for key, value in pairs(decoded) do
                Config[key] = value
            end
            print("โหลดการตั้งค่าสำเร็จ!")
        end
    end
end

-- 3. ฟังก์ชันเซฟค่าลงเครื่อง
local function SaveConfig()
    if writefile then
        local success, encoded = pcall(function()
            -- แปลงตาราง Config ให้เป็น JSON
            return HttpService:JSONEncode(Config)
        end)
        
        if success then
            writefile(FileName, encoded) -- เซฟทับไฟล์เดิม
        end
    end
end
LoadConfig()

-- ฟังก์ชันส่งข้อความเข้า Discord Webhook
local function SendWebhook(message)
    if Config.WebhookURL and Config.WebhookURL ~= "" then
        pcall(function()
            local data = {
                ["content"] = message,
                ["username"] = "REAPER-X BOT"
            }
            local headers = { ["content-type"] = "application/json" }
            local requestFunc = http_request or request or HttpPost
            if requestFunc then
                requestFunc({Url = Config.WebhookURL, Body = HttpService:JSONEncode(data), Method = "POST", Headers = headers})
            end
        end)
    end
end

local Progress = {}
local ProcessedUnits = {}

local function ResetData()
    Progress = {
        FirstRabbitPlaced = false,
        SprintwagonsPlaced = 0,
        SprintwagonsMaxed = false,
        RabbitsPlaced = 1,
        TakarodaPlaced = 0,
        Lane2Bought = false,
        Lane3Bought = false,
        ModifiersBought = false,
        LateGameDoorsBought = false,
        LichSpellsConfirmed = false,
        BoughtFortuneCity = false,
        BoughtFastHands = false,
        BoughtEagleEyed = false,
        BoughtHeavyHitter = false,
        BoughtArmorBeGone = false
    }

    ProcessedUnits = {
        Upgrade = {},
        Priority = {},
        EquipSkill = {},
        PackATrait = {}
    }
end

ResetData()

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
    ["Koguro (Unsealed)"] = 235,
    ["Ice Queen (Release)"] = 363
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
    Title = "REAPER-X | V22.0 OMNI-AUTOMATA", SubTitle = "Humanized Edition",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl
})
local Tabs = { 
    Main = Window:AddTab({ Title = "Main Auto", Icon = "play" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "link" })
}

-- แท็บ Main
Tabs.Main:AddToggle("AutoPlay", {Title = "Auto Play Zombie Mode", Default = Config.AutoPlayZombies }):OnChanged(function(v) Config.AutoPlayZombies = v SaveConfig() end)
Tabs.Main:AddToggle("AutoUp", {Title = "In-Game Auto Upgrade", Default = Config.AutoUpgrade }):OnChanged(function(v) Config.AutoUpgrade = v SaveConfig() end)
Tabs.Main:AddToggle("AutoSkill", {Title = "Auto Use Unit Skills", Default = Config.AutoSkill }):OnChanged(function(v) Config.AutoSkill = v SaveConfig() end)
Tabs.Main:AddToggle("SpamBox", {Title = "Spam Mystery Box & Place", Default = Config.MysteryBoxSpam }):OnChanged(function(v) Config.MysteryBoxSpam = v SaveConfig() end)

-- แท็บ Misc
Tabs.Misc:AddToggle("AutoRecon", {Title = "Auto Reconnect & Execute", Default = Config.AutoReconnect }):OnChanged(function(v) Config.AutoReconnect = v SaveConfig() end)

-- แท็บ Webhook
Tabs.Webhook:AddInput("WebURL", {
    Title = "Discord Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        Config.WebhookURL = Value
        SaveConfig()
        SendWebhook("✅ เชื่อมต่อ Webhook สำเร็จแล้ว ระบบพร้อมทำงาน!")
    end
})

Fluent:Notify({ Title = "REAPER-X V22", Content = "ระบบพร้อมทำงาน (ปลอดภัยขั้นสุด)!", Duration = 5 })

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
    local cleanText = string.gsub(text, "[^%d]", "")
    return tonumber(cleanText) or 0
end

local function Interact(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then fireproximityprompt(prompt, 1) end
end

local TweenService = game:GetService("TweenService")

local function TweenTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local distance = (hrp.Position - pos).Magnitude
        
        -- ถ้าระยะห่างมากกว่า 5 หน่วย ค่อย Tween
        if distance > 5 then
            -- [ หัวใจสำคัญ: คำนวณเวลาให้เนียน ]
            -- สมมติให้ความเร็ว = 30 หน่วยต่อวินาที (เร็วกว่าเดินปกตินิดหน่อยแต่ไม่เว่อร์)
            local speed = 30 
            local timeToTake = distance / speed
            
            -- สร้างรูปแบบการ Tween (ให้เคลื่อนที่ด้วยความเร็วคงที่ Linear)
            local tweenInfo = TweenInfo.new(timeToTake, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
            
            tween:Play()
            tween.Completed:Wait() -- รอจนกว่าตัวละครจะสไลด์ไปถึงเป้าหมาย
            task.wait(0.2)
        end
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

local function ClickButton(btn)
    if not btn then return end
    pcall(function()
        if getconnections then
            for _, connection in pairs(getconnections(btn.MouseButton1Click)) do connection:Fire() end
            for _, connection in pairs(getconnections(btn.Activated)) do connection:Fire() end
            for _, connection in pairs(getconnections(btn.MouseButton1Down)) do connection:Fire() end
            for _, connection in pairs(getconnections(btn.MouseButton1Up)) do connection:Fire() end
        end
    end)
end

---------------------------------------------------------------------------
-- [4] Background Tasks (Auto Upgrade, Priority, Skills & Defense)
---------------------------------------------------------------------------
task.spawn(function()
    local KoguroDomains = {"Fire", "Ice", "Sand"}
    local domainIndex = 1

    while task.wait(3) do
        if not Config.AutoPlayZombies then continue end
        local uids = GetAllMyUnitUIDs()
        local hasLichKing = false

        for _, uid in pairs(uids) do
            local unitFolder = workspace.Units:FindFirstChild(uid)
            local unitName = ""

            if unitFolder then
                for _, child in pairs(unitFolder:GetChildren()) do
                    if string.find(child.Name, "Warlord") or string.find(child.Name, "Koguro") or
                       string.find(child.Name, "Trash Gamer") or string.find(child.Name, "Lich King") or
                       string.find(child.Name, "Ice Queen") then
                        unitName = child.Name
                        break
                    end
                end
            end

            if Config.AutoUpgrade and not ProcessedUnits.Upgrade[uid] then
                pcall(function() Networking.Units.AutoUpgradeEvent:FireServer("Toggle", uid) end)
                ProcessedUnits.Upgrade[uid] = true
            end

            if Config.AutoPriority and not ProcessedUnits.Priority[uid] then
                pcall(function()
                    local targetPriority = string.find(unitName, "Warlord") and "Closest" or "First"
                    Networking.UnitEvent:FireServer("ChangePriority", uid, targetPriority)
                end)
                ProcessedUnits.Priority[uid] = true
            end

            if Config.AutoSkill and unitName ~= "" then
                pcall(function()
                    if string.find(unitName, "Koguro") then
                        Networking.Units["Update 6.5"].Koguro_DomainEvent:FireServer("ActivateDomain", KoguroDomains[domainIndex], uid)
                    elseif string.find(unitName, "Trash Gamer") then
                        if not ProcessedUnits.EquipSkill[uid] then
                            Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Primary", 3)
                            Networking.Units["Update 10.5"].EquipSkill:FireServer(uid, "Secondary", 3)
                            ProcessedUnits.EquipSkill[uid] = true
                        end
                    elseif string.find(unitName, "Lich King") then
                        hasLichKing = true
                        local wave = GetWave()
                        if wave > 0 and wave % 10 == 0 then
                            Networking.AbilityEvent:FireServer("Activate", uid, "The Goal of All Life is Death")
                        end
                    elseif string.find(unitName, "Ice Queen") then
                        Networking.AbilityEvent:FireServer("Activate", uid, "Frozen World")
                    end
                end)
            end
            task.wait(0.1)
        end

        domainIndex = domainIndex >= 3 and 1 or domainIndex + 1

        if Config.AutoSkill and hasLichKing and not Progress.LichSpellsConfirmed then
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
                    if string.find(prompt.ObjectText, "0/5") then
                        TweenTo(workspace.Map.Interactions["Barricade"..i].default.Position)
                        Interact(prompt)
                        task.wait(1)
                    end
                end
            end)
        end

        if wave >= 100 and wave % 10 == 0 then
            pcall(function()
                local trapPrompt = workspace.Map.Interactions.Trap2.Part.ProximityPrompt
                if string.find(trapPrompt.ObjectText, "ACTIVE") then
                    TweenTo(workspace.Map.Interactions.Trap2.Part.Position)
                    Interact(trapPrompt)
                    task.wait(1)
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

    while task.wait(1) do
        if not Config.AutoPlayZombies then continue end
        local currentWave = GetWave()
        local money = GetMoney()

        local endScreen = LocalPlayer.PlayerGui:FindFirstChild("EndScreen")
        local rewardsDisplay = LocalPlayer.PlayerGui:FindFirstChild("RewardsDisplay") 

        local isEndScreenOpen = endScreen and endScreen.Enabled
        local isRewardsOpen = rewardsDisplay and rewardsDisplay.Enabled

        -- [ อัปเดต ] ลอจิกรอจบเกมและกดข้าม Rewards
        if isEndScreenOpen or isRewardsOpen then
            if currentWave < 150 then
                SendWebhook("💀 ฐานแตกที่ Wave: " .. currentWave .. " กำลังเริ่มรอบใหม่...")
            end
            ResetData()
            
           if isRewardsOpen then
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    local cam = workspace.CurrentCamera
                    local x = cam.ViewportSize.X / 2
                    local y = cam.ViewportSize.Y / 2
                    
                    local timeout = 0
                    while rewardsDisplay and rewardsDisplay.Enabled and timeout < 20 do
                        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
                        task.wait(0.1)
                        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
                        task.wait(0.4) 
                        timeout = timeout + 1 
                    end
                end)
            end
            
            task.wait(1)
            if endScreen then
                pcall(function() ClickButton(endScreen.Holder.Buttons.Retry.Button) end)
            end
            task.wait(3)
            continue
        end

        if currentWave > 0 and currentWave < 10 and not Progress.FirstRabbitPlaced then
            task.wait(1)
            continue
        end

        if currentWave == 0 and not Progress.FirstRabbitPlaced then
            TweenTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position)
            Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt)
            task.wait(1)

            local unitsBefore = #workspace.Units:GetChildren()
            PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[1], UnitDatabase["Rabbit Hero (Guts)"])
            task.wait(2)

            if #workspace.Units:GetChildren() > unitsBefore then
                Progress.FirstRabbitPlaced = true
                Networking.SkipWaveEvent:FireServer("Skip"); task.wait(3)
                SendWebhook("🚀 เริ่มฟาร์มรอบใหม่แล้ว!")
            end
        end

        if currentWave >= 1 and currentWave < 20 then
            if Progress.SprintwagonsPlaced < 3 and money >= 1000 then
                TweenTo(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].Position)
                Interact(workspace.Map.Interactions.UnitShrine_Sprintwagon["1"].ProximityPrompt); task.wait(1)

                if money >= 550 then
                    local index = Progress.SprintwagonsPlaced + 1
                    local unitsBefore = #workspace.Units:GetChildren()
                    PlaceUnit("Sprintwagon", 1, SprintwagonCoords[index], UnitDatabase["Sprintwagon"])
                    task.wait(2)
                    if #workspace.Units:GetChildren() > unitsBefore then Progress.SprintwagonsPlaced = index end
                end
            elseif Progress.RabbitsPlaced < 3 and money >= 500 then
                TweenTo(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].Position)
                Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt); task.wait(1)

                if money >= 1200 then
                    local index = Progress.RabbitsPlaced + 1
                    local unitsBefore = #workspace.Units:GetChildren()
                    PlaceUnit("Rabbit Hero (Guts)", 1, RabbitCoords[index], UnitDatabase["Rabbit Hero (Guts)"])
                    task.wait(2)
                    if #workspace.Units:GetChildren() > unitsBefore then Progress.RabbitsPlaced = index end
                end
            elseif not Progress.SprintwagonsMaxed then
                if money > 8000 then Progress.SprintwagonsMaxed = true end
            elseif Progress.TakarodaPlaced < 1 then
                TweenTo(workspace.Map.Interactions.UnitShrine_Takaroda["1"].Position)
                Interact(workspace.Map.Interactions.UnitShrine_Takaroda["1"].ProximityPrompt); task.wait(1)

                local unitsBefore = #workspace.Units:GetChildren()
                PlaceUnit("Takaroda", 1, Vector3.new(-22.70, 253.16, 49.12), UnitDatabase["Takaroda"])
                task.wait(2)
                if #workspace.Units:GetChildren() > unitsBefore then Progress.TakarodaPlaced = 1 end
            end
        end

        if currentWave >= 20 and currentWave < 149 then
            if not Progress.Lane2Bought and money >= 5000 then
                TweenTo(workspace.Map.Interactions.PurchaseLane2.Part.Position)
                Interact(workspace.Map.Interactions.PurchaseLane2.Part.ProximityPrompt); Progress.Lane2Bought = true
            elseif Progress.Lane2Bought and not Progress.Lane3Bought and money >= 10000 then
                TweenTo(workspace.Map.Interactions.PurchaseLane3.Part.Position)
                Interact(workspace.Map.Interactions.PurchaseLane3.Part.ProximityPrompt); Progress.Lane3Bought = true
            end

            if Config.AutoBuyModifiers and Progress.Lane3Bought then
                if not Progress.BoughtFortuneCity and money >= 10000 then
                    Networking.WinterZombies.ModifierMachineEvent:FireServer("Purchase", { ModifierId = "FortuneCity" })
                    Progress.BoughtFortuneCity = true; task.wait(1)
                elseif Progress.BoughtFortuneCity and not Progress.BoughtFastHands and money >= 50000 then
                    Networking.WinterZombies.ModifierMachineEvent:FireServer("Purchase", { ModifierId = "FastHands" })
                    Progress.BoughtFastHands = true; task.wait(1)
                elseif Progress.BoughtFastHands and not Progress.BoughtEagleEyed and money >= 50000 then
                    Networking.WinterZombies.ModifierMachineEvent:FireServer("Purchase", { ModifierId = "EagleEyed" })
                    Progress.BoughtEagleEyed = true; task.wait(1)
                elseif Progress.BoughtEagleEyed and not Progress.BoughtHeavyHitter and money >= 50000 then
                    Networking.WinterZombies.ModifierMachineEvent:FireServer("Purchase", { ModifierId = "HeavyHitter" })
                    Progress.BoughtHeavyHitter = true; task.wait(1)
                elseif Progress.BoughtHeavyHitter and not Progress.BoughtArmorBeGone and money >= 100000 then
                    Networking.WinterZombies.ModifierMachineEvent:FireServer("Purchase", { ModifierId = "ArmorBeGone" })
                    Progress.BoughtArmorBeGone = true; task.wait(1)
                end
            end

            -- [ ลอจิกใหม่: บัพเหมาเข่งทุกตัวบนบอร์ด (เพราะเรารวย!) ]
            if Config.AutoBuyModifiers and Progress.BoughtArmorBeGone then
                local targetUid = nil
                
                -- 1. ค้นหา UID ที่ยังไม่ได้บัพ
                for _, uid in pairs(GetAllMyUnitUIDs()) do
                    if not ProcessedUnits.PackATrait[uid] then
                        targetUid = uid
                        break 
                    end
                end

                -- 2. วิ่งไปซื้อบัพให้ตัวที่ยังไม่ได้รับ
                if targetUid and money >= 50000 then
                    TweenTo(workspace.Map.Interactions.PackATrait1["Cube.005"].Position)
                    Interact(workspace.Map.Interactions.PackATrait1["Cube.005"].ProximityPrompt)
                    task.wait(2)

                    pcall(function()
                        -- [แก้ปัญหา 1] ดับเบิลเช็คยอดเงิน ก่อนตัดสินใจกด UI
                        local currentMoney = GetMoney()
                        if currentMoney < 50000 then
                            return -- ยกเลิกการกดปุ่ม UI
                        end

                        ClickButton(LocalPlayer.PlayerGui.Guides.List.StageInfo.Buttons.UnitManager.Button)
                        task.wait(2)

                        local unitManager = LocalPlayer.PlayerGui:FindFirstChild("UnitManager")
                        if unitManager then
                            local unitListItem = unitManager.Holder.List:FindFirstChild(targetUid)
                            if unitListItem and unitListItem:FindFirstChild("Unit") then
                                for _, child in pairs(unitListItem.Unit:GetChildren()) do
                                    if child:FindFirstChild("Container") and child.Container:FindFirstChild("Button") then
                                        
                                        ClickButton(child.Container.Button)
                                        
                                        -- [แก้ปัญหา 1] ย้ายการมาร์คว่าสำเร็จมาไว้ตรงนี้ เพื่อให้แน่ใจว่าได้กดปุ่มไปแล้วจริงๆ
                                        ProcessedUnits.PackATrait[targetUid] = true
                                        
                                        task.wait(1)
                                        break
                                    end
                                end
                            end
                            ClickButton(unitManager.Holder.Back.Button)
                        end
                    end)
                    
                    task.wait(2)

                -- 3. [แก้ปัญหา 2] ถ้าบัพครบหมดแล้ว และตัวยังไม่ตัน 25 ให้พุ่งไปสุ่มตู้ทันที (ถอดล็อกเวฟ 90-105 ออกแล้ว)
                elseif not targetUid and #workspace.Units:GetChildren() < 25 and Config.MysteryBoxSpam and money >= 10000 then
                    TweenTo(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.Position)
                    
                    local timesToSpam = (money >= 50000) and 10 or 1
                    for _ = 1, timesToSpam do
                        Interact(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.ProximityPrompt)
                        task.wait(0.2)
                    end
                    task.wait(2)

                    pcall(function()
                            for i = 1, 6 do
                                if #workspace.Units:GetChildren() >= 25 then break end
                                
                                local slot = LocalPlayer.PlayerGui.Hotbar.Main.Units[tostring(i)]
                                
                                -- เช็คให้ชัวร์ว่าช่องนี้มีตัวละครอยู่จริงๆ (ไม่พังถ้าช่องว่าง)
                                if slot and slot:FindFirstChild("UnitTemplate") and slot.UnitTemplate:FindFirstChild("Container") then
                                    local mainHolder = slot.UnitTemplate.Container.Holder:FindFirstChild("Main")
                                    if mainHolder and mainHolder:FindFirstChild("UnitName") then
                                        local unitName = mainHolder.UnitName.Text

                                        if UnitDatabase[unitName] and unitName ~= "Sprintwagon" and unitName ~= "Takaroda" and unitName ~= "Rabbit Hero (Guts)" then
                                            
                                            -- [ อัปเดต ] ระบบ Retry ลองวางซ้ำสูงสุด 3 รอบ
                                            local retryCount = 0
                                            local placedSuccessfully = false

                                            while retryCount < 15 and not placedSuccessfully do
                                                -- สุ่มพิกัดใหม่ "ทุกครั้ง" ที่ลองวางเผื่อจุดเดิมมันบัค
                                                local randomPos = Vector3.new(8.12 + (math.random(-150, 150) / 10), 255.58, 97.70 + (math.random(-150, 150) / 10))
                                                local unitsBefore = #workspace.Units:GetChildren()
                                                
                                                PlaceUnit(unitName, i, randomPos, UnitDatabase[unitName])
                                                task.wait(1.5)
                                                
                                                -- ถ้าจำนวนตัวละครบนบอร์ดเพิ่มขึ้น = วางสำเร็จ!
                                                if #workspace.Units:GetChildren() > unitsBefore then
                                                    placedSuccessfully = true
                                                else
                                                    -- ถ่ายังวางไม่ลง ให้บวกเลขแล้วลองวนลูปวางใหม่
                                                    retryCount = retryCount + 1
                                                end
                                            end
                                            
                                        end
                                    end
                                end
                            end
                        end)
                end
            end
        end

        if currentWave == 149 and not Progress.LateGameDoorsBought then
            pcall(function()
                TweenTo(workspace.Map.Interactions.PurchaseLane4.Part.Position)
                Interact(workspace.Map.Interactions.PurchaseLane4.Part.ProximityPrompt)
                task.wait(1)
                Interact(workspace.Map.Interactions.PurchaseLane5.Part.ProximityPrompt)

                TweenTo(workspace.Map.Interactions.PurchaseLane6.Part.Position)
                Interact(workspace.Map.Interactions.PurchaseLane6.Part.ProximityPrompt)
                task.wait(1)
                Interact(workspace.Map.Interactions.PurchaseLane7.Part.ProximityPrompt)
            end)
            Progress.LateGameDoorsBought = true
        end

        if currentWave >= 150 then
            SendWebhook("👑 ชนะเวฟ 150 สำเร็จ! รับเหรียญจุกๆ แล้วกำลังกลับไป Lobby...")
            task.wait(3)
            Networking.TeleportEvent:FireServer("Lobby")
            task.wait(10)
        end
    end
end)
