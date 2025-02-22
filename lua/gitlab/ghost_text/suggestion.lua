local lsp = require('gitlab.ghost_text.lsp')

---@class GhostTextSuggestions
---@field text {
---value: string,
---show: boolean|nil,
---as_text: fun(): string
---}
---@field stream {
---active: boolean, id: number|nil, buffer: string,
--- start_new_stream: fun(new_stream_id: number): nil,
--- cancel_streaming: fun(): nil,
--- finish_streaming: fun(): nil,
--- display_streaming_suggestion: fun(value: string): nil,
--- handle_streaming_response: fun(err: any, result: { id?: number, completion?: string, done?: boolean }): nil,
--- cancel_streaming: fun(): nil,
--- finish_streaming: fun(): nil,
--- create_or_update_extmark: fun(lines: string[]): nil,
--- }
local M = {} ---@type GhostText

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

--- Handles the streaming response from the LSP.
--- @param err any
--- @param result { id?: number, completion?: string, done?: boolean }
M.handle_streaming_response = function(err, result)
  if err then
    M.finish_streaming()
    return
  end
  if not result.id or result.id ~= M.stream.id then
    return
  end
  if not M.stream.active then
    return
  end
  if result.completion then
    M.stream.buffer = result.completion
    M.display_streaming_suggestion(M.stream.buffer)
  end
  if result.done then
    M.finish_streaming()
  end
end

--- Starts a new streaming session.
--- @param new_stream_id number
M.stream.start_new_stream = function(new_stream_id)
  M.text.show = true
  if M.stream.active then
    M.cancel_streaming()
  end
  M.stream.id = new_stream_id
  M.stream.active = true
  M.stream.buffer = ''
end

--- Cancels the current streaming session.
M.stream.cancel_streaming = function()
  if M.stream.active and M.stream.id then
    lsp.notify('cancelStreaming', M.stream.id)
    M.finish_streaming()
  end
end

--- Finishes the current streaming session.
M.stream.finish_streaming = function()
  M.stream.active = false
  M.stream.id = nil
  M.text.value = M.stream.buffer -- Preserve the last streamed suggestion.
end

--- Displays the streaming suggestion by updating extmarks.
--- @param value string
M.stream.display_streaming_suggestion = function(value)
  local lines = vim.split(value, '\n')
  M.create_or_update_extmark(lines)
end

-- Alias the streaming cancel/finish functions at the module level
M.cancel_streaming = M.stream.cancel_streaming
M.finish_streaming = M.stream.finish_streaming

--- Stub for creating or updating extmarks.
--- @param lines string[]
M.create_or_update_extmark = function(lines)
  -- Implementation goes here.
end

return M
