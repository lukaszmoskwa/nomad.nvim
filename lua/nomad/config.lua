-- Nomad.nvim configuration module

local M = {}

-- Default configuration
M.defaults = {
  -- Sidebar configuration
  sidebar = {
    width = 45,
    position = "left", -- "left", "right", or "float"
    auto_close = false,
    border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
    float = {
      relative = "editor",
      row = 1,
      col = "80%",
      width = 55,
      height = "90%",
    },
  },

  -- Nomad configuration
  nomad = {
    address = nil, -- nil to use NOMAD_ADDR environment variable
    token = nil, -- nil to use NOMAD_TOKEN environment variable
    timeout = 30000, -- timeout in milliseconds
    namespace = "default", -- default namespace
    region = nil, -- nil to use default region
  },

  -- UI configuration
  ui = {
    show_icons = true,
    show_namespace = true,
    show_datacenter = true,
    show_status = true,
    show_type = true,
    show_node_class = true,
    indent = "  ",
    refresh_interval = 30, -- seconds
  },

  -- Keybindings
  keymaps = {
    toggle_sidebar = "<leader>no",
    toggle_floating = "<leader>nf",
    refresh = "r",
    details = "<CR>",
    logs = "l",
    exec = "e",
    copy_id = "y",
    copy_name = "Y",
    search_jobs = "/",
    search_nodes = "n",
    topology = "t",
    close = "q",
    -- Job control
    start_job = "s",
    stop_job = "S",
    restart_job = "R",
    -- Node control
    drain_node = "d",
    enable_node = "E",
  },

  -- Debug mode
  debug = false,

  -- Cache configuration
  cache = {
    ttl_seconds = 30, -- 30 seconds cache TTL for cluster data
    auto_cleanup = true,
  },

  -- Rate limiting configuration
  rate_limiting = {
    enabled = true,
    min_interval_ms = 500, -- Minimum 0.5 second between requests
    max_requests_per_minute = 60, -- More permissive for local cluster
  },

  -- Topology view configuration
  topology = {
    show_allocation_details = true,
    show_resource_usage = true,
    group_by_datacenter = true,
    node_sort_by = "name", -- "name", "status", "drain", "class"
  },
}

-- Current configuration
M.options = {}

-- Job status icons mapping
M.job_status_icons = {
  running = "▶️ ",
  pending = "⏸️ ",
  dead = "⏹️ ",
  failed = "❌",
  stopped = "⏹️ ",
  complete = "✅",
  unknown = "❓",
}

-- Node status icons mapping
M.node_status_icons = {
  ready = "🟢",
  down = "🔴",
  disconnected = "🟡",
  initializing = "🔵",
  draining = "🟠",
  ineligible = "⚫",
  unknown = "❓",
}

-- Job type icons mapping
M.job_type_icons = {
  service = "🔧",
  batch = "📦",
  system = "⚙️ ",
  sysbatch = "🔄",
  parameterized = "📋",
  periodic = "⏰",
  unknown = "❓",
}

-- Node class icons mapping
M.node_class_icons = {
  compute = "🖥️ ",
  storage = "💾",
  network = "🌐",
  gpu = "🎮",
  memory = "🧠",
  default = "🖥️ ",
}

-- Resource type icons
M.resource_icons = {
  cpu = "⚡",
  memory = "🧠",
  disk = "💾",
  network = "🌐",
  gpu = "🎮",
}

-- Setup configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Validate configuration
  M.validate()

  if M.options.debug then
    vim.schedule(function()
      vim.notify("Nomad.nvim configuration loaded", vim.log.levels.DEBUG)
      -- Only show brief config summary in debug mode
      vim.notify(
        string.format(
          "Nomad address: %s, Namespace: %s, Sidebar: %s",
          M.get_nomad_address(),
          M.get_nomad_namespace(),
          M.options.sidebar.position
        ),
        vim.log.levels.DEBUG
      )
    end)
  end
end

-- Validate configuration
function M.validate()
  -- Validate sidebar position
  if
    M.options.sidebar.position ~= "left"
    and M.options.sidebar.position ~= "right"
    and M.options.sidebar.position ~= "float"
  then
    vim.schedule(function()
      vim.notify("Invalid sidebar position. Using 'left'", vim.log.levels.WARN)
    end)
    M.options.sidebar.position = "left"
  end

  -- Validate sidebar width
  if type(M.options.sidebar.width) ~= "number" or M.options.sidebar.width < 30 or M.options.sidebar.width > 120 then
    vim.schedule(function()
      vim.notify("Invalid sidebar width. Using 45", vim.log.levels.WARN)
    end)
    M.options.sidebar.width = 45
  end

  -- Validate timeout
  if type(M.options.nomad.timeout) ~= "number" or M.options.nomad.timeout < 1000 then
    vim.schedule(function()
      vim.notify("Invalid Nomad timeout. Using 30000ms", vim.log.levels.WARN)
    end)
    M.options.nomad.timeout = 30000
  end

  -- Validate refresh interval
  if type(M.options.ui.refresh_interval) ~= "number" or M.options.ui.refresh_interval < 5 then
    vim.schedule(function()
      vim.notify("Invalid refresh interval. Using 30 seconds", vim.log.levels.WARN)
    end)
    M.options.ui.refresh_interval = 30
  end
end

-- Get icon for job status
function M.get_job_status_icon(status)
  if not M.options.ui.show_icons then
    return ""
  end

  return M.job_status_icons[status] or M.job_status_icons.unknown
end

-- Get icon for node status
function M.get_node_status_icon(status)
  if not M.options.ui.show_icons then
    return ""
  end

  return M.node_status_icons[status] or M.node_status_icons.unknown
end

-- Get icon for job type
function M.get_job_type_icon(job_type)
  if not M.options.ui.show_icons then
    return ""
  end

  return M.job_type_icons[job_type] or M.job_type_icons.unknown
end

-- Get icon for node class
function M.get_node_class_icon(node_class)
  if not M.options.ui.show_icons then
    return ""
  end

  return M.node_class_icons[node_class] or M.node_class_icons.default
end

-- Get icon for resource type
function M.get_resource_icon(resource_type)
  if not M.options.ui.show_icons then
    return ""
  end

  return M.resource_icons[resource_type] or ""
end

-- Get current configuration
function M.get()
  return M.options
end

-- Get Nomad address
function M.get_nomad_address()
  return M.options.nomad.address or os.getenv("NOMAD_ADDR") or "http://localhost:4646"
end

-- Get Nomad token
function M.get_nomad_token()
  return M.options.nomad.token or os.getenv("NOMAD_TOKEN")
end

-- Get Nomad namespace
function M.get_nomad_namespace()
  return M.options.nomad.namespace or "default"
end

-- Get Nomad region
function M.get_nomad_region()
  return M.options.nomad.region or os.getenv("NOMAD_REGION")
end

return M
