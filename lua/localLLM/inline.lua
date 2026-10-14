local config = require("localLLM.config")
local selection = require("localLLM.selection")
local ollama = require("localLLM.ollama")
local state = require("localLLM.state")

local M = {}

local ns = vim.api.nvim_create_namespace("localLLM_inline")
local active = nil -- the run in progress: { buf, mark, ... }

local MARK_OPTS = {
  virt_text = { { "  ⠶ localLLM writing…", "Comment" } },
  virt_text_pos = "eol",
}

--- Clear the "writing…" marker. Returns true if a run was active.
function M.cleanup()
  local was_active = active ~= nil
  if active and vim.api.nvim_buf_is_valid(active.buf) then
    vim.api.nvim_buf_clear_namespace(active.buf, ns, 0, -1)
  end
  active = nil
  return was_active
end

--- Build the code context around the insertion point, with a marker line.
local function build_context(buf, insert_row, skip_row)
  local opts = config.options.inline
  local total = vim.api.nvim_buf_line_count(buf)

  local before_from = math.max(0, insert_row - opts.context_before)
  local before = vim.api.nvim_buf_get_lines(buf, before_from, insert_row, false)

  local after_from = insert_row + (skip_row and 1 or 0)
  local after_to = math.min(total, after_from + opts.context_after)
  local after = vim.api.nvim_buf_get_lines(buf, after_from, after_to, false)

  local parts = {}
  vim.list_extend(parts, before)
  parts[#parts + 1] = "<INSERT_HERE>"
  vim.list_extend(parts, after)
  return table.concat(parts, "\n")
end

local function build_prompt(request, filetype, name, context)
  return string.format(
    "File: %s (%s)\n\n"
      .. "The marker <INSERT_HERE> shows where the new code will be inserted:\n\n"
      .. "```%s\n%s\n```\n\nRequest: %s",
    name, filetype, filetype, context, request
  )
end

--- Insert whole lines after the anchor line, then move the anchor to the last
--- inserted line. The anchor is an extmark, so edits above it can't misplace us.
local function insert_lines(ctx, lines)
  if #lines == 0 then return end
  if not vim.api.nvim_buf_is_valid(ctx.buf) then
    ollama.cancel()
    return
  end

  local row = vim.api.nvim_buf_get_extmark_by_id(ctx.buf, ns, ctx.mark, {})[1]
  local ok, err = pcall(function()
    if ctx.count > 0 then
      -- merge with the previous insertion so one `u` undoes everything
      vim.api.nvim_buf_call(ctx.buf, function() pcall(vim.cmd, "undojoin") end)
    end
    if ctx.replace_blank then
      vim.api.nvim_buf_set_lines(ctx.buf, row, row + 1, false, lines)
      row = row + #lines - 1
      ctx.replace_blank = false
    else
      vim.api.nvim_buf_set_lines(ctx.buf, row + 1, row + 1, false, lines)
      row = row + #lines
    end
  end)

  if not ok then
    ollama.cancel()
    M.cleanup()
    vim.notify("localLLM: could not insert code: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  ctx.count = ctx.count + #lines
  vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, 0, vim.tbl_extend("force", MARK_OPTS, { id = ctx.mark }))
end

--- Filter complete lines (drop fences, leading/trailing blanks), then insert them.
local function push_lines(ctx, lines)
  local out = {}
  for _, line in ipairs(lines) do
    if ctx.strip_fences and line:match("^%s*```") then
      -- drop fence lines
    elseif line:match("^%s*$") then
      ctx.blank = ctx.blank + 1 -- hold blanks until we know more text follows
    else
      if ctx.started then
        for _ = 1, ctx.blank do out[#out + 1] = "" end
      end
      ctx.blank = 0
      ctx.started = true
      out[#out + 1] = line
    end
  end
  insert_lines(ctx, out)
end

local function start(buf, cursor_row, filetype, request)
  M.cleanup()

  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  if name == "" then name = "[No Name]" end

  local line = vim.api.nvim_buf_get_lines(buf, cursor_row, cursor_row + 1, false)[1] or ""
  local replace_blank = line:match("^%s*$") ~= nil
  local insert_row = replace_blank and cursor_row or cursor_row + 1

  local context = build_context(buf, insert_row, replace_blank)
  local prompt = build_prompt(request, filetype, name, context)

  local ctx = {
    buf = buf,
    count = 0,
    pending = "",
    blank = 0,
    started = false,
    replace_blank = replace_blank,
    strip_fences = filetype ~= "markdown", -- fences are legitimate content in markdown
  }
  ctx.mark = vim.api.nvim_buf_set_extmark(buf, ns, cursor_row, 0, MARK_OPTS)
  active = ctx

  state.start("inline", filetype)
  local cfg = config.options.inline

  ollama.generate(prompt, function(chunk)
    state.chunk()
    ctx.pending = ctx.pending .. chunk
    local lines = {}
    while true do
      local nl = ctx.pending:find("\n", 1, true)
      if not nl then break end
      lines[#lines + 1] = ctx.pending:sub(1, nl - 1)
      ctx.pending = ctx.pending:sub(nl + 1)
    end
    push_lines(ctx, lines)
  end, function(err, stats)
    state.finish(err, stats)
    if ctx.pending ~= "" then
      push_lines(ctx, { ctx.pending })
      ctx.pending = ""
    end
    M.cleanup()
    if err then
      vim.notify("localLLM: " .. err, vim.log.levels.ERROR)
    end
  end, {
    system = cfg.system,
    options = { temperature = cfg.temperature },
  })
end

--- Generate code at the cursor. `request` is optional: without it, we ask for one.
function M.run(request)
  local buf = vim.api.nvim_get_current_buf()
  if not vim.bo[buf].modifiable then
    vim.notify("localLLM: buffer is not modifiable", vim.log.levels.WARN)
    return
  end

  -- Capture everything now: the input prompt may move focus (floating inputs).
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local filetype = selection.get_filetype()

  if request and request ~= "" then
    start(buf, cursor_row, filetype, request)
    return
  end

  vim.ui.input({ prompt = "Inline request: " }, function(input)
    if input and input ~= "" then
      start(buf, cursor_row, filetype, input)
    end
  end)
end

return M
