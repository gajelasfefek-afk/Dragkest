-- =========================================================
--   ROBLOX AUTO-HOPPER PRO  ·  Termux Edition  v3.0
-- =========================================================

-- ── Auto-Update dari GitHub ───────────────────────────────
local REMOTE_URL   = "https://raw.githubusercontent.com/Dragkest/Hopper/refs/heads/main/Hopper.lua"
local INSTALL_DIR  = "/sdcard/Download/Dragkest"
local INSTALL_PATH = INSTALL_DIR .. "/Hopper.lua"
local SELF_PATH    = arg and arg[0] or "Hopper.lua"

local function bootstrap()
    os.execute("mkdir -p " .. INSTALL_DIR)

    io.write("\27[1;33m[~] Checking update...\27[0m\r")
    io.flush()

    local tmp = INSTALL_DIR .. "/.hopper_tmp.lua"
    local ret = os.execute(string.format(
        "curl -fsSL --connect-timeout 5 -o '%s' '%s' 2>/dev/null",
        tmp, REMOTE_URL
    ))

    if ret == 0 then
        local function fread(p)
            local f = io.open(p, "r"); if not f then return "" end
            local s = f:read("*a"); f:close(); return s
        end
        local old = fread(INSTALL_PATH)
        local new = fread(tmp)
        if old ~= new then
            os.execute("mv " .. tmp .. " " .. INSTALL_PATH)
            print("\27[1;32m[✓] Script diperbarui dari GitHub!\27[0m")
        else
            os.execute("rm -f " .. tmp)
            print("\27[1;30m[✓] Versi sudah terbaru.          \27[0m")
        end
    else
        os.execute("rm -f " .. tmp)
        print("\27[1;31m[!] Offline — pakai versi lokal.  \27[0m")
    end
    os.execute("sleep 1")

    -- Kalau script ada di INSTALL_PATH dan bukan diri sendiri, jalanin dari sana
    local f = io.open(INSTALL_PATH, "r")
    if f then
        f:close()
        if SELF_PATH ~= INSTALL_PATH then
            dofile(INSTALL_PATH)
            os.exit(0)
        end
    end
end

bootstrap()

-- =========================================================
--   MAIN SCRIPT
-- =========================================================

local config_file = INSTALL_DIR .. "/hopper_data.json"

-- ── Helper ────────────────────────────────────────────────
local function shell(cmd)
    return os.execute(cmd)
end

local function shell_read(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return s or ""
end

-- ── Freeform / Windowed Mode (Android 13+) ───────────────
local function enable_freeform()
    shell("su -c 'settings put global enable_freeform_support 1' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 1' 2>/dev/null")
end

local function disable_freeform()
    shell("su -c 'settings put global enable_freeform_support 0' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 0' 2>/dev/null")
end

-- ── Detect Package — general, bebas prefix apapun ────────
local function detect_package(saved_pkg)
    if saved_pkg and saved_pkg ~= "" then
        local chk = shell_read("pm list packages | grep -F '" .. saved_pkg .. "'")
        if chk ~= "" then return saved_pkg end
    end
    local found = shell_read("pm list packages | grep -i roblox")
    if found ~= "" then
        local pkg = found:match("package:(.-)%s*[\r\n]")
        if pkg then return pkg end
    end
    return saved_pkg or "com.roblox.client"
end

-- ── Simpan Data ke JSON ───────────────────────────────────
local function save_db(data)
    os.execute("mkdir -p " .. INSTALL_DIR)
    local f = io.open(config_file, "w")
    if f then
        local srv_list = {}
        for _, v in ipairs(data.list) do
            table.insert(srv_list, string.format(
                '    {"name": "%s", "link": "%s", "min": %d}',
                v.name, v.link, v.min
            ))
        end
        f:write('{\n' ..
            '  "package": "' .. data.package .. '",\n' ..
            '  "freeform": ' .. (data.freeform and "true" or "false") .. ',\n' ..
            '  "servers": [\n' .. table.concat(srv_list, ",\n") .. '\n  ]\n}')
        f:close()
    end
end

-- ── Baca Data dari JSON ───────────────────────────────────
local function load_db()
    local f = io.open(config_file, "r")
    if not f then
        return {package = "com.roblox.client", freeform = false, list = {}}
    end
    local content = f:read("*a"); f:close()
    local pkg   = content:match('"package"%s*:%s*"(.-)"') or "com.roblox.client"
    local ffstr = content:match('"freeform"%s*:%s*(%a+)') or "false"
    local list  = {}
    for n, l, m in content:gmatch(
        '{"name"%s*:%s*"(.-)"%s*,%s*"link"%s*:%s*"(.-)"%s*,%s*"min"%s*:%s*(%d+)}'
    ) do
        table.insert(list, {name = n, link = l, min = tonumber(m)})
    end
    return {package = pkg, freeform = (ffstr == "true"), list = list}
end

-- ── Warna ANSI ────────────────────────────────────────────
local C = {
    reset   = "\27[0m",
    cyan    = "\27[1;36m",
    green   = "\27[1;32m",
    yellow  = "\27[1;33m",
    red     = "\27[1;31m",
    white   = "\27[1;37m",
    gray    = "\27[0;90m",
    magenta = "\27[1;35m",
    blue    = "\27[1;34m",
}

local function c(color, text) return color .. text .. C.reset end
local SEP = "  " .. string.rep("─", 44)

-- ── Draw Header ───────────────────────────────────────────
local function draw_header(title)
    shell("clear")
    print(C.cyan)
    print("  ╔══════════════════════════════════════════╗")
    print(string.format("  ║  %-42s║", "🎮  " .. title))
    print("  ╚══════════════════════════════════════════╝")
    print(C.reset)
end

-- ── Dashboard Hopping ─────────────────────────────────────
local function draw_ui(pkg, srv_name, sisa, total_m, idx, total_srv, freeform)
    shell("clear")
    local m      = math.floor(sisa / 60)
    local s      = sisa % 60
    local pct    = ((total_m * 60) - sisa) / (total_m * 60)
    local filled = math.floor(pct * 22)
    local bar    = c(C.green, string.rep("█", filled))
               .. c(C.gray,  string.rep("░", 22 - filled))
    local ff_str = freeform and c(C.green, "ON ✓") or c(C.gray, "OFF")

    print(C.cyan)
    print("  ╔══════════════════════════════════════════╗")
    print("  ║        ROBLOX HOPPER  -Jacob      ║")
    print("  ╚══════════════════════════════════════════╝")
    print(C.reset)

    print(c(C.gray, "  ┌──────────────────────────────────────────┐"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "PACKAGE"))
          .. c(C.white, string.format("%-30s", pkg:sub(1,29))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "SERVER"))
          .. c(C.white, string.format("%-30s", srv_name:sub(1,29))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "SLOT"))
          .. c(C.white, string.format("%-30s",
              string.format("%d dari %d server", idx, total_srv))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "FREEFORM"))
          .. ff_str .. string.rep(" ", 27) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "SISA WAKTU"))
          .. c(C.cyan, string.format("%02d:%02d", m, s))
          .. c(C.gray, string.format(" / %d:00 min", total_m))
          .. string.rep(" ", 17 - #tostring(total_m)) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "PROGRESS"))
          .. "[" .. bar .. "] " .. c(C.magenta, string.format("%3d%%", math.floor(pct*100)))
          .. c(C.gray, "│"))
    print(c(C.gray, "  └──────────────────────────────────────────┘"))
    print("")
    print(c(C.green, "  ● STATUS  ") .. c(C.white, "Roblox sedang berjalan"))
    print(c(C.gray,  "  ⌨  CTRL+C  ") .. c(C.gray, "untuk menghentikan script"))
    print("")
end

-- ── Main ──────────────────────────────────────────────────
local function main()
    local db = load_db()
    db.package = detect_package(db.package)

    while true do
        draw_header("ROBLOX PRIVATE SERVER HOPPER")
        print(c(C.gray, SEP))
        print(c(C.yellow, "  PACKAGE   ") .. c(C.white, db.package))
        print(c(C.yellow, "  FREEFORM  ") .. (db.freeform and c(C.green, "ON ✓") or c(C.gray, "OFF")))
        print(c(C.gray, SEP))
        print("")
        print(c(C.green,   "  [1]") .. c(C.white, "  Jalankan Auto-Hop"))
        print(c(C.blue,    "  [2]") .. c(C.white, "  Tambah Private Server"))
        print(c(C.blue,    "  [3]") .. c(C.white, "  Lihat / Hapus Server  ")
              .. c(C.gray, string.format("(%d tersimpan)", #db.list)))
        print(c(C.magenta, "  [4]") .. c(C.white, "  Ganti Package Name"))
        print(c(C.cyan,    "  [5]") .. c(C.white, "  Toggle Freeform Android 13  ")
              .. (db.freeform and c(C.green, "[ON]") or c(C.gray, "[OFF]")))
        print(c(C.red,     "  [6]") .. c(C.white, "  Keluar"))
        print("")
        print(c(C.gray, SEP))
        io.write(c(C.cyan, "  » "))
        local opt = io.read()

        -- ── [1] Auto-Hop ───────────────────────────────────
        if opt == "1" then
            if #db.list == 0 then
                print(c(C.red, "\n  [!] List server kosong. Tambah dulu!"))
                shell("sleep 2")
            else
                if db.freeform then enable_freeform() end

                local i = 1
                while true do
                    local s = db.list[i]
                    draw_header("AUTO-HOP AKTIF")

                    print(c(C.yellow, "  Menutup Roblox..."))
                    shell("su -c 'am force-stop " .. db.package .. "' 2>/dev/null")
                    shell("sleep 2")

                    print(c(C.green, "  Membuka server: " .. s.name))
                    if db.freeform then
                        shell(string.format(
                            "su -c 'am start --windowingMode 5 -a android.intent.action.VIEW -d \"%s\" %s' > /dev/null 2>&1",
                            s.link, db.package
                        ))
                    else
                        shell(string.format(
                            "am start -a android.intent.action.VIEW -d '%s' %s > /dev/null 2>&1",
                            s.link, db.package
                        ))
                    end

                    for d = (s.min * 60), 0, -1 do
                        draw_ui(db.package, s.name, d, s.min, i, #db.list, db.freeform)
                        shell("sleep 1")
                    end

                    i = (i % #db.list) + 1
                end
            end

        -- ── [2] Tambah Server ──────────────────────────────
        elseif opt == "2" then
            draw_header("TAMBAH PRIVATE SERVER")
            io.write(c(C.yellow, "  Nama Server  : ")); local n = io.read()
            io.write(c(C.yellow, "  Link PS      : ")); local l = io.read()
            io.write(c(C.yellow, "  Durasi (mnt) : ")); local m = tonumber(io.read()) or 5
            if n ~= "" and l ~= "" then
                table.insert(db.list, {name = n, link = l, min = m})
                save_db(db)
                print(c(C.green, "\n  [+] Berhasil ditambahkan!"))
            else
                print(c(C.red, "\n  [!] Gagal — data tidak lengkap."))
            end
            shell("sleep 1")

        -- ── [3] Lihat / Hapus ──────────────────────────────
        elseif opt == "3" then
            draw_header("DAFTAR SERVER")
            if #db.list == 0 then
                print(c(C.gray, "  (kosong)"))
            else
                print(c(C.gray, SEP))
                for idx, val in ipairs(db.list) do
                    print(string.format(
                        c(C.yellow, "  [%d]") .. c(C.white, "  %-28s") .. c(C.gray, " %d min"),
                        idx, val.name:sub(1,28), val.min
                    ))
                end
                print(c(C.gray, SEP))
            end
            io.write(c(C.cyan, "\n  Nomor untuk hapus / [x] kembali: "))
            local del = io.read()
            if tonumber(del) and db.list[tonumber(del)] then
                table.remove(db.list, tonumber(del))
                save_db(db)
                print(c(C.green, "  [-] Berhasil dihapus!"))
                shell("sleep 1")
            end

        -- ── [4] Ganti Package ──────────────────────────────
        elseif opt == "4" then
            draw_header("GANTI PACKAGE NAME")
            print(c(C.gray,   "  Package saat ini : ") .. c(C.white, db.package))
            print(c(C.gray,   "  ─────────────────────────────────────────"))
            print(c(C.gray,   "  Package apapun diterima, contoh:"))
            print(c(C.cyan,   "    com.roblox.client"))
            print(c(C.cyan,   "    com.byfron.roblox"))
            print(c(C.cyan,   "    app.roblox.android"))
            io.write(c(C.yellow, "\n  Package baru : "))
            local new_p = io.read()
            if new_p and new_p ~= "" then
                if not new_p:match("%.") then
                    print(c(C.red, "\n  [!] Format kurang valid, minimal ada titik (contoh: com.xxx.yyy)"))
                else
                    db.package = new_p
                    save_db(db)
                    print(c(C.green, "  [OK] Package diperbarui → " .. new_p))
                end
            end
            shell("sleep 2")

        -- ── [5] Toggle Freeform ────────────────────────────
        elseif opt == "5" then
            draw_header("FREEFORM MODE — Android 13+")
            db.freeform = not db.freeform
            save_db(db)
            if db.freeform then
                enable_freeform()
                print(c(C.green, "  [ON]  Freeform diaktifkan!"))
                print(c(C.gray,  "  App akan launch dalam mode windowed."))
                print(c(C.gray,  "  Pastikan device support freeform (Android 13+)."))
            else
                disable_freeform()
                print(c(C.gray,  "  [OFF] Freeform dimatikan."))
                print(c(C.gray,  "  App akan launch fullscreen seperti biasa."))
            end
            shell("sleep 2")

        -- ── [6] Keluar ─────────────────────────────────────
        elseif opt == "6" then
            print(c(C.cyan, "\n  Sampai jumpa! 👋\n"))
            break
        end
    end
end

main()
