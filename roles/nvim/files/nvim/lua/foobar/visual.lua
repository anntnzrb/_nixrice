-- visual.lua

local options = {
  guicursor      = "n-v-c-sm:block,i-ci-ve:blinkon1",
  number         = true,
  relativenumber = true,
  hlsearch       = false,
  incsearch      = true,
  scrolloff      = 10,
  signcolumn     = "auto", -- add ean extra column for symbols & info

  colorcolumn = "80",
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
