vim.lsp.config("zls", {
	settings = {
		zls = {
			inlay_hints_hide_redundant_param_names = true,
			inlay_hints_hide_redundant_param_names_last_token = true,
			warn_style = true,
		},
	},
	on_attach = function(_, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.code_action({
					---@diagnostic disable-next-line: missing-fields
					context = { only = { "source.organizeImports" } },
					apply = true,
				})
				vim.lsp.buf.code_action({
					---@diagnostic disable-next-line: missing-fields
					context = { only = { "source.fixAll" } },
					apply = true,
				})
				vim.wait(100) -- wait for the code actions to be applied
			end,
		})
	end,
})

---@module "utils.lang"
---@type table<string, LanguageConfig>
return {
	zig = {
		lsp = "zls",
		treesitter = "zig",
	},
}
