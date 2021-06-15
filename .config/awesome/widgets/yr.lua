-- yr.no widget

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")

local widget = {}
local popup = {}
local function worker(args)

    local args = args or {}
    local path_to_icons = args.path_to_icons or "/usr/share/icons/Papirus-Dark"
    path_to_icons = path_to_icons .. "/symbolic/status/"
    local timeout = args.timeout or 300
    local margin = args.margin or 3
    local location = args.location or os.getenv("LOCATION") or "Oslo"

    local lpattern = string.gsub(location, "%a", function (c)
        return string.format("[%s%s]", string.lower(c),
        string.upper(c))
    end)

    local yrdata = {}
    local xmlfile = gfs.get_cache_dir() .. "/yr.no.xml"

    local push = function(x) return x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x end
    local icon = {}
    icon[1] = push('weather-clear-symbolic.svg')

    icon[2],icon[3] = push('weather-few-clouds-symbolic.svg')

    icon[4] = push('weather-overcast-symbolic.svg')

    icon[5],icon[6],icon[7],icon[20],icon[24],icon[25],icon[26],icon[27],
    icon[30],icon[31],icon[40],icon[41],icon[42],icon[43] = push('weather-showers-scattered-symbolic.svg')

    icon[9],icon[10],icon[11],icon[12],icon[22],icon[23],icon[32],
    icon[46],icon[47],icon[48] = push('weather-showers-symbolic.svg')

    icon[8],icon[13],icon[14],icon[21],icon[28],icon[29],icon[33],icon[34],
    icon[44],icon[45],icon[49],icon[50] = push('weather-snow-symbolic.svg')

    icon[15] = push('weather-fog-symbolic.svg')

    widget = wibox.widget {
        {
            {
                id = "icon",
                image = path_to_icons .. icon[4],
                resize = true,
                widget = wibox.widget.imagebox,
            },
            top = margin,
            bottom = margin,
            right = margin,
            widget = wibox.container.margin
        },
        {
            id = "text",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
    }

    popup = awful.popup {
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        margins = 10,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        type = "dock",
        widget = {}
    }

    local update_xml = function()
        spawn.easy_async("curl -s https://www.yr.no/soek/soek.aspx?sted=" .. location,
        function(stdout, stderr, exitreason, exitcode)
            local url = string.match(stdout, 'href="(%C*/'..lpattern..'/%C-)"') or nil
            if url == nil then return end
            spawn.easy_async("curl -s https://www.yr.no/" .. url .. "/forecast.xml",
            function(stdout, stderr, exitreason, exitcode)
                local f = assert(io.open(xmlfile, "w"))
                f:write(string.gsub(stdout, "\r\n", "\n"))
                f:close()

            end)
        end)
    end

    local update_widget = function()
        if not gfs.file_readable(xmlfile) then
            widget:get_children_by_id('text')[1].markup = " no data"
            update_xml()
            return
        end

        local f = assert(io.open(xmlfile, "r"))
        local xml = f:read("*all")
        f:close()

        local match_pattern = string.match(xml, '<weatherdata%W?%C*>.-<location%W?%C*>.-<name%W?%C*>%C*('..lpattern..')%C*</name>.*</location>.*</weatherdata>')
        if match_pattern == nil then
            widget:get_children_by_id('text')[1].markup = " data error"
            update_xml()
            return
        end

        local rows = {
            { widget = wibox.widget.textbox },
            layout = wibox.layout.fixed.vertical,
        }

        local nextupdate = string.match(xml, '<weatherdata%W?%C*>.-<meta%W?%C*>.-<nextupdate%W?%C*>(%C*)</nextupdate>.*</meta>.*</weatherdata>')
        local year, month, day, hour, min, sec = string.match(nextupdate, "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)")
        local nextupdate_unix = os.time{year = year, month = month, day = day, hour = hour, min = min, sec = sec}
        local timediff = os.time(os.date("!*t")) - nextupdate_unix

        local tabular = string.match(xml, '<weatherdata%W?%C*>.-<forecast%W?%C*>.-<tabular%W?%C*>(.-)</tabular>.*</forecast>.*</weatherdata>') or ""
        local i = 1
        for wdata in string.gmatch(tabular, '(<time%W?%C*>.-</time>)') do
            if yrdata[i] == nil then yrdata[i] = {} end
            local year, month, day, hour, min, sec = string.match(wdata, '<time%C*from="(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)"')
            yrdata[i].time = os.time{year = year, month = month, day = day, hour = hour, min = min, sec = sec}
            local symbolnumber = string.match(wdata, '<symbol%C*number="(.-)"')
            local precipitation = string.match(wdata, '<precipitation%C*value="(.-)"')
            local winddirection = string.match(wdata, '<windDirection%C*deg="(.-)"')
            local windspeed = string.match(wdata, '<windSpeed%C*mps="(.-)"')
            local temperature = string.match(wdata, '<temperature%C*value="(.-)"')
            local pressure = string.match(wdata, '<pressure%C*value="(.-)"')
            if symbolnumber == nil or precipitation == nil or winddirection == nil
                or windspeed == nil or temperature == nil or pressure == nil then
                widget:get_children_by_id('text')[1].markup = " data error"
                update_xml()
                break
            end
            local windarrow, precipitationtext
            if tonumber(winddirection) <= 22 then windarrow = "↓"
            elseif tonumber(winddirection) <= 67 then windarrow = "↙"
            elseif tonumber(winddirection) <= 112 then windarrow = "←"
            elseif tonumber(winddirection) <= 157 then windarrow = "↖"
            elseif tonumber(winddirection) <= 202 then windarrow = "↑"
            elseif tonumber(winddirection) <= 247 then windarrow = "↗"
            elseif tonumber(winddirection) <= 292 then windarrow = "→"
            elseif tonumber(winddirection) <= 337 then windarrow = "↘"
            else windarrow = "↓" end
            if tonumber(precipitation) > 0 then precipitationtext = ", (" .. precipitation .. "mm)"
            else precipitationtext = "" end
            yrdata[i].image = path_to_icons .. icon[tonumber(symbolnumber)]
            yrdata[i].markup = temperature .. "°C" .. precipitationtext .. ", " .. windarrow .. windspeed .. "m/s"
            if i == 1 then
                widget:get_children_by_id('icon')[1].image = yrdata[i].image
                widget:get_children_by_id('text')[1].markup = yrdata[i].markup
            end
            local row = wibox.widget {
                {
                    {
                        markup = os.date("%a, %H:%M", yrdata[i].time),
                        widget = wibox.widget.textbox,
                    },
                    left = 15,
                    right = 10,
                    widget = wibox.container.margin
                },
                {
                    {
                        image = yrdata[i].image,
                        resize = true,
                        -- forced_height = 15,
                        widget = wibox.widget.imagebox,
                    },
                    margins = margin,
                    widget = wibox.container.margin
                },
                {
                    {
                        markup = yrdata[i].markup,
                        widget = wibox.widget.textbox,
                    },
                    right = 15,
                    widget = wibox.container.margin
                },
                forced_height = 20,
                layout = wibox.layout.fixed.horizontal,
            }
            table.insert(rows, row)

            i = i + 1
        end
        if timediff > 1 then update_xml() end
        popup:setup(rows)
    end
    timer = gears.timer {
        timeout = timeout,
        call_now  = true,
        autostart = true,
        callback  = function() update_widget() end
    }

    widget:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            if popup.visible then
                popup.visible = not popup.visible
            else
                popup:move_next_to(mouse.current_widget_geometry)
            end
        end
    end)

    return widget
end

return setmetatable(widget, { __call = function(_, ...) return worker(...) end })

-- vim: set ts=4 sw=4 tw=0 et :
