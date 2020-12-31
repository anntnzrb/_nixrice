#                    ██           ██
#   ████            ░██          ░██
#  ██░░██  ██   ██ ██████  █████ ░██      ██████  ██████  ███     ██  ██████  █████  ██████
# ░██ ░██ ░██  ░██░░░██░  ██░░░██░██████ ░░██░░█ ██░░░░██░░██  █ ░██ ██░░░░  ██░░░██░░██░░█
# ░░█████ ░██  ░██  ░██  ░███████░██░░░██ ░██ ░ ░██   ░██ ░██ ███░██░░█████ ░███████ ░██ ░
#  ░░░░██ ░██  ░██  ░██  ░██░░░░ ░██  ░██ ░██   ░██   ░██ ░████░████ ░░░░░██░██░░░░  ░██
#     ░███░░██████  ░░██ ░░██████░██████ ░███   ░░██████  ███░ ░░░██ ██████ ░░██████░███
#     ░░░  ░░░░░░    ░░   ░░░░░░ ░░░░░   ░░░     ░░░░░░  ░░░    ░░░ ░░░░░░   ░░░░░░ ░░░

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# general settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# encoding
c.editor.encoding = "utf8"

# messages timeout
c.messages.timeout = 1500

# start page
c.url.start_pages = "https://start.duckduckgo.com"

# disable autoplay
c.content.autoplay = False

# smooth scrolling
c.scrolling.smooth = True

# scrollbar visibility
c.scrolling.bar = "always"

# allow viewing PDFs
c.content.pdfjs = True

# enters insert when an insert-element is focused after load
c.input.insert_mode.auto_load = True

# backend (force chromium-based engine)
c.backend = "webengine"

# ignore normal mode keys for a few moments after sucessful auto-follow
c.hints.auto_follow_timeout = 750

# hint characters
# normally locked at 9 letters, you can't use any keys at hint mode anyways,
# use home-row keys

# enable this boolean var if using qwerty, disable to use all keys
kb_qwerty = True
qwerty_hint_chars = "asdfghjkl"
c.hints.chars = qwerty_hint_chars if kb_qwerty else "abcdefghijklmnopqrstuvwxyz"

# hints are uppercased (it's just easier to differentiate)
c.hints.uppercase = True

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# tabs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# window title format
c.tabs.title.format = "{private}{audio}{index}: {current_title}"
# tabs position
c.tabs.position = "bottom"

# last-tab behavior allows (ctrl+w) spam to close the browser
c.tabs.last_close = "close"

# open new tabs in background (middleclick/ctrl+click)
c.tabs.background = True

# prevents auto-entering insert-mode when a new page is loaded
c.input.insert_mode.auto_load = False

c.url.default_page = "https://www.voidlinux.org"

# spell checking
#  c.spellcheck.languages = ["en-US", "es-ES"]

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# privacy
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# allow geo-location
c.content.geolocation = "ask"

# cookie restriction
c.content.cookies.accept = "no-3rdparty"

# allow websites to record audio and video
c.content.media.audio_video_capture = "ask"

# allow websites to lock your mouse pointer?
# i don't know what kind of setting this is
c.content.mouse_lock = "ask"

# allow desktop content sharing
c.content.desktop_capture = "ask"

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# completion box
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# completion box height
c.completion.height = 350

# completion delay (instantaneous pretty much anyway)
c.completion.delay = 50

# shrink completion box when narrowing results
c.completion.shrink = True

# date format
c.completion.timestamp_format = "%d-%m-%Y"

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# sessions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# auto-save interval
c.auto_save.interval = 60000

# re-open browser on last session (keep last session)
c.auto_save.session = True

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# downloads
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# default download directory
c.downloads.location.directory = "$HOME/downloads"
# progress bar download position
c.downloads.position = "bottom"
# remove finished downloads after...
c.downloads.remove_finished = 5000

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# indexing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# search engines
c.url.searchengines = {
    "DEFAULT": "https://www.duckduckgo.com/?q={}",

    # search engines
    "bing": "https://www.bing.com/search?q={}",
    "google": "https://www.google.com/search?q={}",

    # programming
    "ghub": "https://github.com/{}",
    "glab": "https://gitlab.com/{}",

    # unix
    "manobsd": "http://man.openbsd.org/{}",
    "manvoid": "https://man.voidlinux.org/{}",
    "mangnu": "https://www.gnu.org/software/coreutils/{}",

    # linux
    "aw": "https://wiki.archlinux.org/index.php?search={}",
    "pacman": "https://www.archlinux.org/packages/?q={}",
    "aur": "https://aur.archlinux.org/packages/?K={}",

    # emacs
    "melpa": "https://melpa.org/?q={}",
    "wikimacs": "https://duckduckgo.com/?q={}+site%3Aemacswiki.org",

    # misc
    "yt": "https://www.youtube.com/results?search_query={}",
    "lbry": "https://lbry.tv/$/search?q={}",
    "redd": "https://reddit.com/r/{}",
    "wiki": "https://www.wikipedia.org/wiki/{}",

    # socials (last, because yes)
    "twitter": "https://nitter.net/{}",
}

""" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
# key-binds
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" """

# switch tabs with <C-n>, where n is number of the tab
config.bind('<Ctrl-1>', 'tab-focus 1')
config.bind('<Ctrl-2>', 'tab-focus 2')
config.bind('<Ctrl-3>', 'tab-focus 3')
config.bind('<Ctrl-4>', 'tab-focus 4')
config.bind('<Ctrl-5>', 'tab-focus 5')
config.bind('<Ctrl-6>', 'tab-focus 6')
config.bind('<Ctrl-7>', 'tab-focus 7')
config.bind('<Ctrl-8>', 'tab-focus 8')
config.bind('<Ctrl-9>', 'tab-focus 9')
config.bind('<Ctrl-0>', 'tab-focus 10')

# Zen mode
config.bind('xx', 'config-cycle statusbar.show always never ;;\
            config-cycle tabs.show always never')
