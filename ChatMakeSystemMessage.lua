local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "neoblox Hub",
    SubTitle = "by Hexa",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 400),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

Tabs.Main:AddButton({
    Title = "Send WTB",
    Description = "Kirim pesan WTB ke chat publik",
    Callback = function()
        -- Panggil fungsi WTB di sini
    end
})
