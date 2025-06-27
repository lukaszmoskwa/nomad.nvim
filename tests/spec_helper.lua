-- Test helper to set up mocks and test environment

-- Mock vim global for tests
_G.vim = {
  log = {
    levels = {
      DEBUG = 0,
      INFO = 1,
      WARN = 2,
      ERROR = 3,
    },
  },
  json = {
    encode = function(data)
      -- Simple JSON encoder for tests
      if type(data) == "table" then
        local parts = {}
        for k, v in pairs(data) do
          table.insert(parts, '"' .. tostring(k) .. '":' .. (type(v) == "string" and '"' .. v .. '"' or tostring(v)))
        end
        return "{" .. table.concat(parts, ",") .. "}"
      end
      return tostring(data)
    end,
    decode = function(str)
      -- Simple JSON decoder for tests
      return { status = "ok" }
    end,
  },
  schedule = function(fn)
    fn()
  end,
  defer_fn = function(fn, delay)
    fn()
  end,
  notify = function(msg, level)
    print("NOTIFY: " .. msg)
  end,
  tbl_isempty = function(t)
    return next(t) == nil
  end,
  tbl_deep_extend = function(behavior, ...)
    local result = {}
    local tables = {...}
    
    for _, tbl in ipairs(tables) do
      for k, v in pairs(tbl) do
        if type(v) == "table" and type(result[k]) == "table" then
          result[k] = vim.tbl_deep_extend(behavior, result[k], v)
        else
          result[k] = v
        end
      end
    end
    
    return result
  end,
  deepcopy = function(t)
    if type(t) ~= "table" then
      return t
    end
    local copy = {}
    for k, v in pairs(t) do
      copy[k] = vim.deepcopy(v)
    end
    return copy
  end,
  split = function(str, delimiter, opts)
    local result = {}
    local pattern = "[^" .. delimiter .. "]+"
    for match in string.gmatch(str, pattern) do
      table.insert(result, match)
    end
    return result
  end,
  fn = {
    setreg = function(reg, value)
      -- Mock clipboard
    end,
  },
  keymap = {
    set = function(mode, key, fn, opts)
      -- Mock keymap
    end,
  },
  api = {
    nvim_create_autocmd = function(event, opts)
      -- Mock autocmd
    end,
    nvim_buf_set_lines = function(bufnr, start, end_line, strict_indexing, replacement)
      -- Mock buffer operations
    end,
    nvim_buf_set_option = function(bufnr, option, value)
      -- Mock buffer options
    end,
    nvim_get_current_line = function()
      return "test line"
    end,
    nvim_win_get_cursor = function(winnr)
      return { 1, 0 }
    end,
    nvim_win_close = function(winnr, force)
      -- Mock window close
    end,
    nvim_buf_set_name = function(bufnr, name)
      -- Mock buffer name
    end,
  },
}

-- Mock os functions
_G.os = _G.os or {}
_G.os.getenv = _G.os.getenv or function(var)
  if var == "NOMAD_ADDR" then
    return "http://localhost:4646"
  end
  return nil
end

_G.os.time = _G.os.time or function()
  return 1609459200 -- Fixed timestamp for testing
end

_G.os.date = _G.os.date or function(format, time)
  return "2021-01-01 00:00:00"
end

-- Mock plenary.curl
package.preload["plenary.curl"] = function()
  return {
    request = function(opts)
      return {
        status = 200,
        body = '{"status": "ok", "data": []}',
      }
    end,
  }
end

-- Mock nui components
package.preload["nui.tree"] = function()
  return {}
end

package.preload["nui.split"] = function()
  return function()
    return {
      mount = function() end,
      unmount = function() end,
      bufnr = 1,
      winid = 1,
    }
  end
end

package.preload["nui.popup"] = function()
  return function()
    return {
      mount = function() end,
      unmount = function() end,
      bufnr = 1,
      winid = 1,
    }
  end
end

package.preload["nui.line"] = function()
  return function()
    return {}
  end
end

package.preload["nui.text"] = function()
  return function()
    return {}
  end
end

-- Mock health module
package.preload["health"] = function()
  return {
    start = function(name) print("HEALTH START: " .. name) end,
    ok = function(msg) print("HEALTH OK: " .. msg) end,
    warn = function(msg) print("HEALTH WARN: " .. msg) end,
    error = function(msg) print("HEALTH ERROR: " .. msg) end,
    info = function(msg) print("HEALTH INFO: " .. msg) end,
  }
end 