local utils            = require("gitlab.utils")
local display          = require("gitlab.ghost_text.display")
local suggestion       = require("gitlab.ghost_text.suggestion")
local insert           = require("gitlab.ghost_text.insert")

---@class GhostTextCommands
---@field namespace number|nil
---@field setup fun(namespace: number): nil
---@field clear_all_ghost_text fun(): nil
---@field insert_ghost_text fun(): nil
---@field insert_line fun(): nil
---@field insert_word fun(): nil
---@field toggle_enabled fun(): nil
---@field restore_line fun(): nil
---@field restore_word fun(): nil
local M                = {
  namespace = nil,
} ---@type GhostTextCommands

--- Setup the module with a given namespace.
--- @param namespace number
M.setup                = function(namespace)
  M.namespace = namespace
end

--- Clears all ghost text in the current buffer.
M.clear_all_ghost_text = function()
  display.clear_ghost_text()
  if M.namespace then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
  end
end

--- Inserts the entire ghost text at the cursor position.
M.insert_ghost_text    = function()
  insert.is_partial_insertion = false
  insert.insert_text(suggestion.text.as_text())
end

--- Inserts the first line from the current suggestion, preserving exact remainder.
M.insert_line          = function()
  if suggestion.stream.active then
    return
  end
  local text = suggestion.text.as_text()
  if text == "" then
    return
  end
  local first_newline = text:find("\n")
  if not first_newline then
    -- No newline: treat as a line insertion.
    insert.partial_insert_text(text, "", "line")
    return
  end
  local partial = text:sub(1, first_newline)
  local remainder = text:sub(first_newline + 1) -- Also remove the newline
  insert.partial_insert_text(partial, remainder, "line")
end

--- Inserts the first "word" from the suggestion, then re-displays the exact remainder.
M.insert_word          = function()
  if suggestion.stream.active then
    return
  end
  local text = suggestion.text.as_text()
  if text == "" then
    return
  end
  -- Find first word including any preceding whitespace
  local first_word_start, first_word_end = text:find("(%s*%S+)")
  if not first_word_start then
    return
  end
  local partial = text:sub(first_word_start, first_word_end)
  local remainder = text:sub(first_word_end + 1)
  insert.partial_insert_text(partial, remainder, "word")
end

--- Toggles ghost text enabled state.
M.toggle_enabled       = function()
  if display.enabled then
    display.enabled = false
    display.increment_edit_counter()
    display.clear_ghost_text()
  else
    display.enabled = true
    display.update_ghost_text(display.edit_counter)
  end
end

--- Restores the last (or only) partial line insertion.
M.restore_line         = function()
  local event = insert.history["line"]
  if not event then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  insert.suppress_next_events()
  local start_row = event.row_before - 1
  local start_col = event.col_before
  local lines = event.lines_inserted or {}
  local num_lines = #lines
  if num_lines == 0 then
    return
  end
  local end_row = start_row + num_lines - 1
  local end_col = (num_lines == 1) and (start_col + #lines[1]) or (#lines[num_lines])
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {})
  vim.api.nvim_win_set_cursor(0, { event.row_before, event.col_before })
  local restored = event.originalSuggestion
  suggestion.text.value = restored
  suggestion.text.show = true
  local splitted = vim.split(restored, "\n")
  display.create_or_update_extmark(splitted)
  insert.history["line"] = nil
end

--- Restores only the last partial word insertion.
M.restore_word         = function()
  local stack = insert.history["word"]
  if not stack or #stack == 0 then
    return
  end
  local event = table.remove(stack)
  local bufnr = vim.api.nvim_get_current_buf()
  insert.suppress_next_events()
  local start_row = event.row_before - 1
  local start_col = event.col_before
  local lines = event.lines_inserted or {}
  local num_lines = #lines
  if num_lines == 0 then
    return
  end
  local end_row = start_row + num_lines - 1
  local end_col = (num_lines == 1) and (start_col + #lines[1]) or (#lines[num_lines])
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {})
  vim.api.nvim_win_set_cursor(0, { event.row_before, event.col_before })
  local restored = event.originalSuggestion
  suggestion.text.value = restored
  suggestion.text.show = true
  local splitted = vim.split(restored, "\n")
  display.create_or_update_extmark(splitted)
end

return M
