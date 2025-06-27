-- UI module using nui.nvim

local NuiTree = require("nui.tree")
local NuiSplit = require("nui.split")
local NuiPopup = require("nui.popup")
local NuiLine = require("nui.line")
local NuiText = require("nui.text")

local config = require("nomad.config")
local utils = require("nomad.utils")

local M = {}

-- UI state
M.sidebar = nil
M.details_popup = nil
M.topology_popup = nil
M.tree = nil

-- Create sidebar
function M.create_sidebar()
  if M.sidebar then
    return
  end

  local options = config.get()
  
  if options.sidebar.position == "float" then
    -- Create floating sidebar
    M.sidebar = NuiPopup({
      relative = options.sidebar.float.relative,
      position = {
        row = options.sidebar.float.row,
        col = options.sidebar.float.col,
      },
      size = {
        width = options.sidebar.float.width,
        height = options.sidebar.float.height,
      },
      border = {
        style = options.sidebar.border,
        text = {
          top = " Nomad Cluster ",
        },
      },
      buf_options = {
        modifiable = false,
        readonly = true,
        filetype = "nomad",
      },
      win_options = {
        number = false,
        relativenumber = false,
        wrap = false,
        cursorline = true,
      },
    })
  else
    -- Create split sidebar
    M.sidebar = NuiSplit({
      relative = "editor",
      position = options.sidebar.position,
      size = options.sidebar.width,
      buf_options = {
        modifiable = false,
        readonly = true,
        filetype = "nomad",
      },
      win_options = {
        number = false,
        relativenumber = false,
        wrap = false,
        cursorline = true,
      },
    })
  end

  M.sidebar:mount()
  
  -- Set up keymaps
  M.setup_sidebar_keymaps()
  
  -- Set up autocmds
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(M.sidebar.winid),
    callback = function()
      vim.schedule(function()
        M.close_sidebar()
      end)
    end,
    once = true,
  })
end

-- Setup sidebar keymaps
function M.setup_sidebar_keymaps()
  if not M.sidebar then
    return
  end

  local options = config.get()
  local bufnr = M.sidebar.bufnr

  -- Close sidebar
  vim.keymap.set('n', options.keymaps.close, function()
    require("nomad").close_sidebar()
  end, { buffer = bufnr, desc = "Close Nomad sidebar" })

  -- Refresh cluster data
  vim.keymap.set('n', options.keymaps.refresh, function()
    require("nomad").refresh_cluster_data()
  end, { buffer = bufnr, desc = "Refresh cluster data" })

  -- Show details
  vim.keymap.set('n', options.keymaps.details, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node then
        if node.job then
          require("nomad").show_job_details(node.job)
        elseif node.node then
          require("nomad").show_node_details(node.node)
        end
      end
    end
  end, { buffer = bufnr, desc = "Show details" })

  -- Show logs
  vim.keymap.set('n', options.keymaps.logs, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.job then
        M.show_job_logs(node.job)
      end
    end
  end, { buffer = bufnr, desc = "Show job logs" })

  -- Exec into allocation
  vim.keymap.set('n', options.keymaps.exec, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.job then
        M.exec_into_job(node.job)
      end
    end
  end, { buffer = bufnr, desc = "Exec into job" })

  -- Copy ID
  vim.keymap.set('n', options.keymaps.copy_id, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node then
        if node.job then
          require("nomad").copy_job_id(node.job)
        elseif node.node then
          require("nomad").copy_node_id(node.node)
        end
      end
    end
  end, { buffer = bufnr, desc = "Copy ID" })

  -- Copy name
  vim.keymap.set('n', options.keymaps.copy_name, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node then
        if node.job then
          vim.fn.setreg('+', node.job.Name or node.job.ID)
          vim.notify("Copied job name: " .. (node.job.Name or node.job.ID), vim.log.levels.INFO)
        elseif node.node then
          vim.fn.setreg('+', node.node.Name or node.node.ID)
          vim.notify("Copied node name: " .. (node.node.Name or node.node.ID), vim.log.levels.INFO)
        end
      end
    end
  end, { buffer = bufnr, desc = "Copy name" })

  -- Search jobs
  vim.keymap.set('n', options.keymaps.search_jobs, function()
    require("nomad").search_jobs()
  end, { buffer = bufnr, desc = "Search jobs" })

  -- Search nodes
  vim.keymap.set('n', options.keymaps.search_nodes, function()
    require("nomad").search_nodes()
  end, { buffer = bufnr, desc = "Search nodes" })

  -- Show topology
  vim.keymap.set('n', options.keymaps.topology, function()
    require("nomad").show_topology()
  end, { buffer = bufnr, desc = "Show topology" })

  -- Job control
  vim.keymap.set('n', options.keymaps.start_job, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.job then
        require("nomad").start_job(node.job.ID)
      end
    end
  end, { buffer = bufnr, desc = "Start job" })

  vim.keymap.set('n', options.keymaps.stop_job, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.job then
        require("nomad").stop_job(node.job.ID)
      end
    end
  end, { buffer = bufnr, desc = "Stop job" })

  vim.keymap.set('n', options.keymaps.restart_job, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.job then
        require("nomad").restart_job(node.job.ID)
      end
    end
  end, { buffer = bufnr, desc = "Restart job" })

  -- Node control
  vim.keymap.set('n', options.keymaps.drain_node, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.node then
        require("nomad").drain_node(node.node.ID)
      end
    end
  end, { buffer = bufnr, desc = "Drain node" })

  vim.keymap.set('n', options.keymaps.enable_node, function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and node.node then
        require("nomad").enable_node(node.node.ID)
      end
    end
  end, { buffer = bufnr, desc = "Enable node" })

  -- Tree navigation
  vim.keymap.set('n', '<Space>', function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and (node.jobs_section or node.nodes_section) then
        if node:is_expanded() then
          node:collapse()
        else
          node:expand()
        end
        M.tree:render()
      end
    end
  end, { buffer = bufnr, desc = "Expand/collapse section" })

  -- Arrow key navigation
  vim.keymap.set('n', '<Right>', function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and (node.jobs_section or node.nodes_section) and not node:is_expanded() then
        node:expand()
        M.tree:render()
      end
    end
  end, { buffer = bufnr, desc = "Expand section" })

  vim.keymap.set('n', '<Left>', function()
    if M.tree then
      local ok, node = pcall(M.tree.get_node, M.tree)
      if ok and node and (node.jobs_section or node.nodes_section) and node:is_expanded() then
        node:collapse()
        M.tree:render()
      end
    end
  end, { buffer = bufnr, desc = "Collapse section" })
end

-- Close sidebar
function M.close_sidebar()
  if M.sidebar then
    M.sidebar:unmount()
    M.sidebar = nil
    M.tree = nil
  end
  
  -- Close any open popups
  M.close_popups()
end

-- Close all popups
function M.close_popups()
  if M.details_popup then
    M.details_popup:unmount()
    M.details_popup = nil
  end
  
  if M.topology_popup then
    M.topology_popup:unmount()
    M.topology_popup = nil
  end
end

-- Show loading state
function M.show_loading()
  if not M.sidebar then
    return
  end

  local loading_text = NuiText("Loading cluster data...", "Comment")
  local line = NuiLine()
  line:append(loading_text)

  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.sidebar.bufnr, 0, -1, false, {})
  line:render(M.sidebar.bufnr, -1, 1)
  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", false)
end

-- Show error state
function M.show_error(error_message)
  if not M.sidebar then
    return
  end

  local error_text = NuiText("Error: " .. error_message, "ErrorMsg")
  local line = NuiLine()
  line:append(error_text)

  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.sidebar.bufnr, 0, -1, false, {})
  line:render(M.sidebar.bufnr, -1, 1)
  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", false)
end

-- Update sidebar with cluster data
function M.update_sidebar(data)
  if not M.sidebar then
    return
  end

  local jobs = data.jobs or {}
  local nodes = data.nodes or {}
  local options = config.get()

  -- Create tree nodes
  local tree_nodes = {}

  -- Jobs section
  local jobs_children = {}
  for _, job in ipairs(jobs) do
    local display_text = job.ID
    if options.ui.show_status then
      display_text = job.StatusDisplay .. " " .. display_text
    end
    if options.ui.show_type then
      display_text = display_text .. " [" .. (job.TypeDisplay or job.Type or "unknown") .. "]"
    end
    if options.ui.show_namespace and job.Namespace and job.Namespace ~= "default" then
      display_text = display_text .. " (" .. job.Namespace .. ")"
    end

    table.insert(jobs_children, NuiTree.Node({ text = display_text, job = job }))
  end

  local jobs_section = NuiTree.Node(
    { text = "📦 Jobs (" .. #jobs .. ")", jobs_section = true },
    jobs_children
  )
  table.insert(tree_nodes, jobs_section)

  -- Nodes section
  local nodes_children = {}
  for _, node in ipairs(nodes) do
    local display_text = node.Name or node.ID
    if options.ui.show_status then
      display_text = node.StatusDisplay .. " " .. display_text
    end
    if options.ui.show_node_class then
      display_text = display_text .. " [" .. (node.ClassDisplay or node.NodeClass or "default") .. "]"
    end
    if options.ui.show_datacenter and node.Datacenter then
      display_text = display_text .. " (" .. node.Datacenter .. ")"
    end

    table.insert(nodes_children, NuiTree.Node({ text = display_text, node = node }))
  end

  local nodes_section = NuiTree.Node(
    { text = "🖥️  Nodes (" .. #nodes .. ")", nodes_section = true },
    nodes_children
  )
  table.insert(tree_nodes, nodes_section)

  -- Create tree
  M.tree = NuiTree({
    winid = M.sidebar.winid,
    nodes = tree_nodes,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(string.rep(options.ui.indent, node:get_depth() - 1))
      
      if node:has_children() then
        line:append(node:is_expanded() and "▼ " or "▶ ", "Special")
      else
        line:append("  ")
      end
      
      line:append(node.text)
      return line
    end,
  })

  -- Render tree
  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", true)
  M.tree:render()
  vim.api.nvim_buf_set_option(M.sidebar.bufnr, "modifiable", false)

  -- Expand sections by default
  jobs_section:expand()
  nodes_section:expand()
  M.tree:render()
end

-- Show job details in popup
function M.show_job_details(job, details)
  M.close_popups()

  local content = {}
  table.insert(content, "Job: " .. job.ID)
  table.insert(content, "Status: " .. (job.Status or "unknown"))
  table.insert(content, "Type: " .. (job.Type or "unknown"))
  table.insert(content, "Namespace: " .. (job.Namespace or "default"))
  
  if job.Datacenters then
    table.insert(content, "Datacenters: " .. table.concat(job.Datacenters, ", "))
  end
  
  if details then
    table.insert(content, "")
    table.insert(content, "=== Details ===")
    if details.TaskGroups then
      table.insert(content, "Task Groups: " .. #details.TaskGroups)
      for _, tg in ipairs(details.TaskGroups) do
        table.insert(content, "  - " .. tg.Name .. " (Count: " .. (tg.Count or 1) .. ")")
      end
    end
    
    if details.Allocations then
      table.insert(content, "")
      table.insert(content, "Allocations: " .. #details.Allocations)
      for _, alloc in ipairs(details.Allocations) do
        table.insert(content, "  - " .. (alloc.ID or "unknown") .. " [" .. (alloc.ClientStatus or "unknown") .. "]")
      end
    end
  end

  M.details_popup = NuiPopup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Job Details ",
      },
    },
    position = "50%",
    size = {
      width = 80,
      height = math.min(#content + 4, 30),
    },
  })

  M.details_popup:mount()

  vim.api.nvim_buf_set_lines(M.details_popup.bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(M.details_popup.bufnr, "modifiable", false)

  -- Close on q or Escape
  vim.keymap.set('n', 'q', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
  
  vim.keymap.set('n', '<Esc>', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
end

-- Show node details in popup
function M.show_node_details(node, details)
  M.close_popups()

  local content = {}
  table.insert(content, "Node: " .. (node.Name or node.ID))
  table.insert(content, "Status: " .. (node.Status or "unknown"))
  table.insert(content, "Class: " .. (node.NodeClass or "default"))
  table.insert(content, "Datacenter: " .. (node.Datacenter or "unknown"))
  table.insert(content, "Drain: " .. (node.Drain and "true" or "false"))
  table.insert(content, "Scheduling Eligibility: " .. (node.SchedulingEligibility or "unknown"))
  
  if node.Attributes then
    table.insert(content, "")
    table.insert(content, "=== Attributes ===")
    for key, value in pairs(node.Attributes) do
      table.insert(content, key .. ": " .. tostring(value))
    end
  end
  
  if details and details.Allocations then
    table.insert(content, "")
    table.insert(content, "=== Allocations (" .. #details.Allocations .. ") ===")
    for _, alloc in ipairs(details.Allocations) do
      table.insert(content, "  - " .. (alloc.JobID or "unknown") .. " [" .. (alloc.ClientStatus or "unknown") .. "]")
    end
  end

  M.details_popup = NuiPopup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Node Details ",
      },
    },
    position = "50%",
    size = {
      width = 80,
      height = math.min(#content + 4, 30),
    },
  })

  M.details_popup:mount()

  vim.api.nvim_buf_set_lines(M.details_popup.bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(M.details_popup.bufnr, "modifiable", false)

  -- Close on q or Escape
  vim.keymap.set('n', 'q', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
  
  vim.keymap.set('n', '<Esc>', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
end

-- Generate visual progress bar
local function generate_progress_bar(used, total, width)
  width = width or 40
  used = tonumber(used) or 0
  total = tonumber(total) or 0
  
  if total == 0 then
    return string.rep("░", width)
  end
  
  local percentage = math.min(used / total, 1.0)
  local filled = math.floor(percentage * width)
  local empty = width - filled
  
  local bar = string.rep("█", filled) .. string.rep("░", empty)
  return bar
end

-- Format memory in human readable format
local function format_memory(mb)
  mb = tonumber(mb) or 0
  if mb >= 1024 then
    return string.format("%.1f GiB", mb / 1024)
  else
    return string.format("%d MiB", mb)
  end
end

-- Format CPU in human readable format
local function format_cpu(mhz)
  mhz = tonumber(mhz) or 0
  if mhz >= 1000 then
    return string.format("%.1f GHz", mhz / 1000)
  else
    return string.format("%d MHz", mhz)
  end
end

-- Show enhanced topology in full buffer (Web UI style)
function M.show_topology_buffer(topology)
  M.close_popups()
  
  -- Create a new buffer for the topology view
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines - 2,
    row = 0,
    col = 0,
    style = "minimal",
    border = "rounded",
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_name(bufnr, "Nomad Topology")
  
  local content = {}
  local allocation_map = {}  -- Map line numbers to allocation data
  
  -- Header
  table.insert(content, "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗")
  table.insert(content, "║                                                          🏗️  NOMAD CLUSTER TOPOLOGY 🏗️                                                           ║")
  table.insert(content, "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝")
  table.insert(content, "")

  if topology.datacenters then
    for dc_name, dc_info in pairs(topology.datacenters) do
      -- Datacenter header with summary stats
      local total_allocs = 0
      for _, node in ipairs(dc_info.nodes) do
        if node.allocations then
          total_allocs = total_allocs + #node.allocations
        end
      end
      
      local cpu_percent = math.floor((dc_info.used_resources.cpu / math.max(dc_info.total_resources.cpu, 1)) * 100)
      local mem_percent = math.floor((dc_info.used_resources.memory / math.max(dc_info.total_resources.memory, 1)) * 100)
      
      table.insert(content, string.format("📍 %s    %d Allocs    %d Nodes    %s / %s, %s / %s", 
        dc_name, 
        total_allocs, 
        #dc_info.nodes,
        format_memory(dc_info.used_resources.memory),
        format_memory(dc_info.total_resources.memory),
        format_cpu(dc_info.used_resources.cpu),
        format_cpu(dc_info.total_resources.cpu)
      ))
      table.insert(content, "")
      
      -- Column headers
      table.insert(content, string.format("%-22s %-8s %-12s %-20s %-20s %-10s %-10s", 
        "Node", "Allocs", "Pool", "Memory", "CPU", "Class", "State"))
      table.insert(content, string.rep("─", 120))
      
      -- Node rows
      for _, node in ipairs(dc_info.nodes) do
        local node_name = (node.Name or node.ID):sub(1, 20)
        local alloc_count = node.allocations and #node.allocations or 0
        local node_pool = (node.NodePool or "default"):sub(1, 10)
        local node_class = (node.NodeClass or ""):sub(1, 8)
        local state = (node.Status or "unknown"):sub(1, 8)
        
        -- Calculate node resource usage
        local node_cpu_used = node.resource_usage and node.resource_usage.cpu or 0
        local node_mem_used = node.resource_usage and node.resource_usage.memory or 0
        
        -- Get node total resources
        local node_cpu_total = 0
        local node_mem_total = 0
        local node_resources = node.NodeResources or node.Resources
        if node_resources and type(node_resources) == "table" then
          if node.NodeResources and type(node.NodeResources) == "table" then
            if type(node_resources.Cpu) == "table" and node_resources.Cpu.CpuShares then
              node_cpu_total = tonumber(node_resources.Cpu.CpuShares) or 0
            end
            if type(node_resources.Memory) == "table" and node_resources.Memory.MemoryMB then
              node_mem_total = tonumber(node_resources.Memory.MemoryMB) or 0
            end
          else
            node_cpu_total = tonumber(node_resources.CPU) or 0
            node_mem_total = tonumber(node_resources.MemoryMB) or 0
          end
        end
        
        -- Generate progress bars
        local mem_bar = generate_progress_bar(node_mem_used, node_mem_total, 15)
        local cpu_bar = generate_progress_bar(node_cpu_used, node_cpu_total, 15)
        
        local mem_percent = node_mem_total > 0 and math.floor((node_mem_used / node_mem_total) * 100) or 0
        local cpu_percent = node_cpu_total > 0 and math.floor((node_cpu_used / node_cpu_total) * 100) or 0
        
        -- Status icon
        local status_icon = config.get_node_status_icon(node.Status or "unknown")
        
        -- Ensure all values are not nil
        local safe_status_icon = status_icon or "?"
        local safe_node_name = node_name or "unknown"
        local safe_alloc_count = alloc_count or 0
        local safe_node_pool = node_pool or "default"
        local safe_mem_display = format_memory(node_mem_used) or "0 MiB"
        local safe_cpu_display = format_cpu(node_cpu_used) or "0 MHz"
        local safe_node_class = node_class or ""
        local safe_state = state or "unknown"
        
        table.insert(content, string.format("%-20s %2d %-10s %-12s %-12s %-8s %-8s", 
          safe_status_icon .. " " .. safe_node_name,
          safe_alloc_count,
          safe_node_pool,
          safe_mem_display,
          safe_cpu_display,
          safe_node_class,
          safe_state
        ))
        
        -- Memory bar with percentage
        table.insert(content, string.format("  M %s %3d%%", mem_bar, mem_percent))
        
        -- CPU bar with percentage  
        table.insert(content, string.format("  C %s %3d%%", cpu_bar, cpu_percent))
        
        -- Show allocations as a clickable list
        if node.allocations and #node.allocations > 0 then
          table.insert(content, "    Allocations:")
          for i, alloc in ipairs(node.allocations) do
            local job_icon = config.get_job_status_icon(alloc.ClientStatus or "unknown")
            local job_name = (alloc.JobID or "unknown"):sub(1, 15)
            local alloc_name = (alloc.Name or "unknown"):sub(1, 20)
            
            -- Add resource info for each allocation
            local cpu_val = 0
            local mem_val = 0
            if alloc.ResourceUsage then
              cpu_val = tonumber(alloc.ResourceUsage.CPU) or 0
              mem_val = tonumber(alloc.ResourceUsage.MemoryMB) or 0
            end
            
            -- Store allocation info for click handling
            local alloc_line = string.format("      %s %-15s %-20s %4dMHz %4dMB [logs]", 
              job_icon, job_name, alloc_name, cpu_val, mem_val)
            table.insert(content, alloc_line)
            
            -- Store allocation data mapped to line number
            local line_num = #content
            allocation_map[line_num] = {
              job_id = alloc.JobID or "unknown",
              alloc_id = alloc.ID or "unknown", 
              task_group = alloc.TaskGroup or "unknown"
            }
          end
        end
        
        table.insert(content, "")
      end
      
      table.insert(content, "")
    end
  else
    table.insert(content, "No topology data available")
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "nomad-topology")

  -- Set keymaps for the topology buffer
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set('n', 'r', function()
    vim.notify("Refreshing topology data...", vim.log.levels.INFO)
    require("nomad").show_topology()
  end, opts)
  
  -- Add click/enter handling for allocations
  vim.keymap.set('n', '<CR>', function()
    local current_line = vim.api.nvim_get_current_line()
    local line_num = vim.api.nvim_win_get_cursor(winnr)[1]
    
    -- Check if current line contains allocation info
    if current_line:match("%[logs%]") and allocation_map[line_num] then
      local alloc_data = allocation_map[line_num]
      vim.notify("Opening logs for " .. alloc_data.job_id .. " (" .. alloc_data.alloc_id .. ")", vim.log.levels.INFO)
      -- Close topology window
      vim.api.nvim_win_close(winnr, true)
      -- Open logs
      require("nomad").show_job_logs(alloc_data.job_id, alloc_data.alloc_id, alloc_data.task_group)
    end
  end, opts)
  
  -- Add 'l' key for logs (alternative to Enter)
  vim.keymap.set('n', 'l', function()
    local current_line = vim.api.nvim_get_current_line()
    local line_num = vim.api.nvim_win_get_cursor(winnr)[1]
    
    -- Check if current line contains allocation info
    if current_line:match("%[logs%]") and allocation_map[line_num] then
      local alloc_data = allocation_map[line_num]
      vim.notify("Opening logs for " .. alloc_data.job_id .. " (" .. alloc_data.alloc_id .. ")", vim.log.levels.INFO)
      -- Close topology window
      vim.api.nvim_win_close(winnr, true)
      -- Open logs
      require("nomad").show_job_logs(alloc_data.job_id, alloc_data.alloc_id, alloc_data.task_group)
    end
  end, opts)

  -- Store references for cleanup
  M.topology_buffer = { bufnr = bufnr, winnr = winnr }
end

-- Show topology view (enhanced version)
function M.show_topology(topology)
  if topology then
    M.show_topology_buffer(topology)
  else
    M.close_popups()

    local content = {}
    table.insert(content, "=== Nomad Cluster Topology ===")
    table.insert(content, "")
    table.insert(content, "No topology data available")

    M.topology_popup = NuiPopup({
      enter = true,
      focusable = true,
      border = {
        style = "rounded",
        text = {
          top = " Cluster Topology ",
        },
      },
      position = "50%",
      size = {
        width = 100,
        height = math.min(#content + 4, 40),
      },
    })

    M.topology_popup:mount()

    vim.api.nvim_buf_set_lines(M.topology_popup.bufnr, 0, -1, false, content)
    vim.api.nvim_buf_set_option(M.topology_popup.bufnr, "modifiable", false)

    -- Close on q or Escape
    vim.keymap.set('n', 'q', function()
      M.topology_popup:unmount()
      M.topology_popup = nil
    end, { buffer = M.topology_popup.bufnr })
    
    vim.keymap.set('n', '<Esc>', function()
      M.topology_popup:unmount()
      M.topology_popup = nil
    end, { buffer = M.topology_popup.bufnr })
  end
end

-- Show job logs (placeholder)
function M.show_job_logs(job)
  vim.notify("Job logs for " .. job.ID .. " - Feature coming soon!", vim.log.levels.INFO)
end

-- Exec into job (placeholder)
function M.exec_into_job(job)
  vim.notify("Exec into " .. job.ID .. " - Feature coming soon!", vim.log.levels.INFO)
end

-- Show logs in interactive buffer
function M.show_logs_buffer(job_id, alloc_id, task_name, logs_data)
  M.close_popups()
  
  -- Close existing logs buffer if it exists
  if M.logs_buffer and M.logs_buffer.winnr and vim.api.nvim_win_is_valid(M.logs_buffer.winnr) then
    vim.api.nvim_win_close(M.logs_buffer.winnr, true)
  end
  
  -- Create a new buffer for the logs view
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines - 2,
    row = 0,
    col = 0,
    style = "minimal",
    border = "rounded",
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  
  -- Create unique buffer name with timestamp to avoid conflicts
  local buffer_name = "Nomad Logs: " .. job_id .. " (" .. os.date("%H:%M:%S") .. ")"
  vim.api.nvim_buf_set_name(bufnr, buffer_name)
  
  local content = {}
  table.insert(content, "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗")
  table.insert(content, "║                                                          📋 NOMAD JOB LOGS 📋                                                               ║")
  table.insert(content, "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝")
  table.insert(content, "")
  table.insert(content, "Job: " .. job_id)
  table.insert(content, "Allocation: " .. alloc_id)
  table.insert(content, "Task: " .. task_name)
  table.insert(content, "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
  table.insert(content, "Keys: [r] refresh, [q/Esc] close")
  table.insert(content, "")
  table.insert(content, "════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════")
  table.insert(content, "")

  -- Process logs data
  if logs_data then
    if type(logs_data) == "string" then
      -- Split logs by newlines
      for line in logs_data:gmatch("[^\r\n]+") do
        table.insert(content, line)
      end
    elseif type(logs_data) == "table" then
      -- Handle structured log data
      for _, log_entry in ipairs(logs_data) do
        if type(log_entry) == "string" then
          table.insert(content, log_entry)
        else
          table.insert(content, vim.inspect(log_entry))
        end
      end
    else
      table.insert(content, "Logs data: " .. tostring(logs_data))
    end
  else
    table.insert(content, "No logs available")
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "log")

  -- Set keymaps for the logs buffer
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set('n', 'r', function()
    vim.notify("Refreshing logs...", vim.log.levels.INFO)
    local nomad = require("nomad.nomad")
    nomad.get_allocation_logs(alloc_id, task_name, function(new_logs, error)
      if error then
        vim.notify("Error refreshing logs: " .. error, vim.log.levels.ERROR)
      else
        M.show_logs_buffer(job_id, alloc_id, task_name, new_logs)
      end
    end)
  end, opts)
  


  -- Store references for cleanup
  M.logs_buffer = { bufnr = bufnr, winnr = winnr }
  
  -- Auto-scroll to bottom
  vim.schedule(function()
    vim.api.nvim_win_set_cursor(winnr, {#content, 0})
  end)
end

-- Enhanced job details with logs option
function M.show_job_details_enhanced(job, details)
  M.close_popups()

  local content = {}
  table.insert(content, "Job: " .. job.ID)
  table.insert(content, "Status: " .. (job.Status or "unknown"))
  table.insert(content, "Type: " .. (job.Type or "unknown"))
  table.insert(content, "Namespace: " .. (job.Namespace or "default"))
  
  if job.Datacenters then
    table.insert(content, "Datacenters: " .. table.concat(job.Datacenters, ", "))
  end
  
  if details then
    table.insert(content, "")
    table.insert(content, "=== Details ===")
    if details.TaskGroups then
      table.insert(content, "Task Groups: " .. #details.TaskGroups)
      for _, tg in ipairs(details.TaskGroups) do
        table.insert(content, "  - " .. tg.Name .. " (Count: " .. (tg.Count or 1) .. ")")
      end
    end
    
    if details.Allocations then
      table.insert(content, "")
      table.insert(content, "=== Allocations (" .. #details.Allocations .. ") ===")
      for i, alloc in ipairs(details.Allocations) do
        table.insert(content, "  " .. i .. ". " .. (alloc.ID or "unknown") .. " [" .. (alloc.ClientStatus or "unknown") .. "]")
        if alloc.TaskStates then
          for task_name, task_state in pairs(alloc.TaskStates) do
            table.insert(content, "     Task: " .. task_name .. " [" .. (task_state.State or "unknown") .. "]")
          end
        end
      end
      table.insert(content, "")
      table.insert(content, "Press 'l' to view logs for an allocation")
    end
  end

  M.details_popup = NuiPopup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Job Details ",
      },
    },
    position = "50%",
    size = {
      width = 80,
      height = math.min(#content + 4, 30),
    },
  })

  M.details_popup:mount()

  vim.api.nvim_buf_set_lines(M.details_popup.bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(M.details_popup.bufnr, "modifiable", false)

  -- Close on q or Escape
  vim.keymap.set('n', 'q', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
  
  vim.keymap.set('n', '<Esc>', function()
    M.details_popup:unmount()
    M.details_popup = nil
  end, { buffer = M.details_popup.bufnr })
  
  -- Show logs for allocation
  vim.keymap.set('n', 'l', function()
    if details and details.Allocations and #details.Allocations > 0 then
      local alloc = details.Allocations[1] -- Use first allocation for now
      local task_name = "main" -- Default task name
      
      -- Try to find the first task name
      if alloc.TaskStates then
        for name, _ in pairs(alloc.TaskStates) do
          task_name = name
          break
        end
      end
      
      M.details_popup:unmount()
      M.details_popup = nil
      
      vim.notify("Loading logs for " .. job.ID .. "...", vim.log.levels.INFO)
      local nomad = require("nomad.nomad")
      nomad.get_allocation_logs(alloc.ID, task_name, function(logs, error)
        if error then
          vim.notify("Error loading logs: " .. error, vim.log.levels.ERROR)
        else
          M.show_logs_buffer(job.ID, alloc.ID, task_name, logs)
        end
      end)
    else
      vim.notify("No allocations found for this job", vim.log.levels.WARN)
    end
  end, { buffer = M.details_popup.bufnr })
end

return M 