local sl = require("localLLM.statusline")

local function at_least(key)
  return function()
    return sl.width() >= sl.MIN_WIDTH[key]
  end
end

-- A function, so each call returns fresh tables (lualine mutates what it loads).
local function build_sections()
  return {
    lualine_a = { { sl.state, color = sl.state_color } },
    lualine_b = { sl.model },
    lualine_c = { { sl.context, cond = at_least("context") } },
    lualine_x = { { sl.stats, cond = at_least("stats") } },
    lualine_y = { { sl.elapsed, cond = at_least("elapsed") } },
    lualine_z = {},
  }
end

return {
  sections = build_sections(),
  inactive_sections = build_sections(), -- the chat window is usually unfocused
  filetypes = { "localllm" },
}
