-- Nomad.nvim: Nomad Cluster Explorer for Neovim
-- Main module

local config = require("nomad.config")
local ui = require("nomad.ui")
local nomad = require("nomad.nomad")
local telescope_extension = require("nomad.telescope")

local M = {}

-- Plugin state
M.state = {
  setup_done = false,
  sidebar_open = false,
  jobs = {},
  nodes = {},
  topology = {},
  loading = false,
}

-- Setup function
function M.setup(opts)
  if M.state.setup_done then
    return
  end

  -- Merge user config with defaults
  config.setup(opts)

  -- Register telescope extension
  telescope_extension.setup()

  -- Set up global keymaps if configured
  if config.options.keymaps.toggle_sidebar then
    vim.keymap.set("n", config.options.keymaps.toggle_sidebar, function()
      M.toggle_sidebar()
    end, { desc = "Toggle Nomad sidebar" })
  end

  if config.options.keymaps.toggle_floating then
    vim.keymap.set("n", config.options.keymaps.toggle_floating, function()
      M.toggle_floating_right()
    end, { desc = "Toggle floating sidebar on right" })
  end

  M.state.setup_done = true
end

-- Toggle sidebar
function M.toggle_sidebar()
  if M.state.sidebar_open then
    M.close_sidebar()
  else
    M.open_sidebar()
  end
end

-- Open sidebar
function M.open_sidebar()
  if M.state.sidebar_open then
    return
  end

  -- Create and show sidebar
  ui.create_sidebar()
  M.state.sidebar_open = true

  -- Load data if not already loaded
  if (#M.state.jobs == 0 and #M.state.nodes == 0) and not M.state.loading then
    M.refresh_cluster_data()
  else
    ui.update_sidebar({
      jobs = M.state.jobs,
      nodes = M.state.nodes,
      topology = M.state.topology,
    })
  end
end

-- Close sidebar
function M.close_sidebar()
  if not M.state.sidebar_open then
    return
  end

  ui.close_sidebar()
  M.state.sidebar_open = false
end

-- Refresh cluster data
function M.refresh_cluster_data()
  if M.state.loading then
    return
  end

  M.state.loading = true

  -- Update UI to show loading state
  if M.state.sidebar_open then
    ui.show_loading()
  end

  -- Fetch jobs and nodes in parallel
  local jobs_done = false
  local nodes_done = false
  local jobs_error = nil
  local nodes_error = nil

  local function check_completion()
    if jobs_done and nodes_done then
      M.state.loading = false

      vim.schedule(function()
        if jobs_error and nodes_error then
          vim.notify("Failed to fetch cluster data: " .. jobs_error .. "; " .. nodes_error, vim.log.levels.ERROR)
          if M.state.sidebar_open then
            ui.show_error(jobs_error .. "; " .. nodes_error)
          end
          return
        elseif jobs_error then
          vim.notify("Failed to fetch jobs: " .. jobs_error, vim.log.levels.ERROR)
        elseif nodes_error then
          vim.notify("Failed to fetch nodes: " .. nodes_error, vim.log.levels.ERROR)
        end

        -- Generate topology data
        M.state.topology = nomad.generate_topology(M.state.jobs, M.state.nodes)

        -- Update sidebar if open
        if M.state.sidebar_open then
          ui.update_sidebar({
            jobs = M.state.jobs,
            nodes = M.state.nodes,
            topology = M.state.topology,
          })
        end

        vim.notify("Refreshed " .. #M.state.jobs .. " jobs and " .. #M.state.nodes .. " nodes", vim.log.levels.INFO)
      end)
    end
  end

  nomad.get_jobs(function(jobs, error)
    M.state.jobs = jobs or {}
    jobs_error = error
    jobs_done = true
    check_completion()
  end)

  nomad.get_nodes(function(nodes, error)
    M.state.nodes = nodes or {}
    nodes_error = error
    nodes_done = true
    check_completion()
  end)
end

-- Search jobs with telescope
function M.search_jobs()
  if #M.state.jobs == 0 then
    vim.schedule(function()
      vim.notify("No jobs loaded. Refreshing...", vim.log.levels.INFO)
    end)
    M.refresh_cluster_data()
    return
  end

  telescope_extension.search_jobs(M.state.jobs)
end

-- Search nodes with telescope
function M.search_nodes()
  if #M.state.nodes == 0 then
    vim.schedule(function()
      vim.notify("No nodes loaded. Refreshing...", vim.log.levels.INFO)
    end)
    M.refresh_cluster_data()
    return
  end

  telescope_extension.search_nodes(M.state.nodes)
end

-- Show job details
function M.show_job_details(job)
  nomad.get_job_details(job, function(details, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to get job details: " .. error, vim.log.levels.ERROR)
        return
      end

      ui.show_job_details_enhanced(job, details)
    end)
  end)
end

-- Show node details
function M.show_node_details(node)
  nomad.get_node_details(node, function(details, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to get node details: " .. error, vim.log.levels.ERROR)
        return
      end

      ui.show_node_details(node, details)
    end)
  end)
end

-- Show enhanced topology view
function M.show_topology()
  if #M.state.nodes == 0 then
    vim.schedule(function()
      vim.notify("No cluster data loaded. Refreshing...", vim.log.levels.INFO)
    end)
    M.refresh_cluster_data()
    return
  end

  vim.schedule(function()
    vim.notify("Loading enhanced topology data...", vim.log.levels.INFO)
  end)

  -- Get allocations data for enhanced topology
  nomad.get_allocations(function(allocations, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to get allocations: " .. error, vim.log.levels.ERROR)
        -- Fallback to basic topology
        ui.show_topology(M.state.topology)
        return
      end

      -- Generate enhanced topology with allocations
      nomad.generate_enhanced_topology(M.state.jobs, M.state.nodes, allocations, function(enhanced_topology, topo_error)
        if topo_error then
          vim.notify("Failed to generate enhanced topology: " .. topo_error, vim.log.levels.ERROR)
          ui.show_topology(M.state.topology)
        else
          M.state.enhanced_topology = enhanced_topology
          ui.show_topology_buffer(enhanced_topology)
        end
      end)
    end)
  end)
end

-- Copy job ID to clipboard
function M.copy_job_id(job)
  vim.fn.setreg("+", job.ID)
  vim.schedule(function()
    vim.notify("Copied job ID: " .. job.ID, vim.log.levels.INFO)
  end)
end

-- Copy node ID to clipboard
function M.copy_node_id(node)
  vim.fn.setreg("+", node.ID)
  vim.schedule(function()
    vim.notify("Copied node ID: " .. node.ID, vim.log.levels.INFO)
  end)
end

-- Toggle sidebar to floating on the right
function M.toggle_floating_right()
  local current_config = config.get()

  if current_config.sidebar.position == "float" then
    -- Switch back to left split
    current_config.sidebar.position = "left"
  else
    -- Switch to floating on the right
    current_config.sidebar.position = "float"
  end

  -- Close current sidebar if open
  if M.state.sidebar_open then
    M.close_sidebar()
    -- Reopen with new position
    vim.schedule(function()
      M.open_sidebar()
    end)
  end
end

-- Get current state (for telescope extension)
function M.get_state()
  return M.state
end

-- Job control functions
function M.start_job(job_id)
  nomad.start_job(job_id, function(success, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to start job " .. job_id .. ": " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Job " .. job_id .. " started successfully", vim.log.levels.INFO)
        M.refresh_cluster_data()
      end
    end)
  end)
end

function M.stop_job(job_id)
  nomad.stop_job(job_id, function(success, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to stop job " .. job_id .. ": " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Job " .. job_id .. " stopped successfully", vim.log.levels.INFO)
        M.refresh_cluster_data()
      end
    end)
  end)
end

function M.restart_job(job_id)
  nomad.restart_job(job_id, function(success, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to restart job " .. job_id .. ": " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Job " .. job_id .. " restarted successfully", vim.log.levels.INFO)
        M.refresh_cluster_data()
      end
    end)
  end)
end

-- Node control functions
function M.drain_node(node_id)
  nomad.drain_node(node_id, function(success, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to drain node " .. node_id .. ": " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Node " .. node_id .. " drain initiated", vim.log.levels.INFO)
        M.refresh_cluster_data()
      end
    end)
  end)
end

function M.enable_node(node_id)
  nomad.enable_node(node_id, function(success, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to enable node " .. node_id .. ": " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Node " .. node_id .. " enabled successfully", vim.log.levels.INFO)
        M.refresh_cluster_data()
      end
    end)
  end)
end

-- Show logs for a job allocation
function M.show_job_logs(job_id, alloc_id, task_name)
  vim.schedule(function()
    vim.notify("Loading logs for " .. job_id .. "...", vim.log.levels.INFO)
  end)

  nomad.get_allocation_logs(alloc_id, task_name or "main", function(logs, error)
    vim.schedule(function()
      if error then
        vim.notify("Failed to get logs: " .. error, vim.log.levels.ERROR)
        return
      end

      ui.show_logs_buffer(job_id, alloc_id, task_name or "main", logs)
    end)
  end)
end

return M
