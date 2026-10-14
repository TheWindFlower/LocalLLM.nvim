local M = {}

M.defaults = {
    host = "http://127.0.0.1:11434",
    model = "hf.co/Olak17/Qwen2.5-Coder-1.5B-Unsensored-DPO-i1-GGUF:q4_k_m",
    window = {
        width = 0.33,
    },
    statusline = {
        model_width = 14
    },
    system = table.concat({
        "You are a coding assistant inside a text editor.",
        "Always respond in valid Markdown.",
        "Put every piece of code in a fenced code block, and always put the language name after the opening fence (for example ```lua).",
        "Use short headings (##) and bullet points to organize longer answers.",
        "Use inline `backticks` for identifiers, function names, and file names.",
        "Be concise. Do not add greetings or closing remarks.",
    }, " "),
    prompts = {
        explain = "Explain the following {filetype} code.\n\n"
            .. "Structure your answer as:\n"
            .. "## Summary\nOne or two sentences on what it does.\n"
            .. "## Walkthrough\nBullet points going through the logic step by step.\n"
            .. "## Notes\nAnything notable (edge cases, gotchas). Omit this section if there is nothing to say.",
        document = "Add documentation comments to the following {filetype} code, "
            .. "using the idiomatic doc-comment style for that language.\n\n"
            .. "Return the complete documented code in a single fenced code block. "
            .. "Do not change the logic. After the block, add at most two sentences "
            .. "about anything you assumed.",
        bugs = "Review the following {filetype} code for bugs, edge cases, and potential problems.\n\n"
            .. "For each issue use this format:\n"
            .. "### <short title>\n"
            .. "**Problem:** what is wrong and when it happens.\n"
            .. "**Fix:** a fenced code block with the corrected code.\n\n"
            .. "If you find no real issues, say so in one sentence instead of inventing some.",
        refactor = "Suggest improvements to the following {filetype} code.\n\n"
            .. "Structure your answer as:\n"
            .. "## Improved version\nA single fenced code block with the full refactored code.\n"
            .. "## What changed\nBullet points, one per change, with the reason.",
        tests = "Write unit tests for the following {filetype} code, "
            .. "using the most common testing framework for that language.\n\n"
            .. "Return the tests in a single fenced code block, including any needed imports. "
            .. "Cover normal cases and edge cases. After the block, list what each test covers "
            .. "in a short bullet list.",
    },
    inline = {
        context_before = 150, -- lines of code kept above the insertion point
        context_after = 50, -- lines of code kept below it
        temperature = 0.2, -- lower = more predictable code
        system = table.concat({
            "You are a code generator inside a text editor.",
            "You receive a file containing the marker <INSERT_HERE> and a request.",
            "Output ONLY the code that should be inserted at the marker.",
            "No Markdown, no code fences, no explanations, no greetings.",
            "Do not repeat the surrounding code or the marker.",
            "Match the language, naming, style, and indentation of the surrounding code,",
            "and reuse existing functions and variables from the file when relevant.",
        }, " "),
    },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
