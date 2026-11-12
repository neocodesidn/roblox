local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage:WaitForChild("KardusRemotes"):WaitForChild("BeliProduct")
local plot = workspace:WaitForChild("Plot1")
local clickObject = plot:WaitForChild("ClickObject")

-- Variabel Konfigurasi
local autoRestokEnabled = false
local namaItem = "Bebelove"
local jumlahBeli = 10
local sudahBeli = false

-- Fungsi Hitung Sisa Kardus
local function hitungSisaKardus()
    local jumlah = 0
    for _, v in pairs(clickObject:GetChildren()) do
        if v.Name == "Kardus" then
            jumlah = jumlah + 1
        end
    end
    return jumlah
end

-- Buat Window Utama
local Window = Rayfield:CreateWindow({
    Name = "Kopdes Together | v0.1",
    LoadingTitle = "Kopdes Together",
    LoadingSubtitle = "by Cheese Dev",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- ==========================================
-- TAB 1: INFO
-- ==========================================
local InfoTab = Window:CreateTab("Info", "info")

InfoTab:CreateSection("Informasi Script")

InfoTab:CreateParagraph({
    Title = "Kopdes Together",
    Content = "Versi: 0.1\nStatus: Online & Anti-Spam Ready"
})

InfoTab:CreateSection("Komunitas & Support")

InfoTab:CreateButton({
    Name = "Discord : https://cheesedev.biz.id (Klik untuk Salin)",
    Callback = function()
        if setclipboard then
            setclipboard("https://cheesedev.biz.id")
            Rayfield:Notify({
                Title = "Berhasil Disalin!",
                Content = "Link Discord https://cheesedev.biz.id telah disalin ke clipboard.",
                Duration = 3,
                Image = "check-circle"
            })
        else
            Rayfield:Notify({
                Title = "Gagal Menyalin",
                Content = "Executor kamu tidak mendukung fungsi setclipboard.",
                Duration = 3,
                Image = "alert-triangle"
            })
        end
    end,
})

-- ==========================================
-- TAB 2: SHOP
-- ==========================================
local ShopTab = Window:CreateTab("Shop", "shopping-cart")

ShopTab:CreateSection("Auto Restok Kardus")

ShopTab:CreateToggle({
    Name = "Auto Restok Kardus",
    CurrentValue = false,
    Flag = "ToggleRestok",
    Callback = function(Value)
        autoRestokEnabled = Value
        if Value then
            sudahBeli = false
            Rayfield:Notify({
                Title = "Auto Restok Aktif",
                Content = "Memantau kardus di Plot1...",
                Duration = 3,
                Image = "refresh-cw"
            })
        else
            Rayfield:Notify({
                Title = "Auto Restok Dimatikan",
                Content = "Pemantauan restok dihentikan.",
                Duration = 3,
                Image = "power"
            })
        end
    end,
})

ShopTab:CreateInput({
    Name = "Nama Item",
    PlaceholderText = "Bebelove",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text ~= "" then
            namaItem = Text
        end
    end,
})

ShopTab:CreateSlider({
    Name = "Jumlah Kardus Sekali Beli",
    Range = {1, 50},
    Increment = 1,
    Suffix = " Kardus",
    CurrentValue = 10,
    Flag = "SliderJumlah",
    Callback = function(Value)
        jumlahBeli = Value
    end,
})

-- ==========================================
-- LOOP PEMANTAUAN ANTI-SPAM
-- ==========================================
task.spawn(function()
    while true do
        if autoRestokEnabled then
            local sisa = hitungSisaKardus()
            
            if sisa > 0 then
                sudahBeli = false
            elseif sisa == 0 and not sudahBeli then
                sudahBeli = true
                
                Event:FireServer({
                    {
                        jumlahKardus = jumlahBeli,
                        itemName = namaItem
                    }
                })
                
                Rayfield:Notify({
                    Title = "Restok Berhasil",
                    Content = "Membeli " .. jumlahBeli .. "x " .. namaItem,
                    Duration = 3,
                    Image = "package"
                })
            end
        end
        task.wait(1)
    end
end)
