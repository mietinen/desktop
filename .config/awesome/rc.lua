-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Enable hotkeys help widget
local hotkeys_popup = require("awful.hotkeys_popup")
-- require("awful.hotkeys_popup.keys"
-- Notification library
local naughty = require("naughty")
naughty.config.defaults['icon_size'] = 100
-- Widgets
local yr_widget = require("widgets.yr")
local iface_widget = require("widgets.iface")
local mem_widget = require("widgets.mem")
local cpu_widget = require("widgets.cpu")
local volume_widget = require("widgets.volume")
local battery_widget = require("widgets.battery")
local clock_widget = require("widgets.clock")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors })
end
-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
        title = "Oops, an error happened!",
        text = tostring(err) })
        in_error = false
    end)
end
-- }}}
-- {{{ Layout change notification
local layout_notification_var
local layout_notification = function()
    naughty.destroy(layout_notification_var)
    layout_notification_var = naughty.notify {
        title = "Layout",
        text = awful.layout.getname(),
        timeout = 5,
    }
end
-- }}}
-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
local xrdb                      = require("beautiful.xresources").get_current_theme()
beautiful.font                  = "Monospace 9"
beautiful.useless_gap           = 4
beautiful.border_width          = 2

beautiful.border_normal         = xrdb.color0
beautiful.border_focus          = xrdb.color4
beautiful.border_marked         = xrdb.color1

beautiful.bg_normal             = xrdb.background
beautiful.bg_focus              = xrdb.color4
beautiful.bg_urgent             = xrdb.color1
beautiful.bg_minimize           = xrdb.background
beautiful.bg_systray            = xrdb.background

beautiful.fg_normal             = xrdb.foreground
beautiful.fg_focus              = xrdb.color0
beautiful.fg_urgent             = xrdb.color7
beautiful.fg_minimize           = xrdb.foreground

beautiful.taglist_bg_empty      = xrdb.color0
beautiful.taglist_bg_occupied   = xrdb.color8
beautiful.taglist_spacing       = 2

beautiful.tasklist_fg_normal    = xrdb.foreground
beautiful.tasklist_bg_normal    = xrdb.background
beautiful.tasklist_fg_focus     = xrdb.foreground
beautiful.tasklist_bg_focus     = xrdb.background

beautiful.notification_shape    = gears.shape.rounded_rect

beautiful.systray_icon_spacing  = 3
beautiful.hotkeys_modifiers_fg  = xrdb.color2

-- This is used later as the default terminal and editor to run.
terminal        = os.getenv("TERMINAL") or "sensible-terminal"
editor          = os.getenv("EDITOR") or "sensible-editor"
browser         = os.getenv("BROWSER") or "firefox"
editor_cmd      = terminal .. " -e " .. editor

-- Default modkey.
modkey          = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile.right,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.corner.nw,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.floating,
}
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({ }, 3, function() awful.menu.client_list({ theme = { width = 500 } }) end)
)

awful.screen.connect_for_each_screen(function(s)
    -- Tag names and layouts
    local l = awful.layout.layouts  -- Just to save some typing: use an alias.
    --                term   web    chat   media  file   virt   game   float  rand
    local names =   { "1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7 ", "8 ", "9 " }
    local layouts = { l[1],  l[1],  l[1],  l[1],  l[1],  l[1],  l[5],  l[5],  l[1]  }

    -- Each screen has its own tag table.
    if (s.index == 1) then
        -- awful.tag({ "1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7 ", "8 ", "9 " } , s, awful.layout.layouts[1])
        awful.tag(names, s, layouts)
    else
        root.tags()[s.index].screen = s
        root.tags()[s.index]:view_only()
    end

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    }
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.focused,
            buttons = tasklist_buttons,
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            spacing = 15,
            spacing_widget = wibox.widget.separator,
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            wibox.widget.textbox(""),
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            spacing = 15,
            spacing_widget = wibox.widget.separator,
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.textbox(""),

            yr_widget(),
            iface_widget(),
            mem_widget(),
            cpu_widget(),
            volume_widget(),
            battery_widget(),
            clock_widget(),
            wibox.widget.systray(),
        },
    }
end)
-- Focus primary screen
awful.screen.focus(1)

-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- XF86 binds
    awful.key({ }, "XF86AudioRaiseVolume",
        function () awful.spawn("volumectl up") end,
        {description = "Volume increase", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86AudioLowerVolume",
        function () awful.spawn("volumectl down") end,
        {description = "Volume decrease", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86AudioMute",
        function () awful.spawn("volumectl toggle") end,
        {description = "Volume mute toggle", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86AudioMicMute",
        function () awful.spawn("volumectl togglemic") end,
        {description = "Microphone mute toggle", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86MonBrightnessDown",
        function () awful.spawn("xbacklight -dec 10") end,
        {description = "Backlight decrease", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86MonBrightnessUp",
        function () awful.spawn("xbacklight -inc 10") end,
        {description = "Backlight increase", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86Display",
        function () awful.spawn("arandr") end,
        {description = "Launch ARandR", group = "XF86 keys"}
    ),

    awful.key({ }, "XF86Tools",
        function () awful.spawn("rofieditconfig") end,
        {description = "Config editor", group = "XF86 keys"}
    ),

    awful.key({ }, "Print",
        function () awful.spawn("scrot -e 'scrotmv $f'") end,
        {description = "Screenshot", group = "XF86 keys"}
    ),

    awful.key({ "Shift" }, "Print",
        function () awful.spawn("scrot -sfe 'scrotmv $f'") end,
        {description = "Screenshot selected area", group = "XF86 keys"}
    ),

    awful.key({ "Mod1" }, "Print",
        function () awful.spawn("scrot -ue 'scrotmv $f'") end,
        {description = "Screenshot focused window", group = "XF86 keys"}
    ),

    awful.key({ modkey }, "s",
        hotkeys_popup.show_help,
        {description="show help", group="awesome"}
    ),

    awful.key({ modkey }, "Escape",
        awful.tag.history.restore,
        {description = "go back", group = "tag"}
    ),

    awful.key({ modkey }, "j",
        function () awful.client.focus.byidx( 1) end,
        {description = "focus next by index", group = "client"}
    ),

    awful.key({ modkey }, "k",
        function () awful.client.focus.byidx(-1) end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Rofi apps
    awful.key({ modkey }, "d",
        function () awful.spawn("rofirun -modi drun -show drun -show-icons") end,
        {description = "Rofi drun launcher", group = "Rofi apps"}
    ),

    awful.key({ modkey, "Shift" }, "d",
        function () awful.spawn("rofirun -show run") end,
        {description = "Rofi run launcher", group = "Rofi apps"}
    ),

    awful.key({ modkey, "Shift" }, "w",
        function () awful.spawn("networkmanager_dmenu") end,
        {description = "Rofi NetworkManager", group = "Rofi apps"}
    ),

    awful.key({ modkey, "Shift" }, "t",
        function () awful.spawn("rofisetxrdb") end,
        {description = "Rofi Xresources themes", group = "Rofi apps"}
    ),

    awful.key({ modkey }, "x",
        function () awful.spawn("rofiunicode") end,
        {description = "Rofi unicode menu", group = "Rofi apps"}
    ),

    awful.key({ modkey }, "m",
        function () awful.spawn("rofiman") end,
        {description = "Rofi manpage launcher", group = "Rofi apps"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "j",
        function () awful.client.swap.byidx( 1) end,
        {description = "swap with next client by index", group = "client"}
    ),
    awful.key({ modkey, "Shift" }, "k",
        function () awful.client.swap.byidx( -1) end,
        {description = "swap with previous client by index", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "j",
        function ()
            local tag = awful.screen.focused().selected_tag
            local target_screen = gears.math.cycle(screen:count(), awful.screen.focused().index + 1)
            if tag then
                tag.screen = target_screen
                tag:view_only()
                awful.screen.focus(target_screen)
                local i = 1
                for t in pairs(root.tags()) do
                    if (root.tags()[t].screen.index == target_screen) then
                        screen[target_screen].tags[root.tags()[t].index].index = i
                        i = i + 1
                    end
                end
            end
        end,
        {description = "move tag to next screen", group = "screen"}
    ),
    awful.key({ modkey, "Control" }, "k",
        function ()
            local tag = awful.screen.focused().selected_tag
            local target_screen = gears.math.cycle(screen:count(), awful.screen.focused().index - 1)
            if tag then
                tag.screen = target_screen
                tag:view_only()
                awful.screen.focus(target_screen)
                local i = 1
                for t in pairs(root.tags()) do
                    if (root.tags()[t].screen.index == target_screen) then
                        screen[target_screen].tags[root.tags()[t].index].index = i
                        i = i + 1
                    end
                end
            end
        end,
        {description = "move tag to previous screen", group = "screen"}
    ),
    awful.key({ modkey }, "u",
        awful.client.urgent.jumpto,
        {description = "jump to urgent client", group = "client"}
    ),
    awful.key({ modkey }, "Tab",
        function () awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}
    ),

    -- Apps
    awful.key({ modkey }, "Return", function
        () awful.spawn(terminal) end,
        {description = "open a terminal", group = "Apps"}
    ),
    awful.key({ modkey }, "w",
        function () awful.spawn(browser) end,
        {description = "Launch web browser", group = "Apps"}
    ),
    awful.key({ modkey }, "e", function
        () awful.spawn("xdg-open " .. os.getenv("HOME")) end,
        {description = "open file browser", group = "Apps"}
    ),
    awful.key({ modkey }, "n", function
        () awful.spawn("nitrogen") end,
        {description = "open nitrogen (wallpaper)", group = "Apps"}
    ),
    awful.key({ modkey,  "Shift" }, "n", function
        () awful.spawn("nitrogen --restore") end,
        {description = "nitrogen --restore (wallpaper)", group = "awesome"}
    ),
    awful.key({ modkey }, "v", function
        () awful.spawn(editor_cmd .. " -c VimwikiIndex") end,
        {description = "open vimwiki", group = "Apps"}
    ),

    -- Standard program
    awful.key({ modkey, "Shift" }, "r",
        awesome.restart,
        {description = "restart awesome", group = "awesome"}
    ),
    awful.key({ modkey }, "Delete", function
        () awful.spawn("rofiexit") end,
        {description = "System exit menu", group = "awesome"}
    ),

    awful.key({ modkey }, "l",
        function () awful.tag.incmwfact( 0.05) end,
        {description = "increase master width factor", group = "layout"}
    ),
    awful.key({ modkey }, "h",
        function () awful.tag.incmwfact(-0.05) end,
        {description = "decrease master width factor", group = "layout"}
    ),
    awful.key({ modkey, "Shift" }, "h",
        function () awful.tag.incnmaster( 1, nil, true) end,
        {description = "increase the number of master clients", group = "layout"}
    ),
    awful.key({ modkey, "Shift" }, "l",
        function () awful.tag.incnmaster(-1, nil, true) end,
        {description = "decrease the number of master clients", group = "layout"}
    ),
    awful.key({ modkey, "Control" }, "h",
        function () awful.tag.incncol( 1, nil, true) end,
        {description = "increase the number of columns", group = "layout"}
    ),
    awful.key({ modkey, "Control" }, "l",
        function () awful.tag.incncol(-1, nil, true) end,
        {description = "decrease the number of columns", group = "layout"}
    ),
    awful.key({ modkey }, "space",
        function () awful.layout.inc(1) layout_notification() end,
        {description = "select next layout", group = "layout"}
    ),
    awful.key({ modkey, "Shift" }, "space",
        function () awful.layout.inc(-1) layout_notification() end,
        {description = "select previous layout", group = "layout"}
    ),

    awful.key({ modkey, "Control" }, "n",
        function () local c = awful.client.restore()
            if c then
                c:emit_signal(
                "request::activate", "key.unminimize", {raise = true}
                )
            end
        end,
        {description = "restore minimized", group = "client"}
    )
)
-- Window key bindings
clientkeys = gears.table.join(
    awful.key({ modkey }, "f",
        function (c)
            c.maximized = false
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),
    awful.key({ modkey }, "q",
        function (c) c:kill() end,
        {description = "close", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "space",
        awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "Return",
        function (c) c:swap(awful.client.getmaster()) end,
        {description = "move to master", group = "client"}
    ),
    awful.key({ modkey }, "t",
        function (c) c.ontop = not c.ontop end,
        {description = "toggle keep on top", group = "client"}
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9,
    function ()
        local tag = root.tags()[i]
        local screen = tag.screen
        if tag then
            tag:view_only()
            awful.screen.focus(screen)
        end
    end,
    {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
    awful.key({ modkey, "Control" }, "#" .. i + 9,
    function ()
        local tag = root.tags()[i]
        if tag then
            awful.tag.viewtoggle(tag)
        end
    end,
    {description = "toggle tag #" .. i, group = "tag"}),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
    function ()
        if client.focus then
            local tag = root.tags()[i]
            if tag then
                client.focus:move_to_tag(tag)
            end
        end
    end,
    {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
    function ()
        if client.focus then
            local tag = root.tags()[i]
            if tag then
                client.focus:toggle_tag(tag)
            end
        end
    end,
    {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
            titlebars_enabled = false
        }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
            "DTA",  -- Firefox addon DownThemAll.
            "copyq",  -- Includes session name in class.
            "pinentry",
        },
        class = {
            "Arandr",
            "Qalculate-gtk",
            "Blueman-manager",
            "Gpick",
            "Kruler",
            "MessageWin",  -- kalarm.
            "Sxiv",
            "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
            "Wpa_gui",
            "veromix",
            "xtightvncviewer"},
            name = {
                "Event Tester",  -- xev.
                "glxgears",
            },
            role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
            }
        },
        properties = { floating = true, ontop = true }
    },

    -- force ontop for floating windows
    { rule = { floating = true },
    properties = { ontop = true } },

    -- Specific tags
    { rule_any = { class = { "discord", "[Ss]ignal", "[Ee]lement" } },
    properties = { screen = root.tags()[3].screen, tag = root.tags()[3].name } },
    { rule_any = { class = { "[Ss]potify", "plexmediaplayer", "[Ll][Bb][Rr][Yy]", "mpv", ".*%.Celluloid", "[Gg]imp%-.*" } },
    properties = { screen = root.tags()[4].screen, tag = root.tags()[4].name } },
    { rule_any = { class = { "Pcmanfm", "Thunar", "Doublecmd" } },
    properties = { screen = root.tags()[5].screen, tag = root.tags()[5].name } },
    { rule_any = { class = { "[Vv]irt%-manager", "[Vv]irt%-viewer", "[Vv]irtual[Bb]ox" } },
    properties = { screen = root.tags()[6].screen, tag = root.tags()[6].name } },
    { rule_any = { class = { "[Ss]team", "[Ll]utris" } },
    properties = { screen = root.tags()[7].screen, tag = root.tags()[7].name } },
    { rule_any = { class = { "steam_app_.*" } },
    properties = { screen = root.tags()[7].screen, tag = root.tags()[7].name, border_width = 0 } },
}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
    -- {{{ Spotify  rule fix
    if c.class == nil then
        c:connect_signal("property::class", function () awful.rules.apply(c) end)
    end
    -- }}}
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim: set ts=4 sw=4 tw=0 et :
