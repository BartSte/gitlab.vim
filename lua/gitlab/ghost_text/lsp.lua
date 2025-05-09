---@class GhostTextLsp
---@field setup fun(client: vim.lsp.Client): nil
---@field request_completion fun(callback: fun(err: any, result: any, ctx: any): any): nil
---@field notify fun(message: string, id: number): nil
local M = {}

--- Setup the client for the module.
--- @param client table
function M.setup(client)
    M.client = client
end

--- Request inline completion.
--- @param callback fun(err: any, result: any, ctx: any): any
function M.request_completion(callback)
    --- @type number
    local bufnr = vim.api.nvim_get_current_buf()
    --- @type number
    local client_id = M.client.client_id
    --- @type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        return
    end
    --- @type table
    local params = vim.tbl_extend('force', { context = {} }, vim.lsp.util.make_position_params(0, client.offset_encoding))
    client.request('textDocument/inlineCompletion', params, callback, bufnr)
end

--- Notify the client.
--- @param message string
--- @param id number
function M.notify(message, id)
    --- @type number
    local client_id = M.client.client_id
    --- @type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        return
    end
    client.notify(message, { id = id })
end

return M
