return {
	"nvim-tree/nvim-tree.lua",
	config = function ()
		require("nvim-tree").setup()
	end
}

-- return {
--     "nvim-tree/nvim-tree.lua",
--     dependencies = {
--         "nvim-tree/nvim-web-devicons",
--     },
--
--     config = function()
-- 		local api = require("nvim-tree.api")
--         require("nvim-tree").setup({
--             on_attach = function(bufnr)
-- 				api.map.on_attach.default(bufnr)
--
--                 local opts = { buffer = bufnr}
--
--                 vim.keymap.set("n", "l", "<cmd>lua require('nvim-tree.api').node.open.edit()<CR>", opts)
-- 				vim.keymap.set("n", "<Space>", "<cmd>lua require('nvim-tree.api').node.open.edit()<CR>", opts)
--
-- 				vim.keymap.set("n", "h", "-", opts)
-- 				vim.keymap.set("n", "<S-Space>", "-", opts)
--
-- 				vim.keymap.set("n", "f", "<cmd>NvimTreeFindFile<CR>", opts)
-- 			end,
--         })
--     end,
-- }

