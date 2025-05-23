# Code Formatter-Vetter GitHub Action

This GitHub Action can be used to check sources files for formatting and vetting issues.

To enable this Action, you can create a .yml file under your repo's .github/workflows directory.
Simple example:

```yaml
name: Code Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:

  code-check:
    name: Check formatting and vetting
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v4
      - name: Run the formatter and vetter
        uses: dell/common-github-actions/go-code-formatter-vetter@main
        with:
          directories: ./...
```

The `directories` for the Action is a path in which to check for these issues. You can use `./...` (default if no `directories` are provided) to check from the root of the repo.
