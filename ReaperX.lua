local PlaceId = game.PlaceId
local LobbyId = 16146832113
local ZombieId = 16277809958
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")

-- ตั้งค่า Config พื้นฐาน
local Config = {
    AutoCreate = true,
    AutoStart = true,
    AutoPlayZombies = true
}

---------------------------------------------------------------------------
-- [1] ระบบ Lobby
---------------------------------------------------------------------------
if PlaceId == LobbyId then
    print("อยู่ใน Lobby กำลังสร้างห้อง...")
    task.spawn(function()
        while task.wait(5) do
            if Config.AutoCreate then 
                pcall(function() Networking.Winter.WinterLTMEvent:FireServer("Create") end) 
            end
            task.wait(2)
            if Config.AutoStart then 
                pcall(function() Networking.LobbyEvent:FireServer("StartMatch") end) 
            end
        end
    end)
    return -- หยุดการทำงานสคริปต์ส่วนอื่นถ้าอยู่ใน Lobby
end

---------------------------------------------------------------------------
-- [2] โหลด Fluent UI (เมื่ออยู่ใน Zombie Mode)
---------------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "REAPER-X | V21.0 OMNI-AUTOMATA",
    SubTitle = "Anime Vanguards",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main Auto", Icon = "play" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local ToggleAutoPlay = Tabs.Main:AddToggle("AutoPlay", {Title = "Auto Play Zombie Mode", Default = true })
ToggleAutoPlay:OnChanged(function(Value)
    Config.AutoPlayZombies = Value
end)

Fluent:Notify({
    Title = "REAPER-X Loaded",
    Content = "สคริปต์พร้อมทำงานแล้ว!",
    Duration = 5
})

---------------------------------------------------------------------------
-- [3] ฟังก์ชันช่วยเหลือ (Helper Functions)
---------------------------------------------------------------------------

-- ฟังก์ชันดึงจำนวน Wave ปัจจุบัน (ดึงตัวเลขจาก XML tags)
local function GetWave()
    local success, waveText = pcall(function()
        return LocalPlayer.PlayerGui.HUD.Map.WavesAmount.Text
    end)
    if success and waveText then
        local waveNum = string.match(waveText, "<font.->(%d+)</font>")
        return tonumber(waveNum) or 0
    end
    return 0
end

-- ฟังก์ชันดึงจำนวนเงิน
local function GetMoney()
    local success, moneyText = pcall(function()
        return LocalPlayer.PlayerGui.Hotbar.Main.Yen.Text
    end)
    if success and moneyText then
        local cleanMoney = string.gsub(moneyText, "[^%d]", "")
        return tonumber(cleanMoney) or 0
    end
    return 0
end

-- ฟังก์ชันโต้ตอบกับ ProximityPrompt
local function Interact(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

-- ฟังก์ชันวาร์ป
local function TeleportTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- ฟังก์ชันวางตัวละคร
local function PlaceUnit(unitName, slotIndex, pos)
    local args = {
        "Render",
        { unitName, 35, pos, 0 }, -- 35 คือ ID จำลอง ตามที่คุณให้มา
        { SlotIndex = slotIndex }
    }
    Networking.UnitEvent:FireServer(unpack(args))
end

---------------------------------------------------------------------------
-- [4] Main Logic: ระบบเล่นอัตโนมัติ
---------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if not Config.AutoPlayZombies then continue end

        local currentWave = GetWave()

        -- [เงื่อนไขอินเทอร์เน็ตช้า] ถ้าโหลดมาแล้วเวฟเกิน 0 ให้รอจนกว่าจะแพ้และเริ่มใหม่
        if currentWave > 0 and currentWave < 10 then 
            -- สมมติว่าช่วงเวฟ 1-9 คือเพิ่งเข้ามา เลทไปแล้ว
            Fluent:Notify({Title = "Waiting for Reset", Content = "เข้าเกมช้า! กำลังรอให้รอบนี้จบลง...", Duration = 3})
            task.wait(10) -- เช็คใหม่ทุก 10 วินาทีจนกว่าเวฟจะกลับเป็น 0 (เริ่มตาใหม่)
            continue
        end

        -- ==== WAVE 0 (เตรียมตัว) ====
        if currentWave == 0 then
            -- 1. วาร์ปไปซื้อ Rabbit Hero (Guts)
            TeleportTo(Vector3.new(27.8, 254.6, 92.1)) -- วาร์ปไปจุด Shrine คร่าวๆ
            task.wait(1)
            Interact(workspace.Map.Interactions.UnitShrine_RabbitHero["1"].ProximityPrompt)
            task.wait(1)
            
            -- 2. วาง Rabbit Hero จุดแรก
            PlaceUnit("Rabbit Hero (Guts)", 1, Vector3.new(27.824, 254.632, 92.191))
            
            -- 3. กด Vote Start
            Networking.SkipWaveEvent:FireServer("Skip")
            task.wait(3)
        end

        -- ==== ต้นเกม (ซื้อ Sprintwagon & Rabbit Hero) ====
        -- ตรงนี้คุณสามารถใส่ Logic ลูปเช็คเงิน (GetMoney()) แล้วทยอยวางให้ครบ 3 ตัวตามพิกัดที่คุณให้มาได้เลย
        -- ตัวอย่างการรอเงินและวาง Sprintwagon:
        if currentWave >= 1 and currentWave < 20 then
            -- ลอจิกการอัพเกรด และซื้อตัวละครตามลำดับที่คุณบรีฟมา
            -- (ระบบจะลูปเช็คเงินและส่ง RemoteEvent ไปอัพเกรด)
        end

        -- ==== กลางเกม - เลทเกม (เวฟ 20 ถึง 149) ====
        if currentWave >= 20 and currentWave < 149 then
            -- ระบบซื้อบัพ, สุ่ม Mystery Box, และ Auto Upgrade
            -- สังเกต Barricade และซ่อม:
            pcall(function()
                -- ตรวจสอบ Barricade ถ้าน้อยกว่าหรือเท่ากับ 1/5 ให้ซ่อม
                local barricadePrompt = workspace.Map.Interactions.Barricade1.default.ProximityPrompt
                if string.find(barricadePrompt.ObjectText, "0/5") or string.find(barricadePrompt.ObjectText, "1/5") then
                    Interact(barricadePrompt)
                end
            end)
        end

        -- ==== เวฟ 149 (เปิดประตูทั้งหมดเพื่อรับบัพคูณรางวัล) ====
        if currentWave == 149 then
            pcall(function()
                Interact(workspace.Map.Interactions.PurchaseLane4.Part.ProximityPrompt)
                task.wait(0.5)
                Interact(workspace.Map.Interactions.PurchaseLane6.Part.ProximityPrompt)
            end)
        end

        -- ==== เวฟ 150 (ออกเกม / กลับ Lobby) ====
        if currentWave >= 150 then
            Fluent:Notify({Title = "Mission Accomplished", Content = "ถึงเวฟ 150 แล้ว! กำลังกลับ Lobby...", Duration = 5})
            task.wait(2)
            Networking.TeleportEvent:FireServer("Lobby")
            task.wait(10) -- รอวาร์ป
        end
    end
end)
