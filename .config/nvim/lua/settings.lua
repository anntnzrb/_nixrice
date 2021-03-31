-- settings.lua --- general nvim settings

-- ----------------------------------------------------------------------------
-- indenting
-- ----------------------------------------------------------------------------

local NUM_SPACES_TABS = 4

vim.bo.autoindent  = true
vim.bo.cindent     = true -- C-like indenting
vim.bo.expandtab   = true
vim.bo.smartindent = true
vim.o.smarttab    = true
vim.bo.shiftwidth  = NUM_SPACES_TABS
vim.bo.softtabstop = NUM_SPACES_TABS
vim.bo.tabstop     = NUM_SPACES_TABS

-- ----------------------------------------------------------------------------
-- visual settings
-- ----------------------------------------------------------------------------

local MAX_LINE_CHARS = 80

vim.o.termguicolors   = true
vim.wo.number         = true
vim.wo.relativenumber = true
vim.wo.cursorline     = true
vim.o.showmatch       = true
vim.wo.colorcolumn    = tostring(MAX_LINE_CHARS)
vim.bo.textwidth      = MAX_LINE_CHARS
vim.wo.list           = true
vim.wo.listchars      = 'trail:-,tab:<->,nbsp:%'

-- ----------------------------------------------------------------------------
-- find & replace
-- ----------------------------------------------------------------------------

vim.o.hlsearch   = true -- highlight all search results
vim.o.ignorecase = true -- always case-insensitive
vim.o.smartcase  = true
vim.o.infercase  = true

-- ----------------------------------------------------------------------------
-- miscellaneous
-- ----------------------------------------------------------------------------

vim.o.scrolljump = -20                -- lines to scroll when cursor gets off screen
vim.o.clipboard  = 'unnamedplus'      -- clipboard integration for all operations
vim.o.mouse      = 'a'                -- enable normie mouse
vim.o.autochdir  = true               -- automatically cd to opened file's directory
vim.o.path       = vim.o.path .. '**' -- extend the path
vim.o.visualbell = true               -- visual bell over beeping
vim.bo.swapfile  = false              -- disable swap file for Vim files
