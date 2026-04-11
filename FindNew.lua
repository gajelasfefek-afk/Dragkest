-- =============================================
--   Roblox User ID Finder v2.4
--   By: github.com/gajelasfefek-afk
--   Features: Avatar, Account Age, Discord Webhook
-- =============================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- =============================================
-- SAVE / LOAD WEBHOOK URL
-- =============================================
local SAVE_FILE = "userfinder_webhook.txt"

local function saveWebhook(url)
    pcall(function() writefile(SAVE_FILE, url) end)
end

local function loadWebhook()
    local ok, data = pcall(function() return readfile(SAVE_FILE) end)
    if ok and data and data ~= "" then return data end
    return ""
end

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
-- ACCOUNT AGE CALCULATOR
-- =============================================
local function getAccountAge(createdISO)
    local y, m, d = createdISO:match("(%d+)-(%d+)-(%d+)")
    if not y then return "Unknown", "Unknown" end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)

    local now = os.time()
    local created = os.time({ year=y, month=m, day=d, hour=0, min=0, sec=0 })
    local totalDays = math.floor((now - created) / 86400)

    local years  = math.floor(totalDays / 365)
    local months = math.floor((totalDays % 365) / 30)
    local days   = totalDays % 30

    local ageStr = ""
    if years > 0 then
        ageStr = years .. "y"
        if months > 0 then ageStr = ageStr .. " " .. months .. "mo" end
    elseif months > 0 then
        ageStr = months .. "mo"
        if days > 0 then ageStr = ageStr .. " " .. days .. "d" end
    else
        ageStr = totalDays .. " days"
    end

    local monthNames = {"Jan","Feb","Mar","Apr","May","Jun",
                        "Jul","Aug","Sep","Oct","Nov","Dec"}
    local dateStr = d .. " " .. (monthNames[m] or m) .. " " .. y

    return ageStr, dateStr
end

-- =============================================
-- DESTROY OLD GUI
-- =============================================
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("UserIDFinder")
    if old then old:Destroy() end
end)

-- =============================================
-- SCREEN SIZE
-- =============================================
local vp = workspace.CurrentCamera.ViewportSize
local W = math.min(320, vp.X * 0.85)
local H = math.min(420, vp.Y * 0.80)

-- =============================================
-- GUI
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UserIDFinder"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent or ScreenGui.Parent ~= game:GetService("CoreGui") then
    ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, W, 0, H)
Frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

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
TitleLabel.Text = "User Finder v2.4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- =============================================
-- AVATAR
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
AvatarIcon.Text = "?"
AvatarIcon.TextColor3 = Color3.fromRGB(180, 180, 180)
AvatarIcon.TextSize = 28
AvatarIcon.Font = Enum.Font.GothamBold
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

local function makeRow(parent, yPos, label)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 30)
    row.Position = UDim2.new(0, 6, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0, 100, 1, 0)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = Color3.fromRGB(155, 155, 170)
    lb.TextSize = 11
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = row

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 160, 1, 0)
    vl.Position = UDim2.new(0, 102, 0, 0)
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

local displayVal  = makeRow(InfoFrame, 4,   "Display Name")
local usernameVal = makeRow(InfoFrame, 36,  "Username")
local useridVal   = makeRow(InfoFrame, 68,  "User ID")
local ageVal      = makeRow(InfoFrame, 100, "Account Age")

-- =============================================
-- WEBHOOK INPUT SECTION
-- =============================================
local WebhookSection = Instance.new("Frame")
WebhookSection.Size = UDim2.new(1, -16, 0, 52)
WebhookSection.Position = UDim2.new(0, 8, 0, 278)
WebhookSection.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
WebhookSection.BorderSizePixel = 0
WebhookSection.Parent = Frame
Instance.new("UICorner", WebhookSection).CornerRadius = UDim.new(0, 8)

local WebhookLabel = Instance.new("TextLabel")
WebhookLabel.Size = UDim2.new(1, -12, 0, 18)
WebhookLabel.Position = UDim2.new(0, 8, 0, 4)
WebhookLabel.BackgroundTransparency = 1
WebhookLabel.Text = "Discord Webhook URL"
WebhookLabel.TextColor3 = Color3.fromRGB(155, 155, 170)
WebhookLabel.TextSize = 10
WebhookLabel.Font = Enum.Font.Gotham
WebhookLabel.TextXAlignment = Enum.TextXAlignment.Left
WebhookLabel.Parent = WebhookSection

local WebhookInput = Instance.new("TextBox")
WebhookInput.Size = UDim2.new(1, -16, 0, 24)
WebhookInput.Position = UDim2.new(0, 8, 0, 22)
WebhookInput.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
WebhookInput.PlaceholderText = "https://discord.com/api/webhooks/..."
WebhookInput.Text = loadWebhook()
WebhookInput.TextColor3 = Color3.fromRGB(220, 220, 220)
WebhookInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
WebhookInput.TextSize = 10
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.ClearTextOnFocus = false
WebhookInput.Parent = WebhookSection
Instance.new("UICorner", WebhookInput).CornerRadius = UDim.new(0, 5)
Instance.new("UIPadding", WebhookInput).PaddingLeft = UDim.new(0, 6)

-- Auto-save webhook URL when user finishes typing
WebhookInput.FocusLost:Connect(function()
    local url = WebhookInput.Text
    if url:find("discord.com/api/webhooks/") then
        saveWebhook(url)
    end
end)

-- =============================================
-- USERNAME INPUT
-- =============================================
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -16, 0, 34)
InputBox.Position = UDim2.new(0, 8, 0, 338)
InputBox.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
InputBox.PlaceholderText = "Enter Roblox username..."
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 128)
InputBox.TextSize = 12
InputBox.Font = Enum.Font.Gotham
InputBox.ClearTextOnFocus = false
InputBox.Parent = Frame
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 7)
Instance.new("UIPadding", InputBox).PaddingLeft = UDim.new(0, 8)

-- =============================================
-- BUTTONS
-- =============================================
local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, (W/2)-12, 0, 32)
SearchBtn.Position = UDim2.new(0, 8, 0, 380)
SearchBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SearchBtn.Text = "Search"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 12
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = Frame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 7)

local WebhookBtn = Instance.new("TextButton")
WebhookBtn.Size = UDim2.new(0, (W/2)-12, 0, 32)
WebhookBtn.Position = UDim2.new(0, W/2+4, 0, 380)
WebhookBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
WebhookBtn.Text = "Send Webhook"
WebhookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBtn.TextSize = 12
WebhookBtn.Font = Enum.Font.GothamBold
WebhookBtn.Parent = Frame
Instance.new("UICorner", WebhookBtn).CornerRadius = UDim.new(0, 7)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 16)
StatusLabel.Position = UDim2.new(0, 8, 0, H - 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready."
StatusLabel.TextColor3 = Color3.fromRGB(100, 210, 120)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = Frame

-- =============================================
-- DRAGGABLE
-- =============================================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
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
    StatusLabel.TextColor3 = color or Color3.fromRGB(100, 210, 120)
end

local function resetUI()
    displayVal.Text = "—"
    usernameVal.Text = "—"
    useridVal.Text = "—"
    ageVal.Text = "—"
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
        setStatus("Enter a username first.", Color3.fromRGB(255, 200, 50))
        return
    end

    resetUI()
    setStatus("Searching...", Color3.fromRGB(180, 180, 180))

    local okId, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not okId or not userId then
        setStatus("User not found.", Color3.fromRGB(220, 80, 80))
        return
    end

    AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
    AvatarIcon.Visible = false

    setStatus("Fetching info...", Color3.fromRGB(180, 180, 180))

    local displayName = username
    local ageStr = "Unknown"
    local dateStr = "Unknown"
    local avatarUrl = ""

    local infoJson = httpGet("https://users.roblox.com/v1/users/" .. userId)
    if infoJson then
        local okP, info = pcall(HttpService.JSONDecode, HttpService, infoJson)
        if okP and info then
            displayName = info.displayName or username
            if info.created then
                ageStr, dateStr = getAccountAge(info.created)
            end
        end
    end

    local avatarJson = httpGet(
        "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
        .. userId .. "&size=150x150&format=Png&isCircular=false"
    )
    if avatarJson then
        local okP, data = pcall(HttpService.JSONDecode, HttpService, avatarJson)
        if okP and data and data.data and data.data[1] then
            avatarUrl = data.data[1].imageUrl or ""
        end
    end

    displayVal.Text = displayName
    usernameVal.Text = username
    useridVal.Text = tostring(userId)
    ageVal.Text = ageStr

    pcall(function() setclipboard(tostring(userId)) end)

    currentData = {
        userId = tostring(userId),
        username = username,
        displayName = displayName,
        ageStr = ageStr,
        dateStr = dateStr,
        avatarUrl = avatarUrl
    }

    setStatus("Found! User ID copied.", Color3.fromRGB(100, 210, 120))
end)

-- =============================================
-- SEND WEBHOOK
-- =============================================
WebhookBtn.MouseButton1Click:Connect(function()
    if not currentData.userId then
        setStatus("Search for a user first.", Color3.fromRGB(255, 200, 50))
        return
    end

    local webhookUrl = WebhookInput.Text
    if webhookUrl == "" or not webhookUrl:find("discord.com/api/webhooks/") then
        setStatus("Enter a valid webhook URL.", Color3.fromRGB(220, 80, 80))
        return
    end

    setStatus("Sending to Discord...", Color3.fromRGB(150, 170, 255))

    local payload = HttpService:JSONEncode({
        username = "Roblox User Finder",
        avatar_url = "https://www.roblox.com/favicon.ico",
        embeds = {{
            title = "User Found",
            color = 5814783,
            thumbnail = {
                url = currentData.avatarUrl ~= "" and currentData.avatarUrl
                      or "https://www.roblox.com/favicon.ico"
            },
            fields = {
                {name = "Username",     value = "`" .. currentData.username .. "`",    inline = true},
                {name = "Display Name", value = "`" .. currentData.displayName .. "`", inline = true},
                {name = "User ID",      value = "`" .. currentData.userId .. "`",      inline = false},
                {name = "Account Age",  value = "`" .. currentData.ageStr .. "` (created: " .. currentData.dateStr .. ")", inline = false},
            },
            footer = { text = "Roblox User Finder v2.4 • Delta Executor" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })

    local okSend = httpPost(webhookUrl, payload)
    if okSend then
        setStatus("Successfully sent to Discord.", Color3.fromRGB(100, 210, 120))
    else
        setStatus("Failed to send webhook.", Color3.fromRGB(220, 80, 80))
    end
end)

print("[User Finder v2.4] Loaded.")
