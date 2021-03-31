-- utils.lua --- utilities to be used globally across nvim configuration files

-- lesser verbosity
_G.exec = vim.api.nvim_command
_G.fn = vim.fn
_G.set_keymap = vim.api.nvim_set_keymap
_G.cmd = vim.cmd
