local lsp = require('gitlab.ghost_text.lsp')

local M = {}

M.text = {
  value = "",
  show = nil,
  as_text = function()
    if not M.text.show then
      return ""
    end
    local text_to_insert = (M.stream.buffer ~= '') and M.stream.buffer or M.text.value
    if not text_to_insert then
      return ""
    end
    return text_to_insert
  end
}

M.stream = {
  active = false,
  id = nil,
  buffer = '',
}

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

M.stream.start_new_stream = function(new_stream_id)
  M.text.show = true
  if M.stream.active then
    M.cancel_streaming()
  end
  M.stream.id = new_stream_id
  M.stream.active = true
  M.stream.buffer = ''
end

M.stream.cancel_streaming = function()
  if M.stream.active and M.stream.id then
    lsp.notify('cancelStreaming', M.stream.id)
    M.finish_streaming()
  end
end

M.stream.finish_streaming = function()
  M.stream.active = false
  M.stream.id = nil
  M.text.value = M.stream.buffer -- Preserve the last streamed suggestion.
end

M.stream.display_streaming_suggestion = function(value)
  local lines = vim.split(value, '\n')
  M.create_or_update_extmark(lines)
end

return M
