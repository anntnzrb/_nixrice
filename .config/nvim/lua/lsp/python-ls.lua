-- python-ls.lua --- LSP configurations for Python

require'lspconfig'.pyright.setup{ on_attach = require'lsp'.common_on_attach }
