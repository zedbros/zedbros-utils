require("config.lazy")
require("lazy").setup("plugins")


----------background change--------------
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
       vim.fn.system("~/.local/bin/nvim-bg")
    end,
})

vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
       vim.fn.system("~/.local/bin/kitty-bg")
    end,
})
--------------------------------------------------

vim.opt.number = true -- line number
vim.opt.relativenumber = true -- relative line number
vim.api.nvim_set_hl(0, 'LineNr', { fg = "green" })

vim.opt.tabstop = 4 -- tabsize
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.opt.ignorecase = true -- in lowercase searches -> case insensitive foo=>Foo
vim.opt.smartcase = true -- if uppercase in search, then case sensitive

vim.o.incsearch = true -- shows matches as am typing (might turn off)

vim.opt.wrap = true -- wraps (I think it does this by default)
vim.opt.linebreak = true -- doesn't break in the middle of a word
vim.opt.breakindent = true

vim.opt.scrolloff = 12 -- keeps the cursor in the middle (by 12 lines)
-- vim.opt.sidescrolloff = 12 -- horizontally

vim.opt.list = true -- shows tabs and shit

vim.opt.clipboard = "unnamedplus" -- uses system clipboard

vim.opt.mouse = "a" -- adds mouse clicking and selecting

vim.opt.undofile = true -- keeps a history of changes so when reopen, can still undo

vim.opt.termguicolors = true -- activates 24bit colors (by default I believe)

vim.opt.completeopt = { "menu", "menuone", "noselect" } -- autocomplete tweeks

vim.cmd.highlight({ "Normal", "guibg=NONE" }) -- makes background transparent, so kitty background shows
--vim.cmd.highlight({ "Normal", "ctermbg=NONE" })
