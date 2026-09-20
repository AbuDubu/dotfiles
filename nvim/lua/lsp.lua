require("mason").setup()

-- Per-server tweaks go here, keyed by the name nvim-lspconfig ships
-- (see `:h lspconfig-all` or the "lsp/" dir of nvim-lspconfig).
-- Turns on clang-tidy diagnostics (uses ~/.clang-tidy as a fallback when a
-- project has none) and points clangd at build/compile_commands.json by
-- convention - see ../../zsh/.zshrc's `cmake` wrapper, which always
-- generates it there. Projects using a different build dir need their own
-- .clangd with `CompileFlags: CompilationDatabase: <dir>`.
vim.lsp.config("clangd", {
    cmd = { "clangd", "--clang-tidy", "--compile-commands-dir=build" },
})

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
-- Full asdlist of installable servers: :Mason  /  https://mason-registry.dev
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd",
        "pyright",
        "rust_analyzer",
        "lua_ls",
        "neocmake", -- CMakeLists.txt / *.cmake (prebuilt binary; Mason's
        -- cmake-language-server needs python <3.14)
        "bashls", -- shell scripts
        "jsonls", -- json/jsonc (compile_commands.json, configs)
        "taplo", -- TOML (Cargo.toml, ...)
    },
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

-- <a>/<a> in html/xml: editing an open tag renames the matching close tag.
vim.lsp.linked_editing_range.enable(true)

-- Everything below runs once per (buffer, server) attach, so each feature is
-- gated on what that server actually supports. Neovim also provides these
-- with no config once a server attaches: K hover, grn rename, gra code
-- action, grr references, gri implementation, grt type definition, gO
-- document symbols, grx run code lens, <C-s> (insert) signature help,
-- <C-o>/<C-t> to jump back after go-to-definition.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        local builtin = require("telescope.builtin")
        local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
        end
        local function supports(method)
            return client:supports_method(method, bufnr)
        end

        -- Go to (jump list: <C-o> back, <C-i> forward, <C-t> pop tag stack)
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gy", vim.lsp.buf.type_definition, "Go to type definition")
        map("gI", vim.lsp.buf.implementation, "Go to implementation")

        -- Find (Telescope pickers with a live preview)
        map("<leader>lr", builtin.lsp_references, "References")
        map("<leader>li", builtin.lsp_implementations, "Implementations")
        map("<leader>ld", builtin.lsp_definitions, "Definitions (list + preview)")
        map("<leader>ls", builtin.lsp_document_symbols, "Document symbols")
        map("<leader>lS", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")

        -- Refactor
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })

        if supports("callHierarchy/incomingCalls") then
            map("<leader>lc", builtin.lsp_incoming_calls, "Incoming calls (who calls this)")
            map("<leader>lC", builtin.lsp_outgoing_calls, "Outgoing calls (what this calls)")
        end
        if supports("textDocument/prepareTypeHierarchy") then
            map("<leader>lt", function() vim.lsp.buf.typehierarchy("supertypes") end, "Type hierarchy: supertypes")
            map("<leader>lT", function() vim.lsp.buf.typehierarchy("subtypes") end, "Type hierarchy: subtypes")
        end

        -- Highlight every use of the symbol under the cursor while idle.
        if supports("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("user-lsp-highlight-" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = group,
                buffer = bufnr,
                callback = function()
                    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/documentHighlight" }) > 0 then
                        vim.lsp.buf.document_highlight()
                    end
                end,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                group = group,
                buffer = bufnr,
                callback = vim.lsp.buf.clear_references,
            })
        end

        if supports("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end

        -- Run/Debug/"N references" lenses above functions (rust-analyzer, ...).
        if supports("textDocument/codeLens") then
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
        end

        -- Fold by the server's ranges (falls back to treesitter, see plugins.lua).
        if supports("textDocument/foldingRange") then
            local win = vim.fn.bufwinid(bufnr)
            if win ~= -1 then
                vim.wo[win].foldmethod = "expr"
                vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
            end
        end

        if client.name == "clangd" then
            -- Re-format as you type (per your .clang-format) on `;` and `}` -
            -- the closest thing to CLion's live formatting. clangd also asks
            -- for "\n", but Neovim fires that request on every Enter keypress
            -- even when blink.cmp consumed it to accept a completion, and the
            -- reply then wipes the accepted text - so Enter is dropped from
            -- the triggers (cindent already handles indenting on Enter).
            if client.server_capabilities.documentOnTypeFormattingProvider then
                client.server_capabilities.documentOnTypeFormattingProvider = {
                    firstTriggerCharacter = "}",
                    moreTriggerCharacter = { ";" },
                }
            end
            vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
            map("<leader>lh", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch source/header")
        end
    end,
})

vim.keymap.set("n", "<leader>th", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "Toggle inlay hints" })
