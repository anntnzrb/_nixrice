#                    ██           ██
#   ████            ░██          ░██
#  ██░░██  ██   ██ ██████  █████ ░██      ██████  ██████  ███     ██  ██████  █████  ██████
# ░██ ░██ ░██  ░██░░░██░  ██░░░██░██████ ░░██░░█ ██░░░░██░░██  █ ░██ ██░░░░  ██░░░██░░██░░█
# ░░█████ ░██  ░██  ░██  ░███████░██░░░██ ░██ ░ ░██   ░██ ░██ ███░██░░█████ ░███████ ░██ ░
#  ░░░░██ ░██  ░██  ░██  ░██░░░░ ░██  ░██ ░██   ░██   ░██ ░████░████ ░░░░░██░██░░░░  ░██
#     ░███░░██████  ░░██ ░░██████░██████ ░███   ░░██████  ███░ ░░░██ ██████ ░░██████░███
#     ░░░  ░░░░░░    ░░   ░░░░░░ ░░░░░   ░░░     ░░░░░░  ░░░    ░░░ ░░░░░░   ░░░░░░ ░░░

# *****************************************************************************
# general settings
# *****************************************************************************
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
# normally locked at 9 letters, you can't use any keys at hint mode anyways, so
# why not enable them all
c.hints.chars = "abcdefghijklmnopqrstuvwxyz"

# hints are uppercased (it's just easier to differentiate)
c.hints.uppercase = True

# *****************************************************************************
# tabs
# *****************************************************************************
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

# *****************************************************************************
# privacy
# *****************************************************************************
# allow geo-location
c.content.geolocation = "ask"

# cookie restriction
c.content.cookies.accept = "no-3rdparty"

# allow websites to lock your mouse pointer?
# i don't know what kind of setting this is
c.content.mouse_lock = "ask"

# allow desktop content sharing
c.content.desktop_capture = "ask"

# *****************************************************************************
# completion box
# *****************************************************************************
# completion box height
c.completion.height = 350

# completion delay (instantaneous pretty much anyway)
c.completion.delay = 50

# shrink completion box when narrowing results
c.completion.shrink = True

# date format
c.completion.timestamp_format = "%d-%m-%Y"

# *****************************************************************************
# sessions
# *****************************************************************************
# auto-save interval
c.auto_save.interval = 60000

# re-open browser on last session (keep last session)
c.auto_save.session = True

# *****************************************************************************
# downloads
# *****************************************************************************
# default download directory
c.downloads.location.directory = "$HOME/downloads"
# progress bar download position
c.downloads.position = "bottom"
# remove finished downloads after...
c.downloads.remove_finished = 5000

# search engines
c.url.searchengines = {
    "DEFAULT": "https://www.duckduckgo.com/?q={}",
    "aw": "https://wiki.archlinux.org/index.php?search={}",
    "aur": "https://aur.archlinux.org/packages/?O=0&K={}",
    "pacman": "https://www.archlinux.org/packages/?q={}",
    "lby": "https://lbry.tv/$/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "redd": "https://reddit.com/r/{}",
    "wiki": "https://www.wikipedia.org/wiki/{}",
}
