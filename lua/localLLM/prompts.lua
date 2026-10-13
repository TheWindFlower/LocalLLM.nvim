local config = require("localLLM.config")

local M = {}

--- Build the full prompt for an action, or nil if the action is unknown.
function M.build(action, code, filetype)
  local template = config.options.prompts[action]
  if not template then
    return nil
  end

  -- Function replacement avoids gsub treating "%" in the filetype specially.
  local instruction = template:gsub("{filetype}", function() return filetype end)

  return string.format("%s\n\n```%s\n%s\n```", instruction, filetype, code)
end

return M
