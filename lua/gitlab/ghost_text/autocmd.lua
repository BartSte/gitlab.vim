local writer = require("gitlab.ghost_text.writer")

---@class GhostTextAutoCmds
---@field setup fun(group: string): nil
local M = {}

--- Callback for the InsertLeave event.
local function on_insert_leave()
  writer.increment_edit_counter()
  writer.clear_ghost_text()
end

--- Callback for the CursorMovedI event.
local function on_cursor_moved()
  if writer.suppress_next_cursor_moved then
    writer.suppress_next_cursor_moved = false
    return
  end
  writer.increment_edit_counter()
  writer.clear_ghost_text()
end

--- Callback for the InsertEnter event.
local function on_insert_enter()
  writer.increment_edit_counter()
  writer.update_ghost_text(writer.edit_counter)
end

--- Callback for the TextChangedI event.
local function on_text_changed()
  if writer.suppress_next_text_changed then
    writer.suppress_next_text_changed = false
    return
  end
  writer.increment_edit_counter()
  writer.clear_ghost_text()
  writer.update_ghost_text_with_debounce(writer.edit_counter)
end

--- Sets up the autocommands for ghost text handling.
--- @param group string The name of the augroup to create.
M.setup = function(group)
  local augroup_id = vim.api.nvim_create_augroup(group, { clear = true })
  vim.api.nvim_create_autocmd('InsertEnter', { group = augroup_id, callback = on_insert_enter })
  vim.api.nvim_create_autocmd('InsertLeave', { group = augroup_id, callback = on_insert_leave })
  vim.api.nvim_create_autocmd('TextChangedI', { group = augroup_id, callback = on_text_changed })
  vim.api.nvim_create_autocmd('CursorMovedI', { group = augroup_id, callback = on_cursor_moved })
end

return M

