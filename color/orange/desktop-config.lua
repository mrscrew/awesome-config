-----------------------------------------------------------------------------------------------------------------------
--                                               Desktop widgets config                                              --
-----------------------------------------------------------------------------------------------------------------------

-- Grab environment
local beautiful = require("beautiful")
local redflat = require("redflat")
local wibox = require("wibox")

local unpack = unpack or table.unpack

-- Initialize tables and vars for module
-----------------------------------------------------------------------------------------------------------------------
local desktop = {}

-- desktop aliases
local workarea = screen[mouse.screen].workarea
local system = redflat.system

-- Desktop widgets
-----------------------------------------------------------------------------------------------------------------------
function desktop:init(args)
	if not beautiful.desktop then return end

	args = args or {}
	local env = args.env or {}
	local style = { color = beautiful.desktop.color }
	local autohide = env.desktop_autohide or false

	-- Setting and placement
	--------------------------------------------------------------------------------
	local gap = { x = { 680, 60 }, y = { 60, 80 } }
	local geometry = {
		width  = workarea.width  - (gap.x[1] + gap.x[2]), x = workarea.x + gap.x[1],
		height = workarea.height - (gap.y[1] + gap.y[2]), y = workarea.y + gap.y[1],
	}

	local main_layout = wibox.layout.fixed.vertical()

	-- highlight settings
	local colset = {
		light = {}, base = {}, diskp = {}, diskpf = {}, tcpu = {}, tgpu = {}, thdd = {},
		sspeed = {}, hspeed = {}, tspeed = {}, cores = {}
	}

	colset.base[-1] = style.color.icon
	colset.light[-1] = style.color.main

	colset.diskp[-1] = style.color.icon
	colset.diskp[75] = style.color.main

	colset.diskpf[-1] = style.color.main
	colset.diskpf[25] = style.color.icon

	colset.tcpu[-1] = style.color.icon
	colset.tcpu[75] = style.color.main

	colset.tgpu[-1] = style.color.icon
	colset.tgpu[80] = style.color.main

	colset.thdd[-1] = style.color.icon
	colset.thdd[40] = style.color.main

	colset.sspeed[-1] = style.color.icon
	colset.sspeed[80 * 2048] = style.color.main

	colset.hspeed[-1] = style.color.icon
	colset.hspeed[30 * 2048] = style.color.main

	colset.tspeed[-1] = style.color.icon
	colset.tspeed[2.5 * 1024] = style.color.main

	--noinspection ArrayElementZero
	colset.cores[-1] = style.color.icon
	colset.cores[3] = style.color.main

	-- Support functions
	--------------------------------------------------------------------------------
	local function get_order(t)
		local order = {}
		for i, _ in pairs(t) do order[#order + 1] = i end
		table.sort(order)
		return order
	end

	local function form_value(value, color_set, text_set, unit, dn)
		color_set = color_set or colset.base
		text_set = text_set or { "none" }
		dn = dn or 3

		local hilight = style.color.gray
		local co = get_order(color_set)
		for _, i in ipairs(co) do
			if value > i then hilight = color_set[i] end
		end

		local txt = value
		if unit then
			txt = redflat.util.text.dformat(value, unit, dn, " ")
		else
			local to = get_order(text_set)

			for i = #to, 1, -1 do
				if value < to[i] then txt = text_set[to[i]] end
			end
		end

		return string.format('<span color="%s">%s</span>', hilight, txt)
	end

	local function form_text(sentences, values)
		local txt = {}
		for i, v in ipairs(values) do txt[#txt + 1] = string.format(sentences[i], unpack(v)) end
		return table.concat(txt)
	end

	local function recolor(txt, c)
		return string.format('<span color="%s">%s</span>', c, txt)
	end

	-- CPU and memory usage
	--------------------------------------------------------------------------------
	local cpu_storage = { cpu_total = {}, cpu_active = {} }
	local cpuset = { blocks = { {}, {} }, height = 150 }
	cpuset.unit = { { "MB", - 1 }, { "GB", 1024 } }

	local cpu_sentences = {
		"%s",
		" %s процентов ЦП. ",
		"Более подробно %s из %s доступных ядер полностью загружены ",
		"и %s %s используется наполовину. ",
		"Furthermore %s %s used by more than ten percent.",
	}

	local cpu_intro = {}
	cpu_intro[11] = "	Ваша система использует всего"
	cpu_intro[50] = "	Ваша система использует"
	cpu_intro[100] = "	Внимание! Ваша система использует"

	-- cpu meter function
	cpuset.blocks[1].timeout = 5
	cpuset.blocks[1].action = function()
		local usage = system.cpu_usage(cpu_storage)

		local core_load = { full = 0, half = 0, low = 0 }
		for _, core in ipairs(usage.core) do
			if     core > 90 then core_load.full = core_load.full + 1
			elseif core > 50 then core_load.half = core_load.half + 1
			elseif core > 10 then core_load.low  = core_load.low + 1 end
		end

		local values = {
			{ form_value(usage.total, {}, cpu_intro) },
			{ form_value(usage.total, colset.light, {}) },
			{ form_value(core_load.full, colset.cores), #usage.core },
			{ form_value(core_load.half, colset.cores, { "не одно" }), core_load.half > 1 and "are" or "не" },
			{ form_value(core_load.low), core_load.low > 1 and "cores are" or "core is" },
		}

		return form_text(cpu_sentences, values)
	end

	-- memory meter function
	local mem_states = {}
	mem_states[10] = "меньше десятой части всего обьема."
	mem_states[25] = "меньше четверти всего обьема."
	mem_states[50] = "меньше половины всего обьема."
	mem_states[75] = "больше половины всего обьема."
	mem_states[100] = "очень близко к пределу."

	local mem_sentences = {
		" Тем временем использование памяти состовляет %s, и это %s",
		" Что касается пространства подкачки, то сейчас используется %s.",
	}

	cpuset.blocks[2].timeout = 10
	cpuset.blocks[2].action = function()
		local mem = system.memory_info()

		local values = {
			{ form_value(mem.inuse, colset.light, nil, cpuset.unit), form_value(mem.usep, {}, mem_states) },
			{ form_value(mem.swp.inuse, colset.light, { "ни одного байта" }, mem.swp.inuse > 0 and cpuset.unit or nil) },
		}

		return form_text(mem_sentences, values)
	end

	-- Disks
	--------------------------------------------------------------------------------
	local diskset = { blocks = { { timeout = 60 } }, height = 150 }
	diskset.unit = { { "KB", 1 }, { "MB", 1024^1 }, { "GB", 1024^2 } }

	local disks_points = { "/", "/home", "/mnt/storage", "/mnt/media" }
	local disk_sentences = {
		"	Переходя к теме дисков, в системном разделе найдено %s данных," ..
				" ыи %s%s процентов дискового пространства остаются свободными.",
		" Домашний раздел использует %s, и %s процента все еще свободны.",
		" Также был выделен отдельный раздел для каталога opt" ..
				" где используется %s, что составляет примерно %s процентов от общего числа,",
		" и для медиа-подкаталога mnt, где используется %s, что составляет %s процентов.",
	}

	-- disk usage meter function
	diskset.blocks[1].action = function()
		local data = {}
		for _, arg in ipairs(disks_points) do
			data[#data + 1] = system.fs_info(arg)
		end

		local values = {
			{
				form_value(data[1][2], colset.light, {}, diskset.unit),
				data[1][1] > 50 and "только " or "",
				form_value(100 - data[1][1], colset.diskpf)
			},
			{ form_value(data[2][2], colset.light, {}, diskset.unit), form_value(100 - data[2][1], colset.diskpf) },
			{ form_value(data[3][2], colset.light, {}, diskset.unit), form_value(data[3][1], colset.diskp ) },
			{ form_value(data[4][2], colset.light, {}, diskset.unit), form_value(data[4][1], colset.diskp ) },
		}

		return form_text(disk_sentences, values)
	end

	-- Sensors parser setup
	--------------------------------------------------------------------------------`
	local sensors_base_timeout = 10

	system.lmsensors.delay = 2
	system.lmsensors.patterns = {
		cpu = { match = "CPU:%s+%+(%d+)%.%d°[CF]" },
	}

	-- start auto async lmsensors check
	system.lmsensors:soft_start(sensors_base_timeout)

	-- Temperature indicator
	--------------------------------------------------------------------------------
	local hardwareset = { blocks = { {}, {}, {}, {} }, height = 200 }
	hardwareset.unit = { { "KBps", -1 }, { "MBps", 2048 } }

	-- temperature cpu
	hardwareset.blocks[1].timeout = sensors_base_timeout
	hardwareset.blocks[1].action = function()
		local data = system.lmsensors.get("cpu")
		local value = form_value(data[1], colset.tcpu, {})
		return string.format("	По показаниям датчика, температура процессора состовляет %s градусов Цельсия,", value)
	end

	-- temperature hdd
	local ssd_smart_check = system.simple_async("smartctl --attributes /dev/sda", "194.+%s(%d+)%s%(.+%)\r?\n")
	local hdd_smart_check = system.simple_async("smartctl --attributes /dev/sdb", "194.+%s(%d+)%s%(.+%)\r?\n")

	hardwareset.blocks[2].async = hdd_smart_check
	hardwareset.blocks[2].action = function(data)
		local value = form_value(data[1], colset.thdd, {})
		return string.format(" а жесткого диска %s градусов.", value)
	end

	-- temperature nvidia
	hardwareset.blocks[3].async = system.thermal.nvoptimus
	hardwareset.blocks[3].action = function(data)
		local value = data.off and "в настоящее время отключена" or
		              string.format("имеет температуру %s градусов", form_value(data[1], colset.tgpu, {}))

		return string.format(" Дискретная видеокарта %s.", value)
	end

	-- disks i/o speed
	local speed_storage = { {}, {} }
	local speed_sentences = {
		" Похоже что системный, твердотельный, диск, %s%s.",
		" В свою очередь жесткий диск носителя %s%s.",
	}

	local rs_txt = recolor("скорость чтения ", style.color.icon)
	local ws_txt = recolor(" скорость записи ", style.color.icon)

	local no_act_txt = { "в последнее время, не проявляет признаков, даже минимальной, активности", "не проявляет признаков активности" }

	hardwareset.blocks[4].action = function()
		local data = {}
		data[1] = system.disk_speed("sda", speed_storage[1])
		data[2] = system.disk_speed("sdb", speed_storage[2])

		local values = {}
		for i, set in ipairs({colset.sspeed, colset.hspeed}) do
			if data[i][1] > 1 or data[i][2] > 1 then
				values[i] = {
					rs_txt .. form_value(data[i][1], set, {}, hardwareset.unit) .. " и",
					ws_txt .. form_value(data[i][2], colset.sspeed, {}, hardwareset.unit)
				}
			else
				values[i] = { no_act_txt[i], (i == 2 and values[1][2] == "") and " или" or "" }
			end
		end

		return form_text(speed_sentences, values)
	end

	-- Transmission info
	--------------------------------------------------------------------------------
	local torrset = { blocks = { { timeout = 10 } }, height = 120 }
	torrset.nactive = 5

	local torrent_sentences = {
		"In conclusion, it should be mentioned that torrent client %s",
		" with %s active items at total.",
		" %s %s of them %s downloading now%s",
		" and %s %s seeding%s.",
		" Current downdload progress:%s",
	}

	local form_torr_speed = function(d)
		return " at speed of " .. form_value(tonumber(d), colset.tspeed, {}, { { "KBps", -1 } })
	end

	local tr_not_found = "does not running and information about your downloads is not available."

	torrset.blocks[1].async = function(setup) system.transmission.info(setup, {}) end
	torrset.blocks[1].action = function(data)
		local values = {}
		values[1] = { data.alert and tr_not_found or "running" }

		if not data.alert then
			values[2] = { form_value(#data.bars) }
			values[3] = { (data.lines[1][2] > 0 or data.lines[2][2] > 0) and "Moreover" or "Unfortunately",
						  form_value(data.lines[2][2]), data.lines[2][2] > 1 and "are" or "is",
						  data.lines[2][2] > 0 and form_torr_speed(data.lines[2][1]) or "" }
			values[4] = { form_value(data.lines[1][2]), data.lines[1][2] > 1 and "are" or "is",
						  data.lines[1][2] > 0 and form_torr_speed(data.lines[1][1]) or "" }

			local tlist = {}
			for i, t in ipairs(data.bars) do
				if tonumber(t.value) < 100 then
					if i <= torrset.nactive then tlist[#tlist + 1] = string.format(" %s%%", t.value) end
				end
			end
			if #tlist > 0 then values[5] = { recolor(table.concat(tlist), style.color.main) } end
		end

		return form_text(torrent_sentences, values)
	end

	-- Initialize all desktop widgets
	--------------------------------------------------------------------------------
	for _, field in ipairs({ cpuset, diskset, hardwareset, torrset }) do
		field.box = redflat.desktop.textset(field.blocks)
		field.box:set_forced_height(field.height)
		main_layout:add(field.box)
	end

	if not autohide then
		local desktopbox = wibox({ type = "desktop", visible = true, bg = style.color.wibox })
		desktopbox:geometry(geometry)
		desktopbox:set_widget(main_layout)
		if args.buttons then main_layout:buttons(args.buttons) end
	else
		local object = { geometry = geometry, body = { area = main_layout} }
		redflat.util.desktop.build.dynamic({ object }, nil, beautiful.desktopbg, args.buttons)
	end
end

-- End
-----------------------------------------------------------------------------------------------------------------------
return desktop
