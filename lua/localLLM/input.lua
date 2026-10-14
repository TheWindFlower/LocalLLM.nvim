local config = require("localLLM.config")

local M = {}

local history = {}
local MAX_HISTORY = 50

--- Open a tiny floating input near the cursor.
--- on_submit(text) is called with the trimmed text; on cancel nothing is called.
function M.open(on_submit)
    local opts = config.options.inline.input
    local prev_win = vim.api.nvim_get_current_win()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "localllm_input"

    -- local win_opts = {
    --   relative = "cursor",
    --   row = 1,
    --   col = 0,
    --   width = math.min(opts.width, vim.o.columns - 4),
    --   height = 1,
    --   style = "minimal",
    --   border = opts.border,
    -- }
    -- -- Titles and footers are only allowed when there is a border.
    -- if opts.border ~= "none" then
    --   win_opts.title = " localLLM · inline "
    --   win_opts.title_pos = "center"
    --   win_opts.footer = " ⏎ run  ⎋ cancel  ↑↓ history "
    --   win_opts.footer_pos = "right"
    -- end


    local win_opts = {
        relative = "cursor",
        row = 1,
        col = 0,
        width = math.max(1, math.min(opts.width, vim.o.columns - 4)),
        height = 1,
        style = "minimal",
        border = opts.border or "rounded",

        title = " localLLM ",
        title_pos = "center",

        footer = " ↵ Submit  ·  Esc Cancel  ·  ↑↓ History ",
        footer_pos = "right",

        zindex = 50,

       -- winhighlight = table.concat({
       --     "Normal:NormalFloat",
       --     "FloatBorder:FloatBorder",
       --     "FloatTitle:FloatTitle",
       --     "FloatFooter:FloatFooter",
       -- }, ","),
    }

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].cursorline = false
    vim.wo[win].colorcolumn = ""


    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.wo[win].wrap = false

    local closed = false
    local function close()
        if closed then return end
        closed = true
        local was_current = vim.api.nvim_get_current_win() == win
        vim.cmd("stopinsert")
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        -- Only give focus back if the user was still in the box.
        if was_current and vim.api.nvim_win_is_valid(prev_win) then
            vim.api.nvim_set_current_win(prev_win)
        end
    end

    local function submit()
        local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), " "))
        close()
        if text == "" then return end
        if history[#history] ~= text then
            history[#history + 1] = text
            if #history > MAX_HISTORY then table.remove(history, 1) end
        end
        vim.schedule(function() on_submit(text) end)
    end

    -- History: idx == #history + 1 means "the text being typed".
    local idx = #history + 1
    local draft = ""
    local function recall(delta)
        if idx == #history + 1 then
            draft = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
        end
        idx = math.max(1, math.min(#history + 1, idx + delta))
        local text = history[idx] or draft
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
        vim.api.nvim_win_set_cursor(win, { 1, #text })
    end

    local function map(lhs, fn)
        vim.keymap.set({ "i", "n" }, lhs, fn, { buffer = buf, nowait = true })
    end
    map("<CR>", submit)
    map("<Esc>", close)
    map("<C-c>", close)
    map("<Up>", function() recall(-1) end)
    map("<C-p>", function() recall(-1) end)
    map("<Down>", function() recall(1) end)
    map("<C-n>", function() recall(1) end)

    -- Clicking or jumping to another window dismisses the box.
    vim.api.nvim_create_autocmd("WinLeave", {
        buffer = buf,
        once = true,
        callback = function() vim.schedule(close) end,
    })

    vim.cmd("startinsert")
end

return M
