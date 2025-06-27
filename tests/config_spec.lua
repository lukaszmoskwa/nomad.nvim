-- Test file for nomad.config module
local config = require("nomad.config")

describe("nomad.config", function()
  before_each(function()
    -- Reset config before each test
    config._config = nil
  end)

  it("should have default configuration", function()
    config.setup({}) -- Initialize with defaults
    local default_config = config.get()
    assert.is_not_nil(default_config)
    assert.is_table(default_config)
    assert.is_table(default_config.nomad)
    assert.is_table(default_config.sidebar)
    assert.is_table(default_config.ui)
    -- nomad.address can be nil (uses environment variable)
    assert.is_true(default_config.nomad.address == nil or type(default_config.nomad.address) == "string")
  end)

  it("should merge user configuration with defaults", function()
    local user_config = {
      nomad = {
        address = "http://custom:4646"
      }
    }
    
    config.setup(user_config)
    local merged_config = config.get()
    
    assert.equals("http://custom:4646", merged_config.nomad.address)
  end)

  it("should validate nomad address format", function()
    local valid_addresses = {
      "http://localhost:4646",
      "https://nomad.example.com:4646",
      "http://127.0.0.1:4646"
    }
    
    for _, addr in ipairs(valid_addresses) do
      local user_config = { nomad = { address = addr } }
      assert.has_no.errors(function()
        config.setup(user_config)
      end)
    end
  end)

  it("should have proper icon configuration", function()
    config.setup({}) -- Initialize with defaults
    local cfg = config.get()
    assert.is_table(cfg.ui)
    assert.is_boolean(cfg.ui.show_icons)
    -- Test icon getter functions
    assert.is_string(config.get_job_status_icon("running"))
    assert.is_string(config.get_node_status_icon("ready"))
    assert.is_string(config.get_job_type_icon("service"))
  end)

  it("should get nomad address from config", function()
    config.setup({ nomad = { address = "http://test:4646" } })
    local addr = config.get_nomad_address()
    assert.equals("http://test:4646", addr)
  end)

  it("should get nomad address from environment", function()
    config.setup({}) -- No address in config
    local addr = config.get_nomad_address()
    assert.equals("http://localhost:4646", addr) -- From our mock
  end)
end) 