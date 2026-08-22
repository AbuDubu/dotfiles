vim.pack.add({
    { src = "https://github.com/blazkowolf/gruber-darker.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-telescope/telescope.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/shortcuts/no-neck-pain.nvim" },
    -- vim.version.range("1") tracks the latest v1.x.y tag, which ships a
    -- prebuilt fuzzy-matcher binary (no cargo/rust needed to build it).
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1") },
})

-- Treesitter ----------------------------------------------------------------
local ts_langs = { "c", "cpp", "python", "rust", "lua", "vim", "vimdoc", "bash", "markdown", "markdown_inline" }

require("nvim-treesitter").install(ts_langs)

vim.api.nvim_create_autocmd("FileType", {
    pattern = ts_langs,
    callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

-- Telescope -------------------------------------------------------------
require("telescope").setup({})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Workspace diagnostics" })
vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume last picker" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Recently opened files" })

-- Oil: edit the filesystem like a normal buffer ------------------------------
require("oil").setup({
    view_options = { show_hidden = true },
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- Statusline ------------------------------------------------------------
require("lualine").setup({
    options = { theme = "auto", globalstatus = true },
})

-- Completion --------------------------------------------------------------
require("blink.cmp").setup({
    keymap = {
        preset = "enter",
        -- Tab/S-Tab cycle the completion menu instead of jumping snippet
        -- placeholders; falls back to normal Tab/S-Tab when menu is closed.
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = true } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    signature = { enabled = true },
})

-- Centered writing width -------------------------------------------------
require("no-neck-pain").setup({
    width = 100,
})
vim.keymap.set("n", "<leader>z", "<cmd>NoNeckPain<CR>", { desc = "Toggle centered/padded buffer" })

-- Formatting ------------------------------------------------------------
-- Explicit formatter per filetype where a fast standalone one exists; any
-- other filetype falls back to the attached LSP's formatter (lsp_format
-- "fallback" below), so this covers new languages automatically once an
-- LSP is added for them in lsp.lua.
require("conform").setup({
    formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        lua = { "stylua" },
        go = { "gofumpt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
    },
    format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})
vim.keymap.set({ "n", "v" }, "<leader>lf", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
