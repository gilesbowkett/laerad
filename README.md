# Laerad: Eliminate Single-Use Abstractions

A static analyzer that detects single-use variables and methods in Ruby code.

## Usage

Scan a file or directory for single-use abstractions:

```bash
bundle exec bin/laerad scan path/to/file.rb
bundle exec bin/laerad scan path/to/directory
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

Run tests:

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
