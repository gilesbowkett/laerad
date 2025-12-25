# Laerad: Eliminate Single-Use Abstractions

A static analyzer that detects single-use variables and methods in Ruby code.

## Usage

Scan a file or directory for single-use abstractions:

```bash
bundle exec bin/laerad scan path/to/file.rb
bundle exec bin/laerad scan path/to/directory
```

## How It Works

Laerad uses [SyntaxTree](https://github.com/ruby-syntax-tree/syntax_tree) to
parse Ruby source files into an abstract syntax tree (AST). It then walks this
tree, tracking every variable and method definition along with their references.

### Detection

Laerad flags variables and methods that are used only once or not at all.

### Scoping

Variables are tracked per lexical scope. Each method body, block, or lambda
creates a new scope. A variable defined inside a block is separate from a
variable with the same name outside that block.

Methods are tracked at file level. A method defined anywhere in the file can be
called from anywhere else in the file, so Laerad counts method usage across the
entire file rather than within individual scopes.

### Dynamic Code

Ruby code that uses metaprogramming constructs like `send`, `define_method`,
`class_eval`, or `method_missing` can call methods in ways that static analysis
cannot detect. When Laerad encounters these constructs, it marks the file as
"dynamic" and skips method-usage checks to avoid false positives.

## Architecture

```
CLI (Thor)
 └─> Runner
      └─> FileAnalyzer (per file)
           ├─> SyntaxTree.parse
           ├─> AST visitor
           ├─> Scope stack (tracks variables/methods)
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

Only check for single-use variables:

```bash
bundle exec bin/laerad scan --variables-only path/to/file.rb
bundle exec bin/laerad scan -v path/to/file.rb
```

Only check for single-use methods:

```bash
bundle exec bin/laerad scan --methods-only path/to/file.rb
bundle exec bin/laerad scan -m path/to/file.rb
```

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

Single-use methods:
  /Users/giles/code/laerad/test/fixtures/unused_variable.rb:1  foo (1 use)

❯ bundle exec bin/laerad scan /Users/giles/code/laerad/test/fixtures/
Single-use variables:
  /Users/giles/code/laerad/test/fixtures/multi_use_variable.rb:3  y (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:4  x (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:2  x (1 use)
  /Users/giles/code/laerad/test/fixtures/unused_variable.rb:2  x (1 use)

Single-use methods:
  /Users/giles/code/laerad/test/fixtures/multi_use_method.rb:  times (1 use)
  /Users/giles/code/laerad/test/fixtures/multi_use_variable.rb:1  foo (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:1  outer (1 use)
  /Users/giles/code/laerad/test/fixtures/nested_scopes.rb:  times (1 use)
  /Users/giles/code/laerad/test/fixtures/simple_method.rb:5  top (1 use)
  /Users/giles/code/laerad/test/fixtures/unused_method.rb:1  helper (1 use)
  /Users/giles/code/laerad/test/fixtures/unused_variable.rb:1  foo (1 use)
```

## Tests

```bash
bundle exec rake test
```

Run a single test file:

```bash
bundle exec ruby -Ilib:test test/unit/test_file_analyzer.rb
```

Run a single test method:

```bash
bundle exec ruby -Ilib:test test/unit/test_file_analyzer.rb -n test_unused_variable
```

### What's in a name?

This gem combines Thor with SyntaxTree. Combining Thor with trees made me think
of Yggdrasil, the world tree of Norse mythology, but there's already a gem by
that name. Laerad is an Anglicization of another Norse mythology tree name. It's
[unclear](https://en.wikipedia.org/wiki/L%C3%A6ra%C3%B0r#Theories) how distinct
this tree is from Yggdrasil — could be another name for the same tree, could
be a separate but related tree — but that's usually how things are with
mythologies.
