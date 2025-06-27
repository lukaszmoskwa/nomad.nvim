-- Health check module for Nomad.nvim

local M = {}

-- Main health check function
function M.check()
  local health = vim.health or require("health")

  health.start("Nomad.nvim: Nomad Cluster Explorer")

  -- Check Neovim version
  M.check_neovim_version(health)

  -- Check required plugins
  M.check_required_plugins(health)

  -- Check Nomad connectivity
  M.check_nomad_connectivity(health)

  -- Check configuration
  M.check_configuration(health)
end

-- Check Neovim version
function M.check_neovim_version(health)
  local version = vim.version()
  local required_major = 0
  local required_minor = 8

  if version.major > required_major or (version.major == required_major and version.minor >= required_minor) then
    health.ok(string.format("Neovim version %d.%d.%d is supported", version.major, version.minor, version.patch))
  else
    health.error(
      string.format(
        "Neovim version %d.%d.%d is not supported. Requires >= %d.%d",
        version.major,
        version.minor,
        version.patch,
        required_major,
        required_minor
      )
    )
  end
end

-- Check required plugins
function M.check_required_plugins(health)
  local required_plugins = {
    {
      name = "nui.nvim",
      module = "nui.popup",
      desc = "Required for UI components",
    },
    {
      name = "telescope.nvim",
      module = "telescope",
      desc = "Required for fuzzy searching",
    },
    {
      name = "plenary.nvim",
      module = "plenary.job",
      desc = "Required for async operations",
    },
    {
      name = "plenary.curl",
      module = "plenary.curl",
      desc = "Required for HTTP requests to Nomad API",
    },
  }

  local optional_plugins = {
    {
      name = "nvim-web-devicons",
      module = "nvim-web-devicons",
      desc = "Optional for resource type icons",
    },
  }

  for _, plugin in ipairs(required_plugins) do
    local ok, _ = pcall(require, plugin.module)
    if ok then
      health.ok(plugin.name .. " is installed")
    else
      health.error(plugin.name .. " is not installed - " .. plugin.desc)
    end
  end

  for _, plugin in ipairs(optional_plugins) do
    local ok, _ = pcall(require, plugin.module)
    if ok then
      health.ok(plugin.name .. " is installed")
    else
      health.warn(plugin.name .. " is not installed - " .. plugin.desc)
    end
  end
end

-- Check Nomad connectivity
function M.check_nomad_connectivity(health)
  local nomad = require("nomad.nomad")
  local config = require("nomad.config")

  -- Check if Nomad address is configured
  local nomad_address = config.get_nomad_address()
  health.info("Nomad address: " .. nomad_address)

  -- Check if token is configured
  local nomad_token = config.get_nomad_token()
  if nomad_token then
    health.ok("Nomad token is configured")
  else
    health.warn("Nomad token is not configured - some operations may fail if ACLs are enabled")
  end

  -- Check connectivity
  nomad.check_connectivity(function(connected, error)
    vim.schedule(function()
      if connected then
        health.ok("Successfully connected to Nomad cluster")

        -- Get cluster info
        nomad.get_cluster_info(function(cluster_info, cluster_error)
          vim.schedule(function()
            if cluster_error then
              health.warn("Could not get cluster info: " .. cluster_error)
            else
              if cluster_info.leader then
                health.ok("Cluster leader: " .. cluster_info.leader)
              end
              if cluster_info.members and #cluster_info.members > 0 then
                health.ok("Cluster members: " .. #cluster_info.members)
              end
            end
          end)
        end)
      else
        health.error("Cannot connect to Nomad cluster: " .. (error or "unknown error"))
        health.info("Make sure Nomad is running and accessible at " .. nomad_address)
        health.info("Check NOMAD_ADDR environment variable or nomad.address config")
      end
    end)
  end)
end

-- Helper function to check sidebar configuration
local function check_sidebar_config(health, options)
  if not options.sidebar then
    return
  end

  if options.sidebar.width and options.sidebar.width >= 30 and options.sidebar.width <= 120 then
    health.ok("Sidebar width is valid: " .. options.sidebar.width)
  else
    health.warn("Sidebar width may be invalid: " .. tostring(options.sidebar.width))
  end

  if
    options.sidebar.position == "left"
    or options.sidebar.position == "right"
    or options.sidebar.position == "float"
  then
    health.ok("Sidebar position is valid: " .. options.sidebar.position)
  else
    health.warn("Sidebar position may be invalid: " .. tostring(options.sidebar.position))
  end
end

-- Helper function to check nomad configuration
local function check_nomad_config(health, options)
  if not options.nomad then
    return
  end

  if options.nomad.address then
    health.info("Using configured Nomad address: " .. options.nomad.address)
  else
    health.info("Using NOMAD_ADDR environment variable or default")
  end

  if options.nomad.namespace then
    health.info("Using namespace: " .. options.nomad.namespace)
  end

  if options.nomad.region then
    health.info("Using region: " .. options.nomad.region)
  end

  if options.nomad.timeout and options.nomad.timeout >= 1000 then
    health.ok("Nomad timeout is valid: " .. options.nomad.timeout .. "ms")
  else
    health.warn("Nomad timeout may be too low: " .. tostring(options.nomad.timeout))
  end
end

-- Helper function to check UI and cache configuration
local function check_ui_and_cache_config(health, options)
  -- Check UI configuration
  if options.ui then
    if options.ui.refresh_interval and options.ui.refresh_interval >= 5 then
      health.ok("Refresh interval is valid: " .. options.ui.refresh_interval .. "s")
    else
      health.warn("Refresh interval may be too low: " .. tostring(options.ui.refresh_interval))
    end
  end

  -- Check cache configuration
  if options.cache then
    if options.cache.ttl_seconds and options.cache.ttl_seconds >= 5 then
      health.ok("Cache TTL is valid: " .. options.cache.ttl_seconds .. "s")
    else
      health.warn("Cache TTL may be too low: " .. tostring(options.cache.ttl_seconds))
    end
  end

  -- Check debug mode
  if options.debug then
    health.info("Debug mode is enabled")
  end
end

-- Check configuration
function M.check_configuration(health)
  local config = require("nomad.config")
  local options = config.get()

  if not options or vim.tbl_isempty(options) then
    health.warn("Nomad.nvim configuration not found - using defaults")
    return
  end

  health.ok("Nomad.nvim configuration loaded")

  check_sidebar_config(health, options)
  check_nomad_config(health, options)
  check_ui_and_cache_config(health, options)
end

-- Check environment variables
function M.check_environment(health)
  health.start("Environment Variables")

  local env_vars = {
    "NOMAD_ADDR",
    "NOMAD_TOKEN",
    "NOMAD_REGION",
    "NOMAD_NAMESPACE",
    "NOMAD_CACERT",
    "NOMAD_CLIENT_CERT",
    "NOMAD_CLIENT_KEY",
  }

  for _, var in ipairs(env_vars) do
    local value = os.getenv(var)
    if value then
      if var == "NOMAD_TOKEN" then
        health.ok(var .. " is set (hidden)")
      else
        health.ok(var .. " = " .. value)
      end
    else
      health.info(var .. " is not set")
    end
  end
end

-- Performance check
function M.check_performance(health)
  health.start("Performance")

  local config = require("nomad.config")
  local options = config.get()

  -- Check rate limiting
  if options.rate_limiting and options.rate_limiting.enabled then
    health.ok("Rate limiting is enabled")
    if options.rate_limiting.min_interval_ms then
      health.info("Min interval: " .. options.rate_limiting.min_interval_ms .. "ms")
    end
    if options.rate_limiting.max_requests_per_minute then
      health.info("Max requests per minute: " .. options.rate_limiting.max_requests_per_minute)
    end
  else
    health.warn("Rate limiting is disabled - may cause API throttling")
  end

  -- Check caching
  if options.cache and options.cache.ttl_seconds then
    health.ok("Caching is enabled with TTL: " .. options.cache.ttl_seconds .. "s")
  else
    health.warn("Caching is disabled - may cause slow performance")
  end
end

-- Run all checks
function M.check_all()
  M.check()
  M.check_environment(vim.health or require("health"))
  M.check_performance(vim.health or require("health"))
end

return M
