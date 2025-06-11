local prompts = {}

function prompts.explain_code_prompt()
    local yanked = vim.fn.getreg('z')
    local prompt_string = "Explain this code: \n" .. yanked
    return prompt_string
end

return prompts
