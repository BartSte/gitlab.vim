local writer = require("gitlab.ghost_text.writer")

local M = {}

local function on_insert_leave()
  writer.increment_edit_counter()
  writer.clear_ghost_text()
end

local function on_cursor_moved()
  if writer.suppress_next_cursor_moved then
    writer.suppress_next_cursor_moved = false
    return
  end
  writer.increment_edit_counter()
  writer.clear_ghost_text()
end

local function on_insert_enter()
  writer.increment_edit_counter()
  writer.update_ghost_text(writer.edit_counter)
end

local function on_text_changed()
  if writer.suppress_next_text_changed then
    writer.suppress_next_text_changed = false
    return
  end
  writer.increment_edit_counter()
  writer.clear_ghost_text()
  writer.update_ghost_text_with_debounce(writer.edit_counter)
end

M.setup = function(group)
  local augroup_id = vim.api.nvim_create_augroup(group, { clear = true })
  vim.api.nvim_create_autocmd('InsertEnter', { group = augroup_id, callback = on_insert_enter })
  vim.api.nvim_create_autocmd('InsertLeave', { group = augroup_id, callback = on_insert_leave })
  vim.api.nvim_create_autocmd('TextChangedI', { group = augroup_id, callback = on_text_changed })
  vim.api.nvim_create_autocmd('CursorMovedI', { group = augroup_id, callback = on_cursor_moved })
end

return M
