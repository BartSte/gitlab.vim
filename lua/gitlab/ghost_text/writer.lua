local lsp                         = require("gitlab.ghost_text.lsp")
local suggestion                  = require("gitlab.ghost_text.suggestion")

---@class GhostTextWriter
---@field edit_counter number
---@field enabled boolean
---@field history table<string,
---@field is_partial_insertion boolean
---@field namespace number|nil
---@field suppress_next_cursor_moved boolean
---@field suppress_next_text_changed boolean
---@field is_requesting boolean
---@field setup fun(namespace: number): nil
---@field debounce fun(func: fun(...): nil): fun(...): nil
---@field create_or_update_extmark fun(lines: string[]): nil
---@field insert_text fun(text: string): nil
---@field partial_insert_text fun(partial: string, remainder: string, insertion_type: string): nil
---@field suppress_next_events fun(): nil
---@field increment_edit_counter fun(): nil
---@field clear_ghost_text fun(): nil
---@field debounce_update_ghost_text fun(counter: number): nil
---@field update_ghost_text_with_debounce fun(counter: number): nil
---@field update_ghost_text fun(counter: number): nil
---@field make_callback fun(counter: number): fun(err: any, result: any): nil
---@field display_suggestion fun(suggestions: any[]): nil
local M                           = {}

M.edit_counter                    = 0
M.enabled                         = true
M.history                         = { word = {}, line = nil }
M.is_partial_insertion            = false
M.namespace                       = nil
M.suppress_next_cursor_moved      = false
M.suppress_next_text_changed      = false
M.is_requesting                   = false

--- Sets up the ghost text module with the given namespace.
--- @param namespace number
M.setup                           = function(namespace)
  M.namespace = namespace
end

local debounce_delay              = 80 -- milliseconds
local ghost_text_extmark_id       = nil
local update_timer                = nil

--- Creates a debounced version of the provided function.
--- @param func fun(...): nil
--- @return fun(...): nil
M.debounce                        = function(func)
  return function(...)
    local args = { ... }
    if update_timer then
      vim.fn.timer_stop(update_timer)
    end
    update_timer = vim.fn.timer_start(debounce_delay, function()
      func(unpack(args))
      update_timer = nil
    end)
  end
end

--- Creates or updates an extmark for ghost text.
--- @param lines string[]
M.create_or_update_extmark        = function(lines)
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local virt_text = { { lines[1] } }
  local virt_lines = {}
  for i = 2, #lines do
    table.insert(virt_lines, { { lines[i], "GitLabGhostText" } })
  end
  local opts = {
    virt_text = virt_text,
    virt_text_pos = 'overlay',
    virt_lines = virt_lines,
    virt_lines_above = false,
    hl_mode = 'combine',
    priority = 100,
  }
  if ghost_text_extmark_id then
    vim.api.nvim_buf_del_extmark(bufnr, M.namespace, ghost_text_extmark_id)
  end
  ghost_text_extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.namespace, row - 1, col, opts)
end

--- Inserts text at the current cursor position.
--- If not performing a partial insertion, it will clear ghost text and cancel streaming.
--- @param text string
M.insert_text                     = function(text)
  if not text or text == "" then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.split(text, '\n')
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
  local new_row = row + #lines - 1
  local new_col = (#lines > 1) and (#lines[#lines]) or (col + #lines[1])
  vim.api.nvim_win_set_cursor(0, { new_row, new_col })
  if not M.is_partial_insertion then
    M.clear_ghost_text()
    if suggestion.stream.active then
      suggestion.stream.cancel()
    end
  end
end

--- Performs a partial insertion and updates insertion history.
--- @param partial string The text to be inserted.
--- @param remainder string The leftover ghost text.
--- @param insertion_type string Either "word" or "line".
M.partial_insert_text             = function(partial, remainder, insertion_type)
  if partial == "" then
    return
  end
  M.suppress_next_events()
  local row_before, col_before = unpack(vim.api.nvim_win_get_cursor(0))
  M.is_partial_insertion = true
  M.insert_text(partial) -- This moves the cursor forward.
  M.is_partial_insertion = false
  if insertion_type == "word" then
    M.history["line"] = nil
    if not M.history["word"] then
      M.history["word"] = {}
    end
    local event = {
      insertionType = insertion_type,
      partial = partial,                         -- inserted word
      remainder = remainder,                     -- leftover ghost text
      originalSuggestion = partial .. remainder, -- state before insertion
      row_before = row_before,
      col_before = col_before,
      lines_inserted = vim.split(partial, "\n"),
    }
    table.insert(M.history["word"], event)
  elseif insertion_type == "line" then
    -- Clear any pending word insertion history.
    M.history["word"] = {}
    M.history["line"] = {
      insertionType = insertion_type,
      partial = partial,
      remainder = remainder,
      originalSuggestion = partial .. remainder,
      row_before = row_before,
      col_before = col_before,
      lines_inserted = vim.split(partial, "\n"),
    }
  end
  if remainder ~= "" then
    suggestion.text.show = true
    suggestion.text.value = remainder
    local lines = vim.split(remainder, "\n")
    M.create_or_update_extmark(lines)
  else
    suggestion.text.show = false
    suggestion.text.value = nil
    M.clear_ghost_text()
  end
end

--- Suppresses the next on_text_changed and on_cursor_moved events.
M.suppress_next_events            = function()
  M.suppress_next_text_changed = true
  M.suppress_next_cursor_moved = true
end

--- Increments the edit counter.
M.increment_edit_counter          = function()
  M.edit_counter = M.edit_counter + 1
end

--- Clears ghost text from the buffer and resets suggestion display.
M.clear_ghost_text                = function()
  if M.namespace and ghost_text_extmark_id then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_del_extmark(bufnr, M.namespace, ghost_text_extmark_id)
    ghost_text_extmark_id = nil
  end
  if not suggestion.stream.active then
    suggestion.stream.buffer = ''
  end
  suggestion.text.show = false
end

--- A helper that calls update_ghost_text with the given counter.
--- @param counter number
M.debounce_update_ghost_text      = function(counter)
  M.update_ghost_text(counter)
end

M.update_ghost_text_with_debounce = M.debounce(M.debounce_update_ghost_text)

--- Updates the ghost text if the edit counter matches and the client and namespace are available.
--- @param counter number
M.update_ghost_text               = function(counter)
  if not M.enabled then
    return
  end
  if M.edit_counter ~= counter then
    return
  end
  if lsp.client == nil or not M.namespace then
    return
  end
  if suggestion.stream.active then
    suggestion.stream.cancel()
  end
  lsp.request_completion(M.make_callback(counter))
end

--- Creates a callback for the LSP request that processes completion results.
--- @param counter number
--- @return fun(err: any, result: any): nil
M.make_callback                   = function(counter)
  return function(err, result)
    if M.edit_counter ~= counter then
      return
    end
    M.is_requesting = false
    if err then
      M.clear_ghost_text()
      return
    end
    if not result or #result.items == 0 then
      M.clear_ghost_text()
      return
    end
    if result.items[1].command and result.items[1].command.command == 'gitlab.ls.startStreaming' then
      local new_stream_id = result.items[1].command.arguments[1]
      suggestion.stream.start(new_stream_id)
    else
      M.display_suggestion(result.items)
    end
  end
end

--- Displays a suggestion by updating ghost text.
--- @param suggestions any[]
M.display_suggestion              = function(suggestions)
  suggestion.text.show = true
  if #suggestions == 0 then
    return
  end
  suggestion.text.value = suggestions[1].insertText
  local lines = vim.split(suggestion.text.value, '\n')
  M.create_or_update_extmark(lines)
end

--- Displays the streaming suggestion by updating extmarks.
--- @param value string
M.display_streaming_suggestion    = function(value)
  local lines = vim.split(value, '\n')
  M.create_or_update_extmark(lines)
end

--- Handles the streaming response from the LSP.
--- @param err any
--- @param result { id?: number, completion?: string, done?: boolean }
M.handle_streaming_response       = function(err, result)
  if err then
    suggestion.stream.finish()
    return
  end
  if not result.id or result.id ~= suggestion.stream.id then
    return
  end
  if not suggestion.stream.active then
    return
  end
  if result.completion then
    suggestion.stream.buffer = result.completion
    M.display_streaming_suggestion(suggestion.stream.buffer)
  end
  if result.done then
    suggestion.stream.finish()
  end
end

return M
