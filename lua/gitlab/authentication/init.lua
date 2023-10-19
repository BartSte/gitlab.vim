local notifier = require('gitlab.notifier')
local provider = require('gitlab.authentication.provider')

-- Lua module: gitlab.authentication
local M = {}

local function new_auth_resolver(options)
  vim.validate({
    gitlab_url = { options.gitlab_url, 'string' },
  })

  local resolved
  return {
    clear = function()
      resolved = nil
    end,
    resolve = function(opts)
      vim.validate({
        ['opts.force'] = { opts.force, 'boolean', true },
        ['opts.prompt_user'] = { opts.prompt_user, 'boolean', true },
      })

      if resolved then
        if opts and opts.force then
          resolved:resolve(opts)
        end

        return resolved, nil
      end

      local env_auth = provider.env(
        { gitlab_url = 'GITLAB_VIM_URL', token = 'GITLAB_TOKEN' },
        { gitlab_url = options.gitlab_url }
      )
      if env_auth:resolve() then
        resolved = env_auth
        notifier.notify('gitlab.vim: Resolved authentication details from environment.')
        return env_auth, nil
      end

      local prompt_auth = provider.prompt()
      if prompt_auth:resolve(opts) then
        resolved = prompt_auth
        notifier.notify('gitlab.vim: Resolved authentication details from user input.')
        return prompt_auth, nil
      end

      return nil, 'Unable to find a valid authentication provider.'
    end,
  }
end

function M.default_resolver()
  local config = require('gitlab.config').current()
  return new_auth_resolver({
    gitlab_url = config.gitlab_url,
  })
end

return M
