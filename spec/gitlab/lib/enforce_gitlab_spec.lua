local enforce_gitlab = require('gitlab.lib.enforce_gitlab')
local mock = require('luassert.mock')
local stub = require('luassert.stub')

describe('enforce_gitlab', function()
  local snapshot
  local rest_api = mock(require('gitlab.api.rest'), true)

  before_each(function()
    snapshot = assert:snapshot()
    stub(rest_api, 'metadata').returns({ version = '16.9.0' }, nil)
  end)

  after_each(function()
    snapshot:revert()
  end)

  it('.at_least("16.8") returns true', function()
    assert.equal(true, enforce_gitlab.at_least('16.8'))
  end)

  it('.at_least("999.99.9") returns false', function()
    assert.equal(false, enforce_gitlab.at_least('999.99.9'))
  end)
end)
