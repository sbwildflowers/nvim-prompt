# Neovim Prompt

Module for in-editor prompting / chatting with LLM. Currently has pre-built prompt that allows you to select a code block and fire it off prefixed with "Explain this code:". You can also start a fresh conversation without sending any code. 

My current setup for using it with a local model looks like this:

```
require('nvim-prompt.lua.config').setup({
	url = "http://localhost:1234/v1/chat/completions",
	model = "qwen2.5-coder-14b-instruct"
})

local prompt = require('nvim-prompt.lua.ui')

-- take selected text and send to LLM with "Explain this code:" prefix
vim.keymap.set("v", "<leader>ec", function() vim.cmd('normal! "zy') prompt:get_explanation() end, { noremap = true })

-- start fresh conversation
vim.keymap.set("n", "<leader>aq", function() prompt:start_prompting() end)

```

Currently uses ```vim.ui.input()``` for continuous prompting / follow-up questions. Type ```exit``` to end conversation. Currently can't exit/re-enter conversation or switch between buffers while a conversation is ongoing.

## Future

- Better input method for conversation
- Allow users to define dynamic pre-built prompts into config
- Parsing of returned answers, especially code blocks, to make it more readable


