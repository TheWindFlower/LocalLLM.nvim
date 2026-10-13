local M = {}

M.defaults = {
  host = "http://127.0.0.1:11434",
  model = "hf.co/Olak17/Qwen2.5-Coder-1.5B-Unsensored-DPO-i1-GGUF:q4_k_m",
  window = {
    width = 0.25,
  },
  prompts = {
    explain = "Explain the following {filetype} code clearly and concisely. "
      .. "Describe what it does and point out anything notable.",
    document = "Write documentation comments for the following {filetype} code, "
      .. "using the idiomatic doc-comment style for that language. "
      .. "Return the documented code.",
    bugs = "Review the following {filetype} code for bugs, edge cases, and "
      .. "potential problems. List each issue and suggest a fix.",
    refactor = "Suggest cleaner or more idiomatic ways to write the following "
      .. "{filetype} code. Show the improved version and explain the changes.",
    tests = "Write unit tests for the following {filetype} code. "
      .. "Use the most common testing framework for that language.",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
