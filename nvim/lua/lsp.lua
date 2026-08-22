require("mason").setup()

-- Per-server tweaks go here, keyed by the name nvim-lspconfig ships
-- (see `:h lspconfig-all` or the "lsp/" dir of nvim-lspconfig).
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
})

-- To add a new language server: add its lspconfig name below and restart.
-- mason-lspconfig installs it via Mason and calls vim.lsp.enable() for you.
-- Full list of installable servers: :Mason  /  https://mason-registry.dev
require("mason-lspconfig").setup({
    ensure_installed = { "clangd", "pyright", "rust_analyzer", "lua_ls" },
})

-- Formatter binaries used by conform.nvim (see lua/plugins.lua). Add a
-- Mason package name here for any new formatter you wire up there.
-- rustfmt is deliberately excluded: it ships via `rustup component add
-- rustfmt`, not Mason, and isn't in the Mason registry.
require("mason-tool-installer").setup({
    ensure_installed = {
        "clang-format",
        "ruff",
        "stylua",
        "gofumpt",
        "shfmt",
        "prettier",
    },
})

vim.diagnostic.config({
    virtual_text = { current_line = false },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })

        if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})

vim.keymap.set("n", "<leader>th", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "Toggle inlay hints" })
