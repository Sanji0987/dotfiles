vim.g.mapleader = " " 

-- Harpoon 
vim.keymap.set("n", "<leader>a", function() require("harpoon"):list():add() end)
vim.keymap.set("n", "<C-e>", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list()) end)
vim.keymap.set("n", "<C-h>", function() require("harpoon"):list():select(1) end)
vim.keymap.set("n", "<C-j>", function() require("harpoon"):list():select(2) end)
vim.keymap.set("n", "<C-k>", function() require("harpoon"):list():select(3) end)
vim.keymap.set("n", "<C-l>", function() require("harpoon"):list():select(4) end)

-- Telescope
vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files() end)
vim.keymap.set("n", "<leader>fg", function() require("telescope.builtin").live_grep() end)
vim.keymap.set("n", "<leader>fb", function() require("telescope.builtin").buffers() end)

-- Oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>")

--Term
vim.keymap.set("n", "<leader>th", function()
  require("toggleterm.terminal").Terminal:new({ direction = "horizontal", size = math.floor(vim.o.lines * 0.4)}):toggle()
end)

vim.keymap.set("n", "<leader>tv", function()
  require("toggleterm.terminal").Terminal:new({ direction = "vertical", size = math.floor(vim.o.columns * 0.4) }):toggle()
end)
