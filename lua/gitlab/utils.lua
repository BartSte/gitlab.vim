local utils = {}
local fn = vim.fn
local loop = vim.loop

function utils.print(m)
  if m == '' then
    return
  end

  print(utils.formatted_line_for_print(m))
end

function utils.formatted_line_for_print(m)
  if m == '' then
    return
  end

  return string.format('[gitlab.vim] %s', m)
end

function utils.current_os()
  return string.lower(loop.os_uname().sysname)
end

function utils.current_arch()
  local res = loop.os_uname().machine

  if res == 'arm64' then
    res = 'amd64'
  end

  return string.lower(res)
end

function utils.exec_cmd(cmd, job_opts, callback)
  local stdout = ''
  local stderr = ''
  local opts = {
    on_stdout = function(_job_id, data, _event)
      stdout = stdout .. '\n' .. vim.fn.join(data)
      stdout = vim.trim(stdout)
    end,

    on_stderr = function(_job_id, data, _event)
      stderr = stderr .. '\n' .. vim.fn.join(data)
      stderr = vim.trim(stderr)
    end,

    on_exit = function(_job_id, exit_code, _event)
      local result = { exit_code = exit_code, stdout = stdout, stderr = stderr, msg = '' }

      if exit_code ~= 0 then
        result.msg = string.format(
          'Error detected, stdout=[%s], stderr=[%s], code=[%s]',
          stdout,
          stderr,
          exit_code
        )
      end

      callback(result)
    end,
  }
  if job_opts ~= nil then
    for k, v in pairs(job_opts) do
      opts[k] = v
    end
  end

  return fn.jobstart(cmd, opts)
end

--- Reimplementation of vim.fs.joinpath.
---
--- From https://github.com/neovim/neovim/blob/v0.10.0/runtime/lua/vim/fs.lua#L95.
---
--- @param ... string
--- @return string
function utils.joinpath(...)
  return (table.concat({ ... }, '/'):gsub('//+', '/'))
end


--- Return a list of words from a given string.
--- The words are split like vim's "w" operator. Whitespace and newlines are
--- retained and are interpereted as words.
---@param text string
---@return string[] words
function utils.split_words(text)
    local words = {}
    for chunk, space in text:gmatch("([^%s]+)(%s*)") do
        local subchunks = {}
        local current_word = ""
        for i = 1, #chunk do
            local c = chunk:sub(i, i)
            if c:match("[%w_]") then
                current_word = current_word .. c
            else
                if #current_word > 0 then
                    table.insert(subchunks, current_word)
                    current_word = ""
                end
                table.insert(subchunks, c)
            end
        end
        if #current_word > 0 then
            table.insert(subchunks, current_word)
        end
        if #subchunks > 0 then
            subchunks[#subchunks] = subchunks[#subchunks] .. space
        else
            table.insert(subchunks, space)
        end
        for _, sc in ipairs(subchunks) do
            table.insert(words, sc)
        end
    end
    return words
end

return utils
