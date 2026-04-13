-- =========================================================
--   ROBLOX AUTO-HOPPER PRO  ·  Termux Edition  v5.0
--   by Dragkest
-- =========================================================

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
    local ret = os.execute(string.format("curl -L -o '%s' '%s' 2>/dev/null", tmp, REMOTE_URL))
    if ret == 0 then
        local function fread(p)
            local f = io.open(p,"r"); if not f then return "" end
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
    local f = io.open(INSTALL_PATH,"r")
    if f then f:close()
        if SELF_PATH ~= INSTALL_PATH then dofile(INSTALL_PATH); os.exit(0) end
    end
end
bootstrap()

-- =========================================================
local function shell(cmd) return os.execute(cmd) end
local function shell_read(cmd)
    local f = io.popen(cmd.." 2>/dev/null"); if not f then return "" end
    local s = f:read("*a"); f:close(); return s or ""
end

-- ── ANSI ─────────────────────────────────────────────────
local C = {
    reset="\27[0m", cyan="\27[1;36m", green="\27[1;32m",
    yellow="\27[1;33m", red="\27[1;31m", white="\27[1;37m",
    gray="\27[0;90m", magenta="\27[1;35m", blue="\27[1;34m",
}
local function c(col,txt) return col..txt..C.reset end
local SEP = "  "..string.rep("─",44)

-- ── ASCII Art JACOB (medium size) ────────────────────────
local JACOB = {
    " ░░░░░░  ░░░░░   ░░░░░░  ░░░░░  ░░░░░░  ",
    "     ░░  ░░  ░░  ░░     ░░   ░  ░░   ░░ ",
    "     ░░  ░░░░░   ░░     ░░░░░░  ░░░░░░  ",
    " ░░  ░░  ░░  ░░  ░░     ░░   ░  ░░   ░░ ",
    "  ░░░░   ░░   ░░  ░░░░░░ ░░   ░  ░░████ ",
}

local function draw_ascii()
    print(C.green)
    for _, line in ipairs(JACOB) do
        print("  " .. line)
    end
    print(C.reset)
end

-- ── Stop flag ─────────────────────────────────────────────
local STOP_FILE = INSTALL_DIR.."/.stop"
local function stop_requested()
    local f = io.open(STOP_FILE,"r"); if f then f:close(); return true end; return false
end
local function clear_stop() os.execute("rm -f "..STOP_FILE) end

-- ── Freeform ──────────────────────────────────────────────
local function enable_freeform()
    shell("su -c 'settings put global enable_freeform_support 1' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 1' 2>/dev/null")
end
local function disable_freeform()
    shell("su -c 'settings put global enable_freeform_support 0' 2>/dev/null")
    shell("su -c 'settings put global force_resizable_activities 0' 2>/dev/null")
end

-- ── Webhook ───────────────────────────────────────────────
local function send_webhook(url, title, desc, color)
    if not url or url == "" then return end
    color = color or 3447003
    -- Escape quotes dalam desc
    desc = desc:gsub('"', '\\"')
    title = title:gsub('"', '\\"')
    local payload = string.format(
        '{"embeds":[{"title":"%s","description":"%s","color":%d}]}',
        title, desc, color
    )
    shell(string.format(
        "curl -s -X POST -H 'Content-Type: application/json' -d '%s' '%s' > /dev/null 2>&1",
        payload, url
    ))
end

-- ── Scan semua package ────────────────────────────────────
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

-- ── Cek apakah package sedang running ────────────────────
local function is_running(pkg)
    local out = shell_read("su -c 'dumpsys activity | grep -c " .. pkg .. "' 2>/dev/null")
    local n = tonumber(out:match("%d+")) or 0
    return n > 0
end

-- ── Parse selection range ─────────────────────────────────
local function parse_selection(input, max)
    local selected, seen = {}, {}
    for part in input:gmatch("[^,]+") do
        part = part:match("^%s*(.-)%s*$")
        local a, b = part:match("^(%d+)-(%d+)$")
        if a and b then
            for i = tonumber(a), tonumber(b) do
                if i>=1 and i<=max and not seen[i] then
                    table.insert(selected,i); seen[i]=true
                end
            end
        else
            local n = tonumber(part)
            if n and n>=1 and n<=max and not seen[n] then
                table.insert(selected,n); seen[n]=true
            end
        end
    end
    return selected
end

-- ── Save / Load DB ────────────────────────────────────────
local function save_db(data)
    os.execute("mkdir -p "..INSTALL_DIR)
    local f = io.open(config_file,"w")
    if f then
        local srv_list = {}
        for _, v in ipairs(data.list) do
            local pkg_f = v.package and ('"pkg":"'..v.package..'",') or ""
            table.insert(srv_list, string.format(
                '    {%s"name":"%s","link":"%s","min":%d}',
                pkg_f, v.name, v.link, v.min
            ))
        end
        local ap = {}
        for _, p in ipairs(data.active_pkgs or {}) do
            table.insert(ap, '"'..p..'"')
        end
        f:write('{\n'..
            '  "package":"'..data.package..'",\n'..
            '  "active_pkgs":['..table.concat(ap,",")..'],\n'..
            '  "webhook":"'..(data.webhook or '')..'",\n'..
            '  "freeform":'..(data.freeform and "true" or "false")..',\n'..
            '  "servers":[\n'..table.concat(srv_list,",\n")..'\n  ]\n}')
        f:close()
    end
end

local function load_db()
    local f = io.open(config_file,"r")
    if not f then return {package="com.roblox.client",active_pkgs={},webhook="",freeform=false,list={}} end
    local content = f:read("*a"); f:close()
    local pkg     = content:match('"package"%s*:%s*"(.-)"') or "com.roblox.client"
    local webhook = content:match('"webhook"%s*:%s*"(.-)"') or ""
    local ffstr   = content:match('"freeform"%s*:%s*(%a+)') or "false"
    local ap = {}
    local ap_raw = content:match('"active_pkgs"%s*:%s*%[(.-)%]')
    if ap_raw then for p in ap_raw:gmatch('"(.-)"') do table.insert(ap,p) end end
    local list = {}
    for entry in content:gmatch("{(.-)}") do
        local spkg = entry:match('"pkg"%s*:%s*"(.-)"')
        local n    = entry:match('"name"%s*:%s*"(.-)"')
        local l    = entry:match('"link"%s*:%s*"(.-)"')
        local m    = entry:match('"min"%s*:%s*(%d+)')
        if n and l and m then
            table.insert(list,{name=n,link=l,min=tonumber(m),package=spkg})
        end
    end
    return {package=pkg,active_pkgs=ap,webhook=webhook,freeform=(ffstr=="true"),list=list}
end

-- ── Draw Header ───────────────────────────────────────────
local function draw_header(title)
    shell("clear")
    draw_ascii()
    print(C.cyan)
    print("  ╔══════════════════════════════════════════╗")
    print(string.format("  ║  %-42s║","🎮  "..title))
    print("  ╚══════════════════════════════════════════╝")
    print(C.reset)
end

-- ── Hopping Dashboard ─────────────────────────────────────
local function draw_ui(pkg, srv_name, sisa, total_m, idx, total_srv, freeform, status)
    shell("clear")
    draw_ascii()
    local m      = math.floor(sisa/60)
    local s      = sisa % 60
    local pct    = ((total_m*60)-sisa)/(total_m*60)
    local filled = math.floor(pct*22)
    local bar    = c(C.green,string.rep("█",filled))..c(C.gray,string.rep("░",22-filled))
    local ff_str = freeform and c(C.green,"ON ✓") or c(C.gray,"OFF")
    status = status or "Running"
    local st_col = (status == "CRASH DETECTED") and C.red or C.green

    print(c(C.gray,"  ┌──────────────────────────────────────────┐"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","PACKAGE"))
          ..c(C.white,string.format("%-30s",pkg:sub(1,29)))..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","SERVER"))
          ..c(C.white,string.format("%-30s",srv_name:sub(1,29)))..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","SLOT"))
          ..c(C.white,string.format("%-30s",string.format("%d of %d",idx,total_srv)))..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","FREEFORM"))
          ..ff_str..string.rep(" ",27)..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","TIME LEFT"))
          ..c(C.cyan,string.format("%02d:%02d",m,s))
          ..c(C.gray,string.format(" / %d:00 min",total_m))
          ..string.rep(" ",17-#tostring(total_m))..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","PROGRESS"))
          .."["..bar.."] "..c(C.magenta,string.format("%3d%%",math.floor(pct*100)))..c(C.gray,"│"))
    print(c(C.gray,"  │")..c(C.yellow,string.format(" %-13s","STATUS"))
          ..c(st_col,string.format("%-30s",status))..c(C.gray,"│"))
    print(c(C.gray,"  └──────────────────────────────────────────┘"))
    print("")
    print(c(C.red,"  [Q] STOP   ")..c(C.gray,"type q + Enter to stop"))
    print("")
end

-- ── Launch Roblox ─────────────────────────────────────────
local function launch_roblox(pkg, link, freeform)
    if freeform then
        shell(string.format(
            "su -c 'am start --windowingMode 5 -a android.intent.action.VIEW -d \"%s\" %s' > /dev/null 2>&1",
            link, pkg
        ))
    else
        shell(string.format(
            "am start -a android.intent.action.VIEW -d '%s' %s > /dev/null 2>&1",
            link, pkg
        ))
    end
end

-- ── Main ──────────────────────────────────────────────────
local function main()
    local db   = load_db()
    local pkgs = scan_packages()

    while true do
        draw_header("PRIVATE SERVER HOPPER")
        print(c(C.gray,SEP))
        print(c(C.yellow,"  DEFAULT   ")..c(C.white,db.package))
        if #db.active_pkgs > 0 then
            print(c(C.yellow,"  RUNNING   ")..c(C.cyan,#db.active_pkgs.." package(s)"))
            for _, p in ipairs(db.active_pkgs) do
                print(c(C.gray,"             · ")..c(C.white,p))
            end
        end
        local wh_status = (db.webhook and db.webhook ~= "") and c(C.green,"SET ✓") or c(C.gray,"not set")
        print(c(C.yellow,"  WEBHOOK   ")..wh_status)
        print(c(C.yellow,"  FREEFORM  ")..(db.freeform and c(C.green,"ON ✓") or c(C.gray,"OFF")))
        print(c(C.gray,SEP))
        print("")
        print(c(C.green,  "  [1]")..c(C.white,"  Start Auto-Hop"))
        print(c(C.blue,   "  [2]")..c(C.white,"  Add Private Server"))
        print(c(C.blue,   "  [3]")..c(C.white,"  View / Delete Servers  ")
              ..c(C.gray,string.format("(%d saved)",#db.list)))
        print(c(C.magenta,"  [4]")..c(C.white,"  Edit Server Duration"))
        print(c(C.magenta,"  [5]")..c(C.white,"  Assign Package per Server"))
        print(c(C.yellow, "  [6]")..c(C.white,"  Select Active Packages"))
        print(c(C.cyan,   "  [7]")..c(C.white,"  Set Webhook URL"))
        print(c(C.cyan,   "  [8]")..c(C.white,"  Toggle Freeform (Android 13+)  ")
              ..(db.freeform and c(C.green,"[ON]") or c(C.gray,"[OFF]")))
        print(c(C.red,    "  [9]")..c(C.white,"  Exit"))
        print("")
        print(c(C.gray,SEP))
        io.write(c(C.cyan,"  » "))
        local opt = io.read()

        -- ── [1] Start Auto-Hop ─────────────────────────────
        if opt == "1" then
            if #db.list == 0 then
                print(c(C.red,"\n  [!] Server list is empty.")); shell("sleep 2")
            else
                -- Pilih urutan server
                draw_header("AUTO-HOP — SET ORDER")
                print(c(C.gray,SEP))
                for idx, val in ipairs(db.list) do
                    print(string.format(c(C.yellow,"  [%d]")..c(C.white,"  %-24s")..c(C.gray," %dmin"),
                        idx, val.name:sub(1,24), val.min))
                end
                print(c(C.gray,SEP))
                print(c(C.gray,"  Set order (e.g. 1,2,3 or 3,1,2 or 2-4,1)"))
                print(c(C.gray,"  Enter = default order"))
                io.write(c(C.yellow,"  Order: "))
                local order_input = io.read()

                local order = {}
                if order_input == "" then
                    for i=1,#db.list do table.insert(order,i) end
                else
                    order = parse_selection(order_input, #db.list)
                    if #order == 0 then
                        for i=1,#db.list do table.insert(order,i) end
                    end
                end

                if db.freeform then enable_freeform() end
                clear_stop()

                local run_pkgs = #db.active_pkgs > 0 and db.active_pkgs or {db.package}
                local pos = 1       -- posisi dalam order
                local running = true

                while running do
                    local srv_idx   = order[pos]
                    local s         = db.list[srv_idx]
                    local pkg_idx   = ((pos-1) % #run_pkgs)+1
                    local active_pkg = s.package or run_pkgs[pkg_idx]

                    -- Notif webhook: pindah server
                    send_webhook(db.webhook,
                        "🎮 Hopping to Server",
                        string.format("**%s**\\nPackage: `%s`\\nDuration: %d min",
                            s.name, active_pkg, s.min),
                        3447003  -- biru
                    )

                    draw_header("AUTO-HOP ACTIVE")
                    print(c(C.yellow,"  Closing Roblox..."))
                    for _, ap in ipairs(run_pkgs) do
                        shell("su -c 'am force-stop "..ap.."' 2>/dev/null")
                    end
                    shell("sleep 2")

                    if stop_requested() then running=false; break end

                    print(c(C.green,"  Opening: "..s.name)..c(C.gray,"  ["..active_pkg.."]"))
                    launch_roblox(active_pkg, s.link, db.freeform)
                    shell("sleep 5") -- tunggu Roblox buka

                    -- Countdown + crash detection tiap 20 detik
                    local total_secs = s.min * 60
                    local elapsed    = 0
                    local crashed    = false

                    while elapsed <= total_secs do
                        if stop_requested() then running=false; break end

                        -- Cek tiap 20 detik
                        if elapsed % 20 == 0 and elapsed > 0 then
                            if not is_running(active_pkg) then
                                crashed = true
                                -- Notif webhook crash
                                send_webhook(db.webhook,
                                    "⚠️ Crash Detected!",
                                    string.format("**%s** crashed!\\nPackage: `%s`\\nRejoining in 3s...",
                                        s.name, active_pkg),
                                    16711680  -- merah
                                )
                                draw_ui(active_pkg, s.name, total_secs-elapsed, s.min,
                                        pos, #order, db.freeform, "CRASH DETECTED")
                                shell("sleep 3")

                                -- Rejoin
                                launch_roblox(active_pkg, s.link, db.freeform)
                                shell("sleep 5")

                                -- Notif webhook rejoined
                                send_webhook(db.webhook,
                                    "✅ Rejoined",
                                    string.format("**%s** rejoined successfully!\\nPackage: `%s`",
                                        s.name, active_pkg),
                                    65280  -- hijau
                                )
                                crashed = false
                            end
                        end

                        draw_ui(active_pkg, s.name, total_secs-elapsed, s.min,
                                pos, #order, db.freeform,
                                crashed and "CRASH DETECTED" or "Running")

                        shell("read -t 1 -n 1 _K 2>/dev/null && [ \"$_K\" = 'q' ] && touch "..STOP_FILE.." || true")
                        elapsed = elapsed + 1
                    end

                    if running then
                        -- Notif webhook: selesai, pindah berikutnya
                        local next_pos  = (pos % #order) + 1
                        local next_srv  = db.list[order[next_pos]]
                        send_webhook(db.webhook,
                            "⏭️ Switching Server",
                            string.format("**%s** done!\\nNext: **%s**",
                                s.name, next_srv.name),
                            16776960  -- kuning
                        )
                        pos = next_pos
                    end
                end

                clear_stop()
                shell("clear")
                print(c(C.yellow,"\n  [!] Hopping stopped. Closing Roblox..."))
                for _, ap in ipairs(run_pkgs) do
                    shell("su -c 'am force-stop "..ap.."' 2>/dev/null")
                end
                send_webhook(db.webhook,"🛑 Hopping Stopped","Auto-hop was stopped manually.",8421504)
                shell("sleep 2")
            end

        -- ── [2] Add Server ─────────────────────────────────
        elseif opt == "2" then
            draw_header("ADD PRIVATE SERVER")
            io.write(c(C.yellow,"  Server Name  : ")); local n = io.read()
            io.write(c(C.yellow,"  PS Link      : ")); local l = io.read()
            io.write(c(C.yellow,"  Duration(min): ")); local m = tonumber(io.read()) or 5
            local srv_pkg = nil
            local source = db.active_pkgs
            if #source > 1 then
                print(c(C.cyan,"\n  Assign package for this server:"))
                print(c(C.gray,"  [0]  Rotate all active packages"))
                for pi, pkg in ipairs(source) do
                    print(string.format(c(C.cyan,"  [%d]")..c(C.white,"  %s"),pi,pkg))
                end
                io.write(c(C.yellow,"  Select (0=rotate): "))
                local psel = tonumber(io.read())
                if psel and psel>0 and source[psel] then srv_pkg=source[psel] end
            end
            if n ~= "" and l ~= "" then
                table.insert(db.list,{name=n,link=l,min=m,package=srv_pkg})
                save_db(db)
                local tag = srv_pkg and c(C.cyan," ["..srv_pkg.."]") or c(C.gray," [rotate]")
                print(c(C.green,"\n  [+] Server added!")..tag)
            else
                print(c(C.red,"\n  [!] Failed — incomplete data."))
            end
            shell("sleep 1")

        -- ── [3] View / Delete ──────────────────────────────
        elseif opt == "3" then
            draw_header("SERVER LIST")
            if #db.list == 0 then
                print(c(C.gray,"  (empty)"))
            else
                print(c(C.gray,SEP))
                for idx, val in ipairs(db.list) do
                    local tag = val.package
                        and c(C.cyan," ["..val.package:sub(1,16).."]")
                        or  c(C.gray," [rotate]")
                    print(string.format(
                        c(C.yellow,"  [%d]")..c(C.white," %-20s")..c(C.gray," %dmin").."%s",
                        idx, val.name:sub(1,20), val.min, tag))
                end
                print(c(C.gray,SEP))
            end
            io.write(c(C.cyan,"\n  Number to delete / [x] back: "))
            local del = io.read()
            if tonumber(del) and db.list[tonumber(del)] then
                table.remove(db.list,tonumber(del))
                save_db(db)
                print(c(C.green,"  [-] Deleted!"))
                shell("sleep 1")
            end

        -- ── [4] Edit Duration ──────────────────────────────
        elseif opt == "4" then
            draw_header("EDIT SERVER DURATION")
            if #db.list == 0 then print(c(C.gray,"  (empty)")); shell("sleep 1")
            else
                print(c(C.gray,SEP))
                for idx, val in ipairs(db.list) do
                    print(string.format(c(C.yellow,"  [%d]")..c(C.white,"  %-24s")..c(C.cyan," %d min"),
                        idx, val.name:sub(1,24), val.min))
                end
                print(c(C.gray,SEP))
                io.write(c(C.cyan,"\n  Select server: "))
                local sel = tonumber(io.read())
                if sel and db.list[sel] then
                    print(c(C.gray,"  Current: ")..c(C.cyan,db.list[sel].min.." min"))
                    io.write(c(C.yellow,"  New duration (min): "))
                    local new_m = tonumber(io.read())
                    if new_m and new_m > 0 then
                        db.list[sel].min = new_m; save_db(db)
                        print(c(C.green,"  [OK] Updated → "..new_m.." min"))
                    else print(c(C.red,"  [!] Invalid.")) end
                else print(c(C.red,"  [!] Invalid selection.")) end
                shell("sleep 2")
            end

        -- ── [5] Assign Package per Server ─────────────────
        elseif opt == "5" then
            draw_header("ASSIGN PACKAGE PER SERVER")
            if #db.list == 0 then print(c(C.gray,"  (empty)")); shell("sleep 1")
            elseif #db.active_pkgs == 0 then
                print(c(C.red,"  [!] Set active packages first (menu 6)."))
                shell("sleep 2")
            else
                print(c(C.gray,SEP))
                for idx, val in ipairs(db.list) do
                    local tag = val.package and c(C.cyan,val.package) or c(C.gray,"rotate")
                    print(string.format(c(C.yellow,"  [%d]")..c(C.white,"  %-22s").."  → %s",
                        idx, val.name:sub(1,22), tag))
                end
                print(c(C.gray,SEP))
                io.write(c(C.cyan,"\n  Select server: "))
                local sel = tonumber(io.read())
                if sel and db.list[sel] then
                    print(c(C.yellow,"\n  Package for: ")..c(C.white,db.list[sel].name))
                    print(c(C.gray,"  [0]  Rotate all"))
                    for pi, pkg in ipairs(db.active_pkgs) do
                        local mark = (pkg==db.list[sel].package) and c(C.green," ◄") or ""
                        print(string.format(c(C.cyan,"  [%d]")..c(C.white,"  %s").."%s",pi,pkg,mark))
                    end
                    io.write(c(C.yellow,"\n  Select: "))
                    local psel = tonumber(io.read())
                    if psel == 0 then
                        db.list[sel].package=nil; save_db(db)
                        print(c(C.green,"  [OK] Set to rotate."))
                    elseif psel and db.active_pkgs[psel] then
                        db.list[sel].package=db.active_pkgs[psel]; save_db(db)
                        print(c(C.green,"  [OK] → "..db.active_pkgs[psel]))
                    else print(c(C.red,"  [!] Invalid.")) end
                else print(c(C.red,"  [!] Invalid.")) end
                shell("sleep 2")
            end

        -- ── [6] Select Active Packages ─────────────────────
        elseif opt == "6" then
            draw_header("SELECT ACTIVE PACKAGES")
            if #pkgs == 0 then print(c(C.red,"  [!] No packages detected.")); shell("sleep 2")
            else
                print(c(C.gray,"  Filter keyword (Enter = show all):"))
                io.write(c(C.yellow,"  Search: "))
                local kw = io.read():lower()
                local filtered = {}
                for _, pkg in ipairs(pkgs) do
                    if kw=="" or pkg:lower():find(kw,1,true) then
                        table.insert(filtered,pkg)
                    end
                end
                if #filtered == 0 then
                    print(c(C.red,"  [!] No match.")); shell("sleep 2")
                else
                    shell("clear"); draw_ascii()
                    print(c(C.gray,SEP))
                    if #db.active_pkgs > 0 then
                        print(c(C.yellow,"  Active:"))
                        for _, p in ipairs(db.active_pkgs) do
                            print(c(C.green,"  ✓ ")..c(C.white,p))
                        end
                        print(c(C.gray,SEP))
                    end
                    for i, pkg in ipairs(filtered) do
                        local active = false
                        for _, ap in ipairs(db.active_pkgs) do
                            if ap==pkg then active=true; break end
                        end
                        local mark = active and c(C.green," ✓") or ""
                        print(string.format(c(C.cyan,"  [%3d]")..c(C.white,"  %s").."%s",i,pkg,mark))
                    end
                    print(c(C.gray,SEP))
                    print(c(C.gray,"  Examples: 1  |  1,3  |  2-5  |  1,3-5"))
                    print(c(C.gray,"  [0] = clear"))
                    io.write(c(C.yellow,"\n  Select: "))
                    local input = io.read()
                    if input == "0" then
                        db.active_pkgs={}; save_db(db)
                        print(c(C.green,"  [OK] Cleared."))
                    else
                        local indices = parse_selection(input,#filtered)
                        if #indices == 0 then print(c(C.red,"  [!] Invalid."))
                        else
                            db.active_pkgs={}
                            for _, idx in ipairs(indices) do
                                table.insert(db.active_pkgs,filtered[idx])
                            end
                            db.package = db.active_pkgs[1]
                            save_db(db)
                            print(c(C.green,"  [OK] Active packages:"))
                            for _, p in ipairs(db.active_pkgs) do
                                print(c(C.cyan,"       · ")..c(C.white,p))
                            end
                        end
                    end
                    shell("sleep 2")
                end
            end

        -- ── [7] Set Webhook ────────────────────────────────
        elseif opt == "7" then
            draw_header("SET WEBHOOK URL")
            print(c(C.gray,"  Current: ")..c(C.white, db.webhook ~= "" and db.webhook or "(none)"))
            print(c(C.gray,"  Paste your Discord webhook URL."))
            print(c(C.gray,"  Enter 0 to remove webhook."))
            io.write(c(C.yellow,"\n  Webhook URL: "))
            local wh = io.read()
            if wh == "0" then
                db.webhook=""; save_db(db)
                print(c(C.green,"  [OK] Webhook removed."))
            elseif wh ~= "" then
                db.webhook=wh; save_db(db)
                -- Test kirim
                send_webhook(db.webhook,"✅ Webhook Connected","Hopper webhook is now active!",65280)
                print(c(C.green,"  [OK] Webhook set & tested!"))
            end
            shell("sleep 2")

        -- ── [8] Toggle Freeform ────────────────────────────
        elseif opt == "8" then
            draw_header("FREEFORM MODE")
            db.freeform = not db.freeform; save_db(db)
            if db.freeform then
                enable_freeform()
                print(c(C.green,"  [ON]  Freeform enabled!"))
            else
                disable_freeform()
                print(c(C.gray,"  [OFF] Freeform disabled."))
            end
            shell("sleep 2")

        -- ── [9] Exit ───────────────────────────────────────
        elseif opt == "9" then
            print(c(C.cyan,"\n  Goodbye! 👋\n")); break
        end
    end
end

main()
