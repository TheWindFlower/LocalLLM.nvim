local state = require("localLLM.state")
local config = require("localLLM.config")

local M = {}

-- Minimum window width (columns) at which each optional component is shown.
M.MIN_WIDTH = { elapsed = 38, stats = 54, context = 70 }

local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local TICK_MS = 100
local MARQUEE_EVERY = 3 -- ticks per marquee step
local MARQUEE_PAUSE = 5 -- steps to rest at the start of each cycle

local tick = 0
local timer = nil
local last_version = -1

local LABELS = {
  idle = { icon = "○", text = "Idle", hl = "Comment" },
  thinking = { text = "Thinking", hl = "DiagnosticWarn", spin = true },
  streaming = { text = "Streaming", hl = "DiagnosticInfo", spin = true },
  done = { icon = "✔", text = "Done", hl = "DiagnosticOk" },
  error = { icon = "✘", text = "Error", hl = "DiagnosticError" },
  cancelled = { icon = "■", text = "Cancelled", hl = "DiagnosticHint" },
}

local function hl_attr(name, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl and hl[attr] then
    return string.format("#%06x", hl[attr])
  end
  return fallback
end

--- Width of the window whose statusline is being drawn.
function M.width()
  local winid = vim.g.statusline_winid
  if winid and vim.api.nvim_win_is_valid(winid) then
    return vim.api.nvim_win_get_width(winid)
  end
  return vim.o.columns
end

function M.state()
  local label = LABELS[state.status]
  local icon = label.spin and SPINNER[tick % #SPINNER + 1] or label.icon
  return icon .. " " .. label.text
end

function M.state_color()
  return {
    fg = hl_attr("Normal", "bg", "#1e1e2e"),
    bg = hl_attr(LABELS[state.status].hl, "fg", "#888888"),
    gui = "bold",
  }
end

--- Model name; scrolls like a marquee when longer than model_width.
function M.model()
  local name = config.options.model
  local width = config.options.statusline.model_width
  if vim.fn.strchars(name) <= width then
    return name
  end
  local loop = name .. "   "
  local n = vim.fn.strchars(loop)
  local step = math.floor(tick / MARQUEE_EVERY) % (n + MARQUEE_PAUSE)
  local offset = math.max(0, step - MARQUEE_PAUSE) -- rests at the start, then scrolls
  return vim.fn.strcharpart(loop .. loop, offset, width)
end

function M.context()
  local parts = {}
  if state.action then parts[#parts + 1] = state.action end
  if state.filetype then parts[#parts + 1] = state.filetype end
  return table.concat(parts, " · ")
end

function M.stats()
  local tokens = state.tokens()
  if tokens == 0 then return "" end
  local out = tokens .. " tok"
  local tps = state.tps()
  if tps then
    out = out .. string.format(" %.0f t/s", tps)
  end
  return out
end

function M.elapsed()
  local secs = state.elapsed()
  if not secs then return "" end
  if secs < 60 then
    return string.format("%.1fs", secs)
  end
  return string.format("%dm%02ds", math.floor(secs / 60), math.floor(secs % 60))
end

--- Start the redraw timer (idempotent). It drives the spinner, the marquee,
--- and the live elapsed time, and stops itself when the window closes.
function M.start()
  if timer then return end
  timer = vim.uv.new_timer()
  timer:start(0, TICK_MS, vim.schedule_wrap(function()
    if not require("localLLM.window").is_open() then
      M.stop()
      return
    end
    tick = tick + 1
    local scrolling = vim.fn.strchars(config.options.model) > config.options.statusline.model_width
    local changed = state.version ~= last_version
    if state.is_running() or scrolling or changed then
      last_version = state.version
      pcall(function()
        require("lualine").refresh({ place = { "statusline" } })
      end)
    end
  end))
end

function M.stop()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

return M
