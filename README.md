# GitLab Plugin for Neovim

[[_TOC_]]

A Lua based plugin for Neovim that offers [GitLab Duo Code Suggestions](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html).

All feedback can be submitted in the [[Feedback] GitLab for Neovim](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22) issue.

If you're interested in contributing check out the [development process](docs/developer/development-process.md).

## Requirements

| Software                                                                                                                                       | Version |
|------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| [GitLab SaaS](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#enable-code-suggestions-on-gitlab-saas)                 | 16.1+   |
| [GitLab self-managed](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#enable-code-suggestions-on-self-managed-gitlab) | 16.1+   |
| [Neovim](https://neovim.io/)                                                                                                                   | 0.9+    |

## Setup

1. Follow the [installation](#installation) steps for your chosen plugin manager.
1. Optional. [Configure GitLab Duo Code Suggestions](#omni-completion) as an Omni completion provider.
1. Set up helptags using `:helptags ALL` for access to [`:help gitlab.txt`](doc/gitlab.txt).

### Installation

To install the GitLab Vim plugin:

1. Clone Neovim's packpath which is included by [packadd](https://neovim.io/doc/user/repeat.html#%3Apackadd) on startup.

   ```shell
   git clone git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
   ```

1. Add the following plugin to your [lazy.nvim](https://github.com/folke/lazy.nvim) configuration:

   ```lua
   {
     'git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git',
     event = { 'BufReadPre', 'BufNewFile' }, -- Activate when a file is created/opened
     ft = { 'go', 'javascript', 'python', 'ruby' }, -- Activate when a supported filetype is open
     cond = function()
       return vim.env.GITLAB_TOKEN ~= nil and vim.env.GITLAB_TOKEN ~= '' -- Only activate is token is present in environment variable (remove to use interactive workflow)
     end,
     opts = {
       statusline = {
         enabled = true, -- Hook into the builtin statusline to indicate the status of the GitLab Duo Code Suggestions integration
       },
     },
   }
   ```

1. Declare the plugin in your [packer.nvim](https://github.com/wbthomason/packer.nvim) configuration:

   ```lua
   use {
     "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
   }
   ```

#### Uninstalling

1. Remove this plugin and any language server binaries with the following commands

      ```shell
      rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
      rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
      ```

### Configuration

These environment variables are the most frequently used.
For a full list, see this plugin's help text at [`doc/gitlab.txt`](doc/gitlab.txt).

| Environment variable | Default              | Description |
|----------------------|----------------------|-------------|
| `GITLAB_TOKEN`.      | n/a                  | The default GitLab Personal Access Token to use for authenticated requests. If provided, interactive authentication is skipped. |
| `GITLAB_VIM_URL`.    | `https://gitlab.com` | Override the GitLab instance to connect with. Defaults to `https://gitlab.com`. |

### Omni completion

To enable [omni completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes)
using GitLab Duo Code Suggestions, you must meet all these conditions:

- You must be using GitLab Enterprise Edition.
- For self-managed installations, Code Suggestions must be
  [enabled for your instance](https://docs.gitlab.com/ee/user/project/repository/code_suggestions/self_managed.html).
- For GitLab.com, Code Suggestions must be
  enabled for your top-level group. See instructions
  [for SaaS](https://docs.gitlab.com/ee/user/group/manage.html#enable-code-suggestions-for-a-group).

If you meet all these conditions, you can enable
[Omni completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes) using GitLab Duo Code Suggestions:

1. Create a [Personal Access Token](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#enable-code-suggestions-in-your-gitlab-saas-account) with the `api` scope.

1. Install the GitLab Duo Code Suggestions [language server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-language-server-for-code-suggestions).

   You may find it helpful to configure omni completion's popup menu even for a single suggestion:

   ```lua
   vim.o.completeopt = 'menu,menuone'
   ```

1. When working in a supported file type, use <kbd>Ctrl</kbd> + <kbd>X</kbd> then <kbd>Ctrl</kbd> + <kbd>O</kbd> to open the Omni completion menu.

### Keymaps

| Mode     | Keymaps                               | Type     | Description                                                                        |
|----------|---------------------------------------|----------|------------------------------------------------------------------------------------|
| `INSERT` | `<C-X><C-O>`                          | Builtin  | Requests completions from GitLab Duo Code Suggestions through the language server. |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>` | Toggles Code Suggestions on/off for the current buffer.                            |

1. Builtin keymaps extend existing functionality. For example because Code Suggestions provides an LSP server the builtin `ctrl-x ctrl-o` omni complete keymap works.
1. `<Plug>` keymaps are provided for convenience.

To use `<Plug>(GitLab...)` maps above you must include your own keymap that references it:

```lua
-- Toggle Code Suggestions on/off with CTRL-g in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

### Resource editing

Enable the `gitlab.resource_editing` to enable:

1. Use `:edit https://gitlab.com/RESOURCE_URL` to open a buffer with the description of an epic, issue, or merge request.
1. Saving the buffer with `:w` will update the resource's Markdown description.

### Statusline

`gitlab.statusline` is enabled by default which hooks into the builtin `statusline` to indicate the status of the GitLab Duo Code Suggestions integration.

```lua
require('gitlab').setup({
  statusline = {
    enabled = false
  }
})
```

### Troubleshooting

For help troubleshooting please refer to the [troubleshooting guide](docs/developer/troubleshooting.md).

## Features

### GitLab Duo Code Suggestions

Write code more efficiently by using generative AI to suggest code while you’re developing. To learn more about this feature, see the
[GitLab Duo Code Suggestions documentation](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#enable-code-suggestions-in-vs-code)

GitLab Duo Code Suggestions is a generative artificial intelligence (AI) model. GitLab currently leverages [Google Cloud’s Vertex AI Codey API models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview)

No new additional data is collected to enable this feature. Private non-public GitLab customer data is not used as training data.
Learn more about [Google Vertex AI Codey APIs Data Governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance)

Users should read about the [known limitations](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#known-limitations)

#### Supported Languages

Languages supported by GitLab Duo Code Suggestions can be found in the [documentation](https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#supported-languages).

For your convenience this plugin provides Vim auto-commands to start the LSP integration for some supported filetypes.
That is Ruby is a supported language so the plugin will add a `FileType ruby` auto-command.

You can configure this behavior for additional filetypes through the `code_suggestions.auto_filetypes` setup option.

## Release Process

1. Review whether each merge request since the last release has/requires a changelog entry.

1. Create a new merge request to increment the plugin version.

   1. Update `PLUGIN_VERSION` in [`lua/gitlab/globals.lua`](lua/gitlab/globals.lua).

   1. Add a new `## vX.Y.Z` header above the previous [CHANGELOG.md](CHANGELOG.md) entry.

1. Merge the merge request once it has been approved.

1. Create a new signed Git tag off of the `main` branch.

## Issues

Looking to [report an issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues)?

## Contributing

This extension is open source and [hosted on GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git). Contributions are more than welcome. Feel free to fork and add new features or submit bug reports. See [CONTRIBUTING](CONTRIBUTING.md) for more information.

[A list of the great people](CONTRIBUTORS.md) who contributed this project, and made it even more awesome, is available. Thank you all! 🎉

## License

See [LICENSE](LICENSE).
