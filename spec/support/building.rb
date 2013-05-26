##
# Builds a list of definitions for the specified block of Ruby code.
#
# @param [String] code The code to analyze.
# @return [RubyLint::Definition::RubyObject]
#
def build_definitions(code)
  loader = RubyLint::ConstantLoader.new
  vm     = RubyLint::VirtualMachine.new
  ast    = parse(code, false)

  loader.iterate(ast)
  vm.iterate(ast)

  return vm.definitions
end

##
# Builds a report for the given code and iterator class.
#
# @param [String] code
# @param [Class] iterator
# @return [RubyLint::Report]
#
def build_report(code, iterator)
  ast          = parse(code, false)
  defs_builder = RubyLint::VirtualMachine.new
  loader       = RubyLint::ConstantLoader.new

  loader.iterate(ast)
  defs_builder.iterate(ast)

  report   = RubyLint::Report.new
  iterator = iterator.new(
    :report           => report,
    :definitions      => defs_builder.definitions,
    :node_definitions => defs_builder.associations
  )

  iterator.iterate(ast)

  return report
end
