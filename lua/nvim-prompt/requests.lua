local config = require('nvim-prompt.config')

local M = {}


function M.ask_llm(buf, prompts, all_data, callback)
    local curl = require('plenary.curl')
    local user_config = config.get_config()
    local messages = {}
    for i = 1, #prompts do
        local prompt_obj = { role = "user", content = prompts[i] }
        table.insert(messages, prompt_obj)
    end

    local request_data = {
        model = user_config.model,
        stream = true,
        messages = messages,
        max_tokens = -1
    }

    local request_data_json = vim.fn.json_encode(request_data)

    all_data = all_data .. '[ANSWER] '

    curl.post(user_config.url, {
        body = request_data_json,
        headers = {
            ['Content-Type'] = 'application/json'
        },
        stream = function(_, chunk)
            if chunk then
                vim.schedule(function()
                    local json_str = chunk:match("^data:%s*(.-)%s*$")
                    if json_str and #json_str > 0 and json_str ~= "[DONE]" then
                        local ok, partial_response = pcall(vim.fn.json_decode, json_str)
                        if not ok then
                            vim.notify("Decode fail:\n" .. partial_response, vim.log.levels.ERROR)
                            return
                        end
                        if partial_response then
                            all_data = callback(buf, all_data, partial_response.choices[1].delta.content)
                            vim.cmd('redraw')
                        end
                    elseif json_str == "[DONE]" then
                        all_data = callback(buf, all_data, "\n[END ANSWER]")
                        vim.cmd('redraw')
                    end
                end)
            end
        end
    })
end

return M
