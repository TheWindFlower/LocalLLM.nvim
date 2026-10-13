local config = require("localLLM.config")
local M = {}

local buf = nil
local win = nil

--- Return the response buffer, creating it if needed.
local function ensure_buffer()
    if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf
    end
    buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_name(buf, "localLLM")
    return buf
end

--- Open the response split (or reuse it if already visible).
function M.open()
    ensure_buffer()
    if win and vim.api.nvim_win_is_valid(win) then
        return
    end
    local prev = vim.api.nvim_get_current_win()
    local width = math.floor(vim.o.columns * config.options.window.width)
    vim.cmd("botright " ..width.. "vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.api.nvim_set_current_win(prev) -- keep focus in the code window
end

--- Append text at the end of the buffer, without breaking the current line.
function M.append_text(text)
  ensure_buffer()
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local last_line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1]
  local new_lines = vim.split(text, "\n", { plain = true })

  vim.api.nvim_buf_set_text(buf, last, #last_line, last, #last_line, new_lines)

  -- Keep the view scrolled to the bottom while text streams in.
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
end

--- Replace the buffer contents with the given text.
function M.set_text(text)
    ensure_buffer()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
end

return M
