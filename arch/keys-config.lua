-----------------------------------------------------------------------------------------------------------------------
--                                          Hotkeys and mouse buttons config                                         --
-----------------------------------------------------------------------------------------------------------------------
-- Grab environment
local table = table
local awful = require("awful")
local redflat = require("redflat")

-- Initialize tables and vars for module
-----------------------------------------------------------------------------------------------------------------------
local hotkeys = {
    mouse = {},
    raw = {},
    keys = {},
    fake = {}
}

-- key aliases
local apprunner = redflat.float.apprunner
local appswitcher = redflat.float.appswitcher
local current = redflat.widget.tasklist.filter.currenttags
local allscr = redflat.widget.tasklist.filter.allscreen
local laybox = redflat.widget.layoutbox
local redtip = redflat.float.hotkeys
local laycom = redflat.layout.common
local grid = redflat.layout.grid
local map = redflat.layout.map
local redtitle = redflat.titlebar
local qlaunch = redflat.float.qlaunch

-- Key support functions
-----------------------------------------------------------------------------------------------------------------------

-- change window focus by history
local function focus_to_previous()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end

-- change window focus by direction
local focus_switch_byd = function(dir)
    return function()
        awful.client.focus.bydirection(dir)
        if client.focus then
            client.focus:raise()
        end
    end
end

-- minimize and restore windows
local function minimize_all()
    for _, c in ipairs(client.get()) do
        if current(c, mouse.screen) then
            c.minimized = true
        end
    end
end

local function minimize_all_except_focused()
    for _, c in ipairs(client.get()) do
        if current(c, mouse.screen) and c ~= client.focus then
            c.minimized = true
        end
    end
end

local function restore_all()
    for _, c in ipairs(client.get()) do
        if current(c, mouse.screen) and c.minimized then
            c.minimized = false
        end
    end
end

local function restore_client()
    local c = awful.client.restore()
    if c then
        client.focus = c;
        c:raise()
    end
end

-- close window
local function kill_all()
    for _, c in ipairs(client.get()) do
        if current(c, mouse.screen) and not c.sticky then
            c:kill()
        end
    end
end

-- new clients placement
local function toggle_placement(env)
    env.set_slave = not env.set_slave
    redflat.float.notify:show({
        text = (env.set_slave and "Slave" or "Master") .. " placement"
    })
end

-- numeric keys function builders
local function tag_numkey(i, mod, action)
    return awful.key(mod, "#" .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
            action(tag)
        end
    end)
end

local function client_numkey(i, mod, action)
    return awful.key(mod, "#" .. i + 9, function()
        if client.focus then
            local tag = client.focus.screen.tags[i]
            if tag then
                action(tag)
            end
        end
    end)
end

-- brightness functions
local brightness = function(args)
    redflat.float.brightness:change_with_xbacklight(args) -- use xbacklight
end

-- right bottom corner position
local rb_corner = function()
    return {
        x = screen[mouse.screen].workarea.x + screen[mouse.screen].workarea.width,
        y = screen[mouse.screen].workarea.y + screen[mouse.screen].workarea.height
    }
end

-- Build hotkeys depended on config parameters
-----------------------------------------------------------------------------------------------------------------------
function hotkeys:init(args)

    -- Init vars
    args = args or {}
    local env = args.env
    local volume = args.volume
    local mainmenu = args.menu
    local appkeys = args.appkeys or {}

    self.mouse.root = (awful.util.table.join(awful.button({}, 3, function()
        mainmenu:toggle()
    end), awful.button({}, 4, awful.tag.viewnext), awful.button({}, 5, awful.tag.viewprev)))

    -- volume functions
    local volume_raise = function()
        volume:change_volume({
            show_notify = true
        })
    end
    local volume_lower = function()
        volume:change_volume({
            show_notify = true,
            down = true
        })
    end
    local volume_mute = function()
        volume:mute()
    end

    -- Init widgets
    redflat.float.qlaunch:init()

    -- Application hotkeys helper
    --------------------------------------------------------------------------------
    local apphelper = function(keys)
        if not client.focus then
            return
        end

        local app = client.focus.class:lower()
        for name, sheet in pairs(keys) do
            if name == app then
                redtip:set_pack(client.focus.class, sheet.pack, sheet.style.column, sheet.style.geometry, function()
                    redtip:remove_pack()
                end)
                redtip:show()
                return
            end
        end

        redflat.float.notify:show({
            text = "No tips for " .. client.focus.class
        })
    end

    -- Keys for widgets
    --------------------------------------------------------------------------------

    -- Apprunner widget
    ------------------------------------------------------------
    local apprunner_keys_move = {{{env.mod}, "k", function()
        apprunner:down()
    end, {
        description = "Выбрать следующий элемент",
        group = "Навигация"
    }}, {{env.mod}, "i", function()
        apprunner:up()
    end, {
        description = "Выбрать предыдущий элемент",
        group = "Навигация"
    }}}

    -- apprunner:set_keys(awful.util.table.join(apprunner.keys.move, apprunner_keys_move), "move")
    apprunner:set_keys(apprunner_keys_move, "move")

    -- Menu widget
    ------------------------------------------------------------
    local menu_keys_move = {{{env.mod}, "k", redflat.menu.action.down, {
        description = "Выбрать следующий элемент",
        group = "Навигация"
    }}, {{env.mod}, "i", redflat.menu.action.up, {
        description = "Выбрать предыдущий элемент",
        group = "Навигация"
    }}, {{env.mod}, "j", redflat.menu.action.back, {
        description = "Назад",
        group = "Навигация"
    }}, {{env.mod}, "l", redflat.menu.action.enter, {
        description = "Открыть подменю",
        group = "Навигация"
    }}}

    -- redflat.menu:set_keys(awful.util.table.join(redflat.menu.keys.move, menu_keys_move), "move")
    redflat.menu:set_keys(menu_keys_move, "move")

    -- Appswitcher widget
    ------------------------------------------------------------
    local appswitcher_keys = {{{env.mod}, "a", function()
        appswitcher:switch()
    end, {
        description = "Выбрать следующее приложение",
        group = "Навигация"
    }}, {{env.mod, "Shift"}, "a", function()
        appswitcher:switch()
    end, {} -- hidden key
    }, {{env.mod}, "q", function()
        appswitcher:switch({
            reverse = true
        })
    end, {
        description = "Выбрать предыдущее приложение",
        group = "Навигация"
    }}, {{env.mod, "Shift"}, "q", function()
        appswitcher:switch({
            reverse = true
        })
    end, {} -- hidden key
    }, {{}, "Super_L", function()
        appswitcher:hide()
    end, {
        description = "Активировать и выйти",
        group = "Действие"
    }}, {{env.mod}, "Super_L", function()
        appswitcher:hide()
    end, {} -- hidden key
    }, {{env.mod, "Shift"}, "Super_L", function()
        appswitcher:hide()
    end, {} -- hidden key
    }, {{}, "Return", function()
        appswitcher:hide()
    end, {
        description = "Активировать и выйти",
        group = "Действие"
    }}, {{}, "Escape", function()
        appswitcher:hide(true)
    end, {
        description = "Exit",
        group = "Действие"
    }}, {{env.mod}, "Escape", function()
        appswitcher:hide(true)
    end, {} -- hidden key
    }, {{env.mod}, "F1", function()
        redtip:show()
    end, {
        description = "Показать помощник по горячим клавишам",
        group = "Действие"
    }}}

    appswitcher:set_keys(appswitcher_keys)

    -- Emacs like key sequences
    --------------------------------------------------------------------------------

    -- initial key
    local keyseq = {{env.mod}, "c", {}, {}}

    -- group
    keyseq[3] = {{{}, "k", {}, {}}, -- application kill group
    {{}, "c", {}, {}}, -- client managment group
    {{}, "r", {}, {}}, -- client managment group
    {{}, "n", {}, {}}, -- client managment group
    {{}, "g", {}, {}}, -- run or rise group
    {{}, "f", {}, {}} -- launch application group
    }

    -- quick launch key sequence actions
    for i = 1, 9 do
        local ik = tostring(i)
        table.insert(keyseq[3][5][3], {{}, ik, function()
            qlaunch:run_or_raise(ik)
        end, {
            description = "Запустить или поднять приложение №" .. ik,
            group = "Запустить или Поднять",
            keyset = {ik}
        }})
        table.insert(keyseq[3][6][3], {{}, ik, function()
            qlaunch:run_or_raise(ik, true)
        end, {
            description = "Запустить приложение №" .. ik,
            group = "Быстрый Запуск",
            keyset = {ik}
        }})
    end

    -- application kill sequence actions
    keyseq[3][1][3] = {{{}, "f", function()
        if client.focus then
            client.focus:kill()
        end
    end, {
        description = "Закрыть выделенного клиента",
        group = "Закрытие клиентов",
        keyset = {"f"}
    }}, {{}, "a", kill_all, {
        description = "Закрыть все клиенты с текущим тегом",
        group = "Закрытие клиентов",
        keyset = {"a"}
    }}}

    -- client managment sequence actions
    keyseq[3][2][3] = {{{}, "p", function()
        toggle_placement(env)
    end, {
        description = "Переключение master/slave window placement",
        group = "Управление клиентами",
        keyset = {"p"}
    }}}

    keyseq[3][3][3] = {{{}, "f", restore_client, {
        description = "Восстановить свернутый клиент",
        group = "Управление клиентами",
        keyset = {"f"}
    }}, {{}, "a", restore_all, {
        description = "Восстановить всех клиентов в текущем теге",
        group = "Управление клиентами",
        keyset = {"a"}
    }}}

    keyseq[3][4][3] = {{{}, "f", function()
        if client.focus then
            client.focus.minimized = true
        end
    end, {
        description = "Минимизировать выделенного клиента",
        group = "Управление клиентами",
        keyset = {"f"}
    }}, {{}, "a", minimize_all, {
        description = "Минимизировать всех клиентов в текущем теге",
        group = "Управление клиентами",
        keyset = {"a"}
    }}, {{}, "e", minimize_all_except_focused, {
        description = "Минимизировать всех клиентов в текущем теге исключая выделенного",
        group = "Управление клиентами",
        keyset = {"e"}
    }}}

    -- Макеты
    --------------------------------------------------------------------------------

    -- shared layout keys
    local layout_tile = {{{env.mod}, "l", function()
        awful.tag.incmwfact(0.05)
    end, {
        description = "Increase master width factor",
        group = "Макет"
    }}, {{env.mod}, "j", function()
        awful.tag.incmwfact(-0.05)
    end, {
        description = "Decrease master width factor",
        group = "Макет"
    }}, {{env.mod}, "i", function()
        awful.client.incwfact(0.05)
    end, {
        description = "Увеличить коэффициент использования окна клиента",
        group = "Макет"
    }}, {{env.mod}, "k", function()
        awful.client.incwfact(-0.05)
    end, {
        description = "Уменьшить коэффициент использования окна клиента",
        group = "Макет"
    }}, {{env.mod}, "+", function()
        awful.tag.incnmaster(1, nil, true)
    end, {
        description = "Увеличить количество основных клиентов",
        group = "Макет"
    }}, {{env.mod}, "-", function()
        awful.tag.incnmaster(-1, nil, true)
    end, {
        description = "Уменьшить количество основных клиентов",
        group = "Макет"
    }}, {{env.mod, "Control"}, "+", function()
        awful.tag.incncol(1, nil, true)
    end, {
        description = "Увеличить количество столбцов",
        group = "Макет"
    }}, {{env.mod, "Control"}, "-", function()
        awful.tag.incncol(-1, nil, true)
    end, {
        description = "Уменьшить количество столбцов",
        group = "Макет"
    }}}

    laycom:set_keys(layout_tile, "tile")

    -- grid layout keys
    local layout_grid_move = {{{env.mod}, "KP_Up", function()
        grid.move_to("up")
    end, {
        description = "Move window up",
        group = "Перемещение"
    }}, {{env.mod}, "KP_Down", function()
        grid.move_to("down")
    end, {
        description = "Move window down",
        group = "Перемещение"
    }}, {{env.mod}, "KP_Left", function()
        grid.move_to("left")
    end, {
        description = "Move window left",
        group = "Перемещение"
    }}, {{env.mod}, "KP_right", function()
        grid.move_to("right")
    end, {
        description = "Move window right",
        group = "Перемещение"
    }}, {{env.mod, "Control"}, "KP_Up", function()
        grid.move_to("up", true)
    end, {
        description = "Move window up by bound",
        group = "Перемещение"
    }}, {{env.mod, "Control"}, "KP_Down", function()
        grid.move_to("down", true)
    end, {
        description = "Move window down by bound",
        group = "Перемещение"
    }}, {{env.mod, "Control"}, "KP_Left", function()
        grid.move_to("left", true)
    end, {
        description = "Move window left by bound",
        group = "Перемещение"
    }}, {{env.mod, "Control"}, "KP_Right", function()
        grid.move_to("right", true)
    end, {
        description = "Move window right by bound",
        group = "Перемещение"
    }}}

    local layout_grid_resize = {{{env.mod}, "i", function()
        grid.resize_to("up")
    end, {
        description = "Inrease window size to the up",
        group = "Resize"
    }}, {{env.mod}, "k", function()
        grid.resize_to("down")
    end, {
        description = "Inrease window size to the down",
        group = "Resize"
    }}, {{env.mod}, "j", function()
        grid.resize_to("left")
    end, {
        description = "Inrease window size to the left",
        group = "Resize"
    }}, {{env.mod}, "l", function()
        grid.resize_to("right")
    end, {
        description = "Inrease window size to the right",
        group = "Resize"
    }}, {{env.mod, "Shift"}, "i", function()
        grid.resize_to("up", nil, true)
    end, {
        description = "Decrease window size from the up",
        group = "Resize"
    }}, {{env.mod, "Shift"}, "k", function()
        grid.resize_to("down", nil, true)
    end, {
        description = "Decrease window size from the down",
        group = "Resize"
    }}, {{env.mod, "Shift"}, "j", function()
        grid.resize_to("left", nil, true)
    end, {
        description = "Decrease window size from the left",
        group = "Resize"
    }}, {{env.mod, "Shift"}, "l", function()
        grid.resize_to("right", nil, true)
    end, {
        description = "Decrease window size from the right",
        group = "Resize"
    }}, {{env.mod, "Control"}, "i", function()
        grid.resize_to("up", true)
    end, {
        description = "Increase window size to the up by bound",
        group = "Resize"
    }}, {{env.mod, "Control"}, "k", function()
        grid.resize_to("down", true)
    end, {
        description = "Increase window size to the down by bound",
        group = "Resize"
    }}, {{env.mod, "Control"}, "j", function()
        grid.resize_to("left", true)
    end, {
        description = "Increase window size to the left by bound",
        group = "Resize"
    }}, {{env.mod, "Control"}, "l", function()
        grid.resize_to("right", true)
    end, {
        description = "Increase window size to the right by bound",
        group = "Resize"
    }}, {{env.mod, "Control", "Shift"}, "i", function()
        grid.resize_to("up", true, true)
    end, {
        description = "Decrease window size from the up by bound ",
        group = "Resize"
    }}, {{env.mod, "Control", "Shift"}, "k", function()
        grid.resize_to("down", true, true)
    end, {
        description = "Decrease window size from the down by bound ",
        group = "Resize"
    }}, {{env.mod, "Control", "Shift"}, "j", function()
        grid.resize_to("left", true, true)
    end, {
        description = "Decrease window size from the left by bound ",
        group = "Resize"
    }}, {{env.mod, "Control", "Shift"}, "l", function()
        grid.resize_to("right", true, true)
    end, {
        description = "Decrease window size from the right by bound ",
        group = "Resize"
    }}}

    redflat.layout.grid:set_keys(layout_grid_move, "move")
    redflat.layout.grid:set_keys(layout_grid_resize, "resize")

    -- user map layout keys
    local layout_map_layout = {{{env.mod}, "s", function()
        map.swap_group()
    end, {
        description = "Change placement direction for group",
        group = "Макет"
    }}, {{env.mod}, "v", function()
        map.new_group(true)
    end, {
        description = "Create new vertical group",
        group = "Макет"
    }}, {{env.mod}, "h", function()
        map.new_group(false)
    end, {
        description = "Create new horizontal group",
        group = "Макет"
    }}, {{env.mod, "Control"}, "v", function()
        map.insert_group(true)
    end, {
        description = "Insert new vertical group before active",
        group = "Макет"
    }}, {{env.mod, "Control"}, "h", function()
        map.insert_group(false)
    end, {
        description = "Insert new horizontal group before active",
        group = "Макет"
    }}, {{env.mod}, "d", function()
        map.delete_group()
    end, {
        description = "Destroy group",
        group = "Макет"
    }}, {{env.mod, "Control"}, "d", function()
        map.clean_groups()
    end, {
        description = "Destroy all empty groups",
        group = "Макет"
    }}, {{env.mod}, "f", function()
        map.set_active()
    end, {
        description = "Set active group",
        group = "Макет"
    }}, {{env.mod}, "g", function()
        map.move_to_active()
    end, {
        description = "Move focused client to active group",
        group = "Макет"
    }}, {{env.mod, "Control"}, "f", function()
        map.hilight_active()
    end, {
        description = "Hilight active group",
        group = "Макет"
    }}, {{env.mod}, "a", function()
        map.switch_active(1)
    end, {
        description = "Activate next group",
        group = "Макет"
    }}, {{env.mod}, "q", function()
        map.switch_active(-1)
    end, {
        description = "Activate previous group",
        group = "Макет"
    }}, {{env.mod}, "]", function()
        map.move_group(1)
    end, {
        description = "Move active group to the top",
        group = "Макет"
    }}, {{env.mod}, "[", function()
        map.move_group(-1)
    end, {
        description = "Move active group to the bottom",
        group = "Макет"
    }}, {{env.mod}, "r", function()
        map.reset_tree()
    end, {
        description = "Reset layout structure",
        group = "Макет"
    }}}

    local layout_map_resize = {{{env.mod}, "j", function()
        map.incfactor(nil, 0.1, false)
    end, {
        description = "Increase window horizontal size factor",
        group = "Resize"
    }}, {{env.mod}, "l", function()
        map.incfactor(nil, -0.1, false)
    end, {
        description = "Decrease window horizontal size factor",
        group = "Resize"
    }}, {{env.mod}, "i", function()
        map.incfactor(nil, 0.1, true)
    end, {
        description = "Increase window vertical size factor",
        group = "Resize"
    }}, {{env.mod}, "k", function()
        map.incfactor(nil, -0.1, true)
    end, {
        description = "Decrease window vertical size factor",
        group = "Resize"
    }}, {{env.mod, "Control"}, "j", function()
        map.incfactor(nil, 0.1, false, true)
    end, {
        description = "Increase group horizontal size factor",
        group = "Resize"
    }}, {{env.mod, "Control"}, "l", function()
        map.incfactor(nil, -0.1, false, true)
    end, {
        description = "Decrease group horizontal size factor",
        group = "Resize"
    }}, {{env.mod, "Control"}, "i", function()
        map.incfactor(nil, 0.1, true, true)
    end, {
        description = "Increase group vertical size factor",
        group = "Resize"
    }}, {{env.mod, "Control"}, "k", function()
        map.incfactor(nil, -0.1, true, true)
    end, {
        description = "Decrease group vertical size factor",
        group = "Resize"
    }}}

    redflat.layout.map:set_keys(layout_map_layout, "layout")
    redflat.layout.map:set_keys(layout_map_resize, "resize")

    -- Global keys
    --------------------------------------------------------------------------------
    self.raw.root = {{{env.mod}, "F1", function()
        redtip:show()
    end, {
        description = "[Hold] Show awesome hotkeys helper",
        group = "Main"
    }}, {{env.mod, "Control"}, "F1", function()
        apphelper(appkeys)
    end, {
        description = "[Hold] Показать помощник по горячим клавишам for application",
        group = "Main"
    }}, {{env.mod}, "c", function()
        redflat.float.keychain:activate(keyseq, "User")
    end, {
        description = "[Hold] User key sequence",
        group = "Main"
    }}, {{env.mod}, "F2", function()
        redflat.service.navigator:run()
    end, {
        description = "[Hold] Tiling window control mode",
        group = "Window control"
    }}, {{env.mod}, "h", function()
        redflat.float.control:show()
    end, {
        description = "[Hold] Floating window control mode",
        group = "Window control"
    }}, {{env.mod}, "Return", function()
        awful.spawn(env.terminal)
    end, {
        description = "Open a terminal",
        group = "Actions"
    }}, {{env.mod, "Mod1"}, "space", function()
        awful.spawn("gpaste-client ui")
    end, {
        description = "Clipboard manager",
        group = "Actions"
    }}, {{env.mod, "Control"}, "r", awesome.restart, {
        description = "Reload WM",
        group = "Actions"
    }}, {{env.mod}, "l", focus_switch_byd("right"), {
        description = "Go to right client",
        group = "Client focus"
    }}, {{env.mod}, "j", focus_switch_byd("left"), {
        description = "Go to left client",
        group = "Client focus"
    }}, {{env.mod}, "i", focus_switch_byd("up"), {
        description = "Go to upper client",
        group = "Client focus"
    }}, {{env.mod}, "k", focus_switch_byd("down"), {
        description = "Go to lower client",
        group = "Client focus"
    }}, {{env.mod}, "u", awful.client.urgent.jumpto, {
        description = "Go to urgent client",
        group = "Client focus"
    }}, {{env.mod}, "Tab", focus_to_previous, {
        description = "Go to previos client",
        group = "Client focus"
    }}, {{env.mod}, "w", function()
        mainmenu:show()
    end, {
        description = "Главное меню",
        group = "Виджеты"
    }}, {{env.mod}, "r", function()
        apprunner:show()
    end, {
        description = "Запуск приложений",
        group = "Виджеты"
    }}, {{env.mod}, "p", function()
        redflat.float.prompt:run()
    end, {
        description = "Выполнить",
        group = "Виджеты"
    }}, {{env.mod}, "x", function()
        redflat.float.top:show("cpu")
    end, {
        description = "Список процессов",
        group = "Виджеты"
    }}, {{env.mod, "Control"}, "m", function()
        redflat.widget.mail:update(true)
    end, {
        description = "Проверить новую почту",
        group = "Виджеты"
    }}, {{env.mod, "Control"}, "i", function()
        redflat.widget.minitray:toggle()
    end, {
        description = "Показать мини-лоток",
        group = "Виджеты"
    }}, {{env.mod, "Control"}, "u", function()
        redflat.widget.updates:update(true)
    end, {
        description = "Проверить наличие обновлений",
        group = "Виджеты"
    }}, {{env.mod}, "g", function()
        qlaunch:show()
    end, {
        description = "Быстрый запуск приложений",
        group = "Виджеты"
    }}, {{env.mod}, "z", function()
        redflat.service.logout:show()
    end, {
        description = "Экран выхода",
        group = "Виджеты"
    }}, {{env.mod}, "y", function()
        laybox:toggle_menu(mouse.screen.selected_tag)
    end, {
        description = "Показать меню макета",
        group = "Макеты"
    }}, {{env.mod}, "Up", function()
        awful.layout.inc(1)
    end, {
        description = "Select next layout",
        group = "Макеты"
    }}, {{env.mod}, "Down", function()
        awful.layout.inc(-1)
    end, {
        description = "Select previous layout",
        group = "Макеты"
    }}, {{}, "XF86MonBrightnessUp", function()
        brightness({
            step = 2
        })
    end, {
        description = "Increase brightness",
        group = "Brightness control"
    }}, {{}, "XF86MonBrightnessDown", function()
        brightness({
            step = 2,
            down = true
        })
    end, {
        description = "Reduce brightness",
        group = "Brightness control"
    }}, {{}, "XF86AudioRaiseVolume", volume_raise, {
        description = "Increase volume",
        group = "Volume control"
    }}, {{}, "XF86AudioLowerVolume", volume_lower, {
        description = "Reduce volume",
        group = "Volume control"
    }}, {{}, "XF86AudioMute", volume_mute, {
        description = "Mute audio",
        group = "Volume control"
    }}, {{env.mod}, "a", nil, function()
        appswitcher:show({
            filter = current
        })
    end, {
        description = "Switch to next with current tag",
        group = "Application switcher"
    }}, {{env.mod}, "q", nil, function()
        appswitcher:show({
            filter = current,
            reverse = true
        })
    end, {
        description = "Switch to previous with current tag",
        group = "Application switcher"
    }}, {{env.mod, "Shift"}, "a", nil, function()
        appswitcher:show({
            filter = allscr
        })
    end, {
        description = "Switch to next through all tags",
        group = "Application switcher"
    }}, {{env.mod, "Shift"}, "q", nil, function()
        appswitcher:show({
            filter = allscr,
            reverse = true
        })
    end, {
        description = "Switch to previous through all tags",
        group = "Application switcher"
    }}, {{env.mod}, "Escape", awful.tag.history.restore, {
        description = "Go previos tag",
        group = "Tag navigation"
    }}, {{env.mod}, "Right", awful.tag.viewnext, {
        description = "View next tag",
        group = "Tag navigation"
    }}, {{env.mod}, "Left", awful.tag.viewprev, {
        description = "View previous tag",
        group = "Tag navigation"
    }}, {{env.mod}, "t", function()
        redtitle.toggle(client.focus)
    end, {
        description = "Show/hide titlebar for focused client",
        group = "Titlebar"
    }}, -- {
    --	{ env.mod, "Control" }, "t", function() redtitle.switch(client.focus) end,
    --	{ description = "Switch titlebar view for focused client", group = "Titlebar" }
    -- },
    {{env.mod, "Shift"}, "t", function()
        redtitle.toggle_all()
    end, {
        description = "Show/hide titlebar for all clients",
        group = "Titlebar"
    }}, {{env.mod, "Control", "Shift"}, "t", function()
        redtitle.global_switch()
    end, {
        description = "Switch titlebar view for all clients",
        group = "Titlebar"
    }}, {{env.mod}, "e", function()
        redflat.float.player:show(rb_corner())
    end, {
        description = "Show/hide widget",
        group = "Audio player"
    }}, {{}, "XF86AudioPlay", function()
        redflat.float.player:action("PlayPause")
    end, {
        description = "Play/Pause track",
        group = "Audio player"
    }}, {{}, "XF86AudioNext", function()
        redflat.float.player:action("Next")
    end, {
        description = "Next track",
        group = "Audio player"
    }}, {{}, "XF86AudioPrev", function()
        redflat.float.player:action("Previous")
    end, {
        description = "Previous track",
        group = "Audio player"
    }}, {{env.mod, "Control"}, "s", function()
        for s in screen do
            env.wallpaper(s)
        end
    end, {} -- hidden key
    }}

    -- Client keys
    --------------------------------------------------------------------------------
    self.raw.client = {{{env.mod}, "f", function(c)
        c.fullscreen = not c.fullscreen;
        c:raise()
    end, {
        description = "Toggle fullscreen",
        group = "Client keys"
    }}, {{env.mod}, "F4", function(c)
        c:kill()
    end, {
        description = "Close",
        group = "Client keys"
    }}, {{env.mod, "Control"}, "f", awful.client.floating.toggle, {
        description = "Toggle floating",
        group = "Client keys"
    }}, {{env.mod, "Control"}, "o", function(c)
        c.ontop = not c.ontop
    end, {
        description = "Toggle keep on top",
        group = "Client keys"
    }}, {{env.mod}, "n", function(c)
        c.minimized = true
    end, {
        description = "Minimize",
        group = "Client keys"
    }}, {{env.mod}, "m", function(c)
        c.maximized = not c.maximized;
        c:raise()
    end, {
        description = "Maximize",
        group = "Client keys"
    }}}

    self.keys.root = redflat.util.key.build(self.raw.root)
    self.keys.client = redflat.util.key.build(self.raw.client)

    -- Numkeys
    --------------------------------------------------------------------------------

    -- add real keys without description here
    for i = 1, 9 do
        self.keys.root = awful.util.table.join(self.keys.root, tag_numkey(i, {env.mod}, function(t)
            t:view_only()
        end), tag_numkey(i, {env.mod, "Control"}, function(t)
            awful.tag.viewtoggle(t)
        end), client_numkey(i, {env.mod, "Shift"}, function(t)
            client.focus:move_to_tag(t)
        end), client_numkey(i, {env.mod, "Control", "Shift"}, function(t)
            client.focus:toggle_tag(t)
        end))
    end

    -- make fake keys with description special for key helper widget
    local numkeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}

    self.fake.numkeys = {{{env.mod}, "1..9", nil, {
        description = "Switch to tag",
        group = "Numeric keys",
        keyset = numkeys
    }}, {{env.mod, "Control"}, "1..9", nil, {
        description = "Toggle tag",
        group = "Numeric keys",
        keyset = numkeys
    }}, {{env.mod, "Shift"}, "1..9", nil, {
        description = "Move focused client to tag",
        group = "Numeric keys",
        keyset = numkeys
    }}, {{env.mod, "Control", "Shift"}, "1..9", nil, {
        description = "Toggle focused client on tag",
        group = "Numeric keys",
        keyset = numkeys
    }}}

    -- Hotkeys helper setup
    --------------------------------------------------------------------------------
    redflat.float.hotkeys:set_pack("Main", awful.util.table.join(self.raw.root, self.raw.client, self.fake.numkeys), 2)

    -- Mouse buttons
    --------------------------------------------------------------------------------
    self.mouse.client = awful.util.table.join(awful.button({}, 1, function(c)
        client.focus = c;
        c:raise()
    end), awful.button({}, 2, awful.mouse.client.move), awful.button({env.mod}, 3, awful.mouse.client.resize),
        awful.button({}, 8, function(c)
            c:kill()
        end))

    -- Set root hotkeys
    --------------------------------------------------------------------------------
    root.keys(self.keys.root)
    root.buttons(self.mouse.root)
end

-- End
-----------------------------------------------------------------------------------------------------------------------
return hotkeys
