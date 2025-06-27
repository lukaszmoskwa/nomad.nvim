-- Telescope extension for Nomad.nvim

local nomad_telescope = require("nomad.telescope")

return require("telescope").register_extension({
  exports = {
    jobs = function()
      local nomad = require("nomad")
      local state = nomad.get_state()
      
      if #state.jobs == 0 then
        vim.notify("No jobs loaded. Refreshing...", vim.log.levels.INFO)
        nomad.refresh_cluster_data()
        return
      end
      
      nomad_telescope.search_jobs(state.jobs)
    end,
    
    nodes = function()
      local nomad = require("nomad")
      local state = nomad.get_state()
      
      if #state.nodes == 0 then
        vim.notify("No nodes loaded. Refreshing...", vim.log.levels.INFO)
        nomad.refresh_cluster_data()
        return
      end
      
      nomad_telescope.search_nodes(state.nodes)
    end,
    
    combined = function()
      local nomad = require("nomad")
      local state = nomad.get_state()
      
      if #state.jobs == 0 and #state.nodes == 0 then
        vim.notify("No cluster data loaded. Refreshing...", vim.log.levels.INFO)
        nomad.refresh_cluster_data()
        return
      end
      
      nomad_telescope.combined_picker(state.jobs, state.nodes)
    end,
  },
}) 