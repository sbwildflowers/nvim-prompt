local M = {}

local config = {}

local default_config = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct"
}

function M.setup(user_config)
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
end


function M.get_config()
    return config
end

return M
