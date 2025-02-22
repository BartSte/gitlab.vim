local M = {}

M.setup = function(client)
  M.client = client
end

M.request_completion = function(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.tbl_extend('force', { context = {} }, vim.lsp.util.make_position_params())
  local client_id = M.client.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    return
  end
  client.request('textDocument/inlineCompletion', params, callback, bufnr)
end

M.notify = function(message, id)
  local client_id = M.client.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    return
  end
  client.notify(message, { id = id })
end
return M
