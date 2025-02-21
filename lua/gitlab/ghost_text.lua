local utils = require("gitlab.utils")


local M = {
  -- Used for dependency injection
  vim = vim,
}

local ns

local last_suggestion
local update_timer = nil

local debounce_delay = 80 -- milliseconds
local ghost_text_extmark_id = nil
local suggestion_shown = nil
local group = 'GitLabGhostText'
local stream_id = nil
local stream_buffer = ''

-- Flags to help skip events and partial-insert logic
M.suppress_next_text_changed = false
M.suppress_next_cursor_moved = false
M.isPartialInsertion = false

-- We keep separate histories:
-- For word insertions, we use a stack (an array)

-- For line insertions, only one event is stored.
M.partial_insertion_history = { word = {}, line = nil }

local function setup_highlights()
  M.vim.api.nvim_set_hl(0, group, { fg = '#808080', italic = true })
  M.vim.api.nvim_set_hl(0, 'GitLabIcon', { fg = '#FC6D26' })
end

local function debounce(func)
  return function(...)
    local args = { ... }
    if update_timer then
      M.vim.fn.timer_stop(update_timer)
    end
    update_timer = M.vim.fn.timer_start(debounce_delay, function()
      func(unpack(args))
      update_timer = nil
    end)
  end
end


M.setup = function(lsp_client, cfg)
  if not cfg or not cfg.enabled then
    return
  end

  setup_highlights()
  M.lsp_client = lsp_client
  M.enabled = true
  M.is_streaming = false

  M.edit_counter = 0
  ns = M.vim.api.nvim_create_namespace('gitlab.GhostText')

  local augroup_id = M.vim.api.nvim_create_augroup(group, { clear = true })

  M.vim.api.nvim_create_autocmd('InsertEnter', {
    group = augroup_id,

    callback = function()
      M.on_insert_enter()
    end,
  })
  M.vim.api.nvim_create_autocmd('InsertLeave', {
    group = augroup_id,

    callback = function()
      M.on_insert_leave()
    end,
  })
  M.vim.api.nvim_create_autocmd('TextChangedI', {
    group = augroup_id,
    callback = function()
      M.on_text_changed()
    end,
  })
  M.vim.api.nvim_create_autocmd('CursorMovedI', {
    group = augroup_id,
    callback = function()
      M.on_cursor_moved()
    end,
  })

  if cfg.toggle_enabled then
    M.vim.keymap.set('i', cfg.toggle_enabled, function()
      M.toggle_enabled()
    end)
  end
  if cfg.accept_suggestion then
    M.vim.keymap.set('i', cfg.accept_suggestion, function()
      M.insert_ghost_text()
    end)
  end
  if cfg.clear_suggestions then
    M.vim.keymap.set('i', cfg.clear_suggestions, function()
      M.clear_all_ghost_text()
    end)
  end
end

local function create_or_update_extmark(lines)
  local bufnr = M.vim.api.nvim_get_current_buf()
  local row, col = unpack(M.vim.api.nvim_win_get_cursor(0))

  local virt_text = { { lines[1], group } }
  local virt_lines = {}
  for i = 2, #lines do
    table.insert(virt_lines, { { lines[i], group } })
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
    M.vim.api.nvim_buf_del_extmark(bufnr, ns, ghost_text_extmark_id)
  end
  ghost_text_extmark_id = M.vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col, opts)
end

--- Return the full text (streaming or last suggestion) to insert/display.
---@return string
local function get_text_to_insert()
  if not suggestion_shown then
    return ""
  end
  local text_to_insert = (stream_buffer ~= '') and stream_buffer or last_suggestion

  if not text_to_insert then
    return ""
  end
  return text_to_insert
end


-- Suppress the next on_text_changed and on_cursor_moved events.

function M.suppress_next_events()
  M.suppress_next_text_changed = true
  M.suppress_next_cursor_moved = true
end

-- Single insert function with internal logic to skip clearing ghost text if performing a partial insertion.
local function insert_text(text)
  if not text or text == "" then
    return
  end
  local row, col = unpack(M.vim.api.nvim_win_get_cursor(0))
  local lines = M.vim.split(text, '\n')


  -- Insert the text.
  M.vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)


  local new_row = row + #lines - 1

  local new_col = (#lines > 1) and (#lines[#lines]) or (col + #lines[1])
  M.vim.api.nvim_win_set_cursor(0, { new_row, new_col })


  -- If this is a full insertion, clear ghost text and cancel streaming if needed.
  if not M.isPartialInsertion then
    M.clear_ghost_text()
    if M.is_streaming then
      M.cancel_streaming()
    end
  end
end

M.clear_all_ghost_text = function()
  M.clear_ghost_text()
  if ns then
    local bufnr = M.vim.api.nvim_get_current_buf()
    M.vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
end

M.clear_ghost_text = function()
  if ns and ghost_text_extmark_id then
    local bufnr = M.vim.api.nvim_get_current_buf()
    M.vim.api.nvim_buf_del_extmark(bufnr, ns, ghost_text_extmark_id)
    ghost_text_extmark_id = nil
  end
  if not M.is_streaming then
    stream_buffer = ''
  end
  suggestion_shown = false
end

M.increment_edit_counter = function()
  M.edit_counter = M.edit_counter + 1
end

local function debounce_update_ghost_text(edit_counter)
  M.update_ghost_text(edit_counter)
end

M.update_ghost_text_with_debounce = debounce(debounce_update_ghost_text)

M.update_ghost_text = function(edit_counter)
  if not M.enabled then
    return
  end
  if M.edit_counter ~= edit_counter then
    -- Request is stale.
    return
  end
  if M.lsp_client == nil or not ns then
    return
  end
  if M.is_streaming then
    M.cancel_streaming()
  end

  local client_id = M.lsp_client.client_id
  local client = M.vim.lsp.get_client_by_id(client_id)
  local bufnr = M.vim.api.nvim_get_current_buf()
  local params = M.vim.tbl_extend('force', { context = {} }, M.vim.lsp.util.make_position_params())

  M.is_requesting = true
  client.request('textDocument/inlineCompletion', params, function(err, result)
    if M.edit_counter ~= edit_counter then
      -- Request is stale.
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
      M.start_new_stream(new_stream_id)
    else
      M.display_suggestion(result.items)
    end
  end, bufnr)
end

M.handle_streaming_response = function(err, result)
  if err then
    M.finish_streaming()
    return
  end
  if not result.id or result.id ~= stream_id then
    return
  end
  if not M.is_streaming then
    return
  end
  if result.completion then
    stream_buffer = result.completion
    M.display_streaming_suggestion(stream_buffer)
  end
  if result.done then
    M.finish_streaming()
  end
end


M.start_new_stream = function(new_stream_id)
  suggestion_shown = true
  if M.is_streaming then
    M.cancel_streaming()
  end
  stream_id = new_stream_id
  M.is_streaming = true
  stream_buffer = ''
end


M.cancel_streaming = function()
  if M.is_streaming and stream_id then
    local client_id = M.lsp_client.client_id
    local client = M.vim.lsp.get_client_by_id(client_id)
    client.notify('cancelStreaming', { id = stream_id })

    M.finish_streaming()
  end
end

M.finish_streaming = function()
  M.is_streaming = false
  stream_id = nil

  last_suggestion = stream_buffer -- Preserve the last streamed suggestion.
end

M.display_streaming_suggestion = function(suggestion)
  local lines = M.vim.split(suggestion, '\n')
  create_or_update_extmark(lines)
end

M.display_suggestion = function(suggestions)
  suggestion_shown = true
  if #suggestions == 0 then
    return
  end

  last_suggestion = suggestions[1].insertText
  local lines = M.vim.split(last_suggestion, '\n')
  create_or_update_extmark(lines)
end

M.insert_or_request_ghost_text = function()
  if suggestion_shown then
    M.insert_ghost_text()
  else
    M.update_ghost_text(M.edit_counter)
  end
end

--- Insert the entire ghost text at the cursor position.
M.insert_ghost_text = function()
  M.isPartialInsertion = false
  insert_text(get_text_to_insert())
end


-- ===========================================================================
-- PARTIAL INSERT + RESTORE
-- ===========================================================================

-- This helper does the actual partial insertion and updates the appropriate history.
local function partial_insert_text(partial, remainder, insertion_type)
  if partial == "" then
    return
  end
  M.suppress_next_events()
  local row_before, col_before = unpack(M.vim.api.nvim_win_get_cursor(0))

  M.isPartialInsertion = true
  insert_text(partial) -- This moves the cursor forward.
  M.isPartialInsertion = false

  if insertion_type == "word" then
    -- Clear any pending line insertion history to avoid cross-type errors.

    M.partial_insertion_history["line"] = nil
    if not M.partial_insertion_history["word"] then
      M.partial_insertion_history["word"] = {}
    end
    local event = {
      insertionType = insertion_type,
      partial = partial,                         -- inserted word
      remainder = remainder,                     -- leftover ghost text
      originalSuggestion = partial .. remainder, -- state before insertion
      row_before = row_before,
      col_before = col_before,
      lines_inserted = M.vim.split(partial, "\n"),
    }
    table.insert(M.partial_insertion_history["word"], event)
  elseif insertion_type == "line" then
    -- Clear any pending word insertion history.
    M.partial_insertion_history["word"] = {}
    M.partial_insertion_history["line"] = {
      insertionType = insertion_type,
      partial = partial,

      remainder = remainder,
      originalSuggestion = partial .. remainder,
      row_before = row_before,
      col_before = col_before,
      lines_inserted = M.vim.split(partial, "\n"),
    }
  end

  if remainder ~= "" then
    suggestion_shown = true
    last_suggestion = remainder
    local lines = M.vim.split(remainder, "\n")
    create_or_update_extmark(lines)
  else
    suggestion_shown = false
    last_suggestion = nil

    M.clear_ghost_text()
  end
end

--- Insert the first line from the current suggestion, preserving exact remainder.
M.insert_line = function()
  if M.is_streaming then
    return
  end
  local text = get_text_to_insert()
  if text == "" then
    return
  end
  local first_newline = text:find("\n")
  if not first_newline then
    -- No newline: treat as a line insertion.
    partial_insert_text(text, "", "line")

    return
  end
  local partial = text:sub(1, first_newline - 1)
  local remainder = text:sub(first_newline + 1)
  partial_insert_text(partial, remainder, "line")
end

--- Insert the first "word" (using utils.split_words) from the suggestion,
--- then re-display the exact remainder.
M.insert_word = function()
  if M.is_streaming then
    return
  end
  local text = get_text_to_insert()
  if text == "" then
    return
  end

  local words = utils.split_words(text)
  if not words or #words == 0 then
    return
  end

  local partial = words[1]
  local remainder = text:sub(#partial + 1)
  partial_insert_text(partial, remainder, "word")
end

M.toggle_enabled = function()
  if M.enabled then
    M.enabled = false
    M.increment_edit_counter()
    M.clear_ghost_text()
  else
    M.enabled = true
    M.update_ghost_text(M.edit_counter)
  end
end

M.on_insert_leave = function()
  M.increment_edit_counter()
  M.clear_ghost_text()
end


M.on_cursor_moved = function()
  if M.suppress_next_cursor_moved then
    M.suppress_next_cursor_moved = false
    return
  end
  M.increment_edit_counter()
  M.clear_ghost_text()
end

M.on_insert_enter = function()
  M.increment_edit_counter()
  M.update_ghost_text(M.edit_counter)
end

M.on_text_changed = function()
  if M.suppress_next_text_changed then
    M.suppress_next_text_changed = false
    return
  end
  M.increment_edit_counter()
  M.clear_ghost_text()
  M.update_ghost_text_with_debounce(M.edit_counter)
end

-- ===========================================================================
-- RESTORE FUNCTIONS
-- ===========================================================================
-- Restore the last (or only) partial line insertion.
M.restore_line = function()
  local event = M.partial_insertion_history["line"]
  if not event then
    return
  end
  local bufnr = M.vim.api.nvim_get_current_buf()
  M.suppress_next_events()
  local start_row = event.row_before - 1
  local start_col = event.col_before
  local lines = event.lines_inserted or {}
  local num_lines = #lines
  if num_lines == 0 then
    return
  end
  local end_row = start_row + num_lines - 1
  local end_col = (num_lines == 1) and (start_col + #lines[1]) or (#lines[num_lines])
  M.vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {})

  M.vim.api.nvim_win_set_cursor(0, { event.row_before, event.col_before })
  local restored = event.originalSuggestion
  last_suggestion = restored
  suggestion_shown = true
  local splitted = M.vim.split(restored, "\n")
  create_or_update_extmark(splitted)
  M.partial_insertion_history["line"] = nil
end

-- Restore only the last partial word insertion.
M.restore_word = function()
  local stack = M.partial_insertion_history["word"]
  if not stack or #stack == 0 then
    return
  end
  local event = table.remove(stack)
  local bufnr = M.vim.api.nvim_get_current_buf()
  M.suppress_next_events()

  local start_row = event.row_before - 1
  local start_col = event.col_before
  local lines = event.lines_inserted or {}
  local num_lines = #lines
  if num_lines == 0 then
    return
  end
  local end_row = start_row + num_lines - 1

  local end_col = (num_lines == 1) and (start_col + #lines[1]) or (#lines[num_lines])
  M.vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {})
  M.vim.api.nvim_win_set_cursor(0, { event.row_before, event.col_before })
  local restored = event.originalSuggestion
  last_suggestion = restored
  suggestion_shown = true
  local splitted = M.vim.split(restored, "\n")
  create_or_update_extmark(splitted)
end

return M
