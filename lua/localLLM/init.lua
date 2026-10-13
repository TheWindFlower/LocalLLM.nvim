local config = require("localLLM.config")
local selection = require("localLLM.selection")
local window = require("localLLM.window")
local prompts = require("localLLM.prompts")
local ollama = require("localLLM.ollama")
local M = {}

function M.setup(opts)
    config.setup(opts)
end

function M.explain()
    line1 = line1 or vim.fn.line(".")
    line2 = line2 or line1

    local code = selection.get_lines(line1, line2)
    local filetype = selection.get_filetype()
    window.open()
    window.set_text(
        "**filetype:** " .. filetype .. "\n\n```" .. filetype .. "\n" .. code .. "\n```")
    vim.cmd("redraw") --force a repaint before we block
    
      local response, err = ollama.generate_blocking(prompts.explain(code, filetype))
  if not response then
    window.set_text("**Error:** " .. err)
    return
  end

  window.set_text(response)
end

return M
