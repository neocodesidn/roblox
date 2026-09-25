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

-- Kirim notifikasi eksekusi
StarterGui:SetCore("SendNotification", {
    Title = "neoblox.biz.id",
    Text = descriptionText,
    Icon = playerIcon,
    Duration = 5 -- Hilang otomatis dalam 5 detik
})

-- Helper Notifikasi Sistem Chat (Hanya terlihat oleh kamu)
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

-- Helper Kirim Chat ke Publik
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

local function sendWTB()
    task.spawn(function()
        sendPublicChat("WTB SKIN UNDER RAP YANG BU TOKEN SUNG TRADE")
    end)
    systemNotify("Pesan WTB terkirim ke publik!")
end

local function sendWTS()
    task.spawn(function()
        sendPublicChat("WTS EVO 2T/EACH")
    end)
    systemNotify("Pesan WTS terkirim ke publik!")
end

-- ==========================================
-- 3. SILENT CHAT INTERCEPTOR (HOOOKMETAMETHOD)
-- ==========================================
local rawNamecall
if hookmetamethod then
    rawNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        -- Intercept TextChatService (Chat Baru seperti di Fisch)
        if method == "SendAsync" and typeof(self) == "Instance" and self:IsA("TextChannel") then
            local msg = tostring(args[1]):lower()
            if msg == "/hop" then
                hopServer()
                return nil -- Membatalkan pengiriman teks "/hop" ke publik
            elseif msg == "/small" then
                joinSmallServer()
                return nil
            elseif msg == "/wtb" then
                sendWTB()
                return nil -- Membatalkan teks "/wtb", diganti pesan WTB asli
            elseif msg == "/wts" then
                sendWTS()
                return nil
            end
        end

        -- Intercept Legacy Chat System (Chat Lama)
        if method == "FireServer" and self.Name == "SayMessageRequest" then
            local msg = tostring(args[1]):lower()
            if msg == "/hop" then
                hopServer()
                return nil
            elseif msg == "/small" then
                joinSmallServer()
                return nil
            elseif msg == "/wtb" then
                sendWTB()
                return nil
            elseif msg == "/wts" then
                sendWTS()
                return nil
            end
        end

        return rawNamecall(self, ...)
    end)
else
    -- Fallback jika executor tidak mendukung hookmetamethod
    LocalPlayer.Chatted:Connect(function(msg)
        local lowerMsg = msg:lower()
        if lowerMsg == "/hop" then hopServer()
        elseif lowerMsg == "/small" then joinSmallServer()
        elseif lowerMsg == "/wtb" then sendWTB()
        elseif lowerMsg == "/wts" then sendWTS()
        end
    end)
end

-- Informasi di Chat Lokal setelah Eksekusi
task.spawn(function()
    task.wait(0.5)
    systemNotify("Script Aktif! Ketik /hop, /small, /wtb, atau /wts di chat.")
end)
