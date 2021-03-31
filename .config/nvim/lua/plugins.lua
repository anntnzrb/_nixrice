-- plugins.lua --- plugin management

local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  exec('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
  exec 'packadd packer.nvim'
end

-- ----------------------------------------------------------------------------
-- plugins
-- ----------------------------------------------------------------------------

return require('packer').startup(function()
  -- 'packer.nvim' can manage itself
  use 'wbthomason/packer.nvim'

  -- appearance
  use {'glepnir/galaxyline.nvim', requires = {'kyazdani42/nvim-web-devicons'}}
  use {'akinsho/nvim-bufferline.lua', requires = 'kyazdani42/nvim-web-devicons'}

  -- navigation
  use {'kyazdani42/nvim-tree.lua', requires = { 'kyazdani42/nvim-web-devicons'}}

  -- LSP
  use 'neovim/nvim-lspconfig'
  use {'glepnir/lspsaga.nvim', requires = {'neovim/nvim-lspconfig'}}
  use 'hrsh7th/nvim-compe'    -- completion

  -- git
  use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}}
  -- git client (neogit)

  -- utilities
  use 'tpope/vim-surround'          -- (vimscript)
  use 'windwp/nvim-autopairs'
  use 'norcalli/nvim-colorizer.lua'
  use 'b3nj5m1n/kommentary'
  -- Which-Key alternative Lua
  -- Codi alternative in Lua
end)
