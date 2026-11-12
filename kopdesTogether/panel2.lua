local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local KardusRemotes = ReplicatedStorage:WaitForChild("KardusRemotes")
local BankRemotes = ReplicatedStorage:WaitForChild("BankRemotes")

local BeliProductRemote = KardusRemotes:WaitForChild("BeliProduct")
local TransferRemote = BankRemotes:WaitForChild("Transfer")

local plot = workspace:WaitForChild("Plot1")
local clickObject = plot:WaitForChild("ClickObject")

-- ==========================================
-- VARIABEL KONFIGURASI
-- ==========================================
local autoRestokEnabled = false
local autoTransferEnabled = false

local namaItem = "Bebelove"
local jumlahBeli = 10
local sudahBeli = false

-- Konfigurasi Auto Transfer
local targetUserId = nil
local targetPlayerName = ""
local nominalTransfer = 1000000 -- Default 1 Juta
local targetJumlahRestok = 2   -- Default setiap 2x restok (bisa diubah di slider)
local hitunganRestok = 0

-- ==========================================
-- FUNGSI PENDUKUNG
-- ==========================================
local function hitungSisaKardus()
    local jumlah = 0
    for _, v in pairs(clickObject:GetChildren()) do
        if v.Name == "Kardus" then
            jumlah = jumlah + 1
        end
    end
    return jumlah
end

-- Ambil daftar player yang sedang ada di server (kecuali diri sendiri)
local function ambilDaftarPlayer()
    local daftar = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(daftar, plr.Name)
        end
    end
    if #daftar == 0 then
        table.insert(daftar, "Tidak ada player lain")
    end
    return daftar
end

-- Eksekusi Transfer Bank
local function jalankanAutoTransfer()
    if not autoTransferEnabled then return end
    
    if not targetUserId then
        Rayfield:Notify({
            Title = "Transfer Gagal",
            Content = "Silakan pilih player tujuan terlebih dahulu di tab Bank!",
            Duration = 4,
            Image = "alert-triangle"
        })
        return
    end

    if nominalTransfer < 10000 then
        Rayfield:Notify({
            Title = "Transfer Gagal",
            Content = "Minimal transfer adalah IDR 10,000.",
            Duration = 4,
            Image = "alert-triangle"
        })
        return
    end

    local response = TransferRemote:InvokeServer({
        targetType = "Player",
        targetUserId = targetUserId,
        sourceType = "Toko",
        amount = nominalTransfer
    })

    if typeof(response) == "table" and response.ok then
        Rayfield:Notify({
            Title = "Auto Transfer Berhasil!",
            Content = "Terkirim Rp " .. nominalTransfer .. " ke " .. targetPlayerName,
            Duration = 4,
            Image = "check-circle"
        })
    else
        local pesanError = (typeof(response) == "table" and response.message) or "Gagal memproses transfer."
        Rayfield:Notify({
            Title = "Transfer Ditolak Server",
            Content = tostring(pesanError),
            Duration = 4,
            Image = "x-circle"
        })
    end
end

-- ==========================================
-- UI RAYFIELD
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Kopdes Together | v0.3",
    LoadingTitle = "Kopdes Together",
    LoadingSubtitle = "by Cheese Dev",
    ConfigurationSaving = { Enabled = false }
})

-- TAB 1: INFO
local InfoTab = Window:CreateTab("Info", "info")
InfoTab:CreateSection("Informasi Script")
InfoTab:CreateParagraph({
    Title = "Kopdes Together",
    Content = "Versi: 0.3\nFitur: Auto Restok (Anti-Spam) & Auto Transfer Bank"
})
InfoTab:CreateSection("Komunitas & Support")
InfoTab:CreateButton({
    Name = "Discord : https://cheesedev.biz.id (Klik untuk Salin)",
    Callback = function()
        if setclipboard then
            setclipboard("https://cheesedev.biz.id")
            Rayfield:Notify({
                Title = "Berhasil Disalin!",
                Content = "Link Discord https://cheesedev.biz.id telah disalin.",
                Duration = 3,
                Image = "check-circle"
            })
        end
    end,
})

-- TAB 2: SHOP (KHUSUS AUTO RESTOK)
local ShopTab = Window:CreateTab("Shop", "shopping-cart")
ShopTab:CreateSection("Pengaturan Produk")

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

ShopTab:CreateSection("Otomatisasi Restok")
ShopTab:CreateToggle({
    Name = "Auto Restok Kardus (Anti-Spam)",
    CurrentValue = false,
    Flag = "ToggleRestok",
    Callback = function(Value)
        autoRestokEnabled = Value
        if Value then
            sudahBeli = false
            hitunganRestok = 0
        end
        Rayfield:Notify({
            Title = Value and "Auto Restok Aktif" or "Auto Restok Dimatikan",
            Content = Value and "Membeli otomatis saat kardus di Plot1 habis." or "Auto beli dihentikan.",
            Duration = 3,
            Image = Value and "refresh-cw" or "power"
        })
    end,
})

-- TAB 3: BANK (ICON DUIT: "banknote")
local BankTab = Window:CreateTab("Bank", "banknote")
BankTab:CreateSection("Pilih Penerima Transfer")

local PlayerDropdown = BankTab:CreateDropdown({
    Name = "Select Player Tujuan",
    Options = ambilDaftarPlayer(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "DropdownPlayer",
    Callback = function(Options)
        local namaDipilih = Options[1]
        local plrTarget = Players:FindFirstChild(namaDipilih)
        
        if plrTarget then
            targetUserId = plrTarget.UserId
            targetPlayerName = plrTarget.Name
            Rayfield:Notify({
                Title = "Penerima Dipilih",
                Content = plrTarget.Name .. " (ID: " .. plrTarget.UserId .. ")",
                Duration = 3,
                Image = "user-check"
            })
        else
            targetUserId = nil
            targetPlayerName = ""
        end
    end,
})

BankTab:CreateButton({
    Name = "Refresh Daftar Player",
    Callback = function()
        local listBaru = ambilDaftarPlayer()
        PlayerDropdown:Refresh(listBaru)
        Rayfield:Notify({
            Title = "Daftar Player Diperbarui",
            Content = "Silakan pilih ulang player pada dropdown di atas.",
            Duration = 2,
            Image = "refresh-cw"
        })
    end,
})

BankTab:CreateSection("Pengaturan Nominal & Kondisi")

BankTab:CreateInput({
    Name = "Nominal Transfer (Minimal 10000)",
    PlaceholderText = "1000000",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local angka = tonumber(Text)
        if angka and angka >= 10000 then
            nominalTransfer = math.floor(angka)
        else
            Rayfield:Notify({
                Title = "Nominal Tidak Valid",
                Content = "Masukkan angka minimal 10000 tanpa titik/koma.",
                Duration = 3,
                Image = "alert-circle"
            })
        end
    end,
})

BankTab:CreateSlider({
    Name = "Transfer Setiap Berapa Kali Restok",
    Range = {1, 20},
    Increment = 1,
    Suffix = "x Restok",
    CurrentValue = 2,
    Flag = "SliderIntervalRestok",
    Callback = function(Value)
        targetJumlahRestok = Value
    end,
})

BankTab:CreateToggle({
    Name = "Auto Transfer Otomatis",
    CurrentValue = false,
    Flag = "ToggleAutoTransfer",
    Callback = function(Value)
        autoTransferEnabled = Value
        if Value then
            hitunganRestok = 0
        end
        Rayfield:Notify({
            Title = Value and "Auto Transfer Aktif" or "Auto Transfer Dimatikan",
            Content = Value and ("Otomatis transfer setiap " .. targetJumlahRestok .. "x restok.") or "Auto transfer dihentikan.",
            Duration = 3,
            Image = Value and "banknote" or "power"
        })
    end,
})

-- ==========================================
-- LOOP UTAMA: AUTO RESTOK & TRIGGER BANK
-- ==========================================
task.spawn(function()
    while true do
        if autoRestokEnabled then
            local sisa = hitungSisaKardus()
            if sisa > 0 then
                sudahBeli = false
            elseif sisa == 0 and not sudahBeli then
                sudahBeli = true
                
                BeliProductRemote:FireServer({
                    {
                        jumlahKardus = jumlahBeli,
                        itemName = namaItem
                    }
                })

                hitunganRestok = hitunganRestok + 1
                
                Rayfield:Notify({
                    Title = "Restok Berhasil (" .. hitunganRestok .. "/" .. targetJumlahRestok .. ")",
                    Content = "Membeli " .. jumlahBeli .. "x " .. namaItem,
                    Duration = 3,
                    Image = "package"
                })

                -- Trigger transfer sesuai jumlah restok yang diatur di slider
                if hitunganRestok >= targetJumlahRestok then
                    hitunganRestok = 0
                    if autoTransferEnabled then
                        task.spawn(jalankanAutoTransfer)
                    end
                end
            end
        end
        task.wait(1)
    end
end)
