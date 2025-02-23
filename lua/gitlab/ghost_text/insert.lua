local suggestion             = require("gitlab.ghost_text.suggestion")
local display                = require("gitlab.ghost_text.display")

---@class GhostTextInsert
---@field insert_text fun(text: string): nil
---@field partial_insert_text fun(partial: string, remainder: string, insertion_type: string): nil
---@field suppress_next_events fun(): nil
local M                      = {}

M.history                    = { word = {}, line = nil }
M.is_partial_insertion       = false
M.suppress_next_cursor_moved = false
M.suppress_next_text_changed = false

--- Inserts text at the current cursor position.
--- If not performing a partial insertion, it will clear ghost text and cancel streaming.
--- @param text string
M.insert_text                = function(text)
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
    display.clear_ghost_text()
    if suggestion.stream.active then
      suggestion.stream.cancel()
    end
  end
end

--- Performs a partial insertion and updates insertion history.
--- @param partial string The text to be inserted.
--- @param remainder string The leftover ghost text.
--- @param insertion_type string Either "word" or "line".
M.partial_insert_text        = function(partial, remainder, insertion_type)
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
    display.create_or_update_extmark(lines)
  else
    suggestion.text.show = false
    suggestion.text.value = nil
    display.clear_ghost_text()
  end
end

--- Suppresses the next on_text_changed and on_cursor_moved events.
M.suppress_next_events       = function()
  M.suppress_next_text_changed = true
  M.suppress_next_cursor_moved = true
end

return M
