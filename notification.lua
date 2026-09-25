local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- 1. Deteksi Foto Profil Roblox LocalPlayer Otomatis
local playerIcon = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"

-- 2. Deteksi Nama Game Otomatis
local gameName = "Roblox Game"
pcall(function()
    local gameInfo = MarketplaceService:GetProductInfo(PlaceId)
    if gameInfo and gameInfo.Name then
        gameName = gameInfo.Name
    end
end)

-- 3. Deteksi Jumlah Pemain & Maksimal Server Otomatis
local currentPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers
local descriptionText = gameName .. " | " .. currentPlayers .. "/" .. maxPlayers

-- Fungsi request HTTP universal untuk executor
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function fetchServers(sortOrder)
    sortOrder = sortOrder or "Asc"
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100", PlaceId, sortOrder)
    
    if not httpRequest then
        warn("Executor tidak mendukung fungsi request HTTP")
        return nil
    end

    local response = httpRequest({
        Url = url,
        Method = "GET"
    })

    if response and response.StatusCode == 200 then
        return HttpService:JSONDecode(response.Body)
    end
    return nil
end

local function hopServer()
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

-- Callback untuk penanganan tombol
local callback = Instance.new("BindableFunction")

callback.OnInvoke = function(buttonText)
    if buttonText == "Hop Server" then
        hopServer()
    elseif buttonText == "Small Server" then
        joinSmallServer()
    end
end

-- Kirim Notifikasi
StarterGui:SetCore("SendNotification", {
    Title = "neoblox.biz.id",
    Text = descriptionText,
    Icon = playerIcon,
    Duration = math.huge,
    Button1 = "Hop Server",
    Button2 = "Small Server",
    Callback = callback
})
