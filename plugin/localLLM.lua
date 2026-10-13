local actions = {
  Explain = "explain",
  Document = "document",
  Bugs = "bugs",
  Refactor = "refactor",
  Tests = "tests",
}

for suffix, action in pairs(actions) do
  vim.api.nvim_create_user_command("LocalLLM" .. suffix, function(opts)
    require("localLLM").run(action, opts.line1, opts.line2)
  end, { range = true, desc = "localLLM: " .. action .. " the selected code" })
end

vim.api.nvim_create_user_command("LocalLLMCancel", function()
  require("localLLM").cancel()
end, { desc = "localLLM: cancel the running request" })
