local awful = require("awful")
local logout_screen = require("redflat.service.logout")

local logout = {}

function logout:init()
    local logout_entries = {
	{   -- Logout
		callback   = function() awesome.quit() end,
		icon_name  = 'logout',
		label      = 'Выход',
		close_apps = true,
	},
	{   -- Shutdown
		callback   = function() awful.spawn.with_shell("systemctl poweroff") end,
		icon_name  = 'poweroff',
		label      = 'Выключение',
		close_apps = true,
	},
	{   -- Reboot
		callback   = function() awful.spawn.with_shell("systemctl reboot") end,
		icon_name  = 'reboot',
		label      = 'Перезагрузка',
		close_apps = true,
	},
	{   -- Switch user
		callback   = function() awful.spawn.with_shell("dm-tool switch-to-greeter") end,
		icon_name  = 'switch',
		label      = 'Сменить Пользователя',
		close_apps = false,
	},
	{   -- Suspend
		callback   = function() awful.spawn.with_shell("systemctl suspend") end,
		icon_name  = 'suspend',
		label      = 'Режим Ожидания',
		close_apps = false,
	},
    }

    logout_screen:set_entries(logout_entries)
end

return logout