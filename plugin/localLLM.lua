vim.api.nvim_create_user_command("LocalLLMExplain", function(opts)
    require("localLLM").explain(opts.line1, opts.line2)
end, { range = true, desc = "Explain selected code with a local LLM" })
