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

-- custom wrapping is required for formatting of colored conversation bars to work
local function wrap_lines(buf_lines, line, win_size)
    local tokens = vim.split(line, ' ')
    local new_tokens = {}
    for i = 1, #tokens do
        table.insert(new_tokens, tokens[i])
        local temp_line = table.concat(new_tokens, ' ')
        if vim.fn.strdisplaywidth(temp_line) > win_size then
            table.remove(new_tokens, #new_tokens)
            local insert_line = table.concat(new_tokens, ' ')
            table.insert(buf_lines, insert_line)
            new_tokens = {}
        end
    end
    local insert_line = table.concat(new_tokens, ' ')
    table.insert(buf_lines, insert_line)
    return buf_lines
end

local function handle_streaming_data(buf, all_data, stream_data)
    if stream_data == nil then
        return all_data
    end
    all_data = all_data .. stream_data
    local buf_lines = {}
    local win = vim.api.nvim_get_current_win()
    local win_size = vim.fn.winwidth(0) - 8
    for line in all_data:gmatch("([^\n]*)\n?") do
        if vim.fn.strdisplaywidth(line) > win_size then
            buf_lines = wrap_lines(buf_lines, line, win_size)
        else
            table.insert(buf_lines, line)
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
    vim.api.nvim_win_set_cursor(win, {#buf_lines, 0})
    vim.api.nvim_set_hl(0, "QuestionHighlight", { bg = "#ff9b59" })
    vim.api.nvim_set_hl(0, "AnswerHighlight", { bg = "#6fb6cd" })
    local ns = vim.api.nvim_create_namespace('ns')
    local active_highlight_group = "QuestionHighlight"
    local question_prefix = '[QUESTION]'
    local answer_prefix = '[ANSWER]'
    for i = 1, #buf_lines do
        if string.sub(buf_lines[i], 1, #question_prefix) == question_prefix then
           active_highlight_group = "QuestionHighlight"
        end
        if string.sub(buf_lines[i], 1, #answer_prefix) == answer_prefix then
           active_highlight_group = "AnswerHighlight"
        end
        vim.api.nvim_buf_set_extmark(buf, ns, i-1, 0, {
            virt_text = { { " ", active_highlight_group }},
            virt_text_pos = "inline"
        })
        vim.api.nvim_buf_set_extmark(buf, ns, i-1, 0, {
            virt_text = { { " ", "Normal"}},
            virt_text_pos = "inline"
        })
    end
    return all_data
end

local function keep_prompting(buf, prompt_list, all_data, callback)
    local still_asking = true
    while still_asking do
        vim.ui.input({ prompt = ">> "}, function(input)
            if input then
                if input == 'exit' then
                    still_asking = false
                elseif input == '' then
                    still_asking = true
                else
                    all_data = get_current_window_lines()
                    if string.find(all_data, '[END ANSWER]') then
                        local conversation_parts = vim.fn.split(all_data, '\\[END ANSWER\\]')
                        local prev_interaction = conversation_parts[#conversation_parts - 1]
                        local prev_parts = vim.fn.split(prev_interaction, '\\[ANSWER\\]')
                        local assistant_obj = { role = "assistant", content = prev_parts[#prev_parts] }
                        table.insert(prompt_list, assistant_obj)
                    end
                    local prompt_obj = { role = "user", content = input }
                    table.insert(prompt_list, prompt_obj)
                    all_data = all_data .. '\n' .. '[QUESTION]\n' .. input .. '\n\n'
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
    local all_data = '[QUESTION]\n' .. prompt .. '\n'
    local prompt_obj = { role = "user", content = prompt}
    local prompt_list = {}
    table.insert(prompt_list, prompt_obj)
    requests.ask_llm(buf, prompt_list, all_data, handle_streaming_data)
    vim.cmd('redraw')
    keep_prompting(buf, prompt_list, all_data, handle_streaming_data)
end

return M
