-- Nomad API integration module

local Job = require("plenary.job")
local config = require("nomad.config")
local curl = require("plenary.curl")

local M = {}

-- Cache for frequently accessed data
M.cache = {
  jobs = nil,
  jobs_timestamp = 0,
  nodes = nil,
  nodes_timestamp = 0,
  cluster_info = nil,
  cluster_info_timestamp = 0,
}

-- Rate limiting state
M.rate_limit = {
  last_request_time = 0,
  request_count = 0,
  request_window_start = 0,
}

-- Check if cached data is still valid
local function is_cache_valid(timestamp)
  local cache_ttl = config.get().cache.ttl_seconds or 30
  return os.time() - timestamp < cache_ttl
end

-- Rate limiting check
local function should_rate_limit()
  local config_opts = config.get()
  if not config_opts.rate_limiting.enabled then
    return false
  end
  
  local now = os.time() * 1000 -- milliseconds
  local max_requests = config_opts.rate_limiting.max_requests_per_minute or 60
  local min_interval = config_opts.rate_limiting.min_interval_ms or 500
  
  -- Reset window if more than a minute has passed
  if now - M.rate_limit.request_window_start > 60000 then
    M.rate_limit.request_count = 0
    M.rate_limit.request_window_start = now
  end
  
  -- Check if we're hitting the rate limit
  if M.rate_limit.request_count >= max_requests then
    return true
  end
  
  -- Check minimum interval between requests
  if now - M.rate_limit.last_request_time < min_interval then
    return true
  end
  
  return false
end

-- Record an API request
local function record_request()
  local now = os.time() * 1000
  M.rate_limit.last_request_time = now
  M.rate_limit.request_count = M.rate_limit.request_count + 1
end

-- Execute a function after rate limiting delay (non-blocking)
local function execute_with_rate_limit(fn)
  local wait_time = 0
  if should_rate_limit() then
    local min_interval = config.get().rate_limiting.min_interval_ms or 500
    wait_time = min_interval - (os.time() * 1000 - M.rate_limit.last_request_time)
    wait_time = math.max(0, wait_time)
  end
  
  if wait_time > 0 then
    vim.defer_fn(function()
      record_request()
      fn()
    end, wait_time)
  else
    record_request()
    fn()
  end
end

-- Clear cache
function M.clear_cache()
  M.cache.jobs = nil
  M.cache.jobs_timestamp = 0
  M.cache.nodes = nil
  M.cache.nodes_timestamp = 0
  M.cache.cluster_info = nil
  M.cache.cluster_info_timestamp = 0
  vim.schedule(function()
    vim.notify("Nomad cache cleared", vim.log.levels.INFO)
  end)
end

-- Build Nomad API URL
local function build_url(path)
  local base_url = config.get_nomad_address()
  local namespace = config.get_nomad_namespace()
  local region = config.get_nomad_region()
  
  local url = base_url .. "/v1" .. path
  local params = {}
  
  if namespace and namespace ~= "default" then
    table.insert(params, "namespace=" .. namespace)
  end
  
  if region then
    table.insert(params, "region=" .. region)
  end
  
  if #params > 0 then
    url = url .. "?" .. table.concat(params, "&")
  end
  
  return url
end

-- Build headers
local function build_headers()
  local headers = {
    ["Content-Type"] = "application/json",
  }
  
  local token = config.get_nomad_token()
  if token then
    headers["X-Nomad-Token"] = token
  end
  
  return headers
end

-- Make HTTP request to Nomad API
local function make_request(method, path, body, callback)
  execute_with_rate_limit(function()
    local url = build_url(path)
    local headers = build_headers()
    local timeout = config.get().nomad.timeout
    
    local request_opts = {
      url = url,
      method = method,
      headers = headers,
      timeout = timeout,
    }
    
    if body then
      request_opts.body = vim.json.encode(body)
    end
    
    -- Use vim.schedule to make the request asynchronous
    vim.schedule(function()
      local response = curl.request(request_opts)
      
      if response.status >= 200 and response.status < 300 then
        local ok, data = pcall(vim.json.decode, response.body)
        if ok then
          callback(data, nil)
        else
          callback(nil, "Failed to parse JSON response")
        end
      else
        local error_msg = "HTTP " .. response.status .. ": " .. (response.body or "Unknown error")
        callback(nil, error_msg)
      end
    end)
  end)
end

-- Check Nomad cluster connectivity
function M.check_connectivity(callback)
  make_request("GET", "/status/leader", nil, function(data, error)
    if error then
      callback(false, error)
    else
      callback(true, nil)
    end
  end)
end

-- Get cluster information
function M.get_cluster_info(callback)
  -- Return cached data if valid
  if M.cache.cluster_info and is_cache_valid(M.cache.cluster_info_timestamp) then
    vim.schedule(function()
      callback(M.cache.cluster_info, nil)
    end)
    return
  end
  
  make_request("GET", "/status/leader", nil, function(leader_data, leader_error)
    if leader_error then
      callback(nil, leader_error)
      return
    end
    
    make_request("GET", "/agent/members", nil, function(members_data, members_error)
      local cluster_info = {
        leader = leader_data,
        members = members_data or {},
        timestamp = os.time()
      }
      
      -- Cache the result
      M.cache.cluster_info = cluster_info
      M.cache.cluster_info_timestamp = os.time()
      
      callback(cluster_info, members_error)
    end)
  end)
end

-- Get jobs
function M.get_jobs(callback)
  -- Return cached data if valid
  if M.cache.jobs and is_cache_valid(M.cache.jobs_timestamp) then
    vim.schedule(function()
      callback(M.cache.jobs, nil)
    end)
    return
  end
  
  make_request("GET", "/jobs", nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Process jobs data
    local jobs = data or {}
    for _, job in ipairs(jobs) do
      -- Add computed fields
      job.StatusDisplay = M.get_job_status_display(job)
      job.TypeDisplay = M.get_job_type_display(job)
    end
    
    -- Cache the result
    M.cache.jobs = jobs
    M.cache.jobs_timestamp = os.time()
    
    callback(jobs, nil)
  end)
end

-- Get nodes
function M.get_nodes(callback)
  -- Return cached data if valid
  if M.cache.nodes and is_cache_valid(M.cache.nodes_timestamp) then
    vim.schedule(function()
      callback(M.cache.nodes, nil)
    end)
    return
  end
  
  make_request("GET", "/nodes?resources=true", nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Process nodes data
    local nodes = data or {}
    for _, node in ipairs(nodes) do
      -- Add computed fields
      node.StatusDisplay = M.get_node_status_display(node)
      node.ClassDisplay = M.get_node_class_display(node)
    end
    
    -- Cache the result
    M.cache.nodes = nodes
    M.cache.nodes_timestamp = os.time()
    
    callback(nodes, nil)
  end)
end

-- Get job details
function M.get_job_details(job, callback)
  local job_id = job.ID
  make_request("GET", "/job/" .. job_id, nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Also get allocations for this job
    make_request("GET", "/job/" .. job_id .. "/allocations", nil, function(allocs_data, allocs_error)
      local details = data
      details.Allocations = allocs_data or {}
      callback(details, allocs_error)
    end)
  end)
end

-- Get node details
function M.get_node_details(node, callback)
  local node_id = node.ID
  make_request("GET", "/node/" .. node_id, nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Also get allocations for this node
    make_request("GET", "/node/" .. node_id .. "/allocations", nil, function(allocs_data, allocs_error)
      local details = data
      details.Allocations = allocs_data or {}
      callback(details, allocs_error)
    end)
  end)
end

-- Job control functions
function M.start_job(job_id, callback)
  -- First check the job status to determine the correct approach
  make_request("GET", "/job/" .. job_id, nil, function(job_data, error)
    if error then
      callback(false, "Failed to get job status: " .. error)
      return
    end
    
    -- If job is dead/stopped, we need to re-register it
    if job_data.Status == "dead" then
      -- Clean up the job data by removing server-generated fields
      local clean_job = vim.deepcopy(job_data)
      
      -- Remove server-generated fields that shouldn't be in submission
      clean_job.SubmitTime = nil
      clean_job.CreateIndex = nil
      clean_job.ModifyIndex = nil
      clean_job.JobModifyIndex = nil
      clean_job.Status = nil
      clean_job.StatusDescription = nil
      clean_job.Stable = nil
      clean_job.Version = nil
      clean_job.Dispatched = nil
      clean_job.Stop = false  -- Ensure the job is not marked as stopped
      
      -- Re-register the job
      local body = { Job = clean_job }
      make_request("POST", "/job/" .. job_id, body, function(data, error)
        callback(not error, error)
      end)
    else
      -- For running jobs with failed allocations, use evaluation with ForceReschedule
      local body = {
        JobID = job_id,
        EvalOptions = {
          ForceReschedule = true
        }
      }
      make_request("POST", "/job/" .. job_id .. "/evaluate", body, function(data, error)
        callback(not error, error)
      end)
    end
  end)
end

function M.stop_job(job_id, callback)
  make_request("DELETE", "/job/" .. job_id, nil, function(data, error)
    callback(not error, error)
  end)
end

function M.restart_job(job_id, callback)
  -- For restart, we can use the evaluation endpoint to force rescheduling
  local body = {
    JobID = job_id,
    EvalOptions = {
      ForceReschedule = true
    }
  }
  
  make_request("POST", "/job/" .. job_id .. "/evaluate", body, function(data, error)
    if error then
      callback(false, error)
      return
    end
    
    callback(true, nil)
  end)
end

-- Node control functions
function M.drain_node(node_id, callback)
  local body = {
    NodeID = node_id,
    DrainSpec = {
      Deadline = 3600000000000, -- 1 hour in nanoseconds
      IgnoreSystemJobs = false
    }
  }
  
  make_request("POST", "/node/" .. node_id .. "/drain", body, function(data, error)
    callback(not error, error)
  end)
end

function M.enable_node(node_id, callback)
  local body = {
    NodeID = node_id,
    Eligibility = "eligible"
  }
  
  make_request("POST", "/node/" .. node_id .. "/eligibility", body, function(data, error)
    callback(not error, error)
  end)
end

-- Generate topology data
function M.generate_topology(jobs, nodes)
  local topology = {
    datacenters = {},
    node_allocations = {},
    resource_usage = {}
  }
  
  -- Group nodes by datacenter
  for _, node in ipairs(nodes) do
    local dc = node.Datacenter or "unknown"
    if not topology.datacenters[dc] then
      topology.datacenters[dc] = {
        name = dc,
        nodes = {},
        total_resources = { cpu = 0, memory = 0, disk = 0 },
        used_resources = { cpu = 0, memory = 0, disk = 0 }
      }
    end
    
    table.insert(topology.datacenters[dc].nodes, node)
    
    -- Add resources if available (prefer NodeResources over legacy Resources)
    local node_resources = node.NodeResources or node.Resources
    if node_resources and type(node_resources) == "table" then
      -- Handle new NodeResources format
      if node.NodeResources and type(node.NodeResources) == "table" then
        local cpu = 0
        local memory = 0
        local disk = 0
        
        if type(node_resources.Cpu) == "table" and node_resources.Cpu.CpuShares then
          cpu = tonumber(node_resources.Cpu.CpuShares) or 0
        end
        if type(node_resources.Memory) == "table" and node_resources.Memory.MemoryMB then
          memory = tonumber(node_resources.Memory.MemoryMB) or 0
        end
        if type(node_resources.Disk) == "table" and node_resources.Disk.DiskMB then
          disk = tonumber(node_resources.Disk.DiskMB) or 0
        end
        
        topology.datacenters[dc].total_resources.cpu = topology.datacenters[dc].total_resources.cpu + cpu
        topology.datacenters[dc].total_resources.memory = topology.datacenters[dc].total_resources.memory + memory
        topology.datacenters[dc].total_resources.disk = topology.datacenters[dc].total_resources.disk + disk
      else
        -- Handle legacy Resources format
        local cpu = tonumber(node_resources.CPU) or 0
        local memory = tonumber(node_resources.MemoryMB) or 0
        local disk = tonumber(node_resources.DiskMB) or 0
        
        topology.datacenters[dc].total_resources.cpu = topology.datacenters[dc].total_resources.cpu + cpu
        topology.datacenters[dc].total_resources.memory = topology.datacenters[dc].total_resources.memory + memory
        topology.datacenters[dc].total_resources.disk = topology.datacenters[dc].total_resources.disk + disk
      end
    end
  end
  
  return topology
end

-- Make raw HTTP request (for non-JSON responses like logs)
local function make_raw_request(method, path, callback)
  execute_with_rate_limit(function()
    local url = build_url(path)
    local headers = build_headers()
    local timeout = config.get().nomad.timeout
    
    local request_opts = {
      url = url,
      method = method,
      headers = headers,
      timeout = timeout,
    }
    
    -- Use vim.schedule to make the request asynchronous
    vim.schedule(function()
      local response = curl.request(request_opts)
      
      if response.status >= 200 and response.status < 300 then
        callback(response.body or "", nil)
      else
        local error_msg = "HTTP " .. response.status .. ": " .. (response.body or "Unknown error")
        callback(nil, error_msg)
      end
    end)
  end)
end

-- Get allocation logs
function M.get_allocation_logs(alloc_id, task_name, callback, follow)
  local follow_param = follow and "true" or "false"
  -- Use the correct client logs endpoint
  local path = "/client/fs/logs/" .. alloc_id
  local query_params = "?task=" .. task_name .. "&follow=" .. follow_param .. "&type=stdout&plain=true"
  
  make_raw_request("GET", path .. query_params, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Return the raw log data
    callback(data, nil)
  end)
end

-- Get all allocations with detailed information
function M.get_allocations(callback)
  -- Add parameters to get AllocatedResources field and disable task_states for performance
  make_request("GET", "/allocations?namespace=*&resources=true&task_states=false", nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    local allocations = data or {}
    callback(allocations, nil)
  end)
end

-- Get allocation details
function M.get_allocation_details(alloc_id, callback)
  make_request("GET", "/allocation/" .. alloc_id, nil, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    callback(data, nil)
  end)
end

-- Generate enhanced topology data with allocations
function M.generate_enhanced_topology(jobs, nodes, allocations, callback)
  local topology = {
    datacenters = {},
    node_allocations = {},
    resource_usage = {}
  }
  
  -- Group nodes by datacenter
  for _, node in ipairs(nodes) do
    local dc = node.Datacenter or "unknown"
    if not topology.datacenters[dc] then
      topology.datacenters[dc] = {
        name = dc,
        nodes = {},
        total_resources = { cpu = 0, memory = 0, disk = 0 },
        used_resources = { cpu = 0, memory = 0, disk = 0 }
      }
    end
    
    -- Initialize node data
    local node_data = vim.deepcopy(node)
    node_data.allocations = {}
    node_data.resource_usage = { cpu = 0, memory = 0, disk = 0 }
    
    table.insert(topology.datacenters[dc].nodes, node_data)
    topology.node_allocations[node.ID] = node_data
    
    -- Add total resources if available (prefer NodeResources over legacy Resources)
    local node_resources = node.NodeResources or node.Resources
    if node_resources and type(node_resources) == "table" then
      -- Handle new NodeResources format
      if node.NodeResources and type(node.NodeResources) == "table" then
        local cpu = 0
        local memory = 0
        local disk = 0
        
        if type(node_resources.Cpu) == "table" and node_resources.Cpu.CpuShares then
          cpu = tonumber(node_resources.Cpu.CpuShares) or 0
        end
        if type(node_resources.Memory) == "table" and node_resources.Memory.MemoryMB then
          memory = tonumber(node_resources.Memory.MemoryMB) or 0
        end
        if type(node_resources.Disk) == "table" and node_resources.Disk.DiskMB then
          disk = tonumber(node_resources.Disk.DiskMB) or 0
        end
        
        topology.datacenters[dc].total_resources.cpu = topology.datacenters[dc].total_resources.cpu + cpu
        topology.datacenters[dc].total_resources.memory = topology.datacenters[dc].total_resources.memory + memory
        topology.datacenters[dc].total_resources.disk = topology.datacenters[dc].total_resources.disk + disk
      else
        -- Handle legacy Resources format
        local cpu = tonumber(node_resources.CPU) or 0
        local memory = tonumber(node_resources.MemoryMB) or 0
        local disk = tonumber(node_resources.DiskMB) or 0
        
        topology.datacenters[dc].total_resources.cpu = topology.datacenters[dc].total_resources.cpu + cpu
        topology.datacenters[dc].total_resources.memory = topology.datacenters[dc].total_resources.memory + memory
        topology.datacenters[dc].total_resources.disk = topology.datacenters[dc].total_resources.disk + disk
      end
    end
  end
  
  -- Add allocations to nodes
  for _, alloc in ipairs(allocations) do
    local node_id = alloc.NodeID
    if node_id and topology.node_allocations[node_id] then
      local node_data = topology.node_allocations[node_id]
      table.insert(node_data.allocations, alloc)
      
      -- Calculate resource usage from AllocatedResources field
      local cpu_usage, memory_usage, disk_usage = 0, 0, 0
      
      if alloc.AllocatedResources and type(alloc.AllocatedResources) == "table" then
        -- Extract CPU and Memory from Tasks
        if alloc.AllocatedResources.Tasks and type(alloc.AllocatedResources.Tasks) == "table" then
          for task_name, task_resources in pairs(alloc.AllocatedResources.Tasks) do
            if type(task_resources) == "table" then
              -- CPU from task
              if task_resources.Cpu and task_resources.Cpu.CpuShares then
                cpu_usage = cpu_usage + (tonumber(task_resources.Cpu.CpuShares) or 0)
              end
              -- Memory from task
              if task_resources.Memory and task_resources.Memory.MemoryMB then
                memory_usage = memory_usage + (tonumber(task_resources.Memory.MemoryMB) or 0)
              end
            end
          end
        end
        
        -- Extract Disk from Shared resources
        if alloc.AllocatedResources.Shared and type(alloc.AllocatedResources.Shared) == "table" then
          if alloc.AllocatedResources.Shared.DiskMB then
            disk_usage = tonumber(alloc.AllocatedResources.Shared.DiskMB) or 0
          end
        end
        
        -- Store resource usage in allocation for UI display
        alloc.ResourceUsage = {
          CPU = cpu_usage,
          MemoryMB = memory_usage,
          DiskMB = disk_usage
        }
        
        node_data.resource_usage.cpu = node_data.resource_usage.cpu + cpu_usage
        node_data.resource_usage.memory = node_data.resource_usage.memory + memory_usage
        node_data.resource_usage.disk = node_data.resource_usage.disk + disk_usage
        
        -- Add to datacenter usage
        local dc = topology.node_allocations[node_id].Datacenter or "unknown"
        if topology.datacenters[dc] then
          topology.datacenters[dc].used_resources.cpu = topology.datacenters[dc].used_resources.cpu + cpu_usage
          topology.datacenters[dc].used_resources.memory = topology.datacenters[dc].used_resources.memory + memory_usage
          topology.datacenters[dc].used_resources.disk = topology.datacenters[dc].used_resources.disk + disk_usage
        end
      end
    end
  end
  
  callback(topology, nil)
end

-- Display helper functions
function M.get_job_status_display(job)
  local status = job.Status or "unknown"
  local icon = config.get_job_status_icon(status)
  return icon .. status
end

function M.get_job_type_display(job)
  local job_type = job.Type or "unknown"
  local icon = config.get_job_type_icon(job_type)
  return icon .. job_type
end

function M.get_node_status_display(node)
  local status = node.Status or "unknown"
  local icon = config.get_node_status_icon(status)
  return icon .. status
end

function M.get_node_class_display(node)
  local node_class = node.NodeClass or "default"
  local icon = config.get_node_class_icon(node_class)
  return icon .. node_class
end

return M 