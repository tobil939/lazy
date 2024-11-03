-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			theme = "dracula",
		},
	},
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v4.x",
		lazy = true,
		config = false,
	},
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = true,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{ "L3MON4D3/LuaSnip" },
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
				}),
				snippet = {
					expand = function(args)
						require("luasnip").expand(args.body)
					end,
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			local lsp_zero = require("lsp-zero")

			local lsp_attach = function(client, bufnr)
				local opts = { buffer = bufnr }
				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
				vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
				vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
				vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
				vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
				vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
				vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
				vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
				vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", opts)
				vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
			end

			lsp_zero.extend_lspconfig({
				sign_text = true,
				lsp_attach = lsp_attach,
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			require("mason-lspconfig").setup({
				ensure_installed = {},
				handlers = {
					function()
						require("lspconfig").lua_ls.setup({})
						require("lspconfig").asm_lsp.setup({})
						require("lspconfig").ast_grep.setup({})
						require("lspconfig").hls.setup({})
						require("lspconfig").texlab.setup({})
						require("lspconfig").matlab_ls.setup({})
						require("lspconfig").r_language_server.setup({})
						require("lspconfig").zls.setup({})
					end,
				},
			})
		end,
	},
	{
		"mhartington/formatter.nvim",
		config = function()
			require("formatter").setup({
				logging = false,
				filetype = {
					sh = {
						function()
							return {
								exe = "shfmt",
								args = { "-w" },
								stdin = true,
							}
						end,
					},
					c = {
						function()
							return {
								exe = "clang-format",
								args = { "--style=google" },
								stdin = true,
							}
						end,
					},
					matlab = {
						function()
							return {
								exe = "mlint",
								args = {},
								stdin = false,
							}
						end,
					},
					tex = {
						function()
							return {
								exe = "latexindent",
								args = { "-y", '{"indent": "    "}' },
								stdin = true,
							}
						end,
					},
					python = {
						function()
							return {
								exe = "black",
								args = { "--fast" },
								stdin = true,
							}
						end,
					},
				},
			})
		end,
	},
}

require("lazy").setup(plugins)

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", builtin.find_files, {})
vim.keymap.set("n", "<M-p>", builtin.live_grep, {})

local config = require("nvim-treesitter.configs")
config.setup({
	ensure_installed = { "lua", "c", "go", "haskell", "latex", "python", "r", "zig", "asm" },
	highlight = { enable = true },
	indent = { enable = true },
	sync_install = false,
})

vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>")

require("catppuccin").setup()
vim.cmd.colorscheme("catppuccin")
