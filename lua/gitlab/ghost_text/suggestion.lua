local lsp = require('gitlab.ghost_text.lsp')

---@class GhostTextSuggestions
---@field text { value: string, show: boolean|nil, as_text: fun(): string }
---@field stream { active: boolean, id: number|nil, buffer: string, start: fun(new_stream_id: number), cancel: fun(), finish: fun() }
local M = {}

M.text = {
  value = "",
  show = nil,
  --- Returns the text to be inserted.
  --- @return string
  as_text = function()
    if not M.text.show then
      return ""
    end
    local text_to_insert = (M.stream.buffer ~= '') and M.stream.buffer or M.text.value
    if not text_to_insert then
      return ""
    end
    return text_to_insert
  end,
}

M.stream = {
  active = false,
  id = nil,
  buffer = '',
}

--- Starts a new streaming session.
--- @param new_stream_id number
M.stream.start = function(new_stream_id)
  M.text.show = true
  if M.stream.active then
    M.stream.cancel()
  end
  M.stream.id = new_stream_id
  M.stream.active = true
  M.stream.buffer = ''
end

--- Cancels the current streaming session.
M.stream.cancel = function()
  if M.stream.active and M.stream.id then
    lsp.notify('cancelStreaming', M.stream.id)
    M.stream.finish()
  end
end

--- Finishes the current streaming session.
M.stream.finish = function()
  M.stream.active = false
  M.stream.id = nil
  M.text.value = M.stream.buffer -- Preserve the last streamed suggestion.
end

return M
