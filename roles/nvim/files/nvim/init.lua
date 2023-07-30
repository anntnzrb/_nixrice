-- init.lua --- Neovim configuration
--
-- Code:

local function set_options(options)
  for k, v in pairs(options) do
    vim.opt[k] = v
  end
end

local indent_level = 4

local options = {
  -- --------------------------------------------------------------------------
  -- core
  -- --------------------------------------------------------------------------

  hidden = true,  -- hide buffer instead of abandon
  exrc   = false, -- avoid sourcing unknown files

  -- backup & state
  swapfile = false, -- avoid using swap files
  backup   = false,

  -- system
  mouse     = "a",           -- enable mouse in all modes
  clipboard = "unnamedplus", -- system clipboard integration

  -- --------------------------------------------------------------------------
  -- editing
  -- --------------------------------------------------------------------------

  expandtab   = true,
  smartindent = true,
  shiftwidth  = indent_level,
  tabstop     = indent_level,
  softtabstop = indent_level,

  -- --------------------------------------------------------------------------
  -- visuals
  -- --------------------------------------------------------------------------

  guicursor      = "n-v-c-sm:block,i-ci-ve:blinkon1",
  number         = true,
  relativenumber = true,
  hlsearch       = false,
  incsearch      = true,
  scrolloff      = 10,
  signcolumn     = "auto", -- add an extra column for symbols & info

  colorcolumn = "80",
}

set_options(options)
