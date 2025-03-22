# Changelog

## v1.3.0

- Added status tracking for code suggestions LSP (waiting, success, failed states)

## v1.2.0

- Upgrade GitLab language server for Code Suggestions to `v7.17.1` (!216)
- Add experimental ghost text (!211)
- Add LSP client settings health check (!202)
- Improve startup time by relying on language server notifications (!196)

## v1.1.0

- Added support for partial suggestion insertion and restoration (next/previous word/line)
- Refactored ghost text implementation into modular components (autocmd, commands, display, insert, lsp, suggestion)
- Updated statusline configuration to accept custom callback functions for dynamic updates
- Implemented word splitting utility to support partial suggestion interactions
- Fixed ghost text display issues with trailing newlines and cursor positioning
- Updated README with fork information and new feature documentation

## v1.0.0

- Upgrade GitLab language server for Code Suggestions to `v2.1.0` (!44)
  - Add `lsp/package.json` to track `@gitlab-org/gitlab-lsp` package compatibility
  - Add `<Plug>(GitLabToggleCodeSuggestions)` keymap which can be used to toggle Code Suggestions on/off
  - Apply the `GitLabCodeSuggestions` `augroup` to all autocommands
  - Handle token check error through `$/gitlab/token/check` LSP method handler
  - Support language server workspace settings introduced in `v2.1.0`

## v0.1.1

- Add autocommands for more supported Code Suggestions languages (!45)

## v0.1.0

- Document Code Suggestions completion and add `fix_newlines` option (!29)
- Add Omni completion support through the Neovim LSP client (!22)
- Setup Lua module and plugin structure (!1)
