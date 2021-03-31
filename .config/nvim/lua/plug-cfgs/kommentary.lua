-- kommentary.lua --- kommentary plugin configurations

vim.g.kommentary_create_default_mappings = false

-- mappings
set_keymap('n', '<Leader>/', '<Plug>kommentary_line_default', {})
set_keymap('v', '<Leader>/', '<Plug>kommentary_visual_default', {})
