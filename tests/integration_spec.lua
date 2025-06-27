-- Integration tests for nomad.nvim
-- These tests use mocked responses to avoid requiring a real Nomad instance

local config = require("nomad.config")

describe("nomad integration", function()
  local test_timeout = 5000 -- 5 seconds
  
  before_each(function()
    -- Setup test configuration
    config.setup({
      nomad = {
        address = os.getenv("NOMAD_ADDR") or "http://localhost:4646",
        timeout = test_timeout
      }
    })
  end)

  it("should have valid configuration", function()
    local cfg = config.get()
    assert.is_table(cfg)
    assert.is_table(cfg.nomad)
    assert.is_string(cfg.nomad.address)
    assert.is_number(cfg.nomad.timeout)
  end)

  it("should get nomad address", function()
    local addr = config.get_nomad_address()
    assert.is_string(addr)
    assert.matches("^https?://", addr)
  end)

  it("should handle nomad token", function()
    local token = config.get_nomad_token()
    -- Token can be nil or string
    assert.is_true(token == nil or type(token) == "string")
  end)

  it("should get nomad namespace", function()
    local namespace = config.get_nomad_namespace()
    -- Namespace can be nil or string
    assert.is_true(namespace == nil or type(namespace) == "string")
  end)

  it("should get nomad region", function()
    local region = config.get_nomad_region()
    -- Region can be nil or string
    assert.is_true(region == nil or type(region) == "string")
  end)

  it("should load nomad module without errors", function()
    assert.has_no.errors(function()
      require("nomad.nomad")
    end)
  end)

  it("should load health module without errors", function()
    assert.has_no.errors(function()
      require("nomad.health")
    end)
  end)

  it("should load ui module without errors", function()
    assert.has_no.errors(function()
      require("nomad.ui")
    end)
  end)
end) 