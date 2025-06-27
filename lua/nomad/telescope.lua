-- Telescope integration for Nomad.nvim

local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local config = require("nomad.config")

local M = {}

-- Setup telescope extension
function M.setup()
  -- Register the extension
  telescope.register_extension({
    exports = {
      jobs = M.jobs_picker,
      nodes = M.nodes_picker,
    },
  })
end

-- Search jobs picker
function M.search_jobs(jobs)
  M.jobs_picker(jobs)
end

-- Search nodes picker
function M.search_nodes(nodes)
  M.nodes_picker(nodes)
end

-- Jobs picker
function M.jobs_picker(jobs)
  jobs = jobs or {}

  pickers
    .new({}, {
      prompt_title = "Nomad Jobs",
      finder = finders.new_table({
        results = jobs,
        entry_maker = function(job)
          local display_text = job.ID
          local ordinal = job.ID

          -- Add status and type information
          if job.Status then
            display_text = config.get_job_status_icon(job.Status) .. job.Status .. " " .. display_text
            ordinal = ordinal .. " " .. job.Status
          end

          if job.Type then
            display_text = display_text .. " [" .. config.get_job_type_icon(job.Type) .. job.Type .. "]"
            ordinal = ordinal .. " " .. job.Type
          end

          if job.Namespace and job.Namespace ~= "default" then
            display_text = display_text .. " (" .. job.Namespace .. ")"
            ordinal = ordinal .. " " .. job.Namespace
          end

          if job.Datacenters then
            display_text = display_text .. " - DC: " .. table.concat(job.Datacenters, ", ")
            ordinal = ordinal .. " " .. table.concat(job.Datacenters, " ")
          end

          return {
            value = job,
            display = display_text,
            ordinal = ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            require("nomad").show_job_details(selection.value)
          end
        end)

        -- Custom mappings
        map("i", "<C-s>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            require("nomad").start_job(selection.value.ID)
          end
        end)

        map("i", "<C-S>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            require("nomad").stop_job(selection.value.ID)
          end
        end)

        map("i", "<C-r>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            require("nomad").restart_job(selection.value.ID)
          end
        end)

        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            require("nomad").copy_job_id(selection.value)
          end
        end)

        -- View logs mapping
        map("i", "<C-l>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            -- Get job details first to find allocations
            local nomad = require("nomad.nomad")
            nomad.get_job_details(selection.value, function(details, error)
              vim.schedule(function()
                if error then
                  vim.notify("Failed to get job details: " .. error, vim.log.levels.ERROR)
                  return
                end

                if details.Allocations and #details.Allocations > 0 then
                  local alloc = details.Allocations[1] -- Use first allocation
                  local task_name = "main" -- Default task name

                  -- Try to find the first task name
                  if alloc.TaskStates then
                    local first_task = next(alloc.TaskStates)
                    if first_task then
                      task_name = first_task
                    end
                  end

                  require("nomad").show_job_logs(selection.value.ID, alloc.ID, task_name)
                else
                  vim.notify("No allocations found for job " .. selection.value.ID, vim.log.levels.WARN)
                end
              end)
            end)
          end
        end)

        return true
      end,
    })
    :find()
end

-- Nodes picker
function M.nodes_picker(nodes)
  nodes = nodes or {}

  pickers
    .new({}, {
      prompt_title = "Nomad Nodes",
      finder = finders.new_table({
        results = nodes,
        entry_maker = function(node)
          local display_text = node.Name or node.ID
          local ordinal = (node.Name or node.ID) .. " " .. node.ID

          -- Add status information
          if node.Status then
            display_text = config.get_node_status_icon(node.Status) .. node.Status .. " " .. display_text
            ordinal = ordinal .. " " .. node.Status
          end

          -- Add node class
          if node.NodeClass then
            display_text = display_text .. " [" .. config.get_node_class_icon(node.NodeClass) .. node.NodeClass .. "]"
            ordinal = ordinal .. " " .. node.NodeClass
          end

          -- Add datacenter
          if node.Datacenter then
            display_text = display_text .. " (" .. node.Datacenter .. ")"
            ordinal = ordinal .. " " .. node.Datacenter
          end

          -- Add drain status
          if node.Drain then
            display_text = display_text .. " 🟠DRAINING"
            ordinal = ordinal .. " draining"
          end

          -- Add eligibility
          if node.SchedulingEligibility == "ineligible" then
            display_text = display_text .. " ⚫INELIGIBLE"
            ordinal = ordinal .. " ineligible"
          end

          return {
            value = node,
            display = display_text,
            ordinal = ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            require("nomad").show_node_details(selection.value)
          end
        end)

        -- Custom mappings
        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            require("nomad").drain_node(selection.value.ID)
          end
        end)

        map("i", "<C-e>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            require("nomad").enable_node(selection.value.ID)
          end
        end)

        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            require("nomad").copy_node_id(selection.value)
          end
        end)

        return true
      end,
    })
    :find()
end

-- Allocations picker (for a specific job or node)
function M.allocations_picker(allocations, title)
  allocations = allocations or {}
  title = title or "Nomad Allocations"

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table({
        results = allocations,
        entry_maker = function(alloc)
          local display_text = alloc.ID or "unknown"
          local ordinal = display_text

          if alloc.JobID then
            display_text = display_text .. " [" .. alloc.JobID .. "]"
            ordinal = ordinal .. " " .. alloc.JobID
          end

          if alloc.TaskGroup then
            display_text = display_text .. " (" .. alloc.TaskGroup .. ")"
            ordinal = ordinal .. " " .. alloc.TaskGroup
          end

          if alloc.ClientStatus then
            local status_icon = ""
            if alloc.ClientStatus == "running" then
              status_icon = "▶️ "
            elseif alloc.ClientStatus == "failed" then
              status_icon = "❌"
            elseif alloc.ClientStatus == "complete" then
              status_icon = "✅"
            elseif alloc.ClientStatus == "pending" then
              status_icon = "⏸️ "
            end

            display_text = status_icon .. alloc.ClientStatus .. " " .. display_text
            ordinal = ordinal .. " " .. alloc.ClientStatus
          end

          if alloc.NodeName then
            display_text = display_text .. " @ " .. alloc.NodeName
            ordinal = ordinal .. " " .. alloc.NodeName
          end

          return {
            value = alloc,
            display = display_text,
            ordinal = ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Show allocation details
            vim.notify("Allocation: " .. (selection.value.ID or "unknown"), vim.log.levels.INFO)
          end
        end)

        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            vim.fn.setreg("+", selection.value.ID)
            vim.notify("Copied allocation ID: " .. selection.value.ID, vim.log.levels.INFO)
          end
        end)

        return true
      end,
    })
    :find()
end

-- Combined picker for both jobs and nodes
function M.combined_picker(jobs, nodes)
  jobs = jobs or {}
  nodes = nodes or {}

  local combined_results = {}

  -- Add jobs
  for _, job in ipairs(jobs) do
    table.insert(combined_results, {
      type = "job",
      data = job,
      display_name = job.ID,
      search_text = job.ID .. " " .. (job.Status or "") .. " " .. (job.Type or "") .. " job",
    })
  end

  -- Add nodes
  for _, node in ipairs(nodes) do
    table.insert(combined_results, {
      type = "node",
      data = node,
      display_name = node.Name or node.ID,
      search_text = (node.Name or node.ID) .. " " .. (node.Status or "") .. " " .. (node.NodeClass or "") .. " node",
    })
  end

  pickers
    .new({}, {
      prompt_title = "Nomad Cluster Resources",
      finder = finders.new_table({
        results = combined_results,
        entry_maker = function(item)
          local ordinal = item.search_text
          local display_text

          if item.type == "job" then
            display_text = "📦 " .. item.display_name
            if item.data.Status then
              display_text = config.get_job_status_icon(item.data.Status) .. item.data.Status .. " " .. display_text
            end
            if item.data.Type then
              display_text = display_text .. " [" .. item.data.Type .. "]"
            end
          else -- node
            display_text = "🖥️  " .. item.display_name
            if item.data.Status then
              display_text = config.get_node_status_icon(item.data.Status) .. item.data.Status .. " " .. display_text
            end
            if item.data.NodeClass then
              display_text = display_text .. " [" .. item.data.NodeClass .. "]"
            end
          end

          return {
            value = item,
            display = display_text,
            ordinal = ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            if selection.value.type == "job" then
              require("nomad").show_job_details(selection.value.data)
            else
              require("nomad").show_node_details(selection.value.data)
            end
          end
        end)

        return true
      end,
    })
    :find()
end

return M
