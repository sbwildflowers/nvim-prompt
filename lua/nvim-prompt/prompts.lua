local prompts = {}

function prompts.explain_code_prompt()
    local yanked = vim.fn.getreg('z')
    local lines_array = vim.split(yanked, '\n')
    table.insert(lines_array, 1, "Explain this code: ")
    local prompt_string = table.concat(lines_array, '\n')
    return prompt_string
end

return prompts
