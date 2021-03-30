-- c-ls.lua --- LSP configurations for C

require'lspconfig'.clangd.setup{ on_attach = require'lsp'.common_on_attach }
