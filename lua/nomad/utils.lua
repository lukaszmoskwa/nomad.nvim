-- Utils module for Nomad.nvim

local M = {}

-- Format bytes to human readable format
function M.format_bytes(bytes)
  if not bytes or bytes == 0 then
    return "0 B"
  end
  
  local units = {"B", "KB", "MB", "GB", "TB"}
  local unit_index = 1
  local size = bytes
  
  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end
  
  return string.format("%.1f %s", size, units[unit_index])
end

-- Format CPU MHz to human readable format
function M.format_cpu(mhz)
  if not mhz or mhz == 0 then
    return "0 MHz"
  end
  
  if mhz >= 1000 then
    return string.format("%.1f GHz", mhz / 1000)
  else
    return string.format("%d MHz", mhz)
  end
end

-- Format duration from nanoseconds
function M.format_duration(nanoseconds)
  if not nanoseconds or nanoseconds == 0 then
    return "0s"
  end
  
  local seconds = nanoseconds / 1000000000
  
  if seconds < 60 then
    return string.format("%.1fs", seconds)
  elseif seconds < 3600 then
    return string.format("%.1fm", seconds / 60)
  elseif seconds < 86400 then
    return string.format("%.1fh", seconds / 3600)
  else
    return string.format("%.1fd", seconds / 86400)
  end
end

-- Format timestamp to relative time
function M.format_relative_time(timestamp)
  if not timestamp then
    return "unknown"
  end
  
  -- Convert from nanoseconds to seconds if needed
  local ts = timestamp
  if timestamp > 9999999999999 then -- If timestamp looks like nanoseconds
    ts = timestamp / 1000000000
  end
  
  local now = os.time()
  local diff = now - ts
  
  if diff < 60 then
    return string.format("%ds ago", diff)
  elseif diff < 3600 then
    return string.format("%dm ago", math.floor(diff / 60))
  elseif diff < 86400 then
    return string.format("%dh ago", math.floor(diff / 3600))
  else
    return string.format("%dd ago", math.floor(diff / 86400))
  end
end

-- Truncate string to max length
function M.truncate(str, max_length)
  if not str then
    return ""
  end
  
  if #str <= max_length then
    return str
  end
  
  return str:sub(1, max_length - 3) .. "..."
end

-- Check if table is empty
function M.is_empty(table)
  if not table then
    return true
  end
  
  return next(table) == nil
end

-- Deep copy table
function M.deep_copy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[M.deep_copy(orig_key)] = M.deep_copy(orig_value)
    end
    setmetatable(copy, M.deep_copy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Merge two tables
function M.merge_tables(t1, t2)
  local result = M.deep_copy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.merge_tables(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Get unique values from table
function M.unique(table)
  local seen = {}
  local result = {}
  
  for _, value in ipairs(table) do
    if not seen[value] then
      seen[value] = true
      table.insert(result, value)
    end
  end
  
  return result
end

-- Filter table by predicate function
function M.filter(table, predicate)
  local result = {}
  
  for i, value in ipairs(table) do
    if predicate(value, i) then
      table.insert(result, value)
    end
  end
  
  return result
end

-- Map table values using function
function M.map(table, func)
  local result = {}
  
  for i, value in ipairs(table) do
    result[i] = func(value, i)
  end
  
  return result
end

-- Find item in table
function M.find(table, predicate)
  for i, value in ipairs(table) do
    if predicate(value, i) then
      return value, i
    end
  end
  
  return nil, nil
end

-- Check if table contains value
function M.contains(table, value)
  for _, v in ipairs(table) do
    if v == value then
      return true
    end
  end
  
  return false
end

-- Sort table by field
function M.sort_by_field(table, field, reverse)
  local sorted = M.deep_copy(table)
  
  table.sort(sorted, function(a, b)
    local a_val = a[field]
    local b_val = b[field]
    
    if reverse then
      return a_val > b_val
    else
      return a_val < b_val
    end
  end)
  
  return sorted
end

-- Get nested value from table using dot notation
function M.get_nested(table, path)
  local keys = vim.split(path, ".", { plain = true })
  local current = table
  
  for _, key in ipairs(keys) do
    if type(current) ~= "table" or current[key] == nil then
      return nil
    end
    current = current[key]
  end
  
  return current
end

-- Set nested value in table using dot notation
function M.set_nested(table, path, value)
  local keys = vim.split(path, ".", { plain = true })
  local current = table
  
  for i = 1, #keys - 1 do
    local key = keys[i]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end
  
  current[keys[#keys]] = value
end

-- Generate a simple hash for caching
function M.hash(str)
  local hash = 0
  for i = 1, #str do
    hash = ((hash * 32) - hash + string.byte(str, i)) % 4294967296
  end
  return hash
end

-- URL encode string
function M.url_encode(str)
  if not str then
    return ""
  end
  
  str = string.gsub(str, "\n", "\r\n")
  str = string.gsub(str, "([^%w _%%%-%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  str = string.gsub(str, " ", "+")
  
  return str
end

-- Check if string starts with prefix
function M.starts_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end

-- Check if string ends with suffix
function M.ends_with(str, suffix)
  return str:sub(-#suffix) == suffix
end

-- Split string by delimiter
function M.split(str, delimiter)
  return vim.split(str, delimiter, { plain = true })
end

-- Join table values with delimiter
function M.join(table, delimiter)
  return table.concat(table, delimiter)
end

-- Capitalize first letter of string
function M.capitalize(str)
  if not str or #str == 0 then
    return ""
  end
  
  return str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- Convert camelCase to snake_case
function M.camel_to_snake(str)
  return str:gsub("(%u)", "_%1"):lower():gsub("^_", "")
end

-- Convert snake_case to camelCase
function M.snake_to_camel(str)
  return str:gsub("_(%w)", function(c) return c:upper() end)
end

-- Escape special characters for use in patterns
function M.escape_pattern(str)
  return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Get file extension
function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

-- Get filename without extension
function M.get_basename(filename)
  return filename:match("(.+)%..+$") or filename
end

-- Check if path is absolute
function M.is_absolute_path(path)
  return M.starts_with(path, "/") or M.starts_with(path, "~") or path:match("^%a:")
end

-- Normalize path separators
function M.normalize_path(path)
  return path:gsub("\\", "/")
end

return M 