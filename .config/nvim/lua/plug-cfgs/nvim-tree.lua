-- nvim-tree.lua --- nvim-tree plugin configuration

vim.g.nvim_tree_width          = 32                        -- 30 by default
vim.g.nvim_tree_auto_open      = 1                         -- 0 by default, opens the tree when typing `vim $DIR` or `vim`
vim.g.nvim_tree_auto_close     = 1                         -- 0 by default, closes the tree when it's the last window
vim.g.nvim_tree_auto_ignore_ft = {'startify', 'dashboard'} -- empty by default, don't auto open tree on specific filetypes.
vim.g.nvim_tree_add_trailing   = 1                         -- 0 by default, append a trailing slash to folder names
vim.g.nvim_tree_group_empty    = 1                         --  0 by default, compact folders that only contain a single folder into one node in the file tree

-- mappings
set_keymap('n', '<Leader>e', ':NvimTreeToggle<CR>',
    {noremap = true, silent = true})

local tree_cb = require'nvim-tree.config'.nvim_tree_callback
vim.g.nvim_tree_bindings = {
    ["<CR>"] = tree_cb("edit"),
    ["<2-LeftMouse>"] = tree_cb("edit"),
    ["v"] = tree_cb("vsplit"),
    ["s"] = tree_cb("split"),
    ["<C-t>"] = tree_cb("tabnew"),
    ["<Tab>"] = tree_cb("preview"),
    ["I"] = tree_cb("toggle_ignored"),
    ["H"] = tree_cb("toggle_dotfiles"),
    ["R"] = tree_cb("refresh"),
    ["a"] = tree_cb("create"),
    ["d"] = tree_cb("remove"),
    ["r"] = tree_cb("rename"),
    ["<C-r>"] = tree_cb("full_rename"),
    ["x"] = tree_cb("cut"),
    ["c"] = tree_cb("copy"),
    ["p"] = tree_cb("paste"),
    ["6"] = tree_cb("dir_up"),
    ["q"] = tree_cb("close")
}

-- icons
vim.g.nvim_tree_icons = {
    default = '',
    symlink = '',
    git = {
        unstaged = "",
        staged = "✓",
        unmerged = "",
        renamed = "➜",
        untracked = ""
    },
    folder = {
        default = "",
        open = "",
        empty = "",
        empty_open = "",
        symlink = ""
    }
}
