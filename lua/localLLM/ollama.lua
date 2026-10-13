local config = require("localLLM.config")

local M = {}

--- Send a prompt to Ollama and wait for the full response.
--- Returns the response text, or nil plus an error message.
function M.generate_blocking(prompt)
  local body = vim.json.encode({
    model = config.options.model,
    prompt = prompt,
    stream = false,
  })

  local result = vim.system({
    "curl", "-sS", "-X", "POST",
    config.options.host .. "/api/generate",
    "-H", "Content-Type: application/json",
    "--data-binary", "@-",
  }, { text = true, stdin = body }):wait()

  if result.code ~= 0 then
    return nil, "curl failed (exit " .. result.code .. "): " .. (result.stderr or "")
  end

  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if not ok then
    return nil, "Invalid JSON from Ollama: " .. result.stdout
  end
  if decoded.error then
    return nil, decoded.error
  end

  return decoded.response
end

return M
