--========================================================================
-- SCRIPT V13 HORIZONTAL COMPACT: GIAO DIỆN NGANG + SONG NGỮ + FIX INF JUMP
--========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Khởi tạo các biến hệ thống
getgenv().waypoints = {}             
getgenv().currentWaypointIndex = 1   
getgenv().isFlyingWaypoints = false  
getgenv().isNoclip = false
getgenv().destroyWalls = false 
getgenv().destroyMonsters = false 
getgenv().isInfJump = false 
getgenv().flySpeed = 100

local FILE_NAME = "V13_Saved_Waypoints.json" 
local bv = nil
local flyConnection = nil
local noclipConnection = nil
local WaypointLabel = nil 

-- Hàm dọn dẹp lực bay
local function cleanupFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bv then bv:Destroy() bv = nil end
end

-- Hàm thực hiện logic bay chuỗi tuần tự + Tự động lặp lại (Loop) của V13
local function startFlyingWaypoints(char)
    cleanupFly()
    if not getgenv().isFlyingWaypoints or #getgenv().waypoints == 0 then return end

    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local lastIndex = 0

    flyConnection = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent or not getgenv().isFlyingWaypoints then cleanupFly() return end
        
        local targetPos = getgenv().waypoints[getgenv().currentWaypointIndex]
        
        if not targetPos then
            print("🔄 Đã hoàn thành chuỗi, tự động quay lại Điểm 1 để tiếp tục bay!")
            getgenv().currentWaypointIndex = 1 
            return
        end

        if WaypointLabel and getgenv().currentWaypointIndex ~= lastIndex then
            lastIndex = getgenv().currentWaypointIndex
            WaypointLabel.Text = "Đang bay: Điểm " .. lastIndex .. " / " .. #getgenv().waypoints .. "\n(Flying: Point " .. lastIndex .. ")"
        end

        local distance = (hrp.Position - targetPos).Magnitude

        if distance > 5 then
            local direction = (targetPos - hrp.Position).Unit
            bv.Velocity = direction * getgenv().flySpeed
            local flatTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
            hrp.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
        else
            bv.Velocity = Vector3.new(0, 0, 0)
            getgenv().currentWaypointIndex = getgenv().currentWaypointIndex + 1
            task.wait(0.1) 
        end
    end)
end

-- Vòng lặp Noclip xuyên vật thể liên tục
if noclipConnection then noclipConnection:Disconnect() end
noclipConnection = RunService.Stepped:Connect(function()
    if getgenv().isNoclip and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- LOGIC TÍNH NĂNG NHẢY VÔ HẠN (Đã sửa lỗi chính tả biến humanoid giúp hoạt động 100%)
UserInputService.JumpRequest:Connect(function()
    if getgenv().isInfJump and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Luồng diệt tường ngắt quãng thông minh
task.spawn(function()
    while true do
        if getgenv().destroyWalls then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if obj:FindFirstChild("TouchInterest") and not n:find("win") and not n:find("spawn") then
                        obj:Destroy()
                    end
                end
            end
            task.wait(1.5)
        else
            task.wait(0.5)
        end
    end
end)

-- Luồng diệt quái ngắt quãng thông minh
task.spawn(function()
    while true do
        if getgenv().destroyMonsters then
            for _, v in ipairs(Workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= player.Character then
                    v:Destroy()
                end
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end)

player.CharacterAdded:Connect(function(char)
    if getgenv().isFlyingWaypoints then
        task.wait(1.2) 
        startFlyingWaypoints(char)
    end
end)

-- HỆ THỐNG LƯU TRỮ JSON NGUYÊN BẢN
local function saveData()
    local success, err = pcall(function()
        local rawCoords = {}
        for _, v3 in ipairs(getgenv().waypoints) do
            table.insert(rawCoords, {x = v3.X, y = v3.Y, z = v3.Z})
        end
        local data = { speed = getgenv().flySpeed, coords = rawCoords }
        writefile(FILE_NAME, HttpService:JSONEncode(data))
    end)
    return success
end

local function loadData()
    if not isfile(FILE_NAME) then return false end
    local success, err = pcall(function()
        local content = readfile(FILE_NAME)
        local data = HttpService:JSONDecode(content)
        if data then
            getgenv().flySpeed = data.speed or 100
            getgenv().waypoints = {}
            for _, c in ipairs(data.coords) do
                table.insert(getgenv().waypoints, Vector3.new(c.x, c.y, c.z))
            end
        end
    end)
    return success
end

--========================================================================
-- GIAO DIỆN NGANG SIÊU COMPACT CỦA V13 (HỖ TRỢ SONG NGỮ DÒNG ĐÔI)
--========================================================================

if CoreGui:FindFirstChild("FlyCoordsMenuVIP") then
    CoreGui.FlyCoordsMenuVIP:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyCoordsMenuVIP"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 190) 
MainFrame.Position = UDim2.new(0.5, -240, 0.35, -95)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true 
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Thanh DragBar kéo thả độc lập
local DragBar = Instance.new("Frame", MainFrame)
DragBar.Size = UDim2.new(1, 0, 0, 40)
DragBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BAY VÒNG LẶP + LƯU ĐIỂM (LOOP FLY + WAYPOINTS) V13"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = DragBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Parent = DragBar

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- Hàm sinh nút tự động hỗ trợ hiển thị tên tiếng Anh ở dưới
local function createToggle(viName, enName, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 145, 0, 32)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = viName .. ": [TẮT]\n(" .. enName .. ": [OFF])"
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 10
    btn.TextWrapped = true
    btn.Parent = Container
    
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 5) corner.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = viName .. ": [BẬT]\n(" .. enName .. ": [ON])"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            btn.TextColor3 = Color3.fromRGB(255, 100, 100)
            btn.Text = viName .. ": [TẮT]\n(" .. enName .. ": [OFF])"
        end
        callback(state)
    end)
    return btn
end

-- ========================================================================
-- CHIA THÀNH 3 CỘT ĐỀU NHAU TRÊN GIAO DIỆN HÀNG NGANG
-- ========================================================================

-- CỘT 1: CHỨC NĂNG DI CHUYỂN CƠ BẢN (X = 0)
createToggle("Bay Vòng Lặp", "Loop Fly", UDim2.new(0, 0, 0, 0), function(state)
    getgenv().isFlyingWaypoints = state
    if state then
        if #getgenv().waypoints == 0 then
            print("⚠️ Bạn chưa có điểm nào!")
        else
            getgenv().currentWaypointIndex = 1 
            if player.Character then startFlyingWaypoints(player.Character) end
        end
    else
        cleanupFly()
    end
end)
createToggle("Xuyên Vật Thể", "Noclip", UDim2.new(0, 0, 0, 36), function(state) getgenv().isNoclip = state end)
createToggle("Nhảy Vô Hạn", "Infinite Jump", UDim2.new(0, 0, 0, 72), function(state) getgenv().isInfJump = state end)
createToggle("Diệt Tường Cản", "Anti-Wall", UDim2.new(0, 0, 0, 108), function(state) getgenv().destroyWalls = state end)

-- CỘT 2: CHỨC NĂNG QUẢN LÝ ĐIỂM + DIỆT QUÁI (X = 155)
createToggle("Diệt Quái Vật", "Anti-Monster", UDim2.new(0, 155, 0, 0), function(state) getgenv().destroyMonsters = state end)

local AddPointBtn = Instance.new("TextButton")
AddPointBtn.Size = UDim2.new(0, 145, 0, 32)
AddPointBtn.Position = UDim2.new(0, 155, 0, 36)
AddPointBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
AddPointBtn.Text = "➕ THÊM ĐIỂM TẠI ĐÂY\n(ADD WAYPOINT HERE)"
AddPointBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddPointBtn.Font = Enum.Font.SourceSansBold
AddPointBtn.TextSize = 10
AddPointBtn.TextWrapped = true
AddPointBtn.Parent = Container
local B1Corner = Instance.new("UICorner") B1Corner.CornerRadius = UDim.new(0, 5) B1Corner.Parent = AddPointBtn

local ClearPointsBtn = Instance.new("TextButton")
ClearPointsBtn.Size = UDim2.new(0, 145, 0, 32)
ClearPointsBtn.Position = UDim2.new(0, 155, 0, 72)
ClearPointsBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ClearPointsBtn.Text = "❌ XÓA ĐIỂM MENU\n(CLEAR MENU POINTS)"
ClearPointsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearPointsBtn.Font = Enum.Font.SourceSansBold
ClearPointsBtn.TextSize = 10
ClearPointsBtn.TextWrapped = true
ClearPointsBtn.Parent = Container
local B2Corner = Instance.new("UICorner") B2Corner.CornerRadius = UDim.new(0, 5) B2Corner.Parent = ClearPointsBtn

WaypointLabel = Instance.new("TextLabel")
WaypointLabel.Size = UDim2.new(0, 145, 0, 32)
WaypointLabel.Position = UDim2.new(0, 155, 0, 108)
WaypointLabel.BackgroundTransparency = 1
WaypointLabel.Text = "Danh sách: 0 / 50 điểm\n(List: 0 / 50 points)"
WaypointLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
WaypointLabel.Font = Enum.Font.SourceSansItalic
WaypointLabel.TextSize = 10
WaypointLabel.TextWrapped = true
WaypointLabel.Parent = Container

-- CỘT 3: HỆ THỐNG LƯU TRỮ VÀ CÀI ĐẶT TỐC ĐỘ (X = 310)
local SaveDataBtn = Instance.new("TextButton")
SaveDataBtn.Size = UDim2.new(0, 150, 0, 32)
SaveDataBtn.Position = UDim2.new(0, 310, 0, 0)
SaveDataBtn.BackgroundColor3 = Color3.fromRGB(210, 140, 0)
SaveDataBtn.Text = "💾 LƯU VÀO MÁY\n(SAVE TO DEVICE)"
SaveDataBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveDataBtn.Font = Enum.Font.SourceSansBold
SaveDataBtn.TextSize = 10
SaveDataBtn.TextWrapped = true
SaveDataBtn.Parent = Container
local S1Corner = Instance.new("UICorner") S1Corner.CornerRadius = UDim.new(0, 5) S1Corner.Parent = SaveDataBtn

local LoadDataBtn = Instance.new("TextButton")
LoadDataBtn.Size = UDim2.new(0, 150, 0, 32)
LoadDataBtn.Position = UDim2.new(0, 310, 0, 36)
LoadDataBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
LoadDataBtn.Text = "📂 TẢI ĐIỂM CŨ\n(LOAD OLD DATA)"
LoadDataBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadDataBtn.Font = Enum.Font.SourceSansBold
LoadDataBtn.TextSize = 10
LoadDataBtn.TextWrapped = true
LoadDataBtn.Parent = Container
local L1Corner = Instance.new("UICorner") L1Corner.CornerRadius = UDim.new(0, 5) L1Corner.Parent = LoadDataBtn

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 150, 0, 32)
SpeedLabel.Position = UDim2.new(0, 310, 0, 72)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Tốc độ (Max 350):\n(Speed - Max 350)"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Font = Enum.Font.SourceSansBold
SpeedLabel.TextSize = 10
SpeedLabel.TextWrapped = true
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center
SpeedLabel.Parent = Container

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 150, 0, 32)
SpeedInput.Position = UDim2.new(0, 310, 0, 108)
SpeedInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
SpeedInput.Text = tostring(getgenv().flySpeed)
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.Font = Enum.Font.SourceSansBold
SpeedInput.TextSize = 13
SpeedInput.Parent = Container
local SpeedCorner = Instance.new("UICorner") SpeedCorner.CornerRadius = UDim.new(0, 5) SpeedCorner.Parent = SpeedInput

-- ========================================================================
-- LOGIC KẾT NỐI SỰ KIỆN CLICK (ĐÃ CẬP NHẬT TRẠNG THÁI SONG NGỮ DÒNG ĐÔI)
-- ========================================================================

AddPointBtn.MouseButton1Click:Connect(function()
    if #getgenv().waypoints >= 50 then return end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        table.insert(getgenv().waypoints, pos)
        WaypointLabel.Text = "Đã lưu: " .. #getgenv().waypoints .. " / 50 điểm\n(Saved: " .. #getgenv().waypoints .. " / 50 points)"
        AddPointBtn.Text = "✅ ĐÃ THÊM ĐIỂM " .. #getgenv().waypoints .. "\n(POINT ADDED)"
        task.wait(0.6) AddPointBtn.Text = "➕ THÊM ĐIỂM TẠI ĐÂY\n(ADD WAYPOINT HERE)"
    end
end)

ClearPointsBtn.MouseButton1Click:Connect(function()
    getgenv().waypoints = {}
    getgenv().currentWaypointIndex = 1
    cleanupFly()
    WaypointLabel.Text = "Danh sách: 0 / 50 điểm\n(List: 0 / 50 points)"
    ClearPointsBtn.Text = "🗑️ ĐÃ XÓA TRÊN MENU!\n(CLEARED MENU!)"
    task.wait(0.8) ClearPointsBtn.Text = "❌ XÓA ĐIỂM MENU\n(CLEAR MENU POINTS)"
end)

SaveDataBtn.MouseButton1Click:Connect(function()
    if #getgenv().waypoints == 0 then
        SaveDataBtn.Text = "⚠️ CHƯA CÓ ĐIỂM!\n(NO POINTS!)"
        task.wait(1) SaveDataBtn.Text = "💾 LƯU VÀO MÁY\n(SAVE TO DEVICE)"
        return
    end
    if saveData() then
        SaveDataBtn.Text = "💾 ĐÃ LƯU THÀNH CÔNG!\n(SAVED SUCCESSFUL!)"
    else
        SaveDataBtn.Text = "❌ LỖI TRÌNH THỰC THI\n(EXECUTION ERROR)"
    end
    task.wait(1) SaveDataBtn.Text = "💾 LƯU VÀO MÁY\n(SAVE TO DEVICE)"
end)

LoadDataBtn.MouseButton1Click:Connect(function()
    if loadData() then
        cleanupFly()
        getgenv().currentWaypointIndex = 1
        SpeedInput.Text = tostring(getgenv().flySpeed)
        WaypointLabel.Text = "Đã nhận lại: " .. #getgenv().waypoints .. " / 50 điểm\n(Loaded: " .. #getgenv().waypoints .. " / 50 points)"
        LoadDataBtn.Text = "📂 ĐÃ SẴN SÀNG!\n(DATA READY!)"
    else
        LoadDataBtn.Text = "📂 KHÔNG CÓ FILE CŨ!\n(NO SAVE FILE!)"
    end
    task.wait(1) LoadDataBtn.Text = "📂 TẢI ĐIỂM CŨ\n(LOAD OLD DATA)"
end)

SpeedInput.FocusLost:Connect(function()
    local num = tonumber(SpeedInput.Text)
    if num then
        if num > 350 then num = 350 end
        getgenv().flySpeed = num
        SpeedInput.Text = tostring(num)
    else
        SpeedInput.Text = tostring(getgenv().flySpeed)
    end
end)

-- THU GỌN MENU CHỮ NHẬT NGANG TỐI ƯU SỐ 1
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Container.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 480, 0, 40), "Out", "Quad", 0.15, true)
        MinimizeBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 480, 0, 190), "Out", "Quad", 0.15, true)
        task.wait(0.15) Container.Visible = true MinimizeBtn.Text = "-"
    end
end)

-- HỆ THỐNG DI CHUYỂN MENU THỦ CÔNG KHÔNG DÙNG DRAGGABLE LỖI CỦA ROBLOX
local dragToggle, dragStart, startPos
DragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragToggle then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)

print("Đã tải thành công Menu VIP V13 bản NGANG Song Ngữ: Sửa hoàn toàn lỗi Nhảy Vô Hạn!")
