local commands = require('gitlab.ghost_text.commands')
local M = {}

M.setup = function(cfg)
  if cfg.toggle_enabled then
    vim.keymap.set('i', cfg.toggle_enabled, commands.toggle_enabled)
  end
  if cfg.accept_suggestion then
    vim.keymap.set('i', cfg.accept_suggestion, commands.insert_ghost_text)
  end
  if cfg.clear_suggestions then
    vim.keymap.set('i', cfg.clear_suggestions, commands.clear_all_ghost_text)
  end
  if cfg.insert_line then
    vim.keymap.set('i', cfg.insert_line, commands.insert_line)
  end
  if cfg.insert_word then
    vim.keymap.set('i', cfg.insert_word, commands.insert_word)
  end
  if cfg.restore_line then
    vim.keymap.set('i', cfg.restore_line, commands.restore_line)
  end
  if cfg.restore_word then
    vim.keymap.set('i', cfg.restore_word, commands.restore_word)
  end
end

return M
