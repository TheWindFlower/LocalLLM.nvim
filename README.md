# localLLM.nvim

**A local AI coding assistant for Neovim, powered by Ollama.**

`localLLM.nvim` is an open-source Neovim plugin project designed to bring local Large Language Models (LLMs) directly into your editor. Its goal is to help developers understand, document, debug, and improve their code without relying on cloud-based AI services.

The project is being built from scratch in Lua, with a focus on learning Neovim's API, asynchronous programming, HTTP communication, and plugin development.

## ✨ Features

### Planned features

* **Code explanation** — Select a block of code and ask a local LLM to explain it.
* **Local inference** — Use locally hosted models through Ollama.
* **Editor integration** — Display responses in a dedicated Neovim split.
* **Custom prompts** — Tailor instructions for different coding tasks.
* **Code documentation** — Generate documentation for selected functions and classes.
* **Bug analysis** — Ask the model to identify potential issues.
* **Refactoring suggestions** — Explore alternative implementations.
* **Test generation** — Generate unit tests for selected code.
* **Interactive chat** — Ask follow-up questions about your code.
* **Streaming responses** — Display generated text as it arrives.

Features will be implemented incrementally as the project develops.

## 🎯 Project goals

This project has two main goals:

1. **Build a useful tool:** Integrate local LLMs into a Neovim workflow with minimal friction.
2. **Learn by building:** Develop a deeper understanding of Lua, Neovim's API, REST APIs, asynchronous operations, and software architecture by implementing the plugin from the ground up.

## 🖥️ How it will work

The intended workflow is simple:

1. Select a block of code in Neovim.
2. Trigger a keymap, such as `<leader>doc`.
3. The plugin retrieves the selected text and the current filetype.
4. The plugin constructs a prompt and sends it to Ollama.
5. The response appears in a dedicated Neovim split.

```text
┌─────────────────────────┬──────────────────────────┐
│ Neovim                  │ localLLM.nvim             │
│                         │                          │
│ def calculate(x):       │ Explain the selected     │
│     return x * 2        │ code...                  │
│                         │                          │
│       <leader>doc       │ Response from the local  │
│                         │ language model           │
└─────────────────────────┴──────────────────────────┘
                 │                    ▲
                 ▼                    │
             Ollama API ──────────────┘
```

## 🛠️ Tech stack

* **Language:** Lua
* **Editor:** Neovim
* **LLM runtime:** Ollama
* **Communication:** HTTP / REST API
* **Model support:** Ollama-compatible language models

## 📋 Requirements

The intended requirements are:

* Neovim with Lua support
* [Ollama](https://ollama.com/) installed and running locally
* A model available in Ollama
* An HTTP client or process interface, to be selected during development

## 🚀 Installation

Installation instructions will be added once the plugin has a working initial release.

For now, this repository is under active development.

## ⚙️ Configuration

The plugin will eventually support configuration options such as:

* Ollama server URL
* Default model
* Keymaps and commands
* Prompt templates
* Response window layout
* Generation parameters

A future configuration may look like this:

```lua
require("localLLM").setup({
    host = "http://127.0.0.1:11434",
    model = "qwen2.5-coder",
})
```

*The configuration above is illustrative and is not yet a working API.*

## 🗺️ Roadmap

* [x] Create the plugin structure and public Lua API
* [x] Implement basic Neovim commands
* [x] Capture visual selections
* [x] Create a dedicated response buffer and split
* [x] Connect to the Ollama REST API
* [x] Display model responses
* [x] Add asynchronous request handling
* [x] Implement streaming responses
* [x] Add configurable prompts and models
* [ ] Implement interactive chat
* [ ] Add error handling and cancellation
* [ ] Add inline chat request
* [ ] Write tests and documentation
* [ ] Prepare a stable release

## 🤝 Contributing

This project is being developed as a learning project, and contributions, suggestions, and feedback are welcome.

If you find a bug or have an idea for a feature, feel free to open an issue or submit a pull request.

## 📄 License

The license has not yet been selected. A license will be added before the first public release.

---

**Built with Lua, Neovim, and local AI.**

