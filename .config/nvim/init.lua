-- init.lua -- nvim initialization file (written in Lua)

require('settings') -- general settings
require('colors')   -- theming/appearance-related settings
require('plugins')

-- Plugin configurations
require('plug-cfgs/nvim-compe')

-- LSP configurations
require('lsp/c-ls')
require('lsp/python-ls')
