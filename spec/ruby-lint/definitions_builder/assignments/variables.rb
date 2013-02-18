require File.expand_path('../../../../helper', __FILE__)

describe 'Building variable definitions' do
  describe 'variables' do
    should 'process basic variable assignments' do
      defs   = build_definitions('number = 10')
      number = defs.lookup(:local_variable, 'number')

      number.is_a?(RubyLint::Definition::RubyObject).should == true
      number.name.should == 'number'

      number.value.is_a?(RubyLint::Definition::RubyObject).should == true
      number.value.value.should == '10'
    end

    should 'process multiple variable assignments' do
      defs    = build_definitions('number, numberx = 10, 20')
      number  = defs.lookup(:local_variable, 'number')
      numberx = defs.lookup(:local_variable, 'numberx')

      number.is_a?(RubyLint::Definition::RubyObject).should == true

      number.name.should        == 'number'
      number.value.value.should == '10'

      numberx.is_a?(RubyLint::Definition::RubyObject).should == true

      numberx.name.should        == 'numberx'
      numberx.value.value.should == '20'
    end

    should 'process constant path assignments' do
      defs = build_definitions('Kernel::FOO = 10')
      foo  = defs.lookup(:constant, 'Kernel').lookup(:constant, 'FOO')

      foo.is_a?(RubyLint::Definition::RubyObject).should == true

      foo.name.should        == 'FOO'
      foo.value.value.should == '10'
    end

    should 'process recursive variable assignments' do
      code = <<-CODE
  a = 1
  b = a
  c = b
  d = c
      CODE

      defs = build_definitions(code)
      var  = defs.lookup(:local_variable, 'd')

      var.value.type.should  == :integer
      var.value.value.should == '1'
    end
  end
end