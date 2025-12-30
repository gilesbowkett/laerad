# frozen_string_literal: true

require "test_helper"

class TestSyntaxTreeMethods < Minitest::Test
  def test_all_methods_called_on_syntax_tree_types_exist
    lib_path = File.expand_path("../../lib", __dir__)
    ruby_files = Dir.glob("#{lib_path}/**/*.rb")

    errors = []

    ruby_files.each do |file|
      ast = SyntaxTree.parse(File.read(file))
      find_case_statements(ast) do |case_node, case_var_name|
        each_when_branch(case_node) do |when_node, types|
          methods_called = find_method_calls_on(when_node.statements, case_var_name)

          types.each do |type_name|
            klass = SyntaxTree.const_get(type_name)
            methods_called.each do |method_name|
              unless klass.instance_methods.include?(method_name.to_sym)
                errors << "#{file}: SyntaxTree::#{type_name}##{method_name} does not exist"
              end
            end
          rescue NameError
            # Handled by test_syntax_tree_constants
          end
        end
      end
    end

    assert errors.empty?, errors.join("\n")
  end

  def test_helper_methods_handle_all_call_site_types
    lib_path = File.expand_path("../../lib", __dir__)
    ruby_files = Dir.glob("#{lib_path}/**/*.rb")

    errors = []

    # Methods to exclude (polymorphic by design)
    excluded_methods = %w[visit visit_params]

    ruby_files.each do |file|
      ast = SyntaxTree.parse(File.read(file))

      method_param_calls = find_method_param_calls(ast)
      method_param_calls.reject! { |name, _| excluded_methods.include?(name) }

      find_case_statements(ast) do |case_node, case_var_name|
        each_when_branch(case_node) do |when_node, types|
          find_method_calls_with_args(when_node.statements, case_var_name) do |method_name, arg_expr|
            next unless method_param_calls[method_name]

            arg_types = infer_argument_types(arg_expr, case_var_name, types)

            arg_types.each do |arg_type|
              method_param_calls[method_name].each do |called_method|
                klass = SyntaxTree.const_get(arg_type)
                unless klass.instance_methods.include?(called_method.to_sym)
                  errors << "#{file}: #{method_name} calls .#{called_method} on param, but SyntaxTree::#{arg_type} (from call site) doesn't have it"
                end
              rescue NameError
                # Skip non-SyntaxTree types
              end
            end
          end
        end
      end
    end

    assert errors.empty?, errors.join("\n")
  end

  def test_case_expression_methods_exist_on_all_when_types
    lib_path = File.expand_path("../../lib", __dir__)
    ruby_files = Dir.glob("#{lib_path}/**/*.rb")

    errors = []

    ruby_files.each do |file|
      ast = SyntaxTree.parse(File.read(file))
      find_case_with_method_call(ast) do |case_node, var_name, method_name|
        types = collect_all_when_types(case_node)
        types.each do |type_name|
          klass = SyntaxTree.const_get(type_name)
          unless klass.instance_methods.include?(method_name.to_sym)
            errors << "#{file}: case #{var_name}.#{method_name} - SyntaxTree::#{type_name}##{method_name} does not exist"
          end
        rescue NameError
          # Handled by test_syntax_tree_constants
        end
      end
    end

    assert errors.empty?, errors.join("\n")
  end

  private

  def find_case_statements(node, &block)
    return unless node

    case node
    when SyntaxTree::Case
      case_var_name = extract_case_variable(node.value)
      yield(node, case_var_name) if case_var_name
      find_case_statements(node.consequent, &block)
    when SyntaxTree::When
      find_case_statements(node.statements, &block)
      find_case_statements(node.consequent, &block)
    else
      node.child_nodes.each { |child| find_case_statements(child, &block) } if node.respond_to?(:child_nodes)
    end
  end

  def extract_case_variable(node)
    case node
    when SyntaxTree::VarRef, SyntaxTree::VCall
      node.value.value if node.value.is_a?(SyntaxTree::Ident)
    when SyntaxTree::CallNode
      if node.receiver.nil? && node.arguments.nil?
        node.message.value if node.message.is_a?(SyntaxTree::Ident)
      end
    end
  end

  def each_when_branch(case_node, &block)
    branch = case_node.consequent
    while branch.is_a?(SyntaxTree::When)
      types = extract_syntax_tree_types(branch.arguments)
      yield(branch, types) unless types.empty?
      branch = branch.consequent
    end
  end

  def extract_syntax_tree_types(args)
    types = []
    return types unless args

    parts = args.respond_to?(:parts) ? args.parts : [args]
    parts.each do |arg|
      if arg.is_a?(SyntaxTree::ConstPathRef)
        if arg.parent.is_a?(SyntaxTree::VarRef) &&
            arg.parent.value.is_a?(SyntaxTree::Const) &&
            arg.parent.value.value == "SyntaxTree" &&
            arg.constant.is_a?(SyntaxTree::Const)
          types << arg.constant.value
        end
      end
    end
    types
  end

  def find_method_calls_on(node, var_name)
    methods = []
    find_calls_recursive(node, var_name, methods)
    methods.uniq
  end

  def find_calls_recursive(node, var_name, methods)
    return unless node

    case node
    when SyntaxTree::CallNode
      if receiver_matches?(node.receiver, var_name)
        methods << node.message.value if node.message.is_a?(SyntaxTree::Ident)
      end
      find_calls_recursive(node.receiver, var_name, methods)
      find_calls_recursive(node.arguments, var_name, methods)
    when SyntaxTree::MethodAddBlock
      find_calls_recursive(node.call, var_name, methods)
      find_calls_recursive(node.block, var_name, methods)
    else
      if node.respond_to?(:child_nodes)
        node.child_nodes.each { |child| find_calls_recursive(child, var_name, methods) }
      end
    end
  end

  def receiver_matches?(receiver, var_name)
    case receiver
    when SyntaxTree::VarRef
      receiver.value.is_a?(SyntaxTree::Ident) && receiver.value.value == var_name
    when SyntaxTree::VCall
      receiver.value.is_a?(SyntaxTree::Ident) && receiver.value.value == var_name
    when SyntaxTree::CallNode
      receiver.receiver.nil? && receiver.arguments.nil? &&
        receiver.message.is_a?(SyntaxTree::Ident) && receiver.message.value == var_name
    else
      false
    end
  end

  def find_case_with_method_call(node, &block)
    return unless node

    case node
    when SyntaxTree::Case
      if node.value.is_a?(SyntaxTree::CallNode) && node.value.receiver
        var_name, method_name = extract_receiver_and_method(node.value)
        yield(node, var_name, method_name) if var_name && method_name
      end
      find_case_with_method_call(node.consequent, &block)
    when SyntaxTree::When
      find_case_with_method_call(node.statements, &block)
      find_case_with_method_call(node.consequent, &block)
    else
      node.child_nodes.each { |child| find_case_with_method_call(child, &block) } if node.respond_to?(:child_nodes)
    end
  end

  def extract_receiver_and_method(call_node)
    return nil unless call_node.is_a?(SyntaxTree::CallNode)

    method_name = call_node.message.value if call_node.message.is_a?(SyntaxTree::Ident)

    var_name = case call_node.receiver
    when SyntaxTree::VarRef
      call_node.receiver.value.value if call_node.receiver.value.is_a?(SyntaxTree::Ident)
    when SyntaxTree::VCall
      call_node.receiver.value.value if call_node.receiver.value.is_a?(SyntaxTree::Ident)
    when SyntaxTree::CallNode
      if call_node.receiver.receiver.nil? && call_node.receiver.arguments.nil?
        call_node.receiver.message.value if call_node.receiver.message.is_a?(SyntaxTree::Ident)
      end
    end

    [var_name, method_name]
  end

  def collect_all_when_types(case_node)
    types = []
    branch = case_node.consequent
    while branch.is_a?(SyntaxTree::When)
      types.concat(extract_syntax_tree_types(branch.arguments))
      branch = branch.consequent
    end
    types.uniq
  end

  def find_method_param_calls(node)
    results = {}
    find_method_defs(node) do |def_node|
      method_name = def_node.name.value
      param_names = extract_param_names(def_node.params)
      methods_called = []
      param_names.each do |param_name|
        methods_called.concat(find_method_calls_on(def_node.bodystmt, param_name))
      end
      results[method_name] = methods_called.uniq unless methods_called.empty?
    end
    results
  end

  def find_method_defs(node, &block)
    return unless node

    case node
    when SyntaxTree::DefNode
      yield(node)
      find_method_defs(node.bodystmt, &block)
    else
      node.child_nodes.each { |child| find_method_defs(child, &block) } if node.respond_to?(:child_nodes)
    end
  end

  def extract_param_names(params)
    return [] unless params

    names = []
    case params
    when SyntaxTree::Params
      params.requireds.each do |p|
        names << p.value if p.is_a?(SyntaxTree::Ident)
      end
    when SyntaxTree::Paren
      names.concat(extract_param_names(params.contents))
    end
    names
  end

  def find_method_calls_with_args(node, var_name, &block)
    return unless node

    case node
    when SyntaxTree::CallNode
      if node.receiver.nil? && node.arguments
        method_name = node.message.value if node.message.is_a?(SyntaxTree::Ident)
        if method_name
          extract_call_args(node.arguments).each do |arg|
            yield(method_name, arg)
          end
        end
      end
      find_method_calls_with_args(node.arguments, var_name, &block)
    when SyntaxTree::MethodAddBlock
      find_method_calls_with_args(node.call, var_name, &block)
    else
      node.child_nodes.each { |child| find_method_calls_with_args(child, var_name, &block) } if node.respond_to?(:child_nodes)
    end
  end

  def extract_call_args(args)
    return [] unless args

    case args
    when SyntaxTree::ArgParen
      extract_call_args(args.arguments)
    when SyntaxTree::Args
      args.parts
    else
      [args]
    end
  end

  def infer_argument_types(arg_expr, case_var_name, branch_types)
    # If arg is just the case variable, return branch types
    if simple_var_ref?(arg_expr, case_var_name)
      return branch_types
    end

    # If arg is case_var.method, look up return types
    if arg_expr.is_a?(SyntaxTree::CallNode)
      receiver_name = extract_simple_receiver_name(arg_expr.receiver)
      if receiver_name == case_var_name
        method_name = arg_expr.message.value if arg_expr.message.is_a?(SyntaxTree::Ident)
        if method_name
          return branch_types.flat_map { |t| return_types_for(t, method_name) }.uniq
        end
      end
    end

    []
  end

  def simple_var_ref?(node, var_name)
    case node
    when SyntaxTree::VarRef
      node.value.is_a?(SyntaxTree::Ident) && node.value.value == var_name
    when SyntaxTree::VCall
      node.value.is_a?(SyntaxTree::Ident) && node.value.value == var_name
    else
      false
    end
  end

  def extract_simple_receiver_name(node)
    case node
    when SyntaxTree::VarRef
      node.value.value if node.value.is_a?(SyntaxTree::Ident)
    when SyntaxTree::VCall
      node.value.value if node.value.is_a?(SyntaxTree::Ident)
    when SyntaxTree::CallNode
      if node.receiver.nil? && node.arguments.nil?
        node.message.value if node.message.is_a?(SyntaxTree::Ident)
      end
    end
  end

  def return_types_for(type_name, method_name)
    # Map known SyntaxTree method return types
    type_returns = {
      "OpAssign" => {
        "target" => ["VarField", "ARefField", "Field", "ConstPathField", "TopConstField"],
        "value" => [],
        "operator" => []
      },
      "Assign" => {
        "target" => ["VarField", "ARefField", "Field", "ConstPathField", "TopConstField"],
        "value" => []
      },
      "VarField" => {
        "value" => ["Ident", "Const", "CVar", "GVar", "IVar"]
      },
      "VarRef" => {
        "value" => ["Ident", "Const", "CVar", "GVar", "IVar", "Kw"]
      }
    }

    type_returns.dig(type_name, method_name) || []
  end
end
