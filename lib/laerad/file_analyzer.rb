# frozen_string_literal: true

require "syntax_tree"

module Laerad
  class FileAnalyzer
    DYNAMIC_METHODS = %w[send public_send define_method class_eval module_eval instance_eval].freeze

    def self.analyze(path)
      new(path).analyze
    end

    def initialize(path)
      @path = path
      @source = File.read(path)
      @scope_stack = [Scope.new]
      @result = Result.new(file: path)
    end

    def analyze
      ast = SyntaxTree.parse(@source)
      visit(ast)
      finalize_scope(@scope_stack.last)
      @result
    rescue SyntaxTree::Parser::ParseError => e
      @result
    end

    private

    def current_scope
      @scope_stack.last
    end

    def push_scope
      @scope_stack.push(Scope.new)
    end

    def pop_scope
      scope = @scope_stack.pop
      finalize_scope(scope)
      scope
    end

    def finalize_scope(scope)
      scope.single_use_variables.each do |name|
        line = scope.variable_definition_line(name)
        @result.add_variable_violation(
          name: name,
          line: line,
          count: scope.variable_count(name)
        )
      end

      scope.single_use_methods.each do |name|
        line = scope.method_definition_line(name)
        @result.add_method_violation(
          name: name,
          line: line,
          count: scope.method_count(name)
        )
      end
    end

    def visit(node)
      return unless node

      case node
      when SyntaxTree::Program
        visit(node.statements)

      when SyntaxTree::Statements
        node.body.each { |stmt| visit(stmt) }

      when SyntaxTree::VarField
        name = extract_var_name(node)
        if name
          line = node.location.start_line
          current_scope.register_variable_def(name, line)
        end

      when SyntaxTree::VarRef
        name = extract_var_name(node)
        current_scope.register_variable_ref(name) if name

      when SyntaxTree::Assign
        visit(node.target)
        visit(node.value)

      when SyntaxTree::OpAssign
        visit(node.target)
        visit(node.value)

      when SyntaxTree::DefNode
        name = node.name.value
        line = node.location.start_line
        current_scope.register_method_def(name, line)

        push_scope
        visit_params(node.params)
        visit(node.bodystmt)
        pop_scope

      when SyntaxTree::BodyStmt
        visit(node.statements)
        node.rescue_clause&.then { |r| visit(r) }
        node.else_clause&.then { |e| visit(e) }
        node.ensure_clause&.then { |en| visit(en) }

      when SyntaxTree::Rescue
        if node.exception
          visit_rescue_exception(node.exception)
        end
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::RescueEx
        if node.variable
          visit(node.variable)
        end

      when SyntaxTree::MethodAddBlock
        visit(node.call)
        visit(node.block)

      when SyntaxTree::CallNode
        visit(node.receiver) if node.receiver
        method_name = extract_method_name(node)
        if method_name
          check_dynamic_method(method_name)
          current_scope.register_method_call(method_name)
        end
        visit(node.arguments) if node.arguments

      when SyntaxTree::VCall
        method_name = node.value.value
        check_dynamic_method(method_name)
        current_scope.register_method_call(method_name)

      when SyntaxTree::Command
        method_name = node.message.value
        check_dynamic_method(method_name)
        current_scope.register_method_call(method_name)
        visit(node.arguments)

      when SyntaxTree::CommandCall
        visit(node.receiver) if node.receiver
        method_name = node.message.value
        check_dynamic_method(method_name)
        current_scope.register_method_call(method_name)
        visit(node.arguments) if node.arguments

      when SyntaxTree::BlockNode
        push_scope
        visit_block_params(node.block_var) if node.block_var
        visit(node.bodystmt)
        pop_scope

      when SyntaxTree::Lambda
        push_scope
        visit_lambda_params(node.params)
        visit(node.statements)
        pop_scope

      when SyntaxTree::ClassDeclaration
        visit(node.bodystmt)

      when SyntaxTree::ModuleDeclaration
        visit(node.bodystmt)

      when SyntaxTree::Binary
        visit(node.left)
        visit(node.right)

      when SyntaxTree::Unary
        visit(node.statement)

      when SyntaxTree::Paren
        visit(node.contents)

      when SyntaxTree::IfNode
        visit(node.predicate)
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::UnlessNode
        visit(node.predicate)
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::Elsif
        visit(node.predicate)
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::Else
        visit(node.statements)

      when SyntaxTree::WhileNode
        visit(node.predicate)
        visit(node.statements)

      when SyntaxTree::UntilNode
        visit(node.predicate)
        visit(node.statements)

      when SyntaxTree::For
        visit(node.index)
        visit(node.collection)
        visit(node.statements)

      when SyntaxTree::Case
        visit(node.value) if node.value
        visit(node.consequent)

      when SyntaxTree::When
        node.arguments.parts.each { |arg| visit(arg) }
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::In
        visit(node.pattern)
        visit(node.statements)
        visit(node.consequent) if node.consequent

      when SyntaxTree::Begin
        visit(node.bodystmt)

      when SyntaxTree::Ensure
        visit(node.statements)

      when SyntaxTree::ReturnNode
        visit(node.arguments) if node.arguments

      when SyntaxTree::YieldNode
        visit(node.arguments) if node.arguments

      when SyntaxTree::Args
        node.parts.each { |part| visit(part) }

      when SyntaxTree::ArgParen
        visit(node.arguments)

      when SyntaxTree::ArrayLiteral
        visit(node.contents) if node.contents

      when SyntaxTree::HashLiteral
        node.assocs.each { |assoc| visit(assoc) } if node.assocs.is_a?(Array)
        visit(node.assocs) if node.assocs && !node.assocs.is_a?(Array)

      when SyntaxTree::Assoc
        visit(node.key)
        visit(node.value)

      when SyntaxTree::AssocSplat
        visit(node.value)

      when SyntaxTree::RangeNode
        visit(node.left) if node.left
        visit(node.right) if node.right

      when SyntaxTree::Not
        visit(node.statement)

      when SyntaxTree::Defined
        visit(node.value)

      when SyntaxTree::ARef
        visit(node.collection)
        visit(node.index)

      when SyntaxTree::ARefField
        visit(node.collection)
        visit(node.index)

      when SyntaxTree::StringConcat
        visit(node.left)
        visit(node.right)

      when SyntaxTree::StringEmbExpr
        visit(node.statements)

      when SyntaxTree::StringLiteral
        node.parts.each { |part| visit(part) }

      when SyntaxTree::DynaSymbol
        node.parts.each { |part| visit(part) }

      when SyntaxTree::XStringLiteral
        node.parts.each { |part| visit(part) }

      when SyntaxTree::RegexpLiteral
        node.parts.each { |part| visit(part) }

      when SyntaxTree::Heredoc
        node.parts.each { |part| visit(part) }

      when SyntaxTree::MAssign
        visit(node.target)
        visit(node.value)

      when SyntaxTree::MLHS
        node.parts.each { |part| visit(part) }

      when SyntaxTree::MLHSParen
        visit(node.contents)

      when SyntaxTree::Next, SyntaxTree::Break, SyntaxTree::Redo, SyntaxTree::Retry
        # control flow, no-op

      when SyntaxTree::VoidStmt
        # empty statement, no-op
      end
    end

    def visit_params(params)
      return unless params

      case params
      when SyntaxTree::Params
        params.requireds.each { |p| register_param(p) }
        params.optionals.each { |opt| register_param(opt[0]); visit(opt[1]) }
        register_param(params.rest) if params.rest && params.rest != :nil
        params.posts.each { |p| register_param(p) }
        params.keywords.each { |kw| register_param(kw[0]); visit(kw[1]) if kw[1] }
        register_param(params.keyword_rest) if params.keyword_rest
        register_param(params.block) if params.block
      when SyntaxTree::Paren
        visit_params(params.contents)
      end
    end

    def visit_block_params(block_var)
      return unless block_var

      visit_params(block_var.params)
      block_var.locals.each { |local| register_param(local) }
    end

    def visit_lambda_params(params)
      case params
      when SyntaxTree::LambdaVar
        visit_params(params.params)
        params.locals.each { |local| register_param(local) }
      when SyntaxTree::Paren
        visit_lambda_params(params.contents)
      when SyntaxTree::Params
        visit_params(params)
      end
    end

    def register_param(param)
      return unless param

      name = case param
      when SyntaxTree::Ident
        param.value
      when SyntaxTree::RestParam
        param.name&.value
      when SyntaxTree::KeywordRestParam
        param.name&.value
      when SyntaxTree::BlockArg
        param.name&.value
      when SyntaxTree::ArgsForward
        nil
      else
        nil
      end

      if name
        current_scope.register_variable_def(name, param.location.start_line)
      end
    end

    def visit_rescue_exception(exception)
      if exception.variable
        visit(exception.variable)
      end
    end

    def extract_var_name(node)
      case node.value
      when SyntaxTree::Ident
        node.value.value
      else
        nil
      end
    end

    def extract_method_name(node)
      case node.message
      when SyntaxTree::Ident
        node.message.value
      when SyntaxTree::Op
        node.message.value
      when Symbol
        node.message.to_s
      else
        nil
      end
    end

    def check_dynamic_method(name)
      if DYNAMIC_METHODS.include?(name)
        mark_all_scopes_dynamic!
      elsif name == "method_missing"
        mark_all_scopes_dynamic!
      end
    end

    def mark_all_scopes_dynamic!
      @scope_stack.each(&:mark_dynamic!)
    end
  end
end
