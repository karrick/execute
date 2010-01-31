require File.join(File.dirname(__FILE__), "test_helpers.rb")
require 'execute'

class TestExecute < Test::Unit::TestCase
  def test_raise_argument_error_if_cmd_not_string
    assert_raise(ArgumentError) do
      Execute.run({})
    end
  end

  def test_raise_argument_error_if_options_not_hash
    assert_raise(ArgumentError) do
      Execute.run('pwd', 'ls')
    end
  end

  def test_raise_argument_error_if_invalid_option_key
    assert_raise(ArgumentError) do
      Execute.run('pwd', :bogus => 'BOGUS')
    end

    assert_raise(ArgumentError) do
      Execute.run!('pwd', :bogus => 'BOGUS')
    end
  end

  def test_validation_for_status_and_emsg_keys
    assert_nothing_raised do
      Execute.run!('true', :emsg => "false", :status => true)
    end

    assert_raise(ArgumentError) do
      Execute.run('true', :status => true)
    end

    assert_raise(ArgumentError) do
      Execute.run('true', :emsg => "true should not raise an error")
    end
  end

  def test_should_not_raise_exception
    assert_nothing_raised do
      Execute.run('false')
    end
  end

  def test_should_raise_exception
    assert_raise(RuntimeError) do
      Execute.run!('false')
    end
  end

  def test_returns_hash_with_required_keys
    result = Execute.run('pwd')
    assert_kind_of(Hash, result)
    [:stdout, :stderr, :status].each {|x| result.has_key?(x)}
  end

  def test_shows_pwd
    assert_equal(Dir.pwd, Execute.run('pwd')[:stdout].strip)
  end

  def test_standard_input_used
    input = ['line 1', 'line 2'].join($/)
    assert_equal(input, Execute.run('cat -', :stdin => input)[:stdout])
  end

end
