local prompts = require('nvim-prompt.prompts')
local requests = require('nvim-prompt.requests')

local M = {}

--local function get_input_buffer()
    --local buf = vim.api.nvim_create_buf(false, true)
    --vim.bo[buf].modifiable = true
    --vim.bo[buf].buftype = ''
    --vim.cmd('belowright split')
    --local win = vim.api.nvim_get_current_win()
    --vim.api.nvim_win_set_buf(win, buf)

    --vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "> "})
    --vim.keymap.set('n', '<CR>', function()
        --local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        --print(table.concat(lines, '\n'))
    --end, { buffer = buf })
    --return buf
--end

local function get_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.cmd('set splitright')
    vim.cmd("vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    return buf
end

local function get_current_window_lines()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines,'\n')
    return content
end

local function handle_streaming_data(buf, all_data, stream_data)
    if stream_data == nil then
        return all_data
    end
    all_data = all_data .. stream_data
    local buf_lines = {}
    for line in all_data:gmatch("([^\n]*)\n?") do
      table.insert(buf_lines, line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win, {#buf_lines, 0})
    return all_data
end

local function keep_prompting(buf, prompt_list, all_data, callback)
    local still_asking = true
    while still_asking do
        vim.ui.input({ prompt = ">> "}, function(input)
            if input then
                if input == 'exit' then
                    still_asking = false
                else
                    table.insert(prompt_list, input)
                    all_data = get_current_window_lines()
                    all_data = all_data .. '\n' .. '[QUESTION] ' .. input .. '\n\n'
                    requests.ask_llm(buf, prompt_list, all_data, callback)
                end
            end
        end)
    end
end

function M.start_prompting()
    local buf = get_buffer()
    local all_data = ''
    local prompt_list = {}
    keep_prompting(buf, prompt_list, all_data, handle_streaming_data)
end

function M.get_explanation()
    local buf = get_buffer()
    local prompt = prompts.explain_code_prompt()
    local all_data = ''
    local prompt_list = {}
    table.insert(prompt_list, prompt)
    requests.ask_llm(buf, prompt_list, all_data, handle_streaming_data)
    vim.cmd('redraw')
    keep_prompting(buf, prompt_list, all_data, handle_streaming_data)
end

return M
