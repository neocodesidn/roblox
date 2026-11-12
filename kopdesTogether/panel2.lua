local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KardusRemotes = ReplicatedStorage:WaitForChild("KardusRemotes")

local BeliProductRemote = KardusRemotes:WaitForChild("BeliProduct")
local PickupRemote = KardusRemotes:WaitForChild("PickupKardus")
local PlaceRemote = KardusRemotes:WaitForChild("PlaceOil")
local PlaceDoneRemote = KardusRemotes:WaitForChild("PlaceOilDone")

local plot = workspace:WaitForChild("Plot1")
local clickObject = plot:WaitForChild("ClickObject")

-- ==========================================
-- VARIABEL KONFIGURASI (DUA FITUR TERPISAH)
-- ==========================================
local autoRestokEnabled = false
local autoPlaceEnabled = false

local namaItem = "Bebelove"
local jumlahBeli = 10
local sudahBeli = false
local sedangProsesPlace = false
local KAPASITAS_RAK = 12

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

local function hitungIsiSlot(slotRak)
    local jumlah = 0
    for _, child in pairs(slotRak:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart")) and child.Name ~= "Hitbox" and child.Name ~= "Part" then
            jumlah = jumlah + 1
        end
    end
    return jumlah
end

local function cariRakKosong()
    for _, rakUtama in pairs(clickObject:GetChildren()) do
        if rakUtama.Name:find("RakBelanja") and rakUtama:FindFirstChild("InputRak") then
            local daftarSubRak = rakUtama.InputRak:GetChildren()
            table.sort(daftarSubRak, function(a, b)
                return a.Name < b.Name
            end)

            for _, slotRak in pairs(daftarSubRak) do
                local isiSekarang = hitungIsiSlot(slotRak)
                if isiSekarang < KAPASITAS_RAK then
                    return slotRak, isiSekarang
                end
            end
        end
    end
    return nil, 0
end

local function buatGridSisaSlot(slotRak, mulaiDariIndex, jumlahItemKardus)
    local daftarPosisi = {}
    local scaleItem = 0.65325327170568559
    local jarakX = 0.5677
    local jarakZ = 0.6099
    local tinggiY = 0.25

    local slotTerpakai = 0
    local indexSekarang = 0

    for baris = 0, 2 do
        for kolom = 0, 3 do
            indexSekarang = indexSekarang + 1
            if indexSekarang > mulaiDariIndex and slotTerpakai < jumlahItemKardus then
                local offsetX = (kolom - 1.5) * jarakX
                local offsetZ = (baris - 1) * jarakZ
                local posisiItem = slotRak.CFrame * CFrame.new(offsetX, tinggiY, offsetZ) * CFrame.Angles(0, math.pi, 0)
                
                table.insert(daftarPosisi, {
                    cf = posisiItem,
                    scale = scaleItem
                })
                slotTerpakai = slotTerpakai + 1
            end
        end
    end

    return daftarPosisi
end

-- ==========================================
-- UI RAYFIELD (INFO & SHOP LENGKAP)
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Kopdes Together | v0.1",
    LoadingTitle = "Kopdes Together",
    LoadingSubtitle = "by Cheese Dev",
    ConfigurationSaving = { Enabled = false }
})

-- TAB 1: INFO
local InfoTab = Window:CreateTab("Info", "info")
InfoTab:CreateSection("Informasi Script")
InfoTab:CreateParagraph({
    Title = "Kopdes Together",
    Content = "Versi: 0.1\nFitur: Auto Restok (Anti-Spam) & Auto Tata Rak Kosong"
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

-- TAB 2: SHOP (SEMUA FITUR TERGABUNG)
local ShopTab = Window:CreateTab("Shop", "shopping-cart")

-- Bagian Pengaturan Produk
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

-- Bagian Fitur 1: Auto Restok (Fitur Lama)
ShopTab:CreateSection("Fitur Auto Restok")
ShopTab:CreateToggle({
    Name = "Auto Restok Kardus (Beli Otomatis)",
    CurrentValue = false,
    Flag = "ToggleRestok",
    Callback = function(Value)
        autoRestokEnabled = Value
        if Value then sudahBeli = false end
        Rayfield:Notify({
            Title = Value and "Auto Restok Aktif" or "Auto Restok Dimatikan",
            Content = Value and "Membeli otomatis saat kardus di Plot1 habis." or "Auto beli dihentikan.",
            Duration = 3,
            Image = Value and "refresh-cw" or "power"
        })
    end,
})

-- Bagian Fitur 2: Auto Place ke Rak Kosong (Fitur Tambahan)
ShopTab:CreateSection("Fitur Auto Tata Rak")
ShopTab:CreateToggle({
    Name = "Auto Ambil & Taruh ke Rak Kosong",
    CurrentValue = false,
    Flag = "ToggleAutoPlace",
    Callback = function(Value)
        autoPlaceEnabled = Value
        Rayfield:Notify({
            Title = Value and "Auto Place Aktif" or "Auto Place Dimatikan",
            Content = Value and "Memindahkan kardus ke rak yang kosong..." or "Auto tata rak dihentikan.",
            Duration = 3,
            Image = Value and "package" or "power"
        })
    end,
})

-- ==========================================
-- LOOP 1: AUTO RESTOK (ANTI-SPAM)
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
                Rayfield:Notify({
                    Title = "Restok Berhasil",
                    Content = "Membeli " .. jumlahBeli .. "x " .. namaItem,
                    Duration = 3,
                    Image = "shopping-bag"
                })
            end
        end
        task.wait(1)
    end
end)

-- ==========================================
-- LOOP 2: AUTO AMBIL & TARUH KE RAK KOSONG
-- ==========================================
task.spawn(function()
    while true do
        if autoPlaceEnabled and not sedangProsesPlace then
            sedangProsesPlace = true
            
            local kardus = clickObject:FindFirstChild("Kardus")
            local targetRak, isiSekarang = cariRakKosong()
            
            if kardus and targetRak then
                local itemTarget = kardus:GetAttribute("ItemName") or namaItem
                local sisaKapasitas = KAPASITAS_RAK - isiSekarang
                local gridData = buatGridSisaSlot(targetRak, isiSekarang, sisaKapasitas)

                PickupRemote:FireServer(kardus, itemTarget)
                task.wait(0.3)

                PlaceRemote:FireServer(targetRak)
                task.wait(0.3)

                PlaceDoneRemote:FireServer(targetRak, gridData, itemTarget)
                task.wait(0.5)
            end
            
            sedangProsesPlace = false
        end
        task.wait(0.5)
    end
end)
