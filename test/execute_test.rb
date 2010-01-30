require File.join(File.dirname(__FILE__), "test_helpers.rb")
require 'execute'

class TestExecute < Test::Unit::TestCase
  def test_shows_pwd
    assert_equal(Dir.pwd, Execute.shell('pwd')[:stdout].strip)
  end

  def test_standard_input_used
    input = ['line 1', 'line 2'].join($/)
    assert_equal(input, Execute.shell('cat -', :stdin => input)[:stdout])
  end

  def test_raise_exception_if_wrong_args
    assert_raise(ArgumentError) do
      Execute.shell(nil)
    end

    assert_raise(ArgumentError) do
      Execute.shell({})
    end
  end
end
