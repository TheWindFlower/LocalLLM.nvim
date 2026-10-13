local config = require("localLLM.config")
local selection = require("localLLM.selection")
local window = require("localLLM.window")
local prompts = require("localLLM.prompts")
local ollama = require("localLLM.ollama")

local M = {}
local state = require("localLLM.state")

function M.setup(opts)
    config.setup(opts)
end

--- Run a named action (explain, document, ...) on a range of lines.
function M.run(action, line1, line2)
    line1 = line1 or vim.fn.line(".")
    line2 = line2 or line1

    local code = selection.get_lines(line1, line2)
    local filetype = selection.get_filetype()

    local prompt = prompts.build(action, code, filetype)
    if not prompt then
        vim.notify("localLLM: unknown action '" .. action .. "'", vim.log.levels.ERROR)
        return
    end

    window.open()
    window.set_text("Thinking...")
    state.start(action, filetype)

    local first = true
    ollama.generate(
        prompt,
        function(chunk)
            state.chunk()
            if first then
                first = false
                window.set_text("")
            end
            window.append_text(chunk)
        end,
        function(err, stats)
            state.finish(err, stats)
            if not err then return end
            if first then
                window.set_text("**Error:** " .. err)
            else
                window.append_text("\n\n**Error:** " .. err)
            end
        end
    )
end

function M.cancel()
    if ollama.cancel() then
        state.cancel()
        window.append_text("\n\n_Cancelled._")
    else
        vim.notify("localLLM: nothing to cancel", vim.log.levels.INFO)
    end
end

-- Convenience wrappers, handy for user keymaps.
function M.explain(l1, l2) M.run("explain", l1, l2) end

function M.document(l1, l2) M.run("document", l1, l2) end

function M.bugs(l1, l2) M.run("bugs", l1, l2) end

function M.refactor(l1, l2) M.run("refactor", l1, l2) end

function M.tests(l1, l2) M.run("tests", l1, l2) end

return M
