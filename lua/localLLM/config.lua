local M = {}

M.defaults = {
    host = "http://127.0.0.1:11434",
    model = "hf.co/Olak17/Qwen2.5-Coder-1.5B-Unsensored-DPO-i1-GGUF:q4_k_m",
    window = {
        width = 0.25, --fraction of the screen
    }
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
