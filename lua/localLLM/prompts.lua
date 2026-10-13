local M = {}

function M.explain(code, filetype)
  return string.format(
    "Explain the following %s code clearly and concisely. "
      .. "Describe what it does and point out anything notable.\n\n```%s\n%s\n```",
    filetype,
    filetype,
    code
  )
end

return M
