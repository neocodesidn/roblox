local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage:WaitForChild("KardusRemotes"):WaitForChild("BeliProduct")

-- Path ke Plot dan ClickObject
local plot = workspace:WaitForChild("Plot1")
local clickObject = plot:WaitForChild("ClickObject")

local NAMA_ITEM = "Bebelove"
local JUMLAH_BELI = 10
local DELAY_CEK = 1 -- Cek setiap 1 detik biar responsif

-- Flag untuk mencegah spam beli
local sudahBeli = false

-- Fungsi untuk hitung sisa kardus di ClickObject
local function hitungSisaKardus()
    local jumlah = 0
    for _, v in pairs(clickObject:GetChildren()) do
        if v.Name == "Kardus" then
            jumlah = jumlah + 1
        end
    end
    return jumlah
end

task.spawn(function()
    print("Auto Restok (Anti-Spam) Active...")
    while true do
        local sisa = hitungSisaKardus()
        
        if sisa > 0 then
            -- Kalau ada kardus di workspace, reset status biar siap beli lagi pas habis
            sudahBeli = false
        elseif sisa == 0 and not sudahBeli then
            -- Kardus habis total DAN belum beli -> panggil FireServer HANYA SEKALI
            print("Kardus habis di workspace! Membeli " .. NAMA_ITEM .. "...")
            
            sudahBeli = true -- Lock status biar ga nyepam di loop berikutnya
            
            Event:FireServer({
                {
                    jumlahKardus = JUMLAH_BELI,
                    itemName = NAMA_ITEM
                }
            })
        end
        
        task.wait(DELAY_CEK)
    end
end)
