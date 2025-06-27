-- Test file for nomad.utils module
local utils = require("nomad.utils")

describe("nomad.utils", function()
  describe("format_time", function()
    it("should format timestamps correctly", function()
      local timestamp = 1609459200000000000 -- 2021-01-01 00:00:00 UTC
      local formatted = utils.format_time(timestamp)
      assert.is_string(formatted)
      assert.matches("%d+%-%d+%-%d+ %d+:%d+:%d+", formatted)
    end)
    
    it("should handle nil timestamps", function()
      local formatted = utils.format_time(nil)
      assert.equals("N/A", formatted)
    end)
  end)

  describe("format_bytes", function()
    it("should format bytes with proper units", function()
      assert.equals("1.0 KB", utils.format_bytes(1024))
      assert.equals("1.0 MB", utils.format_bytes(1024 * 1024))
      assert.equals("1.0 GB", utils.format_bytes(1024 * 1024 * 1024))
    end)
    
    it("should handle zero bytes", function()
      assert.equals("0 B", utils.format_bytes(0))
    end)
    
    it("should handle nil input", function()
      assert.equals("0 B", utils.format_bytes(nil))
    end)
  end)

  describe("truncate_string", function()
    it("should truncate long strings", function()
      local long_string = "This is a very long string that should be truncated"
      local truncated = utils.truncate_string(long_string, 20)
      assert.equals(20, #truncated)
      assert.matches("%.%.%.$", truncated)
    end)
    
    it("should not truncate short strings", function()
      local short_string = "Short"
      local result = utils.truncate_string(short_string, 20)
      assert.equals(short_string, result)
    end)
  end)

  describe("get_status_icon", function()
    it("should return correct icons for job statuses", function()
      assert.equals("▶️", utils.get_status_icon("running"))
      assert.equals("💀", utils.get_status_icon("dead"))
      assert.equals("🟢", utils.get_status_icon("ready"))
    end)
    
    it("should return default icon for unknown status", function()
      local icon = utils.get_status_icon("unknown_status")
      assert.equals("❓", icon)
    end)
  end)

  describe("format_cpu", function()
    it("should format CPU MHz correctly", function()
      assert.equals("500 MHz", utils.format_cpu(500))
      assert.equals("1.5 GHz", utils.format_cpu(1500))
    end)

    it("should handle zero CPU", function()
      assert.equals("0 MHz", utils.format_cpu(0))
    end)
  end)

  describe("truncate", function()
    it("should truncate strings correctly", function()
      assert.equals("hello...", utils.truncate("hello world", 8))
      assert.equals("hello", utils.truncate("hello", 10))
    end)

    it("should handle nil input", function()
      assert.equals("", utils.truncate(nil, 10))
    end)
  end)
end) 