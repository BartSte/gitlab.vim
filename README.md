# GitLab Plugin for Neovim

This extension integrates GitLab Duo with Neovim. It's built with Lua.
This extension provides:

- GitLab Duo Code Suggestions.
- [Omni Completion key mapping](https://docs.gitlab.com/ee/editor_extensions/neovim/#configure-omni-completion).
- Vim auto-commands.
- Local editing of GitLab issues, epics, and merge requests.

## GitLab Duo Code Suggestions

Use GitLab Duo Code Suggestions to write code more efficiently by using generative AI to suggest code while you're
developing. It's a generative artificial intelligence (AI) model that uses
[Google Cloud's Vertex AI Codey API models](https://cloud.google.com/vertex-ai/generative-ai/docs/code/code-models-overview).

To learn more about this feature, see the
[GitLab Duo Code Suggestions documentation](https://docs.gitlab.com/ee/user/project/repository/code_suggestions/index.html)
and the list of [supported languages](https://docs.gitlab.com/ee/user/project/repository/code_suggestions/supported_extensions.html#supported-languages).

No new additional data is collected to enable this feature. Private non-public
GitLab customer data is not used as training data. Learn more about
[Google Vertex AI Codey APIs Data Governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance)

## Extension requirements

This extension requires:

- GitLab version 16.1 or later for both SaaS and self-managed.
  While many extension features might work with earlier versions, they are unsupported.
  - The GitLab Duo Code Suggestions feature requires GitLab version 16.8 or later.
- [Neovim](https://neovim.io/) version 0.9 or later.

## Install the extension

For installation and configuration instructions, see
[Install the extension](https://docs.gitlab.com/ee/editor_extensions/neovim/#install-the-extension)
in the GitLab documentation.

## Uninstall the extension

1. Remove this extension and any language server binaries with these commands:

   ```shell
   rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
   rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
   ```

## Roadmap

- See [all open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues) for this project.
- This project is maintained by the Create:Editor Extensions Group. The team's
  [processes and plans](https://handbook.gitlab.com/handbook/engineering/development/dev/create/editor-extensions/)
  are available in the GitLab handbook.

### Developer resources

- [Development process](docs/developer/development-process.md)
- [Language Server integration](docs/developer/lsp.md)
- [Release process](docs/developer/release-process.md)
- [Testing](docs/developer/testing.md)

## Troubleshooting

See [troubleshooting information](https://docs.gitlab.com/ee/editor_extensions/neovim/neovim_troubleshooting.html)
in the GitLab documentation. If the problem persists,
[report it in an issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues) in this project.

## Contributing

This extension is open source and
[hosted on GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim).
Contributions are more than welcome. Feel free to fork and add new features or
submit bug reports. See [CONTRIBUTING](CONTRIBUTING.md) for more information, and
check out the [development process](docs/developer/development-process.md).

[A list of the great people](CONTRIBUTORS.md) who contributed this project, and
made it even more awesome, is available. Thank you all! 🎉

## License

See [LICENSE](LICENSE).
