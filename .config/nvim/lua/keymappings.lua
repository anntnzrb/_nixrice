-- keymappings.lua -- keyboard mapping configurations

-- leader key
set_keymap('n', '<Space>', '<NOP>', {noremap = true, silent = true})
vim.g.mapleader = ' '

-- toggle search highlighting
set_keymap('n', '<Leader>h', ':set hlsearch!<CR>',
    {noremap = true, silent = true})

-- window movement
set_keymap('n', '<C-h>', '<C-w>h', {})
set_keymap('n', '<C-j>', '<C-w>j', {})
set_keymap('n', '<C-k>', '<C-w>k', {})
set_keymap('n', '<C-l>', '<C-w>l', {})

-- ----------------------------------------------------------------------------
-- shortcuts
-- ----------------------------------------------------------------------------

-- disable the 'Ex-mode' keybind
set_keymap('n', 'Q', '<NOP>', {})

-- save file with Ctrl+S
set_keymap('n', '<C-s>', ':w<CR>', {silent = true})

-- redraw screen
set_keymap('n', '<F5>', ':redraw!<CR>', {silent = true})

-- write file as sudo
set_keymap('c', 'w!!', 'w !sudo tee % >/dev/null', {})

-- (un-)tabing
set_keymap('v', '<', '<gv', {noremap = true})
set_keymap('v', '>', '>gv', {noremap = true})
