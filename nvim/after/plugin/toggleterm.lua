require("toggleterm").setup({
  start_in_insert = true,
  open_mapping = [[<leader>tt]],
})

function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  vim.keymap.set("t", "C-o", [[<C-\><C-n>]], opts)
  vim.keymap.set("n", "<leader>ft", ":ToggleTerm")
end

local function open_floating_terminal(func)
  return "<Cmd> ToggleTerm direction = float<Cr>"
end

vim.keymap.set("n", "<leader>ft", open_floating_terminal())

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
