-- =========================================================
--   ROBLOX AUTO-HOPPER PRO  ·  Termux Edition  v3.0
--   by Dragkest
-- =========================================================

-- ── Auto-Update from GitHub ───────────────────────────────
local REMOTE_URL   = "https://raw.githubusercontent.com/gajelasfefek-afk/Dragkest/refs/heads/main/Hopper.lua"
local INSTALL_DIR  = "/storage/emulated/0/Dragkest"
local INSTALL_PATH = INSTALL_DIR .. "/Hopper.lua"
local SELF_PATH    = arg and arg[0] or "Hopper.lua"
local config_file  = INSTALL_DIR .. "/hopper_data.json"

local function bootstrap()
    os.execute("mkdir -p " .. INSTALL_DIR)

    io.write("\27[1;33m[~] Checking for updates...\27[0m\r")
    io.flush()

    local tmp = INSTALL_DIR .. "/.hopper_tmp.lua"
    local ret = os.execute(string.format(
        "curl -L -o '%s' '%s' 2>/dev/null",
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
            print("\27[1;32m[✓] Script updated from GitHub!   \27[0m")
        else
            os.execute("rm -f " .. tmp)
            print("\27[1;30m[✓] Already up to date.           \27[0m")
        end
    else
        os.execute("rm -f " .. tmp)
        print("\27[1;31m[!] Offline — using local version. \27[0m")
    end
    os.execute("sleep 1")

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

-- ── Helpers ───────────────────────────────────────────────
local function shell(cmd)
    return os.execute(cmd)
end

local function shell_read(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return s or ""
end

-- ── Stop flag ─────────────────────────────────────────────
local STOP_FILE = INSTALL_DIR .. "/.stop"

local function stop_requested()
    local f = io.open(STOP_FILE, "r")
    if f then f:close(); return true end
    return false
end

local function clear_stop()
    os.execute("rm -f " .. STOP_FILE)
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

-- ── Detect Package ────────────────────────────────────────
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

-- ── Save DB ───────────────────────────────────────────────
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

-- ── Load DB ───────────────────────────────────────────────
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

-- ── ANSI Colors ───────────────────────────────────────────
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

-- ── Hopping Dashboard ─────────────────────────────────────
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
    print("  ║      🎮  ROBLOX HOPPER  - Jacob  🎮      ║")
    print("  ╚══════════════════════════════════════════╝")
    print(C.reset)

    print(c(C.gray, "  ┌──────────────────────────────────────────┐"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "PACKAGE"))
          .. c(C.white, string.format("%-30s", pkg:sub(1,29))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "SERVER"))
          .. c(C.white, string.format("%-30s", srv_name:sub(1,29))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "SLOT"))
          .. c(C.white, string.format("%-30s",
              string.format("%d of %d servers", idx, total_srv))) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "FREEFORM"))
          .. ff_str .. string.rep(" ", 27) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "TIME LEFT"))
          .. c(C.cyan, string.format("%02d:%02d", m, s))
          .. c(C.gray, string.format(" / %d:00 min", total_m))
          .. string.rep(" ", 17 - #tostring(total_m)) .. c(C.gray, "│"))
    print(c(C.gray, "  │") .. c(C.yellow, string.format(" %-13s", "PROGRESS"))
          .. "[" .. bar .. "] " .. c(C.magenta, string.format("%3d%%", math.floor(pct*100)))
          .. c(C.gray, "│"))
    print(c(C.gray, "  └──────────────────────────────────────────┘"))
    print("")
    print(c(C.green, "  ● STATUS   ") .. c(C.white, "Roblox is running"))
    print(c(C.red,   "  [Q] STOP   ") .. c(C.gray, "type q + Enter to stop hopping"))
    print("")
end

-- ── Non-blocking input check ──────────────────────────────
-- Nulis 'q' ke stop file dari sesi lain tidak practical di Lua murni,
-- jadi kita pakai pendekatan: tiap detik cek stop file
-- User bisa stop dengan buka Termux sesi baru lalu: touch /storage/emulated/0/Dragkest/.stop
-- ATAU: kita pakai stty + read dengan timeout 1 detik
local function check_stop_input()
    -- Set terminal non-blocking, baca 1 char, restore
    local ret = os.execute(
        "read -t 1 -n 1 _KEY 2>/dev/null && [ \"$_KEY\" = 'q' ] && touch " .. STOP_FILE
    )
    return stop_requested()
end

-- ── Main ──────────────────────────────────────────────────
local function main()
    local db = load_db()
    db.package = detect_package(db.package)

    while true do
        draw_header("HOPPER SERVER")
        print(c(C.gray, SEP))
        print(c(C.yellow, "  PACKAGE   ") .. c(C.white, db.package))
        print(c(C.yellow, "  FREEFORM  ") .. (db.freeform and c(C.green, "ON ✓") or c(C.gray, "OFF")))
        print(c(C.gray, SEP))
        print("")
        print(c(C.green,   "  [1]") .. c(C.white, "  Start Auto-Hop"))
        print(c(C.blue,    "  [2]") .. c(C.white, "  Add Private Server"))
        print(c(C.blue,    "  [3]") .. c(C.white, "  View / Delete Servers  ")
              .. c(C.gray, string.format("(%d saved)", #db.list)))
        print(c(C.magenta, "  [4]") .. c(C.white, "  Edit Server Duration"))
        print(c(C.magenta, "  [5]") .. c(C.white, "  Change Package Name"))
        print(c(C.cyan,    "  [6]") .. c(C.white, "  Toggle Freeform (Android 13+)  ")
              .. (db.freeform and c(C.green, "[ON]") or c(C.gray, "[OFF]")))
        print(c(C.red,     "  [7]") .. c(C.white, "  Exit"))
        print("")
        print(c(C.gray, SEP))
        io.write(c(C.cyan, "  » "))
        local opt = io.read()

        -- ── [1] Start Auto-Hop ─────────────────────────────
        if opt == "1" then
            if #db.list == 0 then
                print(c(C.red, "\n  [!] Server list is empty. Add one first!"))
                shell("sleep 2")
            else
                if db.freeform then enable_freeform() end
                clear_stop()

                local i = 1
                local running = true

                while running do
                    local s = db.list[i]
                    draw_header("AUTO-HOP ACTIVE")

                    print(c(C.yellow, "  Closing Roblox..."))
                    shell("su -c 'am force-stop " .. db.package .. "' 2>/dev/null")
                    shell("sleep 2")

                    if stop_requested() then
                        running = false; break
                    end

                    print(c(C.green, "  Opening server: " .. s.name))
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

                    -- Countdown dengan cek stop tiap detik
                    for d = (s.min * 60), 0, -1 do
                        draw_ui(db.package, s.name, d, s.min, i, #db.list, db.freeform)
                        -- Cek input 'q' non-blocking via shell
                        shell("read -t 1 -n 1 _K 2>/dev/null && [ \"$_K\" = 'q' ] && touch " .. STOP_FILE .. " || true")
                        if stop_requested() then
                            running = false; break
                        end
                    end

                    if running then
                        i = (i % #db.list) + 1
                    end
                end

                -- Stop: tutup Roblox, balik menu
                clear_stop()
                shell("clear")
                print(c(C.yellow, "\n  [!] Hopping stopped. Closing Roblox..."))
                shell("su -c 'am force-stop " .. db.package .. "' 2>/dev/null")
                shell("sleep 2")
            end

        -- ── [2] Add Server ─────────────────────────────────
        elseif opt == "2" then
            draw_header("ADD PRIVATE SERVER")
            io.write(c(C.yellow, "  Server Name  : ")); local n = io.read()
            io.write(c(C.yellow, "  PS Link      : ")); local l = io.read()
            io.write(c(C.yellow, "  Duration(min): ")); local m = tonumber(io.read()) or 5
            if n ~= "" and l ~= "" then
                table.insert(db.list, {name = n, link = l, min = m})
                save_db(db)
                print(c(C.green, "\n  [+] Server added successfully!"))
            else
                print(c(C.red, "\n  [!] Failed — incomplete data."))
            end
            shell("sleep 1")

        -- ── [3] View / Delete ──────────────────────────────
        elseif opt == "3" then
            draw_header("SERVER LIST")
            if #db.list == 0 then
                print(c(C.gray, "  (empty)"))
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
            io.write(c(C.cyan, "\n  Enter number to delete / [x] to go back: "))
            local del = io.read()
            if tonumber(del) and db.list[tonumber(del)] then
                table.remove(db.list, tonumber(del))
                save_db(db)
                print(c(C.green, "  [-] Server deleted!"))
                shell("sleep 1")
            end

        -- ── [4] Edit Duration ──────────────────────────────
        elseif opt == "4" then
            draw_header("EDIT SERVER DURATION")
            if #db.list == 0 then
                print(c(C.gray, "  (empty)"))
                shell("sleep 1")
            else
                print(c(C.gray, SEP))
                for idx, val in ipairs(db.list) do
                    print(string.format(
                        c(C.yellow, "  [%d]") .. c(C.white, "  %-24s") .. c(C.cyan, " %d min"),
                        idx, val.name:sub(1,24), val.min
                    ))
                end
                print(c(C.gray, SEP))
                io.write(c(C.cyan, "\n  Select server number: "))
                local sel = tonumber(io.read())
                if sel and db.list[sel] then
                    print(c(C.gray, "  Current duration : ") .. c(C.cyan, db.list[sel].min .. " min"))
                    io.write(c(C.yellow, "  New duration (min): "))
                    local new_m = tonumber(io.read())
                    if new_m and new_m > 0 then
                        db.list[sel].min = new_m
                        save_db(db)
                        print(c(C.green, "  [OK] Duration updated → " .. new_m .. " min"))
                    else
                        print(c(C.red, "  [!] Invalid input."))
                    end
                else
                    print(c(C.red, "  [!] Invalid selection."))
                end
                shell("sleep 2")
            end

        -- ── [5] Change Package ─────────────────────────────
        elseif opt == "5" then
            draw_header("CHANGE PACKAGE NAME")
            print(c(C.gray, "  Current package : ") .. c(C.white, db.package))
            print(c(C.gray, "  ─────────────────────────────────────────"))
            print(c(C.gray, "  Any package is accepted, examples:"))
            print(c(C.cyan, "    com.roblox."))
            print(c(C.cyan, "    com.bajingan.client"))
            print(c(C.cyan, "    jacob.roblox."))
            io.write(c(C.yellow, "\n  New package : "))
            local new_p = io.read()
            if new_p and new_p ~= "" then
                if not new_p:match("%.") then
                    print(c(C.red, "\n  [!] Invalid format, must contain a dot (e.g. com.xxx.yyy)"))
                else
                    db.package = new_p
                    save_db(db)
                    print(c(C.green, "  [OK] Package updated → " .. new_p))
                end
            end
            shell("sleep 2")

        -- ── [6] Toggle Freeform ────────────────────────────
        elseif opt == "6" then
            draw_header("FREEFORM MODE — Android 13+")
            db.freeform = not db.freeform
            save_db(db)
            if db.freeform then
                enable_freeform()
                print(c(C.green, "  [ON]  Freeform enabled!"))
                print(c(C.gray,  "  App will launch in windowed mode."))
                print(c(C.gray,  "  Make sure your device supports freeform (Android 13+)."))
            else
                disable_freeform()
                print(c(C.gray,  "  [OFF] Freeform disabled."))
                print(c(C.gray,  "  App will launch in fullscreen as usual."))
            end
            shell("sleep 2")

        -- ── [7] Exit ───────────────────────────────────────
        elseif opt == "7" then
            print(c(C.cyan, "\n  Goodbye! 👋\n"))
            break
        end
    end
end

main()
