local Maclib = loadstring(game:HttpGet("https://github.com/vaxerDev/Maclib/releases/latest/download/maclib.txt"))()

local Window = Maclib:CreateWindow({
    Title = "neoblox Hub",
    Subtitle = "Minimalist Edition",
    Size = UDim2.fromOffset(520, 340),
    Dragable = true
})

local TabGroup = Window:TabGroup()
local MainTab = TabGroup:AddTab({ Title = "Main", Icon = "home" })

MainTab:AddButton({
    Title = "Send WTB",
    Description = "Kirim pesan WTB ke publik",
    Callback = function()
        -- Panggil fungsi WTB
    end
})

MainTab:AddButton({
    Title = "Anti-Lag",
    Description = "Optimasi FPS game",
    Callback = function()
        -- Panggil fungsi Anti-Lag
    end
})
