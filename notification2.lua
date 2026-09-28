local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- ========================================================
-- 1. FITUR AUTO BOOST FPS (Otomatis Aktif saat Disimpan)
-- ========================================================
local function autoBoostFPS()
    pcall(function()
        -- Pengaturan Lighting
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1

        -- Matikan efek pencahayaan/post-processing
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("Atmosphere") then
                obj.Enabled = false
            end
        end

        -- Pengaturan Terrain
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end

        -- Fungsi untuk optimasi Objek
        local function optimizeObject(v)
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end

        -- Optimasi objek yang sudah ada di Workspace
        for _, v in ipairs(workspace:GetDescendants()) do
            optimizeObject(v)
        end

        -- Optimasi objek baru yang muncul/spawn di Workspace
        workspace.DescendantAdded:Connect(optimizeObject)
    end)
end

-- Jalankan Boost FPS secara otomatis
autoBoostFPS()

-- ========================================================
-- 2. DETEKSI INFORMASI PLAYER & GAME
-- ========================================================
local playerIcon = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"

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

-- ========================================================
-- 3. HTTP REQUEST & HOP SERVER
-- ========================================================
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function fetchServers(sortOrder)
    sortOrder = sortOrder or "Desc"
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

-- ========================================================
-- 4. NOTIFIKASI & CALLBACK (Hanya 1 Tombol Hop Server)
-- ========================================================
local callback = Instance.new("BindableFunction")

callback.OnInvoke = function(buttonText)
    if buttonText == "Hop Server" then
        hopServer()
    end
end

StarterGui:SetCore("SendNotification", {
    Title = "neoblox.biz.id",
    Text = descriptionText,
    Icon = playerIcon,
    Duration = math.huge,
    Button1 = "Hop Server",
    Callback = callback
})
