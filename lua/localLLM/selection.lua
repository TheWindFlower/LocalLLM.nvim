local M = {}

--- Return the lines between line1 and line2 (1-indexed, inclusive) as one string.
function M.get_lines(line1, line2)
    local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
    return table.concat(lines, "\n")
end

--- Return the current buffer's filetype, falling back to "text".
function M.get_filetype()
    local ft = vim.bo.filetype
    if ft == nil or ft == "" then
        return "text"
    end
    return ft
end

function M.get_file()
    return M.get_lines(1, vim.api.nvim_buf_line_count(0))
end
return M
