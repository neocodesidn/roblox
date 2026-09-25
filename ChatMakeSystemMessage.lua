-- 1. LOAD INFINITE YIELD DIRECTLY (TANPA PCALL)
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- 2. NOTIFIKASI EKSEKUSI
local gameInfo = MarketplaceService:GetProductInfo(PlaceId)
local gameName = (gameInfo and gameInfo.Name) or "Roblox Game"
local currentPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers
local descriptionText = gameName .. " | " .. currentPlayers .. "/" .. maxPlayers

notify("neoblox.biz.id", descriptionText)

-- 3. LOGIKA CHAT & SERVER
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

local function joinSmallServer()
    notify("neoblox", "Mencari server sepi...")
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

local function applyAntiLag()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
            v.Enabled = false
        elseif v:IsA("PostEffect") then
            v.Enabled = false
        end
    end
    notify("neoblox", "Anti-Lag / FPS Boost Berhasil Diaktifkan!")
end

-- 4. INJEKSI CUSTOM COMMAND KE INFINITE YIELD
addcmd("small", {"smallserver"}, function(args, speaker)
    joinSmallServer()
end, "Pindah ke server paling sepi", "neoblox")

addcmd("wtb", {}, function(args, speaker)
    sendPublicChat("WTB SKIN UNDER RAP YANG BU TOKEN SUNG TRADE")
    notify("neoblox", "Pesan WTB Terkirim!")
end, "Kirim pesan WTB ke chat publik", "neoblox")

addcmd("wts", {}, function(args, speaker)
    sendPublicChat("WTS EVO 2T/EACH")
    notify("neoblox", "Pesan WTS Terkirim!")
end, "Kirim pesan WTS ke chat publik", "neoblox")

addcmd("antilag", {"fpsboost", "boost"}, function(args, speaker)
    applyAntiLag()
end, "Optimasi grafis game untuk meningkatkan FPS", "neoblox")
