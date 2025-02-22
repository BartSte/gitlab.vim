local M = {}

M.setup = function(group)
  vim.api.nvim_set_hl(0, group, { fg = '#808080', italic = true })
  vim.api.nvim_set_hl(0, 'GitLabIcon', { fg = '#FC6D26' })
end

return M
