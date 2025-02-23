local display = require("gitlab.ghost_text.display")
local insert = require("gitlab.ghost_text.insert")

---@class GhostTextAutoCmds
---@field setup fun(group: string): nil
local M = {}

--- Callback for the InsertLeave event.
local function on_insert_leave()
  display.increment_edit_counter()
  display.clear_ghost_text()
end

--- Callback for the CursorMovedI event.
local function on_cursor_moved()
  if insert.suppress_next_cursor_moved then
    insert.suppress_next_cursor_moved = false
    return
  end
  display.increment_edit_counter()
  display.clear_ghost_text()
end

--- Callback for the InsertEnter event.
local function on_insert_enter()
  display.increment_edit_counter()
  display.update_ghost_text(display.edit_counter)
end

--- Callback for the TextChangedI event.
local function on_text_changed()
  if insert.suppress_next_text_changed then
    insert.suppress_next_text_changed = false
    return
  end
  display.increment_edit_counter()
  display.clear_ghost_text()
  display.update_ghost_text_with_debounce(display.edit_counter)
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

