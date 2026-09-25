local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- ==========================================
-- 1. NOTIFIKASI EKSEKUSI (5 DETIK, TANPA BUTTON)
-- ==========================================
local gameName = "Roblox Game"
pcall(function()
    local gameInfo = MarketplaceService:GetProductInfo(PlaceId)
    if gameInfo and gameInfo.Name then
        gameName = gameInfo.Name
    end
end)

local currentPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers
local descriptionText = gameName .. " | " .. currentPlayers .. "/" .. maxPlayers
local playerIcon = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"

-- Notifikasi popup saat script berhasil jalan
StarterGui:SetCore("SendNotification", {
    Title = "neoblox.biz.id",
    Text = descriptionText,
    Icon = playerIcon,
    Duration = 5
})

-- Helper Notifikasi Chat Sistem Lokal
local function systemNotify(msg)
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[neoblox.biz.id] " .. msg,
            Color = Color3.fromRGB(0, 255, 170),
            Font = Enum.Font.SourceSansBold,
            TextSize = 16
        })
    end)
end

-- Helper Kirim Chat Publik
local function sendPublicChat(message)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            generalChannel:SendAsync(message)
        end
    else
        local defaultEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultEvents and defaultEvents:FindFirstChild("SayMessageRequest") then
            defaultEvents.SayMessageRequest:FireServer(message, "All")
        end
    end
end

-- ==========================================
-- 2. LOGIKA FITUR
-- ==========================================
local function fetchServers(sortOrder)
    sortOrder = sortOrder or "Asc"
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100", PlaceId, sortOrder)
    if not httpRequest then return nil end
    local response = httpRequest({Url = url, Method = "GET"})
    if response and response.StatusCode == 200 then
        return HttpService:JSONDecode(response.Body)
    end
    return nil
end

local function hopServer()
    systemNotify("Mencari server lain...")
    local serverData = fetchServers("Desc")
    if serverData and serverData.data then
        for _, server in ipairs(serverData.data) do
            if server.id ~= CurrentJobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                return
            end
        end
    end
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

local function joinSmallServer()
    systemNotify("Mencari server sepi...")
    local serverData = fetchServers("Asc")
    if serverData and serverData.data then
        for _, server in ipairs(serverData.data) do
            if server.id ~= CurrentJobId and server.playing > 0 and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                return
            end
        end
    end
end

-- ==========================================
-- 3. TOPBARPLUS MENU (FOREVERHD)
-- ==========================================
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/1001-Code/TopbarPlus/main/src/Icon.lua"))()

-- Main Icon
local mainIcon = Icon.new()
mainIcon:setLabel("neoblox")
mainIcon:setImage(playerIcon)

-- Sub Button 1: Hop Server
local btnHop = Icon.new()
btnHop:setLabel("Hop Server")
btnHop:selected:Connect(function()
    btnHop:deselect()
    hopServer()
end)

-- Sub Button 2: Small Server
local btnSmall = Icon.new()
btnSmall:setLabel("Small Server")
btnSmall:selected:Connect(function()
    btnSmall:deselect()
    joinSmallServer()
end)

-- Sub Button 3: Send WTB
local btnWTB = Icon.new()
btnWTB:setLabel("Send WTB")
btnWTB:selected:Connect(function()
    btnWTB:deselect()
    sendPublicChat("WTB SKIN UNDER RAP YANG BU TOKEN SUNG TRADE")
    systemNotify("Pesan WTB terkirim!")
end)

-- Sub Button 4: Send WTS
local btnWTS = Icon.new()
btnWTS:setLabel("Send WTS")
btnWTS:selected:Connect(function()
    btnWTS:deselect()
    sendPublicChat("WTS EVO 2T/EACH")
    systemNotify("Pesan WTS terkirim!")
end)

-- Gabungkan Sub Button ke dalam Dropdown Main Icon
mainIcon:setDropdown({
    btnHop,
    btnSmall,
    btnWTB,
    btnWTS
})
