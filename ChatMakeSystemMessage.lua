local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- 1. Helper Notifikasi Chat System Lokal (Hanya terlihat di layar kamu)
local function systemNotify(msg, color)
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[neoblox.biz.id] " .. msg,
            Color = color or Color3.fromRGB(0, 255, 170),
            Font = Enum.Font.SourceSansBold,
            TextSize = 16
        })
    end)
end

-- 2. Helper Kirim Chat ke Publik
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

-- 3. Logika Server Hop & Small Server
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
    systemNotify("Mencari server lain...", Color3.fromRGB(255, 200, 0))
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
    systemNotify("Mencari server sepi...", Color3.fromRGB(255, 200, 0))
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
    sendPublicChat("WTB SKIN UNDER RAP YANG BU TOKEN SUNG TRADE")
    systemNotify("Pesan WTB berhasil terkirim ke publik!", Color3.fromRGB(100, 255, 100))
end

local function sendWTS()
    sendPublicChat("WTS EVO 2T/EACH")
    systemNotify("Pesan WTS berhasil terkirim ke publik!", Color3.fromRGB(100, 255, 100))
end

-- ==========================================
-- SILENT COMMAND INTERCEPTION
-- ==========================================

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    -- Menggunakan API TextChatCommand resmi (Teks otomatis disembunyikan dari publik)
    local commandsFolder = TextChatService:FindFirstChild("TextChatCommands") or Instance.new("Folder", TextChatService)
    commandsFolder.Name = "TextChatCommands"

    local function registerSilentCmd(name, alias, callback)
        local cmd = Instance.new("TextChatCommand")
        cmd.Name = name
        cmd.PrimaryAlias = alias
        cmd.Parent = commandsFolder
        cmd.OnTriggered:Connect(callback)
    end

    registerSilentCmd("HopCmd", "/hop", hopServer)
    registerSilentCmd("SmallCmd", "/small", joinSmallServer)
    registerSilentCmd("WtbCmd", "/wtb", sendWTB)
    registerSilentCmd("WtsCmd", "/wts", sendWTS)
else
    -- Hook Metamethod untuk memblokir pengiriman pesan ke server pada Legacy Chat
    local rawNamecall
    if hookmetamethod then
        rawNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if method == "FireServer" and self.Name == "SayMessageRequest" then
                local msg = string.lower(tostring(args[1]))
                if msg == "/hop" then
                    hopServer()
                    return nil -- Batalkan pengiriman pesan ke server
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
    end
end

-- ==========================================
-- OPTIONAL: KEYBIND SUPPORT (TANPA KETIK CHAT)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        hopServer()
    elseif input.KeyCode == Enum.KeyCode.F2 then
        joinSmallServer()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        sendWTB()
    elseif input.KeyCode == Enum.KeyCode.F4 then
        sendWTS()
    end
end)

-- Informasi Awal
task.spawn(function()
    task.wait(1)
    systemNotify("System Ready! (Stealth Mode Active)", Color3.fromRGB(0, 200, 255))
    systemNotify("Perintah /hop & /small DIPROTEKSI dan tidak akan terlihat oleh player lain.", Color3.fromRGB(200, 200, 200))
    systemNotify("Opsi Keybind: F1 (Hop) | F2 (Small) | F3 (WTB) | F4 (WTS)", Color3.fromRGB(200, 200, 200))
end)
