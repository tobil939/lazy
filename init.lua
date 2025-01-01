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
		"rafamadriz/friendly-snippets",
		enabled = false, -- Disable friendly-snippets
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		lazy = true,
		config = function()
			-- Ensure luasnip is loaded
			local ls = require("luasnip")
			local s = ls.snippet
			local t = ls.text_node
			local i = ls.insert_node

			-- LaTeX snippet for \begin{}...\end{}
			ls.add_snippets("tex", {
				-- Trigger snippet for \begin{} and \end{}
				s("begin", {
					t({ "\\begin{" }),
					i(1, "environment"), -- Cursor inside the braces
					t({ "}", "" }),
					t({ "", "" }),
					t({ "\\end{" }),
					i(2, "environment"), -- Cursor inside the ending braces
					t({ "}", "" }),
				}),

				-- Other LaTeX snippets you may want to customize
			})

			-- Auto completion setup for LaTeX with {} instead of ()
			require("cmp").setup({
				snippet = {
					expand = function(args)
						-- Make sure luasnip expands the snippet properly
						ls.snippet.expand(args.body)
					end,
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/penary.nvim" },
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
			"MunifZanjim/nvim.nvim",
		},
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope").load_extension("fzf")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
	},
	{
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
			"jose-elias-alvarez/null-ls.nvim",
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
			config = function()
				local null_ls = require("null-ls")
				null_ls.setup({
					sources = {
						null_ls.builtins.formatting.prettier, -- JavaScript, TypeScript, etc.
						null_ls.builtins.formatting.black, -- Python
						null_ls.builtins.formatting.stylua, -- Lua
						null_ls.builtins.formatting.shfmt, -- Shell scripts
						null_ls.builtins.formatting.clang_format, -- C/C++
					},
				})
			end,
		},

		-- Autocompletion
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
							vim.snippet.expand(args.body)
						end,
					},
				})
			end,
		},

		-- LSP
		{
			"neovim/nvim-lspconfig",
			cmd = { "LspInfo", "LspInstall", "LspStart" },
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "williamboman/mason.nvim" },
				{ "williamboman/mason-lspconfig.nvim" },
			},
			config = function()
				local lsp_zero = require("lsp-zero")

				-- lsp_attach is where you enable features that only work
				-- if there is a language server active in the file
				local lsp_attach = function(client, bufnr)
					local opts = { buffer = bufnr }

					vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
					vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
					vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
					vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
					vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
					vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
					vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
					vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
					vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
					vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
				end

				lsp_zero.extend_lspconfig({
					sign_text = true,
					lsp_attach = lsp_attach,
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
				})

				require("mason-lspconfig").setup({
					ensure_installed = {},
					handlers = {
						-- this first function is the "default handler"
						-- it applies to every language server without a "custom handler"
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
	},
}

local opts = {}

require("lazy").setup(plugins, opts)

local config = require("nvim-treesitter.configs")
config.setup({
	ensure_installed = { "lua", "c", "go", "haskell", "latex", "python", "r", "zig", "asm" },
	highlight = { enable = true },
	indent = { enable = true },
	sync_install = false,
})

vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>")

require("catppuccin").setup({
	flavour = "mocha", -- Choose from "latte", "frappe", "macchiato", "mocha"
	integrations = {
		treesitter = true,
		telescope = true,
		lsp_trouble = true,
		cmp = true,
		gitgutter = true,
		gitsigns = true,
	},
})
vim.cmd.colorscheme("catppuccin")

require("lualine").setup({
	otions = {
		theme = "dracula",
	},
})

-- Autoformat beim Speichern
vim.api.nvim_exec(
	[[
   augroup FormatAutogroup
       autocmd!
       autocmd BufWritePost *.sh,*.c,*.lua,*.m,*.tex,*.py,*.js,*.ts lua vim.lsp.buf.format({ async = true })
   augroup END
   ]],
	true
)

-- Funktion, um die Zeile auf eine bestimmte Spalte zu erweitern
function _G.fill_to_column(col)
	local line = vim.fn.getline(".")
	local len = vim.fn.strdisplaywidth(line)
	if len < col then
		vim.fn.setline(".", line .. string.rep(" ", col - len))
	end
	vim.cmd("normal! " .. col .. "|")
	vim.cmd("startinsert")
end

-- Mapping für Ctrl-Shift-K
vim.api.nvim_set_keymap("n", "<C-S-k>", [[:lua fill_to_column(55)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-S-i>", "i% ====================<ESC>", { noremap = true, silent = true })
vim.o.relativenumber = true

--local ls = require("luasnip")
--local s = ls.snippet
--local t = ls.text_node
