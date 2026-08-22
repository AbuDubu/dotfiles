# nvim config

A small, from-scratch Neovim config built on the native `vim.pack` package
manager (Neovim 0.11+), the `gruber-darker` colorscheme, and built-in LSP
(`vim.lsp.enable`/`vim.lsp.config`, no `lspconfig.setup()` wrapper). LSP
servers and formatters are managed by Mason so any new language is a
one-line addition — see [Adding a new LSP server](#adding-a-new-lsp-server)
below.

## Requirements

- **Neovim 0.12+**
- **git** — `vim.pack` clones plugins with it
- **A C compiler** (`cc`/`gcc`/`clang`) — needed to build Treesitter parsers
- **ripgrep** (`rg`) — powers Telescope's live grep
- **A Nerd Font** in your terminal — icons in the statusline, completion
  menu, and file explorer will render as boxes/garbage without one (this
  setup assumes Iosevka Nerd Font, see `../ghostty/config`)
- **npm, python3/pip, go, and a Rust toolchain (rustup) on `PATH`** — Mason
  uses these to install some servers/formatters (pyright and prettier need
  npm, ruff needs pip, gofumpt needs go, rustfmt comes from rustup)

## Layout

| File | Contents |
|---|---|
| `init.lua` | Entry point — just requires the files below, then sets the colorscheme |
| `lua/options.lua` | Core `vim.opt`/`vim.g` settings |
| `lua/keymaps.lua` | General-purpose keymaps not tied to a specific plugin |
| `lua/plugins.lua` | `vim.pack.add()` plugin list + each plugin's setup |
| `lua/lsp.lua` | Mason, LSP server configuration, diagnostics, LSP-attach keymaps |
| `nvim-pack-lock.json` | `vim.pack` lockfile (pinned revisions) — don't hand-edit, it's rewritten by `vim.pack.update()` |

## First launch

`vim.pack.add()` downloads any missing plugins synchronously at startup, so
the very first launch (or the first launch after a plugin is added) will
pause for a few seconds and print progress in the command line. LSP
servers and formatter binaries install themselves in the background via
Mason — check on that anytime with `:Mason`.

## Leader key

`<Space>`

## Keybindings

Leader-prefixed maps are listed as `<leader>x`; leader is Space, so
`<leader>ff` means "press Space, then f, then f".

### General editing

| Key | Mode | Action |
|---|---|---|
| `p` | Visual | Paste over selection without losing what you yanked |
| `<leader>d` | Normal/Visual | Delete without yanking (sends to the black-hole register) |
| `<Esc>` | Normal | Clear search highlighting |
| `J` / `K` | Visual | Move the selected lines down/up |
| `<` / `>` | Visual | Indent/unindent and keep the selection |
| `J` | Normal | Join lines without moving the cursor |
| `<C-d>` / `<C-u>` | Normal | Half-page down/up, cursor kept centered |
| `n` / `N` | Normal | Next/previous search result, centered |
| `<leader>s` | Normal | Global find-and-replace for the word under the cursor (fills the command line, ready to edit) |
| `<leader>X` | Normal | `chmod +x` the current file |
| `<leader>re` | Normal | `:restart` Neovim (reloads config from scratch) |
| `<leader>u` | Normal | Toggle Neovim's built-in undo tree |

### Window navigation

| Key | Action |
|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move to the window left/below/above/right |

### Search & navigation — Telescope

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | List open buffers |
| `<leader>fh` | Search help tags |
| `<leader>fd` | Workspace diagnostics |
| `<leader>fr` | Resume the last picker |
| `<leader>fo` | Recently opened files |

### File explorer — Oil

| Key | Action |
|---|---|
| `-` | Open the parent directory as an editable Oil buffer |

Oil lets you edit a directory listing like a normal buffer — create a
file by typing a new line, delete one by deleting its line, then `:w` to
apply. Inside an Oil buffer:

| Key | Action |
|---|---|
| `<CR>` | Open file/directory under cursor |
| `-` | Go up to the parent directory |
| `<C-s>` / `<C-h>` / `<C-t>` | Open in a vertical/horizontal split / new tab |
| `<C-p>` | Preview |
| `<C-l>` | Refresh |
| `g.` | Toggle hidden files |
| `g?` | Help |

Note: inside an Oil buffer, `<C-h>` opens a horizontal split and `<C-l>`
refreshes the listing (Oil's own buffer-local maps) — both override the
global window-navigation maps of the same keys while you're in that
buffer.

### LSP

These are set only in buffers with an attached language server (see
`lua/lsp.lua`'s `LspAttach` autocommand):

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `<leader>th` | Toggle inlay hints |

Neovim 0.11+ also ships these LSP keymaps by default (no config needed —
they just work once a server attaches):

| Key | Action |
|---|---|
| `K` | Hover documentation |
| `grn` | Rename symbol |
| `gra` | Code action |
| `grr` | Find references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `gO` | Document symbols |
| `grx` | Run code lens |
| `<C-s>` (insert mode) | Signature help |

### Diagnostics

These work whether or not an LSP is attached:

| Key | Action |
|---|---|
| `[d` / `]d` | Previous/next diagnostic (opens a floating preview) |
| `<leader>e` | Show the diagnostic under the cursor |
| `<leader>q` | Send buffer diagnostics to the location list |

### Completion — blink.cmp

The menu pops up automatically as you type in insert mode:

| Key | Action |
|---|---|
| `<CR>` | Accept the selected completion |
| `<Tab>` / `<S-Tab>` | Next/previous item in the menu |
| `<Up>` / `<Down>` | Next/previous item in the menu |
| `<C-space>` | Force-open the menu / toggle the docs preview |
| `<C-e>` | Dismiss the menu |
| `<C-b>` / `<C-f>` | Scroll the docs popup |
| `<C-k>` (insert mode) | Toggle signature help |

All of the above fall back to their normal editing behavior when the menu
isn't open (e.g. `<Tab>` still indents, `<CR>` still inserts a newline).

### Formatting

| Key | Action |
|---|---|
| `<leader>lf` | Format the current buffer (also happens automatically on every save) |

### Misc

| Key | Action |
|---|---|
| `<leader>z` | Toggle a centered, 100-column writing area with padding on both sides (no-neck-pain.nvim) |

## Auto-save & format-on-save

Files auto-save ~1 second after you stop typing (and immediately on
leaving the buffer, losing focus, or quitting), via `auto-save.nvim`. It
skips unnamed buffers, non-modifiable buffers, and special buffers like
Oil and Telescope. Every save — auto or manual — prints `saved
<path>` so it's obvious when it fires, and every save also runs
`conform.nvim`'s formatter for that filetype.

## Plugins used

| Plugin | Purpose |
|---|---|
| [gruber-darker.nvim](https://github.com/blazkowolf/gruber-darker.nvim) | Colorscheme |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | Filetype icons |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Lua stdlib (Telescope dependency) |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | Filesystem editing as a buffer |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting & indent |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Default LSP server configs (consumed by native `vim.lsp.enable`) |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | Installs LSP servers, formatters, linters |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Bridges Mason installs to `vim.lsp.enable` |
| [mason-tool-installer.nvim](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim) | Auto-installs the formatter binaries `conform.nvim` calls |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatting, on save and on demand |
| [no-neck-pain.nvim](https://github.com/shortcuts/no-neck-pain.nvim) | Centered writing width |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | Debounced auto-save |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Completion |

Treesitter parsers installed: `c`, `cpp`, `python`, `rust`, `lua`, `vim`,
`vimdoc`, `bash`, `markdown`, `markdown_inline` (see `ts_langs` in
`lua/plugins.lua`).

## Adding a new LSP server

1. Find the server's name as `nvim-lspconfig` knows it — `:h
   lspconfig-all` or [mason-registry.dev](https://mason-registry.dev)
   (Mason's name and lspconfig's name are usually, but not always, the
   same string).
2. Add it to the `ensure_installed` list in `lua/lsp.lua`:
   ```lua
   require("mason-lspconfig").setup({
       ensure_installed = { "clangd", "pyright", "rust_analyzer", "lua_ls", "gopls" },
   })
   ```
3. `:restart` (or quit and reopen). Mason installs it, and
   `mason-lspconfig` calls `vim.lsp.enable()` for you automatically —
   no further wiring needed.
4. Optional: give it server-specific settings the way `lua_ls` has above
   it, using `vim.lsp.config("<name>", { settings = { ... } })` before the
   `mason-lspconfig.setup()` call.

## Adding a new formatter

1. Add `filetype = { "formatter_name" }` to `formatters_by_ft` in the
   `conform.nvim` setup block in `lua/plugins.lua` (formatter names are
   conform's own — see `:h conform-formatters`).
2. If the formatter binary isn't already on your `PATH`, add its Mason
   package name to `ensure_installed` in the `mason-tool-installer` block
   in `lua/lsp.lua`.
3. `:restart`. Any filetype with no explicit formatter still falls back to
   the attached LSP server's formatter automatically
   (`lsp_format = "fallback"`), so this step is only needed when you want
   a specific standalone formatter instead of (or faster than) the LSP's.

## Updating plugins

```
:lua vim.pack.update()
```

This opens a diff of available updates in a new tab. Review it, then
`:write` to apply the updates or `:quit` to discard them. `:restart`
afterward to start using the new code.

## Troubleshooting

- **A newly added plugin/keymap doesn't seem to work**: if you had Neovim
  open before the config changed, it won't pick up the change on its own
  — `:restart` or quit and reopen.
- **LSP not attaching**: `:LspInfo` (server status for the current buffer)
  or `:checkhealth vim.lsp`.
- **Formatter/server install stuck or failed**: `:Mason` to see status and
  retry installs.
- **Treesitter highlighting missing for a language**: it's probably not
  in `ts_langs` in `lua/plugins.lua` — add it and run
  `:lua require("nvim-treesitter").install({"lang"})`.
