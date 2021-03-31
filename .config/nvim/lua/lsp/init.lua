-- init.lua --- LSP's init configuration file

fn.sign_define("LspDiagnosticsSignError",
               {texthl = "LspDiagnosticsSignError",
                text = "",
                numhl = "LspDiagnosticsSignError"})
fn.sign_define("LspDiagnosticsSignWarning",
               {texthl = "LspDiagnosticsSignWarning",
                text = "",
                numhl = "LspDiagnosticsSignWarning"})
fn.sign_define("LspDiagnosticsSignHint",
               {texthl = "LspDiagnosticsSignHint",
                text = "",
                numhl = "LspDiagnosticsSignHint"})
fn.sign_define("LspDiagnosticsSignInformation",
                   {texthl = "LspDiagnosticsSignInformation",
                    text = "",
                    numhl = "LspDiagnosticsSignInformation"})

-- mappings
set_keymap('n', 'gd', ':lua vim.lsp.buf.definition()<CR>',     {noremap = true, silent = true})
set_keymap('n', 'gD', ':lua vim.lsp.buf.declaration()<CR>',    {noremap = true, silent = true})
set_keymap('n', 'gr', ':lua vim.lsp.buf.references()<CR>',     {noremap = true, silent = true})
set_keymap('n', 'gi', ':lua vim.lsp.buf.implementation()<CR>', {noremap = true, silent = true})

local lsp_config = {}
return lsp_config
