-----------------------------------------------------------------------------------------------------------------------
--                                                 Orange theme                                                      --
-----------------------------------------------------------------------------------------------------------------------
local awful = require("awful")

-- This theme was inherited from another with overwriting some values
-- Check parent theme to find full settings list and its description
local theme = require("themes/colored/theme")


-- Color scheme
-----------------------------------------------------------------------------------------------------------------------
theme.color.main   = "#B22B00"
theme.color.urgent = "#064A71"


-- Common
-----------------------------------------------------------------------------------------------------------------------
theme.path = awful.util.get_configuration_dir() .. "themes/orange"

-- Main config
--------------------------------------------------------------------------------
theme.panel_height = 24 -- panel height
theme.wallpaper    = theme.path .. "/wallpaper/custom.png"

-- Setup parent theme settings
--------------------------------------------------------------------------------
theme:update()


-- Desktop config
-----------------------------------------------------------------------------------------------------------------------
theme.desktop.textset = {
	font  = "Belligerent Madness 10",
	spacing = 10,
	color = theme.desktop.color
}

-- Panel widgets
-----------------------------------------------------------------------------------------------------------------------

-- Circle shaped taglist
--------------------------------------------------------------
theme.gauge.tag.orange = {
	width        = 20,
	line_width   = 2,
	radius       = 7,
	iradius      = 2,
}

-- Tasklist
--------------------------------------------------------------
theme.widget.tasklist = {
	char_digit = 5,
	-- task = theme.gauge.task.blue,
	task = {
		font       = { size = 12 },
		text_shift = 10,
		point      = { size = 4, space = 3, gap = 13 },
		underline  = { height = 20, thickness = 4, gap = 14, dh = 4 },
	},
}
-- Circle shaped monitor
--------------------------------------------------------------
theme.gauge.monitor.circle = {
    width = 20, -- widget width
    line_width = 2, -- width of circle
	radius = 7, -- circle radius
    iradius = 2, -- radius for center point
}

-- individual margins for panel widgets
------------------------------------------------------------
theme.widget.wrapper = {
	layoutbox   = { 5, 5, 3, 3 },
	taglist     = { 5, 5, 3, 3 },
	textclock   = { 5, 5, 3, 3 },
	volume      = { 5, 5, 3, 3 },
	keyboard    = { 5, 5, 3, 3 },
	mail        = { 5, 5, 3, 3 },
	network     = { 0, 0, 3, 3 },
	cpu         = { 5, 5, 3, 3 },
	mem			= { 5, 5, 3, 3 },
	battery     = { 5, 5, 3, 3 },
	tray        = { 5, 5, 3, 3 },
	tasklist    = { 5, 5, 3, 3 }, -- centering tasklist widget
}

-- End
-----------------------------------------------------------------------------------------------------------------------
return theme
