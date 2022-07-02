-- core.lua

local options = {
  hidden    = true,  -- hide buffer instead of abandon
  exrc      = false, -- avoid sourcing unknown files

  -- backup & state
  swapfile  = false, -- avoid using swap files
  backup    = false,

  -- system
  mouse     = "a",           -- enable mouse in all modes
  clipboard = "unnamedplus", -- system clipboard integration
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
