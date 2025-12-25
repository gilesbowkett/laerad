# Laerad: Eliminate Single-Use Variables

A static analyzer that detects single-use variables in Ruby code.

## Usage

Scan a file or directory for single-use variables:

```bash
bundle exec bin/laerad scan path/to/file.rb
bundle exec bin/laerad scan path/to/directory
```

## How It Works

Laerad uses [SyntaxTree](https://github.com/ruby-syntax-tree/syntax_tree) to
parse Ruby source files into an abstract syntax tree (AST). It then walks this
tree, tracking every variable definition along with its references.

### Detection

Laerad flags variables that are used only once or not at all.

### Scoping

Variables are tracked per lexical scope. Each method body, block, or lambda
creates a new scope. A variable defined inside a block is separate from a
variable with the same name outside that block.

## Architecture

```
CLI (Thor)
 └─> Runner
      └─> FileAnalyzer (per file)
           ├─> SyntaxTree.parse
           ├─> AST visitor
           ├─> Scope stack (tracks variables)
           └─> Result (violations)
```

- **CLI** (`lib/laerad/cli.rb`) - Thor-based command interface with `scan` and
  `version` commands
- **Runner** (`lib/laerad/runner.rb`) - Expands directories into file lists
  and orchestrates analysis
- **FileAnalyzer** (`lib/laerad/file_analyzer.rb`) - Parses Ruby, walks the
  AST, maintains a scope stack
- **Scope** (`lib/laerad/scope.rb`) - Tracks definitions and references with
  usage counts
- **Result** (`lib/laerad/result.rb`) - Collects violations and formats output

### Options

Print version:

```bash
bundle exec bin/laerad version
```

## Development

Install dependencies:

```bash
bundle install
```

## Example Output

```
❯ bundle exec bin/laerad scan /Users/giles/code/laerad/test/fixtures/unused_variable.rb
Single-use variables:
  /Users/giles/code/laerad/test/fixtures/unused_variable.rb:2  x (1 use)

❯ bundle exec bin/laerad scan /Users/giles/code/laerad/test/fixtures/
Single-use variables:
  /Users/giles/code/laerad/test/fixtures/multi_use_variable.rb:3  y (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:4  x (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:2  x (1 use)
  /Users/giles/code/laerad/test/fixtures/unused_variable.rb:2  x (1 use)
```

## Tests

```bash
bundle exec rake test
```

### What's in a name?

This gem combines Thor with SyntaxTree. Combining Thor with trees made me think
of Yggdrasil, the world tree of Norse mythology, but there's already a gem by
that name. Laerad is an Anglicization of another Norse mythology tree name. It's
[unclear](https://en.wikipedia.org/wiki/L%C3%A6ra%C3%B0r#Theories) how distinct
this tree is from Yggdrasil — could be another name for the same tree, could
be a separate but related tree — but that's usually how things are with
mythologies.
