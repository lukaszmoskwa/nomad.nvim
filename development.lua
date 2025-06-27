-- Development configuration for Nomad.nvim
-- Place this in ~/.config/nvim-nomad/init.lua for testing
-- Make sure to start Neovim from the nomad.nvim plugin directory!

-- =============================================================================
-- CONFIGURATION VARIABLES
-- =============================================================================
-- Modify these variables to match your Nomad cluster setup
local NOMAD_CONFIG = {
  -- Nomad cluster address
  address = "http://localhost:4646",
  
  -- Nomad namespace (use "default" for single-namespace clusters)
  namespace = "default",
  
  -- Nomad region (optional, leave nil for default)
  region = nil,
  
  -- Nomad ACL token (optional, leave nil if ACL is disabled)
  token = nil,
  
  -- Alternative: Use environment variables
  -- Uncomment these lines to use environment variables instead:
  -- address = os.getenv("NOMAD_ADDR") or "http://localhost:4646",
  -- namespace = os.getenv("NOMAD_NAMESPACE") or "default",
  -- region = os.getenv("NOMAD_REGION"),
  -- token = os.getenv("NOMAD_TOKEN"),
}

-- Development settings
local DEV_CONFIG = {
  debug = false, -- Set to true for verbose debug output
  refresh_interval = 10, -- Seconds between UI refreshes
  cache_ttl = 10, -- Cache TTL in seconds
  sidebar_width = 50,
  sidebar_position = "left", -- "left", "right", or "float"
}

-- =============================================================================

-- Check if we're in the right directory
local cwd = vim.fn.getcwd()
local nomad_init = cwd .. "/lua/nomad/init.lua"
if not vim.loop.fs_stat(nomad_init) then
  vim.schedule(function()
    vim.notify("ERROR: Please start Neovim from the nomad.nvim plugin directory!", vim.log.levels.ERROR)
    vim.notify("Current directory: " .. cwd, vim.log.levels.ERROR)
    vim.notify("Looking for: " .. nomad_init, vim.log.levels.ERROR)
  end)
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specification
local plugins = {
  -- Dependencies
  {
    "MunifTanjim/nui.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "nvim-tree/nvim-web-devicons",
    optional = true,
  },
  
  -- Nomad.nvim plugin (local development)
  {
    name = "nomad.nvim",
    dir = vim.fn.getcwd(), -- Current directory
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", 
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false, -- Load immediately
    priority = 1000, -- Load early
    config = function()
      require("nomad").setup({
        -- Development configuration using variables
        debug = DEV_CONFIG.debug,
        sidebar = {
          width = DEV_CONFIG.sidebar_width,
          position = DEV_CONFIG.sidebar_position,
        },
        nomad = {
          address = NOMAD_CONFIG.address,
          namespace = NOMAD_CONFIG.namespace,
          region = NOMAD_CONFIG.region,
          token = NOMAD_CONFIG.token,
        },
        ui = {
          show_icons = true,
          show_type = true,
          show_status = true,
          show_datacenter = true,
          show_node_class = true,
          refresh_interval = DEV_CONFIG.refresh_interval,
        },
        cache = {
          ttl_seconds = DEV_CONFIG.cache_ttl,
        },
        rate_limiting = {
          enabled = false, -- Disable for local development
        },
      })
    end,
  }
}

-- Setup lazy.nvim
require("lazy").setup(plugins, {
  -- Lazy.nvim configuration
  install = {
    colorscheme = { "default" },
  },
  checker = {
    enabled = false,
  },
})

-- Basic Neovim settings for development
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Set leader key
vim.g.mapleader = " "

-- Development keymaps
vim.keymap.set('n', '<leader>no', ':lua require("nomad").toggle_sidebar()<CR>', { desc = "Toggle Nomad sidebar" })
vim.keymap.set('n', '<leader>nf', ':lua require("nomad").toggle_floating_right()<CR>', { desc = "Toggle floating sidebar" })
vim.keymap.set('n', '<leader>nr', ':lua require("nomad").refresh_cluster_data()<CR>', { desc = "Refresh cluster data" })
vim.keymap.set('n', '<leader>nj', ':lua require("nomad").search_jobs()<CR>', { desc = "Search jobs" })
vim.keymap.set('n', '<leader>nn', ':lua require("nomad").search_nodes()<CR>', { desc = "Search nodes" })
vim.keymap.set('n', '<leader>nt', ':lua require("nomad").show_topology()<CR>', { desc = "Show topology" })
vim.keymap.set('n', '<leader>nh', ':checkhealth nomad<CR>', { desc = "Check Nomad health" })

-- Development commands
vim.api.nvim_create_user_command("NomadReload", function()
  -- Reload the plugin
  package.loaded["nomad"] = nil
  package.loaded["nomad.config"] = nil
  package.loaded["nomad.nomad"] = nil
  package.loaded["nomad.ui"] = nil
  package.loaded["nomad.telescope"] = nil
  package.loaded["nomad.utils"] = nil
  package.loaded["nomad.health"] = nil
  
  require("nomad").setup({
    debug = DEV_CONFIG.debug,
    sidebar = {
      width = DEV_CONFIG.sidebar_width,
      position = DEV_CONFIG.sidebar_position,
    },
    nomad = {
      address = NOMAD_CONFIG.address,
      namespace = NOMAD_CONFIG.namespace,
      region = NOMAD_CONFIG.region,
      token = NOMAD_CONFIG.token,
    },
    ui = {
      show_icons = true,
      show_type = true,
      show_status = true,
      show_datacenter = true,
      show_node_class = true,
      refresh_interval = DEV_CONFIG.refresh_interval,
    },
    cache = {
      ttl_seconds = DEV_CONFIG.cache_ttl,
    },
    rate_limiting = {
      enabled = false,
    },
  })
  
  vim.schedule(function()
    vim.notify("Nomad.nvim reloaded!", vim.log.levels.INFO)
  end)
end, { desc = "Reload Nomad.nvim plugin" })

-- Development helper commands
vim.api.nvim_create_user_command("NomadDevStart", function()
  -- Start local Nomad in dev mode
  vim.fn.system("nomad agent -dev &")
  vim.schedule(function()
    vim.notify("Started Nomad in dev mode", vim.log.levels.INFO)
  end)
end, { desc = "Start Nomad in dev mode" })

vim.api.nvim_create_user_command("NomadDevJobs", function()
  -- Submit example jobs for testing
  local example_jobs = {
    {
      name = "example-web",
      command = [[nomad job run -detach - << 'EOF'
job "example-web" {
  datacenters = ["dc1"]
  type = "service"
  
  group "web" {
    count = 2
    
    task "nginx" {
      driver = "docker"
      
      config {
        image = "nginx:alpine"
        ports = ["http"]
      }
      
      resources {
        cpu = 100
        memory = 128
      }
      
      service {
        name = "nginx"
        port = "http"
        
        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
    
    network {
      port "http" {
        static = 8080
      }
    }
  }
}
EOF]]
    },
    {
      name = "example-batch",
      command = [[nomad job run -detach - << 'EOF'
job "example-batch" {
  datacenters = ["dc1"]
  type = "batch"
  
  group "batch" {
    count = 1
    
    task "hello" {
      driver = "docker"
      
      config {
        image = "alpine:latest"
        command = "sh"
        args = ["-c", "echo 'Hello from Nomad batch job!' && sleep 30"]
      }
      
      resources {
        cpu = 50
        memory = 64
      }
    }
  }
}
EOF]]
    }
  }
  
  for _, job in ipairs(example_jobs) do
    vim.fn.system(job.command)
    vim.schedule(function()
      vim.notify("Submitted " .. job.name .. " job", vim.log.levels.INFO)
    end)
  end
end, { desc = "Submit example jobs for testing" })

vim.api.nvim_create_user_command("NomadDevClean", function()
  -- Stop all jobs and clean up
  vim.fn.system("nomad job stop -purge example-web")
  vim.fn.system("nomad job stop -purge example-batch")
  vim.schedule(function()
    vim.notify("Cleaned up example jobs", vim.log.levels.INFO)
  end)
end, { desc = "Clean up example jobs" })

vim.api.nvim_create_user_command("NomadToggleDebug", function()
  -- Toggle debug mode
  local nomad = require("nomad")
  local config = require("nomad.config")
  config.options.debug = not config.options.debug
  
  vim.schedule(function()
    if config.options.debug then
      vim.notify("Nomad.nvim debug mode enabled", vim.log.levels.INFO)
    else
      vim.notify("Nomad.nvim debug mode disabled", vim.log.levels.INFO)
    end
  end)
end, { desc = "Toggle Nomad debug mode" })

-- Print development info
vim.schedule(function()
  local cwd = vim.fn.getcwd()
  local nomad_init = cwd .. "/lua/nomad/init.lua"
  
  if vim.loop.fs_stat(nomad_init) then
    vim.notify("✅ Nomad.nvim development environment loaded!", vim.log.levels.INFO)
    vim.notify("Plugin directory: " .. cwd, vim.log.levels.INFO)
    vim.notify("Nomad address: " .. NOMAD_CONFIG.address, vim.log.levels.INFO)
    vim.notify("Nomad namespace: " .. NOMAD_CONFIG.namespace, vim.log.levels.INFO)
    vim.notify("Available commands: :NomadToggle, :NomadRefresh, :NomadSearchJobs, :NomadTopology, :NomadHealth, :NomadReload", vim.log.levels.INFO)
    vim.notify("Dev commands: :NomadDevStart, :NomadDevJobs, :NomadDevClean, :NomadToggleDebug", vim.log.levels.INFO)
    vim.notify("Keymaps: <leader>no (toggle), <leader>nf (float), <leader>nr (refresh), <leader>nj (jobs), <leader>nn (nodes), <leader>nt (topology), <leader>nh (health)", vim.log.levels.INFO)
    
    -- Check if Nomad is running
    local nomad_status = vim.fn.system("curl -s " .. NOMAD_CONFIG.address .. "/v1/status/leader 2>/dev/null")
    if nomad_status and nomad_status ~= "" then
      vim.notify("✅ Nomad is running at " .. NOMAD_CONFIG.address, vim.log.levels.INFO)
    else
      vim.notify("⚠️  Nomad not detected. Run :NomadDevStart to start a local dev cluster", vim.log.levels.WARN)
    end
  else
    vim.notify("❌ Nomad.nvim plugin files not found", vim.log.levels.ERROR)
    vim.notify("Make sure to start Neovim from the plugin directory", vim.log.levels.ERROR)
  end
end) 