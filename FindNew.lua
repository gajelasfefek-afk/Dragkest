-- =============================================
--   Roblox User ID Finder v2.2
--   Fix: UI ukuran mobile, avatar rbxthumb, layout
-- =============================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- ⚙️ Webhook URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/1440706799002189998/zVyfFMoV0BRgn3YFC97OXmb8WcbnHJBPX0j-zOsOi7w8j4lddLR4dCuRPgaPcniyKTyd"

-- =============================================
-- HTTP HELPERS
-- =============================================
local function httpGet(url)
    local ok, res = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if ok and res and res.Body then return res.Body end
    return nil
end

local function httpPost(url, body)
    return pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end)
end

-- =============================================
-- DESTROY OLD GUI
-- =============================================
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("UserIDFinderV2")
    if old then old:Destroy() end
end)

-- =============================================
-- SCREEN SIZE
-- =============================================
local vp = workspace.CurrentCamera.ViewportSize
local sw, sh = vp.X, vp.Y

-- Ukuran UI relatif terhadap layar (max 320px lebar)
local W = math.min(320, sw * 0.85)
local H = math.min(380, sh * 0.75)

-- =============================================
-- GUI
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UserIDFinderV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent or ScreenGui.Parent ~= game:GetService("CoreGui") then
    ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

-- Main Frame (pakai Scale biar responsive)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, W, 0, H)
Frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

-- Shadow effect
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 8, 1, 8)
Shadow.Position = UDim2.new(0, -4, 0, -4)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.ZIndex = Frame.ZIndex - 1
Shadow.Parent = Frame
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 14)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔍 User Finder v2.2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- =============================================
-- AVATAR (pakai rbxthumb - support di roblox)
-- =============================================
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size = UDim2.new(0, 64, 0, 64)
AvatarFrame.Position = UDim2.new(0.5, -32, 0, 48)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
AvatarFrame.BorderSizePixel = 0
AvatarFrame.Parent = Frame
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(0.5, 0)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(1, -4, 1, -4)
AvatarImg.Position = UDim2.new(0, 2, 0, 2)
AvatarImg.BackgroundTransparency = 1
AvatarImg.Image = ""
AvatarImg.ScaleType = Enum.ScaleType.Crop
AvatarImg.Parent = AvatarFrame
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(0.5, 0)

local AvatarIcon = Instance.new("TextLabel")
AvatarIcon.Size = UDim2.new(1, 0, 1, 0)
AvatarIcon.BackgroundTransparency = 1
AvatarIcon.Text = "👤"
AvatarIcon.TextSize = 28
AvatarIcon.Font = Enum.Font.Gotham
AvatarIcon.TextXAlignment = Enum.TextXAlignment.Center
AvatarIcon.TextYAlignment = Enum.TextYAlignment.Center
AvatarIcon.Parent = AvatarFrame

-- =============================================
-- INFO PANEL
-- =============================================
local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(1, -16, 0, 148)
InfoFrame.Position = UDim2.new(0, 8, 0, 122)
InfoFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
InfoFrame.BorderSizePixel = 0
InfoFrame.Parent = Frame
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 8)

local function makeRow(parent, yPos, icon, label)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 30)
    row.Position = UDim2.new(0, 6, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 22, 1, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 13
    ic.Font = Enum.Font.Gotham
    ic.TextXAlignment = Enum.TextXAlignment.Center
    ic.Parent = row

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0, 85, 1, 0)
    lb.Position = UDim2.new(0, 24, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = Color3.fromRGB(155, 155, 170)
    lb.TextSize = 11
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = row

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 140, 1, 0)
    vl.Position = UDim2.new(0, 112, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text = "—"
    vl.TextColor3 = Color3.fromRGB(255, 255, 255)
    vl.TextSize = 11
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Left
    vl.TextTruncate = Enum.TextTruncate.AtEnd
    vl.Parent = row

    return vl
end

local displayVal  = makeRow(InfoFrame, 4,   "✏️", "Display Name")
local usernameVal = makeRow(InfoFrame, 36,  "👤", "Username")
local useridVal   = makeRow(InfoFrame, 68,  "🆔", "User ID")
local createdVal  = makeRow(InfoFrame, 100, "📅", "Akun Dibuat")

-- Divider
local Div = Instance.new("Frame")
Div.Size = UDim2.new(1, -16, 0, 1)
Div.Position = UDim2.new(0, 8, 0, 278)
Div.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
Div.BorderSizePixel = 0
Div.Parent = Frame

-- Input
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -16, 0, 36)
InputBox.Position = UDim2.new(0, 8, 0, 286)
InputBox.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
InputBox.PlaceholderText = "Masukkan username..."
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 128)
InputBox.TextSize = 12
InputBox.Font = Enum.Font.Gotham
InputBox.ClearTextOnFocus = false
InputBox.Parent = Frame
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 7)

local InputPad = Instance.new("UIPadding", InputBox)
InputPad.PaddingLeft = UDim.new(0, 8)

-- Buttons
local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, (W/2)-12, 0, 34)
SearchBtn.Position = UDim2.new(0, 8, 0, 330)
SearchBtn.BackgroundColor3 = Color3.fromRGB(0, 145, 255)
SearchBtn.Text = "🔍 Cari"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 12
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = Frame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 7)

local WebhookBtn = Instance.new("TextButton")
WebhookBtn.Size = UDim2.new(0, (W/2)-12, 0, 34)
WebhookBtn.Position = UDim2.new(0, W/2+4, 0, 330)
WebhookBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
WebhookBtn.Text = "📨 Webhook"
WebhookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBtn.TextSize = 12
WebhookBtn.Font = Enum.Font.GothamBold
WebhookBtn.Parent = Frame
Instance.new("UICorner", WebhookBtn).CornerRadius = UDim.new(0, 7)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Position = UDim2.new(0, 8, 0, H - 22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Siap digunakan!"
StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = Frame

-- =============================================
-- DRAGGABLE (touch + mouse)
-- =============================================
local dragging, dragStart, startPos
local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end
local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end
TitleBar.InputBegan:Connect(onInputBegan)
TitleBar.InputEnded:Connect(onInputEnded)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- =============================================
-- STATE
-- =============================================
local currentData = {}

local function setStatus(msg, color)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(100, 220, 120)
end

local function resetUI()
    displayVal.Text = "—"
    usernameVal.Text = "—"
    useridVal.Text = "—"
    createdVal.Text = "—"
    AvatarImg.Image = ""
    AvatarIcon.Visible = true
    currentData = {}
end

-- =============================================
-- SEARCH
-- =============================================
SearchBtn.MouseButton1Click:Connect(function()
    local username = InputBox.Text
    if username == "" then
        setStatus("⚠️ Masukkan username dulu!", Color3.fromRGB(255, 200, 50))
        return
    end

    resetUI()
    setStatus("⏳ Mencari...", Color3.fromRGB(180, 180, 180))

    local okId, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not okId or not userId then
        setStatus("❌ User tidak ditemukan!", Color3.fromRGB(255, 100, 100))
        return
    end

    -- Avatar pakai rbxthumb (render langsung di Roblox, pasti work!)
    AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
    AvatarIcon.Visible = false

    setStatus("⏳ Ambil info...", Color3.fromRGB(180, 180, 180))

    local displayName = username
    local createdDate = "Tidak diketahui"
    local avatarUrl = ""

    -- Info dari Roblox API
    local infoJson = httpGet("https://users.roblox.com/v1/users/" .. userId)
    if infoJson then
        local okP, info = pcall(HttpService.JSONDecode, HttpService, infoJson)
        if okP and info then
            displayName = info.displayName or username
            if info.created then
                local y, m, d = info.created:match("(%d+)-(%d+)-(%d+)")
                local months = {"Jan","Feb","Mar","Apr","May","Jun",
                                "Jul","Aug","Sep","Oct","Nov","Dec"}
                if y and m and d then
                    createdDate = d.." "..(months[tonumber(m)] or m).." "..y
                end
            end
        end
    end

    -- Avatar URL untuk webhook
    local avatarJson = httpGet(
        "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
        ..userId.."&size=150x150&format=Png&isCircular=false"
    )
    if avatarJson then
        local okP, data = pcall(HttpService.JSONDecode, HttpService, avatarJson)
        if okP and data and data.data and data.data[1] then
            avatarUrl = data.data[1].imageUrl or ""
        end
    end

    -- Update UI
    displayVal.Text = displayName
    usernameVal.Text = username
    useridVal.Text = tostring(userId)
    createdVal.Text = createdDate

    pcall(function() setclipboard(tostring(userId)) end)

    currentData = {
        userId = tostring(userId),
        username = username,
        displayName = displayName,
        createdDate = createdDate,
        avatarUrl = avatarUrl
    }

    setStatus("✅ Ketemu! ID di-copy.", Color3.fromRGB(100, 220, 120))
end)

-- =============================================
-- WEBHOOK
-- =============================================
WebhookBtn.MouseButton1Click:Connect(function()
    if not currentData.userId then
        setStatus("⚠️ Cari user dulu!", Color3.fromRGB(255, 200, 50))
        return
    end

    setStatus("📨 Kirim ke Discord...", Color3.fromRGB(150, 170, 255))

    local payload = HttpService:JSONEncode({
        username = "Roblox User Finder",
        avatar_url = "https://www.roblox.com/favicon.ico",
        embeds = {{
            title = "👤 User Ditemukan!",
            color = 5814783,
            thumbnail = {
                url = currentData.avatarUrl ~= "" and currentData.avatarUrl
                      or "https://www.roblox.com/favicon.ico"
            },
            fields = {
                {name="👤 Username",    value="`"..currentData.username.."`",    inline=true},
                {name="✏️ Display Name",value="`"..currentData.displayName.."`", inline=true},
                {name="🆔 User ID",     value="`"..currentData.userId.."`",      inline=false},
                {name="📅 Akun Dibuat", value="`"..currentData.createdDate.."`", inline=false},
            },
            footer = {text = "Roblox User Finder v2.2 • Delta Executor"},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })

    local okSend = httpPost(WEBHOOK_URL, payload)
    if okSend then
        setStatus("✅ Terkirim ke Discord!", Color3.fromRGB(100, 220, 120))
    else
        setStatus("❌ Gagal kirim webhook!", Color3.fromRGB(255, 100, 100))
    end
end)

print("[User Finder v2.2] Loaded!")
