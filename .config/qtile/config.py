from typing import List  # noqa: F401

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Screen
from libqtile.lazy import lazy

# Var definitions
KEY_SUPER = "mod4"
KEY_SHIFT = "shift"
KEY_CTRL = "control"

# Keys
keys = [
    # Switch between windows in current stack pane
    Key([KEY_SUPER], "h", lazy.layout.left()),
    Key([KEY_SUPER], "l", lazy.layout.right()),
    Key([KEY_SUPER], "j", lazy.layout.down()),
    Key([KEY_SUPER], "k", lazy.layout.up()),
    Key([KEY_SUPER, KEY_SHIFT], "h", lazy.layout.swap_left()),
    Key([KEY_SUPER, KEY_SHIFT], "l", lazy.layout.swap_right()),
    Key([KEY_SUPER, KEY_SHIFT], "j", lazy.layout.shuffle_down()),
    Key([KEY_SUPER, KEY_SHIFT], "k", lazy.layout.shuffle_up()),
    # Toggle between different layouts as defined below
    Key([KEY_SUPER, KEY_SHIFT], "o", lazy.next_layout()),
    Key([KEY_SUPER, KEY_SHIFT], "q", lazy.window.kill()),
    Key([KEY_SUPER, KEY_SHIFT], "r", lazy.restart()),
    Key([KEY_SUPER, KEY_CTRL], "q", lazy.shutdown()),
    Key([KEY_SUPER], "r", lazy.spawncmd()),
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # Switch to X group
            Key(
                [KEY_SUPER],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # Send window to X group
            Key(
                [KEY_SUPER, KEY_SHIFT],
                i.name,
                lazy.window.togroup(i.name),
                desc="move focused window to group {}".format(i.name),
            ),
        ]
    )


# ------------------------------------------------------------------------------
# Layouts
# ------------------------------------------------------------------------------

# All layouts can be found [[http://docs.qtile.org/en/latest/manual/ref/layouts.html?highlight=bsp#built-in-layouts][Built-in Layouts]]

layouts = [
    layout.MonadTall(),
    layout.MonadWide(),
    layout.Matrix(),
    layout.TreeTab(),
    layout.Floating(),
]

widget_defaults = dict(
    font="VictorMono",
    fontsize=16,
    padding=3,
)

extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayoutIcon(),
                widget.Sep(),
                widget.GroupBox(),
                widget.Sep(),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(),
                widget.BatteryIcon(),
                widget.Battery(format="{percent:2.0%}"),
                widget.Sep(),
                widget.Clock(format="%a, %d %b @ %H:%M"),
                widget.Sep(),
            ],
            24,
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag(
        [KEY_SUPER],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [KEY_SUPER],
        "Button3",
        lazy.window.set_size_floating(),
        start=lazy.window.get_size(),
    ),
    Click([KEY_SUPER], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None  # WARNING: this is deprecated and will be removed soon
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        {"wmclass": "confirm"},
        {"wmclass": "dialog"},
        {"wmclass": "download"},
        {"wmclass": "error"},
        {"wmclass": "file_progress"},
        {"wmclass": "notification"},
        {"wmclass": "splash"},
        {"wmclass": "toolbar"},
        {"wmclass": "confirmreset"},  # gitk
        {"wmclass": "makebranch"},  # gitk
        {"wmclass": "maketag"},  # gitk
        {"wname": "branchdialog"},  # gitk
        {"wname": "pinentry"},  # GPG key password entry
        {"wmclass": "ssh-askpass"},  # ssh-askpass
    ]
)

# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------

# Controls whether or not focus follows the mouse around as it moves across
# windows
follow_mouse_focus = True

# If true, the cursor follows the focus as directed by the keyboard, warping to
# the center of the focused window
cursor_warp = True

# If a window requests to be fullscreen, it is automatically fullscreened
auto_fullscreen = True

# Behavior of the _NET_ACTIVATE_WINDOW message sent by applications
focus_on_window_activation = "smart"

# Some thing needed to be set in order to make Java apps work as intended
wmname = "LG3D"
