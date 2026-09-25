require("options")
require("keymaps")
require("plugins")
require("lsp")

-- alabaster.nvim picks its dark palette off &background, not a separate
-- colorscheme name (see themes/alabaster_dark under ghostty/helix/tmux for
-- the same palette elsewhere).
vim.o.background = "dark"
vim.cmd.colorscheme("alabaster")
