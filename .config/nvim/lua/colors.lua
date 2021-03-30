-- colors.lua --- appearance (theming) settings

--[[
-- The constant variable 'THEME' should have the desired theme to use,
-- they can be found @ colors/ folder.
]]
local THEME = 'gruvbox'

-- ----------------------------------------------------------------------------
-- Gruvbox customization
-- ----------------------------------------------------------------------------
if THEME == 'gruvbox' then
    vim.o.background = 'dark' -- nvim background

    -- theme customizations
    vim.g.gruvbox_contrast_dark     = 'gray'
    vim.g.gruvbox_italic            = 1
    vim.g.gruvbox_italicize_strings = 1
end

-- Finally set the theme (should be at the end after customizations)
vim.cmd('colorscheme ' .. THEME)
