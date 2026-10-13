local config = require("localLLM.config")

local M = {}

M.job = nil
M.request_id = 0

--- Stream a response from Ollama.
--- on_chunk(text) is called for each piece of generated text.
--- on_done(err) is called once at the end; err is nil on success.
function M.generate(prompt, on_chunk, on_done)
    -- Only one request at a time: kill any previous one.
    if M.job then
        pcall(function() M.job:kill(15) end)
    end
    M.request_id = M.request_id + 1
    local id = M.request_id

    local pending = ""
    local finished = false

    local function finish(err)
        if finished then return end
        finished = true
        if id == M.request_id then
            M.job = nil
        end
        on_done(err)
    end

    local function handle_line(line)
        if finished or line == "" then return end
        local ok, decoded = pcall(vim.json.decode, line)
        if not ok then
            return finish("Invalid JSON from Ollama: " .. line)
        end
        if decoded.error then
            return finish(decoded.error)
        end
        if decoded.response and decoded.response ~= "" then
            on_chunk(decoded.response)
        end
        if decoded.done then
            finish(nil)
        end
    end

    local body = vim.json.encode({
        model = config.options.model,
        prompt = prompt,
        stream = true,
    })

    M.job = vim.system({
        "curl", "-sS", "-N", "-X", "POST",
        config.options.host .. "/api/generate",
        "-H", "Content-Type: application/json",
        "--data-binary", "@-",
    }, {
        text = true,
        stdin = body,
        stdout = function(_, data)
            if not data then return end
            vim.schedule(function()
                if id ~= M.request_id or finished then return end
                pending = pending .. data
                while true do
                    local nl = pending:find("\n", 1, true)
                    if not nl then break end
                    local line = pending:sub(1, nl - 1)
                    pending = pending:sub(nl + 1)
                    handle_line(line)
                end
            end)
        end,
    }, function(result)
        vim.schedule(function()
            if id ~= M.request_id then return end -- superseded by a newer request
            if result.code ~= 0 then
                finish("curl failed (exit " .. result.code .. "): " .. (result.stderr or ""))
            else
                finish(nil)
            end
        end)
    end)
end

--- Stop the running request, if any. Returns true if something was cancelled.
function M.cancel()
    if not M.job then
        return false
    end
    pcall(function() M.job:kill(15) end)
    M.job = nil
    M.request_id = M.request_id + 1 -- makes queued callbacks from the old request bail out
    return true
end

return M
