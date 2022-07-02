-- editing.lua

local indent_level = 4

local options = {
  expandtab   = true,
  smartindent = true,
  shiftwidth  = indent_level,
  tabstop     = indent_level,
  softtabstop = indent_level,
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
