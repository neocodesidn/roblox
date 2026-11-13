local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local KardusRemotes = ReplicatedStorage:WaitForChild("KardusRemotes")
local BankRemotes = ReplicatedStorage:WaitForChild("BankRemotes")

local BeliProductRemote = KardusRemotes:WaitForChild("BeliProduct")
local GetStateRemote = BankRemotes:WaitForChild("GetState")
local TransferRemote = BankRemotes:WaitForChild("Transfer")

local plot = workspace:WaitForChild("Plot1")
local clickObject = plot:WaitForChild("ClickObject")

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- ==========================================
-- VARIABEL KONFIGURASI
-- ==========================================
local autoRestokEnabled = false
local autoGajianGantiHari = false
local modeUlangTiapHari = true
local antiAfkEnabled = true

local namaItem = "Bebelove"
local jumlahBeli = 10
local sudahBeli = false

-- Konfigurasi Gaji Tetap Per Hari
local gajiPerHariJuta = 10
local modePembagian = "Bagi Rata Anggaran ke Semua Anggota"
local targetUserId = nil
local targetPlayerName = ""

-- Konfigurasi Discord Webhook (Components V2)
local webhookUrl = ""
local webhookEnabled = false

-- State Pelacak Hari & Anti-Double Lock
local hariTerakhir = nil
local hariSudahDibayar = nil
local adaLabelHari = false
local sudahGajianClockTime = false
local sedangProsesGajian = false
local waktuGajianAutoTerakhir = 0

-- ==========================================
-- HELPER FORMAT ANGKA & DISCORD WEBHOOK V2
-- ==========================================
local function formatRupiah(angka)
    local formatted = tostring(math.floor(angka))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

local function kirimWebhookV2(judul, isiLaporan, catatanFooter)
    if not httpRequest then return false, "Executor tidak mendukung HTTP Request." end
    if webhookUrl == "" or not webhookUrl:find("discord.com/api/webhooks/") then
        return false, "URL Webhook tidak valid."
    end

    local targetUrl = webhookUrl
    if not targetUrl:find("with_components=true") then
        targetUrl = targetUrl .. (targetUrl:find("?") and "&" or "?") .. "with_components=true"
    end

    -- Components V2 tanpa accent_color pada Container (type = 17)
    local payload = {
        username = "Kopdes Payroll System",
        flags = 32768,
        components = {
            {
                type = 17,
                components = {
                    {
                        type = 10,
                        content = "### " .. judul .. "\n" .. isiLaporan
                    },
                    {
                        type = 14,
                        divider = true,
                        spacing = 1
                    },
                    {
                        type = 10,
                        content = "-# " .. (catatanFooter or "Kopdes Together • Cheese Dev")
                    }
                }
            }
        }
    }

    local success, response = pcall(function()
        return httpRequest({
            Url = targetUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success and response and (response.StatusCode == 200 or response.StatusCode == 204) then
        return true, "Terkirim"
    else
        local kode = response and tostring(response.StatusCode) or "Unknown"
        return false, "Gagal HTTP (" .. kode .. ")"
    end
end

-- ==========================================
-- ANTI-AFK OTOMATIS
-- ==========================================
LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==========================================
-- FUNGSI PENDUKUNG KAS & PEMBAYARAN GAJI
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

local function ambilDaftarAnggota()
    local daftar = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(daftar, plr.Name)
        end
    end
    if #daftar == 0 then
        table.insert(daftar, "Tidak ada anggota lain")
    end
    return daftar
end

local function ambilSaldoToko()
    local success, state = pcall(function()
        return GetStateRemote:InvokeServer()
    end)
    if success and typeof(state) == "table" and typeof(state.shopBalance) == "number" then
        return state.shopBalance
    end
    return nil
end

local function cairkanGajiHarian(labelWaktu, isManual)
    -- Lapis 1: Mutex lock agar tidak ada dua eksekusi berjalan bersamaan
    if sedangProsesGajian then return end

    -- Lapis 2: Cooldown 30 detik khusus trigger otomatis ganti hari
    if not isManual and (os.clock() - waktuGajianAutoTerakhir) < 30 then
        return
    end

    sedangProsesGajian = true
    if not isManual then
        waktuGajianAutoTerakhir = os.clock()
    end

    local okEksekusi, errEksekusi = pcall(function()
        local totalGaji = gajiPerHariJuta * 1000000
        local saldoToko = ambilSaldoToko()

        if not saldoToko then
            Rayfield:Notify({
                Title = "Gagal Mengecek Kas",
                Content = "Tidak dapat membaca saldo toko dari server.",
                Duration = 4,
                Image = "alert-triangle"
            })
            return
        end

        if saldoToko < totalGaji then
            Rayfield:Notify({
                Title = "Kas Toko Tidak Cukup",
                Content = "Saldo (Rp " .. formatRupiah(saldoToko) .. ") kurang dari anggaran Rp " .. gajiPerHariJuta .. " Juta.",
                Duration = 4,
                Image = "shield-alert"
            })
            return
        end

        -- MODE 1: BAGI RATA ANGGARAN KE SEMUA ANGGOTA DI SERVER
        if modePembagian == "Bagi Rata Anggaran ke Semua Anggota" then
            local penerima = {}
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    table.insert(penerima, plr)
                end
            end

            if #penerima == 0 then
                Rayfield:Notify({
                    Title = "Tidak Ada Karyawan",
                    Content = "Tidak ada pemain lain di server saat pergantian hari.",
                    Duration = 3,
                    Image = "users"
                })
                return
            end

            local gajiPerOrang = math.floor(totalGaji / #penerima)
            if gajiPerOrang < 10000 then
                Rayfield:Notify({
                    Title = "Nominal Terlalu Kecil",
                    Content = "Jatah per orang (Rp " .. formatRupiah(gajiPerOrang) .. ") di bawah minimal Rp 10.000.",
                    Duration = 4,
                    Image = "alert-circle"
                })
                return
            end

            local berhasil = 0
            local daftarNamaPenerima = {}

            for _, plr in ipairs(penerima) do
                local res = TransferRemote:InvokeServer({
                    targetType = "Player",
                    targetUserId = plr.UserId,
                    sourceType = "Toko",
                    amount = gajiPerOrang
                })
                if typeof(res) == "table" and res.ok then
                    berhasil = berhasil + 1
                    table.insert(daftarNamaPenerima, "`" .. plr.Name .. "`")
                end
                task.wait(0.35)
            end

            local sisaSaldo = saldoToko - (gajiPerOrang * berhasil)

            Rayfield:Notify({
                Title = "Gajian " .. (labelWaktu or "Harian") .. " Cair!",
                Content = "Rp " .. formatRupiah(gajiPerOrang) .. "/orang dikirim ke " .. berhasil .. " anggota.",
                Duration = 5,
                Image = "check-circle"
            })

            if webhookEnabled and berhasil > 0 then
                local isi = string.format(
                    "**Waktu:** %s\n**Mode:** Bagi Rata (%d Anggota)\n**Jatah / Orang:** Rp %s\n**Total Keluar:** Rp %s\n**Penerima:** %s\n**Sisa Kas Toko:** Rp %s",
                    labelWaktu or "Harian",
                    berhasil,
                    formatRupiah(gajiPerOrang),
                    formatRupiah(gajiPerOrang * berhasil),
                    table.concat(daftarNamaPenerima, ", "),
                    formatRupiah(sisaSaldo)
                )
                task.spawn(function()
                    kirimWebhookV2("Laporan Gajian Koperasi", isi, "Auto Payroll • " .. os.date("%d/%m/%Y %H:%M"))
                end)
            end

        -- MODE 2: FULL KE 1 ANGGOTA PILIHAN
        else
            if not targetUserId then
                Rayfield:Notify({
                    Title = "Anggota Belum Dipilih",
                    Content = "Pilih penerima dulu pada dropdown di tab Bank.",
                    Duration = 3,
                    Image = "user-x"
                })
                return
            end

            local res = TransferRemote:InvokeServer({
                targetType = "Player",
                targetUserId = targetUserId,
                sourceType = "Toko",
                amount = totalGaji
            })

            if typeof(res) == "table" and res.ok then
                local sisaSaldo = saldoToko - totalGaji

                Rayfield:Notify({
                    Title = "Gajian " .. (labelWaktu or "Harian") .. " Cair!",
                    Content = "Terkirim Rp " .. formatRupiah(totalGaji) .. " ke " .. targetPlayerName,
                    Duration = 4,
                    Image = "check-circle"
                })

                if webhookEnabled then
                    local isi = string.format(
                        "**Waktu:** %s\n**Mode:** Perorangan\n**Penerima:** `%s` (`%d`)\n**Nominal Gaji:** Rp %s\n**Sisa Kas Toko:** Rp %s",
                        labelWaktu or "Harian",
                        targetPlayerName,
                        targetUserId,
                        formatRupiah(totalGaji),
                        formatRupiah(sisaSaldo)
                    )
                    task.spawn(function()
                        kirimWebhookV2("Laporan Gajian Koperasi", isi, "Auto Payroll • " .. os.date("%d/%m/%Y %H:%M"))
                    end)
                end
            else
                local msg = (typeof(res) == "table" and res.message) or "Transaksi ditolak server."
                Rayfield:Notify({
                    Title = "Transfer Gagal",
                    Content = tostring(msg),
                    Duration = 4,
                    Image = "x-circle"
                })
            end
        end
    end)

    sedangProsesGajian = false
end

-- ==========================================
-- DETEKTOR PERGANTIAN HARI (ANTI-BENTROK)
-- ==========================================
local AutoGajianToggle

local function eksekusiTriggerHariBaru(hariBaru)
    if not autoGajianGantiHari then return end

    if not modeUlangTiapHari then
        autoGajianGantiHari = false
        if AutoGajianToggle then
            AutoGajianToggle:Set(false)
        end
    end

    local teksHari = hariBaru and ("Hari " .. tostring(hariBaru)) or "Ganti Hari"
    task.spawn(function()
        cairkanGajiHarian(teksHari, false)
    end)
end

-- Jalur Utama: TextLabel HUD "Hari X"
local function pasangListenerLabelHari(obj)
    if obj:IsA("TextLabel") and obj.Text:match("^Hari%s*%d+") then
        adaLabelHari = true
        local angkaAwal = tonumber(obj.Text:match("%d+"))
        if angkaAwal and not hariTerakhir then
            hariTerakhir = angkaAwal
            hariSudahDibayar = angkaAwal -- Tandai hari saat ini agar tidak langsung transfer saat eksekusi awal
        end

        obj:GetPropertyChangedSignal("Text"):Connect(function()
            local angkaBaru = tonumber(obj.Text:match("%d+"))
            if angkaBaru and hariTerakhir and angkaBaru > hariTerakhir then
                hariTerakhir = angkaBaru
                -- Lapis 3: Pastikan nomor hari ini belum pernah dibayar sebelumnya
                if hariSudahDibayar ~= angkaBaru then
                    hariSudahDibayar = angkaBaru
                    eksekusiTriggerHariBaru(angkaBaru)
                end
            end
        end)
    end
end

for _, uiObj in ipairs(PlayerGui:GetDescendants()) do
    pasangListenerLabelHari(uiObj)
end
PlayerGui.DescendantAdded:Connect(pasangListenerLabelHari)

-- Jalur Cadangan: Hanya aktif jika label HUD Hari tidak ditemukan sama sekali
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
    if adaLabelHari then return end

    local jam = Lighting.ClockTime
    if jam >= 21 and jam < 21.5 then
        if not sudahGajianClockTime then
            sudahGajianClockTime = true
            eksekusiTriggerHariBaru(nil)
        end
    elseif jam < 20 then
        sudahGajianClockTime = false
    end
end)

-- ==========================================
-- UI RAYFIELD
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Kopdes Together | v0.8",
    LoadingTitle = "Kopdes Together",
    LoadingSubtitle = "by Cheese Dev",
    ConfigurationSaving = { Enabled = false }
})

-- TAB 1: INFO
local InfoTab = Window:CreateTab("Info", "info")
InfoTab:CreateSection("Informasi Script")
InfoTab:CreateParagraph({
    Title = "Kopdes Together - Anti-Double Payroll",
    Content = "Versi: 0.8\nFitur: Auto Restok, Gaji Harian (Anti-Double Lock), Anti-AFK, & Webhook V2"
})

InfoTab:CreateToggle({
    Name = "Anti-AFK (Cegah Kick 20 Menit)",
    CurrentValue = true,
    Flag = "ToggleAntiAFK",
    Callback = function(Value)
        antiAfkEnabled = Value
    end,
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

-- TAB 2: SHOP
local ShopTab = Window:CreateTab("Shop", "shopping-cart")
ShopTab:CreateSection("Pengaturan Produk")

ShopTab:CreateInput({
    Name = "Nama Item (Tekan Enter Setelah Ketik)",
    PlaceholderText = "Bebelove",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text ~= "" then
            namaItem = Text
            Rayfield:Notify({
                Title = "Item Diatur",
                Content = "Target produk: " .. namaItem,
                Duration = 2,
                Image = "check"
            })
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
        if Value then sudahBeli = false end
        Rayfield:Notify({
            Title = Value and "Auto Restok Aktif" or "Auto Restok Dimatikan",
            Content = Value and "Memantau stok kardus di Plot1..." or "Auto beli dihentikan.",
            Duration = 3,
            Image = Value and "refresh-cw" or "power"
        })
    end,
})

-- TAB 3: BANK
local BankTab = Window:CreateTab("Bank", "banknote")

BankTab:CreateSection("Status Kas & Anggaran Gaji")
BankTab:CreateButton({
    Name = "Cek Saldo Kas Toko & Status Hari",
    Callback = function()
        local saldo = ambilSaldoToko()
        local infoHari = hariTerakhir and ("Hari " .. tostring(hariTerakhir)) or "Terdeteksi otomatis saat ganti hari"
        Rayfield:Notify({
            Title = "Status Koperasi (" .. infoHari .. ")",
            Content = saldo and ("Saldo Toko: Rp " .. formatRupiah(saldo)) or "Gagal membaca saldo.",
            Duration = 4,
            Image = "wallet"
        })
    end,
})

BankTab:CreateSlider({
    Name = "Anggaran Gaji Per Hari",
    Range = {1, 50},
    Increment = 1,
    Suffix = " Juta / Hari",
    CurrentValue = 10,
    Flag = "SliderGajiHarian",
    Callback = function(Value)
        gajiPerHariJuta = Value
    end,
})

BankTab:CreateSection("Penerima Gaji")
BankTab:CreateDropdown({
    Name = "Mode Pembagian Gaji",
    Options = {"Bagi Rata Anggaran ke Semua Anggota", "Full ke 1 Anggota Pilihan"},
    CurrentOption = {"Bagi Rata Anggaran ke Semua Anggota"},
    MultipleOptions = false,
    Flag = "DropdownModeGaji",
    Callback = function(Options)
        modePembagian = Options[1]
    end,
})

local AnggotaDropdown = BankTab:CreateDropdown({
    Name = "Pilih Anggota (Khusus Mode 1 Orang)",
    Options = ambilDaftarAnggota(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "DropdownAnggota",
    Callback = function(Options)
        local namaDipilih = Options[1]
        local plrTarget = Players:FindFirstChild(namaDipilih)
        if plrTarget then
            targetUserId = plrTarget.UserId
            targetPlayerName = plrTarget.Name
            Rayfield:Notify({
                Title = "Penerima Dipilih",
                Content = plrTarget.Name,
                Duration = 2,
                Image = "user-check"
            })
        else
            targetUserId = nil
            targetPlayerName = ""
        end
    end,
})

BankTab:CreateButton({
    Name = "Refresh Daftar Anggota Server",
    Callback = function()
        AnggotaDropdown:Refresh(ambilDaftarAnggota())
        Rayfield:Notify({
            Title = "Daftar Diperbarui",
            Content = "Daftar pemain di server telah dimuat ulang.",
            Duration = 2,
            Image = "refresh-cw"
        })
    end,
})

BankTab:CreateSection("Otomatisasi Gajian Ganti Hari (Jam 21:00)")

BankTab:CreateToggle({
    Name = "Mode AFK: Ulangi Tiap Ganti Hari",
    CurrentValue = true,
    Flag = "ToggleUlangHari",
    Callback = function(Value)
        modeUlangTiapHari = Value
    end,
})

AutoGajianToggle = BankTab:CreateToggle({
    Name = "Auto Gajian Saat Ganti Hari (21:00)",
    CurrentValue = false,
    Flag = "ToggleAutoGajianHari",
    Callback = function(Value)
        autoGajianGantiHari = Value
        Rayfield:Notify({
            Title = Value and "Auto Gajian Aktif" or "Auto Gajian Dimatikan",
            Content = Value and ("Gaji Rp " .. gajiPerHariJuta .. " Juta cair 1x setiap ganti hari.") or "Auto gajian dihentikan.",
            Duration = 3,
            Image = Value and "calendar-check" or "power"
        })
    end,
})

BankTab:CreateButton({
    Name = "Cairkan Gaji Sekarang (Manual 1x Klik)",
    Callback = function()
        task.spawn(function()
            cairkanGajiHarian("Manual", true)
        end)
    end,
})

BankTab:CreateSection("Discord Webhook Log (Components V2)")

BankTab:CreateInput({
    Name = "URL Webhook Discord (Tekan Enter Setelah Paste)",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        webhookUrl = Text
        if Text ~= "" then
            Rayfield:Notify({
                Title = "Webhook Disimpan",
                Content = "URL Webhook telah diatur.",
                Duration = 2,
                Image = "link"
            })
        end
    end,
})

BankTab:CreateToggle({
    Name = "Kirim Slip Gaji ke Discord Webhook",
    CurrentValue = false,
    Flag = "ToggleWebhook",
    Callback = function(Value)
        webhookEnabled = Value
    end,
})

BankTab:CreateButton({
    Name = "Test Kirim Webhook (Components V2)",
    Callback = function()
        task.spawn(function()
            local ok, info = kirimWebhookV2(
                "Test Koneksi Koperasi",
                "**Status:** Webhook Components V2 aktif tanpa accent color.\n**Toko:** Plot1",
                "Test Notifikasi • Kopdes Together"
            )
            Rayfield:Notify({
                Title = ok and "Webhook Terkirim!" or "Webhook Gagal",
                Content = info,
                Duration = 3,
                Image = ok and "check-circle" or "x-circle"
            })
        end)
    end,
})

-- ==========================================
-- LOOP AUTO RESTOK KARDUS
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
                    Image = "package"
                })
            end
        end
        task.wait(1)
    end
end)
