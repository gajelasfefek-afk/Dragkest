-- =========================================================
--   ROBLOX AUTO-HOPPER PRO  ·  Termux Edition  v4.1
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
        "curl -L -o '%s' '%s' 2>/dev/null", tmp, REMOTE_URL
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

local function shell(cmd) return os.execute(cmd) end

local function shell_read(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return s or ""
end

-- ── ANSI Colors ───────────────────────────────────────────
local C = {
    reset   = "\27[0m",  cyan    = "\27[1;36m",
    green   = "\27[1;32m", yellow  = "\27[1;33m",
    red     = "\27[1;31m", white   = "\27[1;37m",
    gray    = "\27[0;90m", magenta = "\27[1;35m",
    blue    = "\27[1;34m",
}
local function c(color, text) return color .. text .. C.reset end
local SEP = "  " .. string.rep("─", 44)

-- ── Stop flag ─────────────────────────────────────────────
local STOP_FILE = INSTALL_DIR .. "/.stop"
local function stop_requested()
    local f = io.open(STOP_FILE, "r"); if f then f:close(); return true end; return false
end
local function clear_stop() os.execute("rm -f " .. STOP_FILE) end

-- ── Freeform ──────────────────────────────────────────────
local function enable_freeform()
    shell("su -c 'settings put global enable_freeform_support 1' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 1' 2>/dev/null")
end
local function disable_freeform()
    shell("su -c 'settings put global enable_freeform_support 0' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 0' 2>/dev/null")
end

-- ── Scan SEMUA package di device ─────────────────────────
local function scan_packages()
    local raw = shell_read("su -c 'pm list packages' 2>/dev/null")
    local pkgs = {}
    for line in raw:gmatch("[^\r\n]+") do
        local pkg = line:match("^package:(%S+)$")
        if pkg and pkg ~= "" and pkg:match("%.") then
            table.insert(pkgs, pkg)
        end
    end
    table.sort(pkgs)
    return pkgs
end

-- ── Parse input range/multi pilihan ──────────────────────
local function parse_selection(input, max)
    local selected = {}
    local seen = {}
    for part in input:gmatch("[^,]+") do
        part = part:match("^%s*(.-)%s*$")
        local a, b = part:match("^(%d+)-(%d+)$")
        if a and b then
            for i = tonumber(a), tonumber(b) do
                if i >= 1 and i <= max and not seen[i] then
                    table.insert(selected, i); seen[i] = true
                end
            end
        else
            local n = tonumber(part)
            if n and n >= 1 and n <= max and not seen[n] then
                table.insert(selected, n); seen[n] = true
            end
        end
    end
    table.sort(selected)
    return selected
end

-- ── Save DB ───────────────────────────────────────────────
local function save_db(data)
    os.execute("mkdir -p " .. INSTALL_DIR)
    local f = io.open(config_file, "w")
    if f then
        local srv_list = {}
        for _, v in ipairs(data.list) do
            local pkg_field = v.package and ('"pkg": "' .. v.package .. '", ') or ""
            table.insert(srv_list, string.format(
                '    {%s"name": "%s", "link": "%s", "min": %d}',
                pkg_field, v.name, v.link, v.min
            ))
        end
        local ap_list = {}
        for _, p in ipairs(data.active_pkgs or {}) do
            table.insert(ap_list, '"' .. p .. '"')
        end
        f:write('{\n' ..
            '  "package": "' .. data.package .. '",\n' ..
            '  "active_pkgs": [' .. table.concat(ap_list, ", ") .. '],\n' ..
            '  "freeform": ' .. (data.freeform and "true" or "false") .. ',\n' ..
            '  "servers": [\n' .. table.concat(srv_list, ",\n") .. '\n  ]\n}')
        f:close()
    end
end

-- ── Load DB ───────────────────────────────────────────────
local function load_db()
    local f = io.open(config_file, "r")
    if not f then
        return {package = "com.roblox.client", active_pkgs = {}, freeform = false, list = {}}
    end
    local content = f:read("*a"); f:close()
    local pkg   = content:match('"package"%s*:%s*"(.-)"') or "com.roblox.client"
    local ffstr = content:match('"freeform"%s*:%s*(%a+)') or "false"
    local active_pkgs = {}
    local ap_raw = content:match('"active_pkgs"%s*:%s*%[(.-)%]')
    if ap_raw then
        for p in ap_raw:gmatch('"(.-)"') do
            table.insert(active_pkgs, p)
        end
    end
    local list = {}
    for entry in content:gmatch("{(.-)}") do
        local spkg = entry:match('"pkg"%s*:%s*"(.-)"')
        local n    = entry:match('"name"%s*:%s*"(.-)"')
        local l    = entry:match('"link"%s*:%s*"(.-)"')
        local m    = entry:match('"min"%s*:%s*(%d+)')
        if n and l and m then
            table.insert(list, {name=n, link=l, min=tonumber(m), package=spkg})
        end
    end
    return {package=pkg, active_pkgs=active_pkgs, freeform=(ffstr=="true"), list=list}
end

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

-- ── Main ──────────────────────────────────────────────────
local function main()
    local db   = load_db()
    local pkgs = scan_packages()  -- semua package, cuma dipakai di menu [6]

    while true do
        draw_header("PRIVATE SERVER HOPPER")
        print(c(C.gray, SEP))
        print(c(C.yellow, "  DEFAULT   ") .. c(C.white, db.package))
        if #db.active_pkgs > 0 then
            print(c(C.yellow, "  RUNNING   ") .. c(C.cyan, #db.active_pkgs .. " package(s)"))
            for _, p in ipairs(db.active_pkgs) do
                print(c(C.gray, "             · ") .. c(C.white, p))
            end
        end
        print(c(C.yellow, "  FREEFORM  ") .. (db.freeform and c(C.green, "ON ✓") or c(C.gray, "OFF")))
        print(c(C.gray, SEP))
        print("")
        print(c(C.green,   "  [1]") .. c(C.white, "  Start Auto-Hop"))
        print(c(C.blue,    "  [2]") .. c(C.white, "  Add Private Server"))
        print(c(C.blue,    "  [3]") .. c(C.white, "  View / Delete Servers  ")
              .. c(C.gray, string.format("(%d saved)", #db.list)))
        print(c(C.magenta, "  [4]") .. c(C.white, "  Edit Server Duration"))
        print(c(C.magenta, "  [5]") .. c(C.white, "  Assign Package per Server"))
        print(c(C.yellow,  "  [6]") .. c(C.white, "  Select Active Packages"))
        print(c(C.cyan,    "  [7]") .. c(C.white, "  Toggle Freeform (Android 13+)  ")
              .. (db.freeform and c(C.green, "[ON]") or c(C.gray, "[OFF]")))
        print(c(C.red,     "  [8]") .. c(C.white, "  Exit"))
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
                local run_pkgs = #db.active_pkgs > 0 and db.active_pkgs or {db.package}
                local i = 1
                local running = true

                while running do
                    local s = db.list[i]
                    local pkg_idx = ((i - 1) % #run_pkgs) + 1
                    local active_pkg = s.package or run_pkgs[pkg_idx]

                    draw_header("AUTO-HOP ACTIVE")
                    print(c(C.yellow, "  Closing Roblox..."))
                    for _, ap in ipairs(run_pkgs) do
                        shell("su -c 'am force-stop " .. ap .. "' 2>/dev/null")
                    end
                    shell("sleep 2")

                    if stop_requested() then running = false; break end

                    print(c(C.green, "  Opening: " .. s.name)
                          .. c(C.gray, "  [" .. active_pkg .. "]"))

                    if db.freeform then
                        shell(string.format(
                            "su -c 'am start --windowingMode 5 -a android.intent.action.VIEW -d \"%s\" %s' > /dev/null 2>&1",
                            s.link, active_pkg
                        ))
                    else
                        shell(string.format(
                            "am start -a android.intent.action.VIEW -d '%s' %s > /dev/null 2>&1",
                            s.link, active_pkg
                        ))
                    end

                    for d = (s.min * 60), 0, -1 do
                        draw_ui(active_pkg, s.name, d, s.min, i, #db.list, db.freeform)
                        shell("read -t 1 -n 1 _K 2>/dev/null && [ \"$_K\" = 'q' ] && touch " .. STOP_FILE .. " || true")
                        if stop_requested() then running = false; break end
                    end

                    if running then i = (i % #db.list) + 1 end
                end

                clear_stop()
                shell("clear")
                print(c(C.yellow, "\n  [!] Hopping stopped. Closing Roblox..."))
                for _, ap in ipairs(run_pkgs) do
                    shell("su -c 'am force-stop " .. ap .. "' 2>/dev/null")
                end
                shell("sleep 2")
            end

        -- ── [2] Add Server ─────────────────────────────────
        elseif opt == "2" then
            draw_header("ADD PRIVATE SERVER")
            io.write(c(C.yellow, "  Server Name  : ")); local n = io.read()
            io.write(c(C.yellow, "  PS Link      : ")); local l = io.read()
            io.write(c(C.yellow, "  Duration(min): ")); local m = tonumber(io.read()) or 5

            -- Assign package dari active_pkgs aja
            local srv_pkg = nil
            local source = #db.active_pkgs > 0 and db.active_pkgs or {}
            if #source > 1 then
                print(c(C.cyan, "\n  Assign specific package for this server:"))
                print(c(C.gray, "  [0]  Rotate all active packages"))
                for pi, pkg in ipairs(source) do
                    print(string.format(c(C.cyan, "  [%d]") .. c(C.white, "  %s"), pi, pkg))
                end
                io.write(c(C.yellow, "  Select (0 = rotate): "))
                local psel = tonumber(io.read())
                if psel and psel > 0 and source[psel] then
                    srv_pkg = source[psel]
                end
            end

            if n ~= "" and l ~= "" then
                table.insert(db.list, {name=n, link=l, min=m, package=srv_pkg})
                save_db(db)
                local tag = srv_pkg and c(C.cyan, " [" .. srv_pkg .. "]") or c(C.gray, " [rotate active pkgs]")
                print(c(C.green, "\n  [+] Server added!") .. tag)
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
                    local tag = val.package
                        and c(C.cyan, " [" .. val.package:sub(1,18) .. "]")
                        or  c(C.gray, " [rotate]")
                    print(string.format(
                        c(C.yellow, "  [%d]") .. c(C.white, " %-20s") .. c(C.gray, " %dmin") .. "%s",
                        idx, val.name:sub(1,20), val.min, tag
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
                print(c(C.gray, "  (empty)")); shell("sleep 1")
            else
                print(c(C.gray, SEP))
                for idx, val in ipairs(db.list) do
                    print(string.format(
                        c(C.yellow, "  [%d]") .. c(C.white, "  %-24s") .. c(C.cyan, " %d min"),
                        idx, val.name:sub(1,24), val.min
                    ))
                end
                print(c(C.gray, SEP))
                io.write(c(C.cyan, "\n  Select server: "))
                local sel = tonumber(io.read())
                if sel and db.list[sel] then
                    print(c(C.gray, "  Current: ") .. c(C.cyan, db.list[sel].min .. " min"))
                    io.write(c(C.yellow, "  New duration (min): "))
                    local new_m = tonumber(io.read())
                    if new_m and new_m > 0 then
                        db.list[sel].min = new_m
                        save_db(db)
                        print(c(C.green, "  [OK] Updated → " .. new_m .. " min"))
                    else
                        print(c(C.red, "  [!] Invalid input."))
                    end
                else
                    print(c(C.red, "  [!] Invalid selection."))
                end
                shell("sleep 2")
            end

        -- ── [5] Assign Package per Server ─────────────────
        -- Ngambil dari active_pkgs yang sudah dipilih user, bukan semua package
        elseif opt == "5" then
            draw_header("ASSIGN PACKAGE PER SERVER")
            if #db.list == 0 then
                print(c(C.gray, "  (empty)")); shell("sleep 1")
            elseif #db.active_pkgs == 0 then
                print(c(C.red,  "  [!] No active packages set."))
                print(c(C.gray, "  Set active packages first via menu [6]."))
                shell("sleep 2")
            else
                -- Tampilkan list server
                print(c(C.gray, SEP))
                for idx, val in ipairs(db.list) do
                    local tag = val.package
                        and c(C.cyan, val.package)
                        or  c(C.gray, "rotate")
                    print(string.format(
                        c(C.yellow, "  [%d]") .. c(C.white, "  %-22s") .. "  → %s",
                        idx, val.name:sub(1,22), tag
                    ))
                end
                print(c(C.gray, SEP))
                io.write(c(C.cyan, "\n  Select server: "))
                local sel = tonumber(io.read())
                if sel and db.list[sel] then
                    print(c(C.yellow, "\n  Package for: ") .. c(C.white, db.list[sel].name))
                    print(c(C.gray, "  [0]  Rotate all active packages"))
                    -- Tampilkan HANYA active_pkgs
                    for pi, pkg in ipairs(db.active_pkgs) do
                        local mark = (pkg == db.list[sel].package) and c(C.green, " ◄") or ""
                        print(string.format(
                            c(C.cyan, "  [%d]") .. c(C.white, "  %s") .. "%s",
                            pi, pkg, mark
                        ))
                    end
                    io.write(c(C.yellow, "\n  Select: "))
                    local psel = tonumber(io.read())
                    if psel == 0 then
                        db.list[sel].package = nil
                        save_db(db)
                        print(c(C.green, "  [OK] Set to rotate."))
                    elseif psel and db.active_pkgs[psel] then
                        db.list[sel].package = db.active_pkgs[psel]
                        save_db(db)
                        print(c(C.green, "  [OK] Assigned → " .. db.active_pkgs[psel]))
                    else
                        print(c(C.red, "  [!] Invalid."))
                    end
                else
                    print(c(C.red, "  [!] Invalid selection."))
                end
                shell("sleep 2")
            end

        -- ── [6] Select Active Packages ─────────────────────
        -- Semua package ditampilkan di sini, user filter sendiri
        elseif opt == "6" then
            draw_header("SELECT ACTIVE PACKAGES")
            if #pkgs == 0 then
                print(c(C.red, "  [!] No packages detected.")); shell("sleep 2")
            else
                print(c(C.gray, "  Filter by keyword (Enter to show all):"))
                io.write(c(C.yellow, "  Search: "))
                local kw = io.read():lower()

                local filtered = {}
                for _, pkg in ipairs(pkgs) do
                    if kw == "" or pkg:lower():find(kw, 1, true) then
                        table.insert(filtered, pkg)
                    end
                end

                if #filtered == 0 then
                    print(c(C.red, "  [!] No packages match."))
                    shell("sleep 2")
                else
                    shell("clear")
                    draw_header("SELECT ACTIVE PACKAGES")
                    print(c(C.gray, SEP))
                    if #db.active_pkgs > 0 then
                        print(c(C.yellow, "  Currently active:"))
                        for _, p in ipairs(db.active_pkgs) do
                            print(c(C.green, "  ✓ ") .. c(C.white, p))
                        end
                        print(c(C.gray, SEP))
                    end
                    for i, pkg in ipairs(filtered) do
                        local active = false
                        for _, ap in ipairs(db.active_pkgs) do
                            if ap == pkg then active = true; break end
                        end
                        local mark = active and c(C.green, " ✓") or ""
                        print(string.format(
                            c(C.cyan, "  [%3d]") .. c(C.white, "  %s") .. "%s",
                            i, pkg, mark
                        ))
                    end
                    print(c(C.gray, SEP))
                    print(c(C.gray, "  Examples: 1  |  1,3  |  2-5  |  1,3-5,7"))
                    print(c(C.gray, "  [0] = clear selection"))
                    io.write(c(C.yellow, "\n  Select: "))
                    local input = io.read()

                    if input == "0" then
                        db.active_pkgs = {}
                        save_db(db)
                        print(c(C.green, "  [OK] Cleared."))
                    else
                        local indices = parse_selection(input, #filtered)
                        if #indices == 0 then
                            print(c(C.red, "  [!] Invalid input."))
                        else
                            db.active_pkgs = {}
                            for _, idx in ipairs(indices) do
                                table.insert(db.active_pkgs, filtered[idx])
                            end
                            db.package = db.active_pkgs[1]
                            save_db(db)
                            print(c(C.green, "  [OK] Active packages set:"))
                            for _, p in ipairs(db.active_pkgs) do
                                print(c(C.cyan, "       · ") .. c(C.white, p))
                            end
                        end
                    end
                    shell("sleep 2")
                end
            end

        -- ── [7] Toggle Freeform ────────────────────────────
        elseif opt == "7" then
            draw_header("FREEFORM MODE — Android 13+")
            db.freeform = not db.freeform
            save_db(db)
            if db.freeform then
                enable_freeform()
                print(c(C.green, "  [ON]  Freeform enabled!"))
                print(c(C.gray,  "  App will launch in windowed mode."))
            else
                disable_freeform()
                print(c(C.gray,  "  [OFF] Freeform disabled."))
            end
            shell("sleep 2")

        -- ── [8] Exit ───────────────────────────────────────
        elseif opt == "8" then
            print(c(C.cyan, "\n  Goodbye! 👋\n"))
            break
        end
    end
end

main()
