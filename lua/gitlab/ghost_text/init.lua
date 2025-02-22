local autocmd     = require("gitlab.ghost_text.autocmd")
local commands    = require("gitlab.ghost_text.commands")
local highlights  = require("gitlab.ghost_text.highlights")
local keymaps     = require("gitlab.ghost_text.keymaps")
local lsp         = require("gitlab.ghost_text.lsp")
local suggestions = require("gitlab.ghost_text.suggestion")
local writer     = require("gitlab.ghost_text.writer")

---@class GitLabGhostText
---@field GROUP string
---@field clear_all_ghost_text fun(): nil
---@field enabled boolean
---@field insert_ghost_text fun(): nil
---@field insert_line fun(): nil
---@field insert_word fun(): nil
---@field namespace number|nil
---@field restore_line fun(): nil
---@field restore_word fun(): nil
---@field toggle_enabled fun(): nil
---@field handle_streaming_response fun(err: any, result: any): nil
local M = {
  GROUP = "GitLabGhostText",
  clear_all_ghost_text = commands.clear_all_ghost_text,
  enabled = writer.enabled,
  insert_ghost_text = commands.insert_ghost_text,
  insert_line = commands.insert_line,
  insert_word = commands.insert_word,
  namespace = nil,
  restore_line = commands.restore_line,
  restore_word = commands.restore_word,
  toggle_enabled = commands.toggle_enabled,
  handle_streaming_response = suggestions.handle_streaming_response
} ---@type GitLabGhostText

--- Sets up the ghost text module.
--- @param lsp_client vim.lsp.Client
--- @param cfg { enabled: boolean }
M.setup = function(lsp_client, cfg)
  if not cfg or not cfg.enabled then
    return
  end
  M.namespace = vim.api.nvim_create_namespace('gitlab.GhostText')
  writer.setup(M.namespace)
  commands.setup(M.namespace)
  highlights.setup(M.GROUP)
  autocmd.setup(M.GROUP)
  keymaps.setup(cfg)
  lsp.setup(lsp_client)
end

return M

