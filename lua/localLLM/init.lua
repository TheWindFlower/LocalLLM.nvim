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
    window.set_text("Thinking...")

    local first = true
    ollama.generate(
        prompts.explain(code, filetype),
        function(chunk)
            if first then
                first = false
                window.set_text("") -- clear "Thinking..."
            end
            window.append_text(chunk)
        end,
        function(err)
            if not err then return end
            if first then
                window.set_text("**Error:** " .. err)
            else
                window.append_text("\n\n**Error:** " .. err)
            end
        end
    )
end

return M
