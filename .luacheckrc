-- Luacheck configuration for nomad.nvim
std = "luajit"

-- Global variables that are OK to use
globals = {
  "vim",
  "unpack", -- LuaJIT compatibility
}

-- Read-only globals
read_globals = {
  "vim",
}

-- Ignore specific warnings
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "631", -- Line is too long
}

-- Per-file overrides for complex functions that are hard to break down
files["lua/nomad/nomad.lua"] = {
  ignore = { "561" }, -- Ignore cyclomatic complexity for generate_enhanced_topology
}

files["lua/nomad/ui.lua"] = {
  ignore = { "561" }, -- Ignore cyclomatic complexity for show_topology_buffer
}

-- Files to exclude
exclude_files = {
  "lua/telescope/_extensions/nomad.lua", -- Telescope extension has different standards
}

-- Maximum line length
max_line_length = 120

-- Maximum cyclomatic complexity
max_cyclomatic_complexity = 15

-- Cache results
cache = true 