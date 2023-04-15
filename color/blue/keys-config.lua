-----------------------------------------------------------------------------------------------------------------------
--                                          Hotkeys and mouse buttons config                                         --
-----------------------------------------------------------------------------------------------------------------------
-- Grab environment
local table = table
local awful = require("awful")
local redflat = require("redflat")

-- Initialize tables and vars for module
-----------------------------------------------------------------------------------------------------------------------
local hotkeys = {mouse = {}, raw = {}, keys = {}, fake = {}}

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
    if client.focus then client.focus:raise() end
end

-- change window focus by direction
local focus_switch_byd = function(dir)
    return function()
        awful.client.focus.bydirection(dir)
        if client.focus then client.focus:raise() end
    end
end

-- minimize and restore windows
local function minimize_all()
    for _, c in ipairs(client.get()) do
        if current(c, mouse.screen) then c.minimized = true end
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
        if current(c, mouse.screen) and not c.sticky then c:kill() end
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
        if tag then action(tag) end
    end)
end

local function client_numkey(i, mod, action)
    return awful.key(mod, "#" .. i + 9, function()
        if client.focus then
            local tag = client.focus.screen.tags[i]
            if tag then action(tag) end
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
        x = screen[mouse.screen].workarea.x +
            screen[mouse.screen].workarea.width,
        y = screen[mouse.screen].workarea.y +
            screen[mouse.screen].workarea.height
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

    self.mouse.root = (awful.util.table.join(
                          awful.button({}, 3, function()
            mainmenu:toggle()
        end), awful.button({}, 4, awful.tag.viewnext),
                          awful.button({}, 5, awful.tag.viewprev)))

    -- volume functions
    local volume_raise = function()
        volume:change_volume({show_notify = true})
    end
    local volume_lower = function()
        volume:change_volume({show_notify = true, down = true})
    end
    local volume_mute = function() volume:mute() end

    -- Init widgets
    redflat.float.qlaunch:init()

    -- Application hotkeys helper
    --------------------------------------------------------------------------------
    local apphelper = function(keys)
        if not client.focus then return end

        local app = client.focus.class:lower()
        for name, sheet in pairs(keys) do
            if name == app then
                redtip:set_pack(client.focus.class, sheet.pack,
                                sheet.style.column, sheet.style.geometry,
                                function() redtip:remove_pack() end)
                redtip:show()
                return
            end
        end

        redflat.float.notify:show({
            text = "Нет подсказок для " .. client.focus.class
        })
    end

    -- Keys for widgets
    --------------------------------------------------------------------------------

    -- Apprunner widget
    ------------------------------------------------------------
    local apprunner_keys_move = {
        {
            {env.mod}, "k", function() apprunner:down() end, {
                description = "Выбрать следующий элемент",
                group = "Навигация"
            }
        }, {
            {env.mod}, "i", function() apprunner:up() end, {
                description = "Выбрать предыдущий элемент",
                group = "Навигация"
            }
        }
    }

    -- apprunner:set_keys(awful.util.table.join(apprunner.keys.move, apprunner_keys_move), "move")
    apprunner:set_keys(apprunner_keys_move, "move")

    -- Menu widget
    ------------------------------------------------------------
    local menu_keys_move = {
        {
            {env.mod}, "k", redflat.menu.action.down, {
                description = "Выбрать следующий элемент",
                group = "Навигация"
            }
        }, {
            {env.mod}, "i", redflat.menu.action.up, {
                description = "Выбрать предыдущий элемент",
                group = "Навигация"
            }
        }, {
            {env.mod}, "j", redflat.menu.action.back,
            {description = "Вернуться", group = "Навигация"}
        }, {
            {env.mod}, "l", redflat.menu.action.enter,
            {
                description = "Открыть подменю",
                group = "Навигация"
            }
        }
    }

    -- redflat.menu:set_keys(awful.util.table.join(redflat.menu.keys.move, menu_keys_move), "move")
    redflat.menu:set_keys(menu_keys_move, "move")

    -- Appswitcher widget
    ------------------------------------------------------------
    local appswitcher_keys = {
        {
            {env.mod}, "a", function() appswitcher:switch() end, {
                description = "Выбрать следующее приложение",
                group = "Навигация"
            }
        }, {
            {env.mod, "Shift"}, "a", function() appswitcher:switch() end, {} -- hidden key
        }, {
            {env.mod}, "Tab",
            function() appswitcher:switch({reverse = true}) end, {
                description = "Выбрать предыдущее приложение",
                group = "Навигация"
            }
        }, {
            {env.mod, "Shift"}, "Tab",
            function() appswitcher:switch({reverse = true}) end, {} -- hidden key
        }, {
            {}, "Super_L", function() appswitcher:hide() end,
            {
                description = "Активировать и выйти",
                group = "Action"
            }
        }, {
            {env.mod}, "Super_L", function() appswitcher:hide() end, {} -- hidden key
        }, {
            {env.mod, "Shift"}, "Super_L", function()
                appswitcher:hide()
            end, {} -- hidden key
        }, {
            {}, "Return", function() appswitcher:hide() end,
            {
                description = "Активировать и выйти",
                group = "Action"
            }
        }, {
            {}, "Escape", function() appswitcher:hide(true) end,
            {description = "Выйти", group = "Action"}
        }, {
            {env.mod}, "Escape", function() appswitcher:hide(true) end, {} -- hidden key
        }, {
            {env.mod}, "F1", function() redtip:show() end, {
                description = "Показать помощник по горячим клавишам",
                group = "Action"
            }
        }
    }

    appswitcher:set_keys(appswitcher_keys)

    -- Emacs like key sequences
    --------------------------------------------------------------------------------

    -- initial key
    local keyseq = {{env.mod}, "c", {}, {}}

    -- group
    keyseq[3] = {
        {{}, "k", {}, {}}, -- application kill group
        {{}, "c", {}, {}}, -- client managment group
        {{}, "r", {}, {}}, -- client managment group
        {{}, "n", {}, {}}, -- client managment group
        {{}, "g", {}, {}}, -- run or rise group
        {{}, "f", {}, {}} -- launch application group
    }

    -- quick launch key sequence actions
    for i = 1, 9 do
        local ik = tostring(i)
        table.insert(keyseq[3][5][3], {
            {}, ik, function() qlaunch:run_or_raise(ik) end, {
                description = "Запустить или поднять приложение №" ..
                    ik,
                group = "Запустить или Поднять",
                keyset = {ik}
            }
        })
        table.insert(keyseq[3][6][3], {
            {}, ik, function() qlaunch:run_or_raise(ik, true) end, {
                description = "Запустить приложение №" ..
                    ik,
                group = "Быстрый Запуск",
                keyset = {ik}
            }
        })
    end

    -- application kill sequence actions
    keyseq[3][1][3] = {
        {
            {}, "f",
            function() if client.focus then client.focus:kill() end end, {
                description = "Закрыть выделенное",
                group = "Закрытие приложений",
                keyset = {"f"}
            }
        }, {
            {}, "a", kill_all, {
                description = "Закрыть все в текущем теге",
                group = "Закрытие приложений",
                keyset = {"a"}
            }
        }
    }

    -- client managment sequence actions
    keyseq[3][2][3] = {
        {
            {}, "p", function() toggle_placement(env) end, {
                description = "Переключение окна (основной/подчиненный)",
                group = "Управление клиентами",
                keyset = {"p"}
            }
        }
    }

    keyseq[3][3][3] = {
        {
            {}, "f", restore_client, {
                description = "Восстановить свернутый клиент",
                group = "Управление клиентами",
                keyset = {"f"}
            }
        }, {
            {}, "a", restore_all, {
                description = "Восстановить всех клиентов в текущим теге",
                group = "Управление клиентами",
                keyset = {"a"}
            }
        }
    }

    keyseq[3][4][3] = {
        {
            {}, "f",
            function()
                if client.focus then
                    client.focus.minimized = true
                end
            end, {
                description = "Свернуть сфокусированный клиент",
                group = "Управление клиентами",
                keyset = {"f"}
            }
        }, {
            {}, "a", minimize_all, {
                description = "Свернуть все клиенты в текущем теге",
                group = "Управление клиентами",
                keyset = {"a"}
            }
        }, {
            {}, "e", minimize_all_except_focused, {
                description = "Свернуть все клиенты, кроме сфокусированных",
                group = "Управление клиентами",
                keyset = {"e"}
            }
        }
    }

    -- Макеты
    --------------------------------------------------------------------------------

    -- shared layout keys
    local layout_tile = {
        {
            {env.mod}, "l", function() awful.tag.incmwfact(0.05) end, {
                description = "Увеличьте коэффициент ширины мастера",
                group = "Макет"
            }
        }, {
            {env.mod}, "j", function() awful.tag.incmwfact(-0.05) end, {
                description = "Уменьшить коэффициент ширины мастера",
                group = "Макет"
            }
        }, {
            {env.mod}, "i", function() awful.client.incwfact(0.05) end, {
                description = "Увеличить фактор окна клиента",
                group = "Макет"
            }
        }, {
            {env.mod}, "k", function() awful.client.incwfact(-0.05) end, {
                description = "Уменьшить фактор окна клиента",
                group = "Макет"
            }
        }, {
            {env.mod}, "+", function()
                awful.tag.incnmaster(1, nil, true)
            end, {
                description = "Увеличить количество мастер-клиентов",
                group = "Макет"
            }
        }, {
            {env.mod}, "-", function()
                awful.tag.incnmaster(-1, nil, true)
            end, {
                description = "Уменьшить количество мастер-клиентов",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "+",
            function() awful.tag.incncol(1, nil, true) end, {
                description = "Увеличить количество колонок",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "-",
            function() awful.tag.incncol(-1, nil, true) end, {
                description = "Уменьшить количество колонок",
                group = "Макет"
            }
        }
    }

    laycom:set_keys(layout_tile, "tile")

    -- grid layout keys
    local layout_grid_move = {
        {
            {env.mod}, "KP_Up", function() grid.move_to("up") end, {
                description = "Переместить окно вверх",
                group = "Перемещение"
            }
        }, {
            {env.mod}, "KP_Down", function() grid.move_to("down") end, {
                description = "Переместить окно вниз",
                group = "Перемещение"
            }
        }, {
            {env.mod}, "KP_Left", function() grid.move_to("left") end, {
                description = "Переместить окно влево",
                group = "Перемещение"
            }
        }, {
            {env.mod}, "KP_right", function() grid.move_to("right") end, {
                description = "Переместить окно вправо",
                group = "Перемещение"
            }
        }, {
            {env.mod, "Control"}, "KP_Up",
            function() grid.move_to("up", true) end, {
                description = "Переместить окно вверх по границе",
                group = "Перемещение"
            }
        }, {
            {env.mod, "Control"}, "KP_Down",
            function() grid.move_to("down", true) end, {
                description = "Переместить окно вниз по границе",
                group = "Перемещение"
            }
        }, {
            {env.mod, "Control"}, "KP_Left",
            function() grid.move_to("left", true) end, {
                description = "Переместить окно влево по границе",
                group = "Перемещение"
            }
        }, {
            {env.mod, "Control"}, "KP_Right",
            function() grid.move_to("right", true) end, {
                description = "Переместить окно вправо по границе",
                group = "Перемещение"
            }
        }
    }

    local layout_grid_resize = {
        {
            {env.mod}, "i", function() grid.resize_to("up") end, {
                description = "Увеличить размер окна вверх",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "k", function() grid.resize_to("down") end, {
                description = "Увеличить размер окна вниз",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "j", function() grid.resize_to("left") end, {
                description = "Увеличить размер окна влево",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "l", function() grid.resize_to("right") end, {
                description = "Увеличить размер окна вправо",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Shift"}, "i",
            function() grid.resize_to("up", nil, true) end, {
                description = "Уменьшить размер окна сверху",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Shift"}, "k",
            function() grid.resize_to("down", nil, true) end, {
                description = "Уменьшить размер окна снизу",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Shift"}, "j",
            function() grid.resize_to("left", nil, true) end, {
                description = "Уменьшить размер окна слева",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Shift"}, "l",
            function() grid.resize_to("right", nil, true) end, {
                description = "Уменьшить размер окна справа",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "i",
            function() grid.resize_to("up", true) end, {
                description = "Увеличить размер окна вверх по границе",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "k",
            function() grid.resize_to("down", true) end, {
                description = "Увеличить размер окна вниз по границе",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "j",
            function() grid.resize_to("left", true) end, {
                description = "Увеличить размер окна влево по границе",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "l",
            function() grid.resize_to("right", true) end, {
                description = "Увеличить размер окна вправопо границе",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control", "Shift"}, "i",
            function() grid.resize_to("up", true, true) end, {
                description = "Уменьшить размер окна сверху на границу ",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control", "Shift"}, "k",
            function() grid.resize_to("down", true, true) end, {
                description = "Уменьшить размер окна снизу на границу ",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control", "Shift"}, "j",
            function() grid.resize_to("left", true, true) end, {
                description = "Уменьшить размер окна слева на границу ",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control", "Shift"}, "l",
            function() grid.resize_to("right", true, true) end, {
                description = "Уменьшить размер окна справа на границу ",
                group = "Изменение размера"
            }
        }
    }

    redflat.layout.grid:set_keys(layout_grid_move, "move")
    redflat.layout.grid:set_keys(layout_grid_resize, "resize")

    -- user map layout keys
    local layout_map_layout = {
        {
            {env.mod}, "s", function() map.swap_group() end, {
                description = "Изменить направление размещения для группы",
                group = "Макет"
            }
        }, {
            {env.mod}, "v", function() map.new_group(true) end, {
                description = "Создать новую вертикальную группу",
                group = "Макет"
            }
        }, {
            {env.mod}, "h", function() map.new_group(false) end, {
                description = "Создать новую горизонтальную группу",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "v", function()
                map.insert_group(true)
            end, {
                description = "Вставить новую вертикальную группу перед активной",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "h", function()
                map.insert_group(false)
            end, {
                description = "Вставить новую горизонтальную группу перед активной",
                group = "Макет"
            }
        }, {
            {env.mod}, "d", function() map.delete_group() end,
            {
                description = "Уничтожить группу",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "d", function() map.clean_groups() end, {
                description = "Уничтожить все пустые группы",
                group = "Макет"
            }
        }, {
            {env.mod}, "f", function() map.set_active() end, {
                description = "Установить активную группу",
                group = "Макет"
            }
        }, {
            {env.mod}, "g", function() map.move_to_active() end, {
                description = "Переместить сфокусированного клиента в активную группу",
                group = "Макет"
            }
        }, {
            {env.mod, "Control"}, "f", function()
                map.hilight_active()
            end, {
                description = "Выделить активную группу",
                group = "Макет"
            }
        }, {
            {env.mod}, "a", function() map.switch_active(1) end, {
                description = "Активировать следующую группу",
                group = "Макет"
            }
        }, {
            {env.mod}, "q", function() map.switch_active(-1) end, {
                description = "Активировать предыдущую группу",
                group = "Макет"
            }
        }, {
            {env.mod}, "]", function() map.move_group(1) end, {
                description = "Переместить активную группу наверх",
                group = "Макет"
            }
        }, {
            {env.mod}, "[", function() map.move_group(-1) end, {
                description = "Переместить активную группу вниз",
                group = "Макет"
            }
        }, {
            {env.mod}, "r", function() map.reset_tree() end, {
                description = "Сбросить структуру макета",
                group = "Макет"
            }
        }
    }

    local layout_map_resize = {
        {
            {env.mod}, "j", function() map.incfactor(nil, 0.1, false) end, {
                description = "Увеличить коэффициент горизонтального размера окна",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "l", function()
                map.incfactor(nil, -0.1, false)
            end, {
                description = "Уменьшить коэффициент горизонтального размера окна",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "i", function() map.incfactor(nil, 0.1, true) end, {
                description = "Увеличить коэффициент вертикального размера окна",
                group = "Изменение размера"
            }
        }, {
            {env.mod}, "k", function() map.incfactor(nil, -0.1, true) end, {
                description = "Уменьшить коэффициент вертикального размера окна",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "j",
            function() map.incfactor(nil, 0.1, false, true) end, {
                description = "Увеличить коэффициент горизонтального размера группы",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "l",
            function() map.incfactor(nil, -0.1, false, true) end, {
                description = "Уменьшить коэффициент горизонтального размера группы",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "i",
            function() map.incfactor(nil, 0.1, true, true) end, {
                description = "Увеличить коэффициент вертикального размера группы",
                group = "Изменение размера"
            }
        }, {
            {env.mod, "Control"}, "k",
            function() map.incfactor(nil, -0.1, true, true) end, {
                description = "Уменьшить коэффициент вертикального размера группы",
                group = "Изменение размера"
            }
        }
    }

    redflat.layout.map:set_keys(layout_map_layout, "layout")
    redflat.layout.map:set_keys(layout_map_resize, "resize")

    -- Global keys
    --------------------------------------------------------------------------------
    self.raw.root = {
        {
            {env.mod}, "F1", function() redtip:show() end, {
                description = "[Удерживать] Показать помощник по горячим клавишам Awesome",
                group = "Основные"
            }
        }, {
            {env.mod, "Control"}, "F1", function() apphelper(appkeys) end, {
                description = "[Удерживать] Показать помощник по горячим клавишам для приложения",
                group = "Основные"
            }
        }, {
            {env.mod}, "b", function()
                myscreen = awful.screen.focused()
                myscreen.panel.visible = not myscreen.panel.visible
            end, {
                description = "Показать/Скрыть панель",
                group = "Основные"
            }
        }, {
            {env.mod}, "c",
            function()
                redflat.float.keychain:activate(keyseq, "User")
            end, {
                description = "[Удерживать] Последовательность клавиш пользователя",
                group = "Основные"
            }
        }, {
            {env.mod}, "F2", function()
                redflat.service.navigator:run()
            end, {
                description = "[Удерживать] Режим управления мозаичным окном",
                group = "Управление окном"
            }
        }, {
            {env.mod}, "h", function() redflat.float.control:show() end, {
                description = "[Удерживать] Режим управления плавающим окном",
                group = "Управление окном"
            }
        }, {
            {env.mod}, "Return", function() awful.spawn(env.terminal) end,
            {
                description = "Открыть терминал",
                group = "Действия"
            }
        }, {
            {env.mod, "Mod1"}, "space",
            function() awful.spawn("gpaste-client ui") end, {
                description = "Менеджер буфера обмена",
                group = "Действия"
            }
        }, {
            {env.mod, "Control"}, "r", awesome.restart, {
                description = "Перезагрузить Awesome",
                group = "Действия"
            }
        }, {
            {env.mod}, "l", focus_switch_byd("right"), {
                description = "Перейти к правому клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.mod}, "j", focus_switch_byd("left"), {
                description = "Перейти к левому клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.mod}, "i", focus_switch_byd("up"), {
                description = "Перейти к верхнему клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.mod}, "k", focus_switch_byd("down"), {
                description = "Перейти к нижнему клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.mod}, "u", awful.client.urgent.jumpto, {
                description = "Перейти к срочному клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.alt}, "Tab", focus_to_previous, {
                description = "Перейти к предыдущему клиенту",
                group = "Фокусировка клиента"
            }
        }, {
            {env.mod}, "w", function() mainmenu:show() end, {
                description = "Показать главное меню",
                group = "Виджеты"
            }
        }, {
            {env.mod}, "r", function() apprunner:show() end, {
                description = "Средство запуска приложений",
                group = "Виджеты"
            }
        }, {
            {env.mod}, "p", function() redflat.float.prompt:run() end, {
                description = "Показать окно быстрого запуска",
                group = "Виджеты"
            }
        }, {
            {env.mod}, "x", function() redflat.float.top:show("cpu") end, {
                description = "Показать список основных процессов",
                group = "Виджеты"
            }
        }, {
            {env.mod, "Control"}, "m",
            function() redflat.widget.mail:update(true) end, {
                description = "Проверить новую почту",
                group = "Виджеты"
            }
        }, {
            {env.mod, "Control"}, "i",
            function() redflat.widget.minitray:toggle() end,
            {
                description = "Показать минитрей",
                group = "Виджеты"
            }
        }, {
            {env.mod, "Control"}, "u",
            function() redflat.widget.updates:update(true) end, {
                description = "Проверить доступные обновления",
                group = "Виджеты"
            }
        }, {
            {env.mod}, "q", function() qlaunch:show() end, {
                description = "Быстрый запуск приложений",
                group = "Виджеты"
            }
        }, {
            {env.mod}, "z", function() redflat.service.logout:show() end,
            {description = "Экран выхода", group = "Виджеты"}
        }, {
            {env.mod}, "y",
            function() laybox:toggle_menu(mouse.screen.selected_tag) end, {
                description = "Показать меню макета",
                group = "Макеты"
            }
        }, {
            {env.mod}, "Up", function() awful.layout.inc(1) end, {
                description = "Выбрать следующий макет",
                group = "Макеты"
            }
        }, {
            {env.mod}, "Down", function() awful.layout.inc(-1) end, {
                description = "Выбрать предыдущий макет",
                group = "Макеты"
            }
        }, {
            {}, "XF86MonBrightnessUp", function()
                brightness({step = 2})
            end, {
                description = "Увеличить яркость",
                group = "Контроль яркости"
            }
        }, {
            {}, "XF86MonBrightnessDown",
            function() brightness({step = 2, down = true}) end, {
                description = "Уменьшить яркость",
                group = "Контроль яркости"
            }
        }, {
            {}, "XF86AudioRaiseVolume", volume_raise, {
                description = "Увеличить громкость",
                group = "Контроль громкости"
            }
        }, {
            {}, "XF86AudioLowerVolume", volume_lower, {
                description = "Уменьшить громкость",
                group = "Контроль громкости"
            }
        }, {
            {}, "XF86AudioMute", volume_mute, {
                description = "Отключить звук",
                group = "Контроль громкости"
            }
        }, {
            {env.alt}, "Tab", nil,
            function() appswitcher:show({filter = current}) end, {
                description = "Перейти к следующему в текущем теге",
                group = "Переключатель приложений"
            }
        }, {
            {env.alt, "Shift"}, "Tab", nil,
            function() appswitcher:show({filter = allscr}) end, {
                description = "Перейти к следующему через все теги",
                group = "Переключатель приложений"
            }
        }, {
            {env.mod}, "Tab", nil,
            function()
                appswitcher:show({filter = current, reverse = true})
            end, {
                description = "Перейти к предыдущему в текущем теге",
                group = "Переключатель приложений"
            }
        }, {
            {env.mod, "Shift"}, "Tab", nil,
            function()
                appswitcher:show({filter = allscr, reverse = true})
            end, {
                description = "Перейти к предыдущему через все теги",
                group = "Переключатель приложений"
            }
        }, {
            {env.mod}, "Escape", awful.tag.history.restore, {
                description = "Перейти к предыдущему тегу",
                group = "Навигация по тегам"
            }
        }, {
            {env.mod}, "Right", awful.tag.viewnext, {
                description = "Посмотреть следующий тег",
                group = "Навигация по тегам"
            }
        }, {
            {env.mod}, "Left", awful.tag.viewprev, {
                description = "Посмотреть предыдущий тег",
                group = "Навигация по тегам"
            }
        }, {
            {env.mod}, "t", function() redtitle.toggle(client.focus) end, {
                description = "Показать/скрыть заголовок для сфокусированного клиента",
                group = "Заголовок"
            }
        }, -- {
        --	{ env.mod, "Control" }, "t", function() redtitle.switch(client.focus) end,
        --	{ description = "Switch titlebar view for focused client", group = "Заголовок" }
        -- },
        {
            {env.mod, "Shift"}, "t", function() redtitle.toggle_all() end, {
                description = "Показать/скрыть заголовок для всех клиентов",
                group = "Заголовок"
            }
        }, {
            {env.mod, "Control", "Shift"}, "t",
            function() redtitle.global_switch() end, {
                description = "Переключить видимость заголовка для всех клиентов",
                group = "Заголовок"
            }
        }, {
            {env.mod}, "e",
            function() redflat.float.player:show(rb_corner()) end, {
                description = "Показать/скрыть виджет",
                group = "Аудиоплеер"
            }
        }, {
            {}, "XF86AudioPlay",
            function() redflat.float.player:action("PlayPause") end, {
                description = "Воспроизведение/Пауза трека",
                group = "Аудиоплеер"
            }
        }, {
            {}, "XF86AudioNext",
            function() redflat.float.player:action("Next") end,
            {
                description = "Следующий трек",
                group = "Аудиоплеер"
            }
        }, {
            {}, "XF86AudioPrev",
            function() redflat.float.player:action("Previous") end,
            {
                description = "Предыдущий трек",
                group = "Аудиоплеер"
            }
        }, {
            {env.mod, "Control"}, "s",
            function() for s in screen do env.wallpaper(s) end end, {} -- hidden key
        }
    }

    -- Ключи клиента
    --------------------------------------------------------------------------------
    self.raw.client = {
        {
            {env.mod}, "f", function(c)
                c.fullscreen = not c.fullscreen;
                c:raise()
            end,
            {
                description = "Полный экран",
                group = "Ключи клиента"
            }
        }, {
            {env.mod}, "F4", function(c) c:kill() end,
            {
                description = "Закрыть",
                group = "Ключи клиента"
            }
        }, {
            {env.mod, "Control"}, "f", awful.client.floating.toggle,
            {
                description = "Плавающий",
                group = "Ключи клиента"
            }
        }, {
            {env.mod, "Control"}, "o", function(c)
                c.ontop = not c.ontop
            end, {
                description = "Держать наверху",
                group = "Ключи клиента"
            }
        }, {
            {env.mod}, "n", function(c) c.minimized = true end,
            {
                description = "Свернуть",
                group = "Ключи клиента"
            }
        }, {
            {env.mod}, "m", function(c)
                c.maximized = not c.maximized;
                c:raise()
            end,
            {
                description = "Развернуть",
                group = "Ключи клиента"
            }
        }
    }

    self.keys.root = redflat.util.key.build(self.raw.root)
    self.keys.client = redflat.util.key.build(self.raw.client)

    -- Numkeys
    --------------------------------------------------------------------------------

    -- add real keys without description here
    for i = 1, 9 do
        self.keys.root = awful.util.table.join(self.keys.root, tag_numkey(i, {
            env.mod
        }, function(t) t:view_only() end), tag_numkey(i, {env.mod, "Control"},
                                                      function(t)
            awful.tag.viewtoggle(t)
        end), client_numkey(i, {env.mod, "Shift"},
                            function(t) client.focus:move_to_tag(t) end),
                                               client_numkey(i, {
            env.mod, "Control", "Shift"
        }, function(t) client.focus:toggle_tag(t) end))
    end

    -- make fake keys with description special for key helper widget
    local numkeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}

    self.fake.numkeys = {
        {
            {env.mod}, "1..9", nil, {
                description = "Переключиться на тег",
                group = "Цифровые клавиши",
                keyset = numkeys
            }
        }, {
            {env.mod, "Control"}, "1..9", nil, {
                description = "Переключить тег",
                group = "Цифровые клавиши",
                keyset = numkeys
            }
        }, {
            {env.mod, "Shift"}, "1..9", nil, {
                description = "Переместить сфокусированного клиента в тег",
                group = "Цифровые клавиши",
                keyset = numkeys
            }
        }, {
            {env.mod, "Control", "Shift"}, "1..9", nil, {
                description = "Переключить сфокусированный клиент на тег",
                group = "Цифровые клавиши",
                keyset = numkeys
            }
        }
    }

    -- Hotkeys helper setup
    --------------------------------------------------------------------------------
    redflat.float.hotkeys:set_pack("Main", awful.util.table
                                       .join(self.raw.root, self.raw.client,
                                             self.fake.numkeys), 2)

    -- Mouse buttons
    --------------------------------------------------------------------------------
    self.mouse.client = awful.util.table.join(
                            awful.button({}, 1, function(c)
            client.focus = c;
            c:raise()
        end), awful.button({}, 2, awful.mouse.client.move), awful.button(
                                {env.mod}, 3, awful.mouse.client.resize),
                            awful.button({}, 8, function(c) c:kill() end))

    -- Set root hotkeys
    --------------------------------------------------------------------------------
    root.keys(self.keys.root)
    root.buttons(self.mouse.root)
end

-- End
-----------------------------------------------------------------------------------------------------------------------
return hotkeys
