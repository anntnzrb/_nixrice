-- init.lua -- nvim initialization file (written in Lua)

require('utils')       -- utility set
require('settings')    -- general settings
require('colors')      -- theming/appearance-related settings
require('keymappings')
require('plugins')

-- Plugin configurations
require('plug-cfgs/galaxyline')
require('plug-cfgs/gitsigns')
require('plug-cfgs/kommentary')
require('plug-cfgs/nvim-autopairs')
require('plug-cfgs/nvim-bufferline')
require('plug-cfgs/nvim-colorizer')
require('plug-cfgs/nvim-compe')
require('plug-cfgs/nvim-tree')

-- LSP configurations
require('lsp')
require('lspsaga')
require('lsp/c-ls')
require('lsp/python-ls')
