-- Nomad.nvim: Nomad Cluster Explorer for Neovim
-- Plugin entry point

if vim.g.loaded_nomad then
  return
end
vim.g.loaded_nomad = 1

-- Create user commands
vim.api.nvim_create_user_command("NomadToggle", function()
  require("nomad").toggle_sidebar()
end, {
  desc = "Toggle Nomad sidebar",
})

vim.api.nvim_create_user_command("NomadOpen", function()
  require("nomad").open_sidebar()
end, {
  desc = "Open Nomad sidebar",
})

vim.api.nvim_create_user_command("NomadClose", function()
  require("nomad").close_sidebar()
end, {
  desc = "Close Nomad sidebar",
})

vim.api.nvim_create_user_command("NomadRefresh", function()
  require("nomad").refresh_cluster_data()
end, {
  desc = "Refresh cluster data",
})

vim.api.nvim_create_user_command("NomadSearchJobs", function()
  require("nomad").search_jobs()
end, {
  desc = "Search jobs with Telescope",
})

vim.api.nvim_create_user_command("NomadSearchNodes", function()
  require("nomad").search_nodes()
end, {
  desc = "Search nodes with Telescope",
})

vim.api.nvim_create_user_command("NomadTopology", function()
  require("nomad").show_topology()
end, {
  desc = "Show cluster topology",
})

vim.api.nvim_create_user_command("NomadFloatRight", function()
  require("nomad").toggle_floating_right()
end, {
  desc = "Toggle floating sidebar on the right",
})

-- Job control commands
vim.api.nvim_create_user_command("NomadStartJob", function(opts)
  if opts.args == "" then
    vim.notify("Please provide a job ID", vim.log.levels.ERROR)
    return
  end
  require("nomad").start_job(opts.args)
end, {
  desc = "Start a job by ID",
  nargs = 1,
})

vim.api.nvim_create_user_command("NomadStopJob", function(opts)
  if opts.args == "" then
    vim.notify("Please provide a job ID", vim.log.levels.ERROR)
    return
  end
  require("nomad").stop_job(opts.args)
end, {
  desc = "Stop a job by ID",
  nargs = 1,
})

vim.api.nvim_create_user_command("NomadRestartJob", function(opts)
  if opts.args == "" then
    vim.notify("Please provide a job ID", vim.log.levels.ERROR)
    return
  end
  require("nomad").restart_job(opts.args)
end, {
  desc = "Restart a job by ID",
  nargs = 1,
})

-- Node control commands
vim.api.nvim_create_user_command("NomadDrainNode", function(opts)
  if opts.args == "" then
    vim.notify("Please provide a node ID", vim.log.levels.ERROR)
    return
  end
  require("nomad").drain_node(opts.args)
end, {
  desc = "Drain a node by ID",
  nargs = 1,
})

vim.api.nvim_create_user_command("NomadEnableNode", function(opts)
  if opts.args == "" then
    vim.notify("Please provide a node ID", vim.log.levels.ERROR)
    return
  end
  require("nomad").enable_node(opts.args)
end, {
  desc = "Enable a node by ID",
  nargs = 1,
})

-- Cache management command
vim.api.nvim_create_user_command("NomadClearCache", function()
  require("nomad.nomad").clear_cache()
end, {
  desc = "Clear Nomad data cache to force fresh data",
})

-- Set up health check
vim.api.nvim_create_user_command("NomadHealth", function()
  require("nomad.health").check()
end, {
  desc = "Check Nomad.nvim health",
})

vim.api.nvim_create_user_command("NomadHealthAll", function()
  require("nomad.health").check_all()
end, {
  desc = "Run all Nomad.nvim health checks",
})

-- Debug commands
vim.api.nvim_create_user_command("NomadDebug", function()
  local state = require("nomad").get_state()
  vim.notify("Jobs: " .. #state.jobs .. ", Nodes: " .. #state.nodes, vim.log.levels.INFO)
  print(vim.inspect(state))
end, {
  desc = "Show debug information",
})

-- Telescope integration commands
vim.api.nvim_create_user_command("NomadTelescope", function(opts)
  local subcommand = opts.args
  if subcommand == "jobs" then
    require("telescope").extensions.nomad.jobs()
  elseif subcommand == "nodes" then
    require("telescope").extensions.nomad.nodes()
  else
    vim.notify("Usage: NomadTelescope {jobs|nodes}", vim.log.levels.ERROR)
  end
end, {
  desc = "Open Nomad telescope picker",
  nargs = 1,
  complete = function()
    return { "jobs", "nodes" }
  end,
})

-- Logs command
vim.api.nvim_create_user_command("NomadLogs", function(opts)
  local args = vim.split(opts.args, " ")
  if #args < 2 then
    vim.notify("Usage: NomadLogs <job_id> <alloc_id> [task_name]", vim.log.levels.ERROR)
    return
  end
  
  local job_id = args[1]
  local alloc_id = args[2]
  local task_name = args[3] or "main"
  
  require("nomad").show_job_logs(job_id, alloc_id, task_name)
end, {
  desc = "Show logs for a job allocation",
  nargs = "+",
})

-- Help command
vim.api.nvim_create_user_command("NomadHelp", function()
  local help_text = {
    "🚀 Nomad.nvim Commands:",
    "",
    "📋 Basic Commands:",
    "  :NomadToggle          - Toggle sidebar",
    "  :NomadOpen            - Open sidebar", 
    "  :NomadClose           - Close sidebar",
    "  :NomadRefresh         - Refresh cluster data",
    "",
    "🔍 Search Commands:",
    "  :NomadSearchJobs      - Search jobs (Telescope)",
    "  :NomadSearchNodes     - Search nodes (Telescope)",
    "  :NomadTelescope jobs  - Telescope jobs picker",
    "  :NomadTelescope nodes - Telescope nodes picker",
    "",
    "🏗️  Topology & Logs:",
    "  :NomadTopology        - Show enhanced cluster topology",
    "  :NomadLogs <job> <alloc> [task] - Show job logs",
    "",
    "⚙️  Job Control:",
    "  :NomadStartJob <id>   - Start job",
    "  :NomadStopJob <id>    - Stop job", 
    "  :NomadRestartJob <id> - Restart job",
    "",
    "🖥️  Node Control:",
    "  :NomadDrainNode <id>  - Drain node",
    "  :NomadEnableNode <id> - Enable node",
    "",
    "🔧 Utility Commands:",
    "  :NomadFloatRight      - Toggle floating sidebar",
    "  :NomadClearCache      - Clear data cache",
    "  :NomadHealth          - Health check",
    "  :NomadDebug           - Show debug info",
    "",
    "💡 Telescope Keymaps (in job/node picker):",
    "  <Enter>    - Show details",
    "  <C-s>      - Start job",
    "  <C-S>      - Stop job", 
    "  <C-r>      - Restart job",
    "  <C-l>      - View logs (jobs only)",
    "  <C-d>      - Drain node (nodes only)",
    "  <C-e>      - Enable node (nodes only)",
    "  <C-y>      - Copy ID to clipboard",
    "",
    "📖 Interactive Buffer Keymaps:",
    "  q, <Esc>   - Close buffer",
    "  r          - Refresh data",
    "  f          - Follow logs (logs buffer only)",
    "  l          - View logs (job details only)",
  }
  
  -- Create a new buffer for help
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = math.min(80, vim.o.columns - 4),
    height = math.min(#help_text + 4, vim.o.lines - 4),
    row = math.floor((vim.o.lines - math.min(#help_text + 4, vim.o.lines - 4)) / 2),
    col = math.floor((vim.o.columns - math.min(80, vim.o.columns - 4)) / 2),
    style = "minimal",
    border = "rounded",
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_name(bufnr, "Nomad Help")
  
  -- Set content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, help_text)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "nomad-help")
  
  -- Close on q or Escape
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
end, {
  desc = "Show Nomad.nvim help",
}) 