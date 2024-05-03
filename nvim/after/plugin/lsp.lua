require("mason").setup()
require("mason-lspconfig").setup()

local lsp = require('lsp-zero')
local lspconfig = require('lspconfig')

lspconfig.lua_ls.setup({})

lsp.on_attach(function(_, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp.default_keymaps({buffer = bufnr})
end)

lspconfig.yamlls.setup({})

local cmp = require('cmp')

cmp.setup({
  mapping = cmp.mapping.preset.insert({
	  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
	  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
	  ['<C-y>'] = cmp.mapping.confirm(cmp_select),
	  ['<C-Space>'] = cmp.mapping.complete(),
  })
})

lsp.set_preferences({
	sign_icons = { }
})

lsp.on_attach(function(_, bufnr)
	local opts = {buffer = bufnr, remap = false}
	
	vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
	vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
	vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
	vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
	vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
	vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
	vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
	vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
	vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
	vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)
