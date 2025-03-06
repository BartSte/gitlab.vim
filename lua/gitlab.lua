local M = {}

function M.plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':p:h:h')
end

function M.setup(user_config)
  require('gitlab.config').setup(user_config)
  require('gitlab.resource_editing')
  require('gitlab.commands').create()
end

return M
