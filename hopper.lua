-- Dragkest Server Hopper (Termux-friendly executors)
-- Features:
-- 1) Private server URL input
-- 2) Duration sequence (add/edit/remove)
-- 3) Start/Stop toggle
-- 4) Animated countdown for next hop

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local requestFn = (syn and syn.request)
    or (http and http.request)
    or (http_request)
    or (request)

local function fetchJson(url)
    if requestFn then
        local ok, response = pcall(requestFn, {
            Url = url,
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" },
        })

        if ok and response and (response.StatusCode == 200 or response.StatusCode == 0) then
            return HttpService:JSONDecode(response.Body)
        end
        return nil
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)

    if ok and body then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if decodeOk then
            return data
        end
    end

    return nil
end

local function parsePrivateServer(url)
    if type(url) ~= "string" or url == "" then
        return nil, nil
    end

    local placeId = tonumber(url:match("/games/(%d+)")) or game.PlaceId
    local code = url:match("privateServerLinkCode=([%w_%-]+)")
        or url:match("code=([%w_%-]+)")

    return placeId, code
end

local function hopPublicServer()
    local placeId = game.PlaceId
    local cursor = ""

    for _ = 1, 15 do
        local endpoint = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
            placeId,
            cursor ~= "" and ("&cursor=" .. cursor) or ""
        )

        local data = fetchJson(endpoint)
        if not data or not data.data then
            break
        end

        local candidates = {}
        for _, server in ipairs(data.data) do
            if server and server.id and server.playing and server.maxPlayers then
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(candidates, server.id)
                end
            end
        end

        if #candidates > 0 then
            local targetId = candidates[math.random(1, #candidates)]
            TeleportService:TeleportToPlaceInstance(placeId, targetId, LocalPlayer)
            return true
        end

        cursor = data.nextPageCursor or ""
        if cursor == "" then
            break
        end
    end

    return false
end

local guiName = "Dragkest_ServerHop_UI"
pcall(function()
    local old = CoreGui:FindFirstChild(guiName)
    if old then old:Destroy() end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(420, 360)
frame.Position = UDim2.new(0.5, -210, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(420, 36)
title.BackgroundTransparency = 1
title.Text = "Dragkest Server Hop"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

local privateBox = Instance.new("TextBox")
privateBox.Size = UDim2.fromOffset(392, 34)
privateBox.Position = UDim2.fromOffset(14, 44)
privateBox.PlaceholderText = "Private Server URL (optional)"
privateBox.Text = ""
privateBox.ClearTextOnFocus = false
privateBox.Font = Enum.Font.Gotham
privateBox.TextSize = 14
privateBox.TextColor3 = Color3.fromRGB(230, 230, 230)
privateBox.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
privateBox.BorderSizePixel = 0
privateBox.Parent = frame
Instance.new("UICorner", privateBox).CornerRadius = UDim.new(0, 8)

local addDurationBox = Instance.new("TextBox")
addDurationBox.Size = UDim2.fromOffset(220, 30)
addDurationBox.Position = UDim2.fromOffset(14, 88)
addDurationBox.PlaceholderText = "Add duration (seconds)"
addDurationBox.Text = ""
addDurationBox.ClearTextOnFocus = false
addDurationBox.Font = Enum.Font.Gotham
addDurationBox.TextSize = 14
addDurationBox.TextColor3 = Color3.fromRGB(230, 230, 230)
addDurationBox.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
addDurationBox.BorderSizePixel = 0
addDurationBox.Parent = frame
Instance.new("UICorner", addDurationBox).CornerRadius = UDim.new(0, 8)

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.fromOffset(80, 30)
addBtn.Position = UDim2.fromOffset(242, 88)
addBtn.Text = "Add"
addBtn.Font = Enum.Font.GothamBold
addBtn.TextSize = 14
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.BackgroundColor3 = Color3.fromRGB(49, 110, 217)
addBtn.BorderSizePixel = 0
addBtn.Parent = frame
Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 8)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(80, 30)
toggleBtn.Position = UDim2.fromOffset(326, 88)
toggleBtn.Text = "Start"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(43, 145, 68)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.fromOffset(392, 150)
listFrame.Position = UDim2.fromOffset(14, 126)
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.ScrollBarThickness = 6
listFrame.BackgroundColor3 = Color3.fromRGB(26, 32, 43)
listFrame.BorderSizePixel = 0
listFrame.Parent = frame
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = listFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.fromOffset(392, 24)
statusLabel.Position = UDim2.fromOffset(14, 284)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(200, 214, 255)
statusLabel.Text = "Status: Idle"
statusLabel.Parent = frame

local countdownBarBg = Instance.new("Frame")
countdownBarBg.Size = UDim2.fromOffset(392, 16)
countdownBarBg.Position = UDim2.fromOffset(14, 312)
countdownBarBg.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
countdownBarBg.BorderSizePixel = 0
countdownBarBg.Parent = frame
Instance.new("UICorner", countdownBarBg).CornerRadius = UDim.new(0, 8)

local countdownBar = Instance.new("Frame")
countdownBar.Size = UDim2.fromScale(0, 1)
countdownBar.BackgroundColor3 = Color3.fromRGB(79, 146, 255)
countdownBar.BorderSizePixel = 0
countdownBar.Parent = countdownBarBg
Instance.new("UICorner", countdownBar).CornerRadius = UDim.new(0, 8)

local durations = { 30, 60 }
local running = false
local workerToken = 0

local function renderDurations()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, value in ipairs(durations) do
        local row = Instance.new("Frame")
        row.Size = UDim2.fromOffset(380, 30)
        row.BackgroundTransparency = 1
        row.Parent = listFrame

        local idx = Instance.new("TextLabel")
        idx.Size = UDim2.fromOffset(28, 30)
        idx.BackgroundTransparency = 1
        idx.Text = tostring(i)
        idx.TextColor3 = Color3.fromRGB(160, 178, 218)
        idx.Font = Enum.Font.GothamSemibold
        idx.TextSize = 13
        idx.Parent = row

        local editor = Instance.new("TextBox")
        editor.Size = UDim2.fromOffset(190, 30)
        editor.Position = UDim2.fromOffset(34, 0)
        editor.Text = tostring(value)
        editor.ClearTextOnFocus = false
        editor.Font = Enum.Font.Gotham
        editor.TextSize = 14
        editor.TextColor3 = Color3.fromRGB(237, 243, 255)
        editor.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
        editor.BorderSizePixel = 0
        editor.Parent = row
        Instance.new("UICorner", editor).CornerRadius = UDim.new(0, 8)

        editor.FocusLost:Connect(function(enterPressed)
            if not enterPressed then return end
            local n = tonumber(editor.Text)
            if n and n >= 5 then
                durations[i] = math.floor(n)
                editor.Text = tostring(durations[i])
                statusLabel.Text = string.format("Status: Duration #%d set to %ds", i, durations[i])
            else
                editor.Text = tostring(durations[i])
                statusLabel.Text = "Status: Enter duration >= 5 seconds"
            end
        end)

        local del = Instance.new("TextButton")
        del.Size = UDim2.fromOffset(70, 30)
        del.Position = UDim2.fromOffset(230, 0)
        del.Text = "Remove"
        del.Font = Enum.Font.GothamSemibold
        del.TextSize = 12
        del.TextColor3 = Color3.fromRGB(255, 255, 255)
        del.BackgroundColor3 = Color3.fromRGB(166, 57, 57)
        del.BorderSizePixel = 0
        del.Parent = row
        Instance.new("UICorner", del).CornerRadius = UDim.new(0, 8)

        del.MouseButton1Click:Connect(function()
            if #durations <= 1 then
                statusLabel.Text = "Status: Keep at least one duration"
                return
            end
            table.remove(durations, i)
            renderDurations()
            statusLabel.Text = "Status: Duration removed"
        end)
    end

    listFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
end

local function animateProgress(progress)
    TweenService:Create(
        countdownBar,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1) }
    ):Play()
end

local function doHop()
    local placeId, code = parsePrivateServer(privateBox.Text)

    if code and placeId then
        statusLabel.Text = "Status: Teleporting to next private server..."
        TeleportService:TeleportToPrivateServer(placeId, code, { LocalPlayer })
        return true
    end

    statusLabel.Text = "Status: Private URL missing/invalid, hopping public server..."
    return hopPublicServer()
end

local function loopHopper(token)
    local index = 1

    while running and token == workerToken do
        local duration = durations[index] or durations[1]
        if not duration then
            statusLabel.Text = "Status: Add at least one duration"
            break
        end

        for t = duration, 1, -1 do
            if not running or token ~= workerToken then
                animateProgress(0)
                return
            end

            statusLabel.Text = string.format(
                "Status: Next private server in %ds (step %d/%d)",
                t,
                index,
                #durations
            )
            animateProgress((duration - t) / duration)
            task.wait(1)
        end

        animateProgress(1)
        local ok = doHop()
        if not ok then
            statusLabel.Text = "Status: Hop failed. Retrying next sequence..."
            task.wait(2)
        end

        index += 1
        if index > #durations then
            index = 1
        end
    end

    animateProgress(0)
end

addBtn.MouseButton1Click:Connect(function()
    local n = tonumber(addDurationBox.Text)
    if n and n >= 5 then
        table.insert(durations, math.floor(n))
        addDurationBox.Text = ""
        renderDurations()
        statusLabel.Text = "Status: Duration added"
    else
        statusLabel.Text = "Status: Enter duration >= 5 seconds"
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    running = not running

    if running then
        workerToken += 1
        toggleBtn.Text = "Stop"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(181, 63, 63)
        statusLabel.Text = "Status: Running sequence..."
        task.spawn(loopHopper, workerToken)
    else
        workerToken += 1
        toggleBtn.Text = "Start"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(43, 145, 68)
        statusLabel.Text = "Status: Stopped"
        animateProgress(0)
    end
end)

renderDurations()
statusLabel.Text = "Status: Ready (set private URL + durations)"
