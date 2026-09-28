pcall(require, "luarocks.loader")

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
local menubar = require("menubar")
local naughty = require("naughty")

local csignal_connect = client.connect_signal

local awbutton = require("awful.button")
local awclient = require("awful.client")
local awkey = require("awful.key")
local awscreen = require("awful.screen")
local awtag = require("awful.tag")
local awwidget = require("awful.widget")

local wilayout = require("wibox.layout")
local wiwidget = require("wibox.widget")

local terminal = os.getenv("TERMINAL") or "alacritty" or "xterm"
local browser = os.getenv("BROWSER") or "firefox"
local keys = {
    super = "Mod4",
    meta = "Mod1",
}
local mbuttons = {
    left = 1,
    middle = 2,
    right = 3,
}

do
    if awesome.startup_errors then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "There were errors during startup",
            text = awesome.startup_errors,
        })
    end

    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "An error has happened",
            text = tostring(err),
        })
        in_error = false
    end)

    require("awful.autofocus")
end

do
    beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
    beautiful.font = "Iosevka Comfy Motion Semilight 14"
end

do
    awful.layout.layouts = {
        awful.layout.suit.tile.right,
        awful.layout.suit.floating,
    }
end

do
    menubar.utils.terminal = terminal

    local launcher_main = awwidget.launcher({
        image = beautiful.awesome_icon,
        menu = awful.menu({
            items = {
                {
                    "wm",
                    {
                        {
                            "hotkeys",
                            function()
                                hotkeys_popup.show_help(nil, awscreen.focused())
                            end,
                        },
                        { "manual", terminal .. " -e man awesome" },
                        { "api", browser .. " https://awesomewm.org/doc/api" },
                        { "restart", awesome.restart },
                        {
                            "quit",
                            function()
                                awesome.quit()
                            end,
                        },
                    },
                    beautiful.awesome_icon,
                },
                { "terminal", terminal },
            },
        }),
    })

    awscreen.connect_for_each_screen(function(s)
        awtag({ "𝛼", "ϐ", "ℽ", "𝛿", "ε", "ϝ", "ͷ", "ϛ", "𝜁" }, s, awful.layout.layouts[1])

        local layoutbox = awwidget.layoutbox(s)
        layoutbox:buttons(gears.table.join(
            awbutton({}, mbuttons.left, function()
                awful.layout.inc(1)
            end),
            awbutton({}, mbuttons.right, function()
                awful.layout.inc(-1)
            end)
        ))

        local taglist = awwidget.taglist({
            screen = s,
            filter = awwidget.taglist.filter.all,
            buttons = gears.table.join(
                awbutton({}, mbuttons.left, function(t)
                    t:view_only()
                end),

                awbutton({ keys.super }, mbuttons.middle, function(t)
                    if client.focus then
                        client.focus:move_to_tag(t)
                    end
                end),

                awbutton({}, mbuttons.right, awtag.viewtoggle),

                awbutton({ keys.super }, mbuttons.right, function(t)
                    if client.focus then
                        client.focus:toggle_tag(t)
                    end
                end)
            ),
        })

        local bar = awful.wibar({
            screen = s,
            position = "top",
            height = 24,
            border_width = 0,
        })
        bar:setup({
            layout = wilayout.align.horizontal,

            {
                layout = wilayout.fixed.horizontal,

                launcher_main,
                taglist,
                awwidget.prompt(),
            },
            {
                layout = wilayout.fixed.horizontal,
            },
            {
                layout = wilayout.fixed.horizontal,

                awwidget.keyboardlayout(),
                wiwidget.systray(),
                wiwidget.textclock("%a, %b %d @ %R"),
                layoutbox,
            },
        })
    end)
end

do
    local clientbuttons = gears.table.join(
        awbutton({}, mbuttons.left, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
        end),
        awbutton({ keys.super }, mbuttons.left, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.move(c)
        end),
        awbutton({ keys.super }, mbuttons.right, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    local globalkeys = gears.table.join(
        awkey({ keys.super, keys.meta }, "r", awesome.restart, {
            description = "reload awesome",
            group = "awesome",
        }),
        awkey({ keys.super, keys.meta }, "q", awesome.quit, {
            description = "quit awesome",
            group = "awesome",
        }),

        awkey({ keys.super }, "r", function()
            awscreen.focused().mypromptbox:run()
        end, {
            description = "run prompt",
            group = "launcher",
        }),

        awkey({ keys.super, "Shift" }, "d", function()
            menubar.show()
        end, {
            description = "show the menubar",
            group = "launcher",
        })
    )

    local clientkeys = gears.table.join(
        awkey({ keys.super }, "j", function()
            awclient.focus.byidx(1)
        end, {
            description = "focus next",
            group = "client",
        }),
        awkey({ keys.super }, "k", function()
            awclient.focus.byidx(-1)
        end, {
            description = "focus prev.",
            group = "client",
        }),
        awkey({ keys.super, "Shift" }, "j", function()
            awclient.swap.byidx(1)
        end, {
            description = "swap with next client",
            group = "client",
        }),
        awkey({ keys.super, "Shift" }, "k", function()
            awclient.swap.byidx(-1)
        end, {
            description = "swap with prev. client",
            group = "client",
        }),

        awkey({ keys.super }, "l", function()
            awtag.incmwfact(0.01)
        end, {
            description = "increase master width factor",
            group = "layout",
        }),
        awkey({ keys.super }, "h", function()
            awtag.incmwfact(-0.01)
        end, {
            description = "decrease master width factor",
            group = "layout",
        }),

        awkey({ keys.super, "Shift" }, "bracketleft", function()
            awscreen.focus_relative(1)
        end, {
            description = "focus next screen",
            group = "screen",
        }),
        awkey({ keys.super, "Shift" }, "bracketright", function()
            awscreen.focus_relative(-1)
        end, {
            description = "focus prev. screen",
            group = "screen",
        }),
        awkey({ keys.super, "Shift" }, "backslash", function(c)
            c:move_to_screen()
        end, {
            description = "move to screen",
            group = "client",
        }),

        awkey({ keys.super, "Shift" }, "q", function(c)
            c:kill()
        end, {
            description = "close",
            group = "client",
        }),
        awkey({ keys.super, "Shift" }, "f", function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end, {
            description = "toggle fullscreen",
            group = "client",
        }),
        awkey({ keys.super, "Control" }, "space", awful.client.floating.toggle, {
            description = "toggle floating",
            group = "client",
        })
    )

    for i = 1, 9 do
        globalkeys = gears.table.join(
            globalkeys,

            awkey({ keys.super }, "#" .. i + 9, function()
                local tag = awscreen.focused().tags[i]
                if tag then
                    tag:view_only()
                end
            end, {
                description = "focus tag #" .. i,
                group = "tag",
            }),

            awkey({ keys.super, "Control" }, "#" .. i + 9, function()
                local tag = awscreen.focused().tags[i]
                if tag then
                    awtag.viewtoggle(tag)
                end
            end, {
                description = "toggle tag #" .. i,
                group = "tag",
            }),

            awkey({ keys.super, "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end, {
                description = "move focused client to tag #" .. i,
                group = "tag",
            }),

            awkey({ keys.super, "Control", "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end, {
                description = "toggle focused client on tag #" .. i,
                group = "tag",
            })
        )
    end

    root.keys(globalkeys)

    awful.rules.rules = {
        {
            rule = {},
            properties = {
                border_width = beautiful.border_width,
                border_color = beautiful.border_normal,
                focus = awful.client.focus.filter,
                raise = true,
                keys = clientkeys,
                buttons = clientbuttons,
                screen = awscreen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            },
        },

        {
            rule_any = {
                class = {
                    "Pcmanfm",
                },
            },
            properties = { floating = true },
        },

        {
            rule_any = {
                class = {
                    "firefox",
                    "qutebrowser",
                },
            },
            properties = { tag = "1" },
        },

        {
            rule_any = { type = { "normal", "dialog" } },
            properties = { titlebars_enabled = true },
        },
    }
end

do
    csignal_connect("manage", function(c)
        if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_offscreen(c)
        end
    end)

    csignal_connect("mouse::enter", function(c)
        c:emit_signal("request::activate", "mouse_enter", { raise = false })
    end)

    csignal_connect("focus", function(c)
        c.border_color = beautiful.border_focus
    end)

    csignal_connect("unfocus", function(c)
        c.border_color = beautiful.border_normal
    end)
end
