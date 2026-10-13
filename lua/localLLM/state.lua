local M = {
  status = "idle", -- idle | thinking | streaming | done | error | cancelled
  action = nil,
  filetype = nil,
  started_at = nil,
  first_chunk_at = nil,
  ended_at = nil,
  chunks = 0,
  stats = nil, -- final stats object from Ollama
  version = 0, -- bumped on every change, so the statusline knows when to redraw
}

local function now()
  return vim.uv.hrtime() / 1e9
end

local function bump()
  M.version = M.version + 1
end

function M.start(action, filetype)
  M.status = "thinking"
  M.action = action
  M.filetype = filetype
  M.started_at = now()
  M.first_chunk_at = nil
  M.ended_at = nil
  M.chunks = 0
  M.stats = nil
  bump()
end

function M.chunk()
  if M.status == "thinking" then
    M.status = "streaming"
    M.first_chunk_at = now()
  end
  M.chunks = M.chunks + 1
  bump()
end

function M.finish(err, stats)
  M.ended_at = now()
  M.status = err and "error" or "done"
  M.stats = stats
  bump()
end

function M.cancel()
  M.ended_at = now()
  M.status = "cancelled"
  bump()
end

function M.is_running()
  return M.status == "thinking" or M.status == "streaming"
end

--- Seconds since the request started (frozen once it ends).
function M.elapsed()
  if not M.started_at then return nil end
  return (M.ended_at or now()) - M.started_at
end

--- Exact count from Ollama when finished; chunk count while streaming.
function M.tokens()
  if M.stats and M.stats.eval_count then
    return M.stats.exal_count
  end
  return M.chunks
end

--- Tokens per second: exact from Ollama when finished, estimated while streaming.
function M.tps()
  local s = M.stats
  if s and s.eval_count and s.eval_duration and s.eval_duration > 0 then
    return s.eval_count / (s.eval_duration / 1e9)
  end
  if M.first_chunk_at and M.chunks > 1 then
    local dt = (M.ended_at or now()) - M.first_chunk_at
    if dt > 0.25 then return M.chunks / dt end
  end
  return nil
end

return M
