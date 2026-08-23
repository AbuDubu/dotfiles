vim.g.mapleader = " "
vim.g.netrw_banner = 0

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.wrap = false
vim.opt.smartindent = true
vim.opt.inccommand = "split"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.laststatus = 3

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

vim.opt.completeopt = "menuone,noselect,fuzzy,nosort"
vim.opt.shortmess:append("c")
vim.opt.clipboard:append("unnamedplus")
vim.opt.isfname:append("@-@")
vim.opt.guicursor = ""
vim.opt.scrolloff = 8

vim.opt.colorcolumn = "0"
vim.opt.signcolumn = "yes"

vim.opt.mouse = "a"
vim.opt.updatetime = 250
-- timeoutlen: how long to wait for the rest of a mapped sequence (e.g.
-- <leader>ff) before giving up and running the first key on its own.
-- ttimeoutlen: separately, how long to wait for the rest of a terminal key
-- code (e.g. the Esc that prefixes an arrow key) - kept low so Esc stays
-- snappy regardless of the more forgiving timeoutlen above.
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10
vim.opt.showmode = false
vim.opt.winborder = "rounded"
vim.opt.pumheight = 10

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    callback = function()
        vim.hl.on_yank()
    end,
})
