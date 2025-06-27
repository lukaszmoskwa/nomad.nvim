# Nomad.nvim 🚀

**Nomad Cluster Explorer for Neovim**

Nomad.nvim is a Neovim plugin that provides a beautiful sidebar interface to explore and manage your Nomad cluster directly from your editor. Monitor jobs, nodes, and cluster topology with ease.

## ✨ Features

- 🔍 **Interactive Sidebar**: Browse jobs and nodes with real-time status
- 🔭 **Telescope Integration**: Fuzzy search jobs and nodes with advanced filtering
- 📊 **Enhanced Cluster Topology**: Interactive full-buffer view showing resource usage and allocations per node
- 📋 **Job Logs Viewer**: Interactive logs display with refresh and follow capabilities
- ⚙️ **Job Control**: Start, stop, restart jobs directly from Neovim
- 🖥️ **Node Management**: Drain and enable nodes with a single command
- 🎯 **Multiple Layouts**: Sidebar, floating window, or split pane
- 🚀 **Async Operations**: Non-blocking API calls with caching and rate limiting
- 🔐 **ACL Support**: Works with Nomad clusters that have ACLs enabled
- 🌐 **Multi-Datacenter**: Support for multi-datacenter Nomad clusters
- 📈 **Resource Monitoring**: View CPU, memory, and disk usage per node
- 🔄 **Auto-refresh**: Configurable auto-refresh intervals
- 💾 **Smart Caching**: Intelligent caching to reduce API load

## 📋 Requirements

- Neovim >= 0.8.0
- Nomad cluster accessible via HTTP API
- Required Neovim plugins:
  - [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
  - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
  - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) (optional, for icons)

## 🚀 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lukaszmoskwa/nomad.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- optional
  },
  config = function()
    require("nomad").setup({
      -- your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "lukaszmoskwa/nomad.nvim",
  requires = {
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- optional
  },
  config = function()
    require("nomad").setup()
  end,
}
```

## ⚙️ Configuration

```lua
require("nomad").setup({
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
    token = nil,   -- nil to use NOMAD_TOKEN environment variable
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
    logs = "l", -- coming soon
    exec = "e", -- coming soon
    copy_id = "y",
    copy_name = "Y",
    search_jobs = "j",
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
})
```

## 🎯 Usage

### Basic Commands

- `:NomadToggle` - Toggle the sidebar
- `:NomadOpen` - Open the sidebar
- `:NomadClose` - Close the sidebar
- `:NomadRefresh` - Refresh cluster data
- `:NomadSearchJobs` - Open Telescope job search
- `:NomadSearchNodes` - Open Telescope node search
- `:NomadTopology` - Show enhanced cluster topology with resource usage
- `:NomadLogs <job_id> <alloc_id> [task_name]` - Show logs for a job allocation
- `:NomadHelp` - Show comprehensive help with all commands and keymaps

### Enhanced Topology View

The topology view now shows:

- **Resource Usage**: CPU, Memory, and Disk usage per datacenter and node
- **Allocation Details**: Which jobs are running on each node
- **Resource Consumption**: How much resources each allocation is using
- **Interactive Navigation**: Press `r` to refresh, `q` to close

### Job Logs Viewer

Features include:

- **Interactive Buffer**: Full-screen logs view with syntax highlighting
- **Real-time Refresh**: Press `r` to refresh logs
- **Follow Mode**: Press `f` to follow/stream logs
- **Multiple Tasks**: Support for multi-task jobs
- **Timestamp Display**: Shows when logs were retrieved

### Job Control Commands

- `:NomadStartJob <job-id>` - Start a specific job
- `:NomadStopJob <job-id>` - Stop a specific job
- `:NomadRestartJob <job-id>` - Restart a specific job

### Node Control Commands

- `:NomadDrainNode <node-id>` - Drain a specific node
- `:NomadEnableNode <node-id>` - Enable a specific node

### Cache Management Commands

- `:NomadClearCache` - Clear cached cluster data to force fresh API calls

### Default Keybindings

In the sidebar:

- `<CR>` - View job/node details
- `l` - View job logs (from job details popup)
- `e` - Exec into job allocation (coming soon)
- `y` - Copy job/node ID to clipboard
- `Y` - Copy job/node name to clipboard
- `r` - Refresh cluster data
- `j` - Search jobs with Telescope
- `n` - Search nodes with Telescope
- `t` - Show enhanced cluster topology
- `q` - Close sidebar

**Job Control (when focused on a job):**

- `s` - Start job
- `S` - Stop job
- `R` - Restart job

**Node Control (when focused on a node):**

- `d` - Drain node
- `E` - Enable node

**Interactive Buffer Keymaps (Topology/Logs):**

- `q`, `<Esc>` - Close buffer
- `r` - Refresh data
- `f` - Follow logs (logs buffer only)

Global:

- `<leader>no` - Toggle sidebar
- `<leader>nf` - Toggle floating sidebar

### Telescope Integration

Use the telescope extensions for advanced searching:

```lua
-- Search jobs
:Telescope nomad jobs

-- Search nodes
:Telescope nomad nodes

-- Combined search
:Telescope nomad combined
```

**Enhanced Telescope Keymaps:**

- `<Enter>` - Show enhanced job/node details
- `<C-s>` - Start job (in job picker)
- `<C-S>` - Stop job (in job picker)
- `<C-r>` - Restart job (in job picker)
- `<C-l>` - View logs (in job picker) 🆕
- `<C-d>` - Drain node (in node picker)
- `<C-e>` - Enable node (in node picker)
- `<C-y>` - Copy ID to clipboard

## 🔧 Setup & Configuration

### Environment Variables

Nomad.nvim respects the following environment variables:

- `NOMAD_ADDR` - Nomad cluster address (default: http://localhost:4646)
- `NOMAD_TOKEN` - Nomad ACL token for authentication
- `NOMAD_REGION` - Nomad region to use
- `NOMAD_NAMESPACE` - Nomad namespace to use
- `NOMAD_CACERT` - Path to CA certificate file
- `NOMAD_CLIENT_CERT` - Path to client certificate file
- `NOMAD_CLIENT_KEY` - Path to client private key file

### Connecting to Remote Clusters

```lua
require("nomad").setup({
  nomad = {
    address = "https://nomad.example.com:4646",
    token = "your-acl-token-here",
    namespace = "production",
    region = "us-west-2",
  },
})
```

### ACL Configuration

If your Nomad cluster has ACLs enabled, you'll need to provide a token:

```lua
require("nomad").setup({
  nomad = {
    token = "your-nomad-acl-token",
  },
})
```

Or set the environment variable:

```bash
export NOMAD_TOKEN="your-nomad-acl-token"
```

## 🔍 Troubleshooting

### "Connection Failed" Error

If you encounter connection errors, check:

1. **Nomad Address**: Ensure `NOMAD_ADDR` is set correctly or configured in setup
2. **Network Connectivity**: Verify you can reach the Nomad cluster
3. **ACL Token**: If ACLs are enabled, ensure you have a valid token

### Performance Issues

If the plugin feels slow:

1. **Increase Cache TTL**: Set longer `cache.ttl_seconds` to reduce API calls
2. **Adjust Rate Limiting**: Tune `rate_limiting` settings for your cluster
3. **Reduce Refresh Interval**: Increase `ui.refresh_interval` to refresh less frequently

### Health Check

Run the health check to diagnose issues:

```vim
:NomadHealth
:NomadHealthAll  " More comprehensive check
```

## 🛠️ Development

### Quick Start Development Environment

For rapid development and testing, use the included development configuration:

```bash
# Clone the repository
git clone https://github.com/lukaszmoskwa/nomad.nvim.git
cd nomad.nvim

# Create development Neovim config directory
mkdir -p ~/.config/nvim-nomad

# Copy development config
cp development.lua ~/.config/nvim-nomad/init.lua

# Start development Neovim instance FROM THE PLUGIN DIRECTORY
NVIM_APPNAME=nvim-nomad nvim
```

This creates an isolated Neovim instance with:

- ✅ All dependencies automatically installed
- ✅ Plugin loaded from local directory
- ✅ Development-optimized configuration
- ✅ Hot-reload capability
- ✅ Debug mode enabled
- ✅ Helper commands for testing

### Development Commands

The development environment includes special commands:

#### Plugin Management

- `:NomadReload` - Hot-reload the plugin without restarting Neovim
- `:NomadHealth` - Run health checks
- `:NomadDebug` - Show plugin state and debug information

#### Local Nomad Cluster

- `:NomadDevStart` - Start a local Nomad cluster in dev mode
- `:NomadDevJobs` - Submit example jobs for testing
- `:NomadDevClean` - Clean up example jobs

### Development Keymaps

In the development environment:

- `<leader>no` - Toggle sidebar
- `<leader>nf` - Toggle floating sidebar
- `<leader>nr` - Refresh cluster data
- `<leader>nj` - Search jobs
- `<leader>nn` - Search nodes
- `<leader>nt` - Show topology
- `<leader>nh` - Run health check

### Setting Up Local Nomad

1. **Install Nomad** (if not already installed):

   ```bash
   # macOS
   brew install nomad

   # Linux
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install nomad
   ```

2. **Start Development Cluster**:

   ```bash
   # Option 1: Use the development command
   :NomadDevStart

   # Option 2: Manual start
   nomad agent -dev
   ```

3. **Submit Test Jobs**:

   ```bash
   # Use the development command
   :NomadDevJobs

   # Or manually
   nomad job run example.nomad
   ```

### Development Configuration

The development environment uses optimized settings:

```lua
require("nomad").setup({
  debug = true,                    -- Enable debug logging
  sidebar = { width = 50 },        -- Wider sidebar for development
  nomad = {
    address = "http://localhost:4646"  -- Local Nomad cluster
  },
  ui = {
    refresh_interval = 10,         -- Faster refresh (10s vs 30s)
  },
  cache = {
    ttl_seconds = 10,             -- Shorter cache (10s vs 30s)
  },
  rate_limiting = {
    enabled = false,              -- Disabled for local development
  },
})
```

### Testing Workflow

1. **Start the development environment** (from the plugin directory):

   ```bash
   cd nomad.nvim  # Make sure you're in the plugin directory!
   NVIM_APPNAME=nvim-nomad nvim
   ```

2. **Start local Nomad** (if not running):

   ```vim
   :NomadDevStart
   ```

3. **Submit test jobs**:

   ```vim
   :NomadDevJobs
   ```

4. **Test the plugin**:

   ```vim
   :NomadToggle      " Open sidebar
   :NomadTopology    " View cluster topology
   :NomadSearchJobs  " Search jobs with Telescope
   ```

5. **Make changes and reload**:

   ```vim
   :NomadReload      " Hot-reload after code changes
   ```

6. **Clean up when done**:
   ```vim
   :NomadDevClean    " Remove test jobs
   ```

### Running Tests

The plugin includes comprehensive health checks:

```lua
-- Run all health checks
require("nomad.health").check_all()

-- Run specific checks
require("nomad.health").check()
require("nomad.health").check_environment(vim.health)
require("nomad.health").check_performance(vim.health)
```

### Code Structure for Contributors

```
nomad.nvim/
├── lua/nomad/
│   ├── init.lua          # Main plugin entry point
│   ├── config.lua        # Configuration management
│   ├── nomad.lua         # Nomad API integration
│   ├── ui.lua            # UI components (nui.nvim)
│   ├── telescope.lua     # Telescope integration
│   ├── utils.lua         # Utility functions
│   └── health.lua        # Health checks
├── lua/telescope/_extensions/
│   └── nomad.lua         # Telescope extension
├── plugin/
│   └── nomad.lua         # Plugin commands
├── development.lua       # Development environment
└── README.md
```

### Contributing Guidelines

1. **Fork and clone** the repository
2. **Set up development environment** using `development.lua`
3. **Create feature branch**: `git checkout -b feature/your-feature`
4. **Test thoroughly** with `:NomadHealth` and manual testing
5. **Update documentation** if adding new features
6. **Submit pull request** with clear description

### Debugging Tips

1. **Enable debug mode**:

   ```lua
   require("nomad").setup({ debug = true })
   ```

2. **Check plugin state**:

   ```vim
   :NomadDebug
   ```

3. **View logs**:

   ```bash
   tail -f ~/.local/share/nvim/log
   ```

4. **Test API connectivity**:
   ```bash
   curl http://localhost:4646/v1/status/leader
   curl http://localhost:4646/v1/jobs
   ```

### Common Development Issues

| Issue                      | Solution                                                                                     |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| `module 'nomad' not found` | Must start Neovim from the plugin directory: `cd nomad.nvim && NVIM_APPNAME=nvim-nomad nvim` |
| Plugin not loading         | Check `:NomadHealth` and ensure dependencies are installed                                   |
| API errors                 | Verify Nomad is running: `nomad status`                                                      |
| UI not updating            | Try `:NomadClearCache` and `:NomadRefresh`                                                   |
| Telescope not working      | Ensure telescope.nvim is properly installed                                                  |
| Hot-reload issues          | Use `:NomadReload` or restart Neovim                                                         |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [nimure](https://github.com/lukaszmoskwa/nimure) for Azure resource management
- Built with [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for beautiful UI components
- Powered by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for fuzzy finding
- Uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async operations

## 🔮 Roadmap

- [ ] Job log viewing
- [ ] Allocation exec functionality
- [ ] Metrics and monitoring integration
- [ ] Job specification editing
- [ ] Allocation resource usage charts
- [ ] Custom job templates
- [ ] Multi-cluster support
- [ ] Advanced filtering and sorting
- [ ] Notification system for job state changes
- [ ] Integration with other HashiCorp tools (Consul, Vault)

---

**Made 100% with Cursor**

> Note: This project is 100% Cursor-generated. I don't know how to feel about this.

