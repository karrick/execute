# -*- compile-command: "rake test"; -*-

require File.join(File.dirname(__FILE__), "test_helpers.rb")
require 'execute'

class TestExecute < Test::Unit::TestCase

  REMOTE_HOSTS = %w[]
  TEST_CMD = "ls -hlF"

  def setup
    # find a remote host we can use for test logins
    REMOTE_HOSTS.each do |host|
      begin
        Execute.run!('echo', :host => host)
        @remote_test_host = host
        break
      rescue
        retry                   # with next host in list
      end
    end
  end

  ################
  # STATUS CODE ERROR TESTS
  ################

  def test_run_nothing_raised_if_false
    assert_nothing_raised(RuntimeError) { Execute.run('false') }
  end

  def test_run_non_zero_status_if_false
    assert_not_equal(0, Execute.run('false')[:status], "failed to set the status flag after failure")
  end

  def test_raise_if_run_bang_false
    assert_raise(RuntimeError) { Execute.run!('false') }
  end

  def test_true_status_prevents_raise
    assert_nothing_raised { Execute.run!('false', :status => true) }
  end

  ################
  # ARGUMENT VALIDATION TESTS
  ################

  def test_raise_argument_error_if_cmd_not_string
    assert_raise(ArgumentError) { Execute.run(nil) }
    assert_raise(ArgumentError) { Execute.run({}) }
  end

  def test_raise_argument_error_if_options_not_hash
    assert_raise(ArgumentError) { Execute.run('pwd', 'ls') }
  end

  def test_raise_argument_error_if_invalid_option_key
    assert_raise(ArgumentError) { Execute.run('pwd', :bogus => 'BOGUS') }
  end

  ################
  # STANDARD INPUT
  ################

  def test_standard_input_used
    input = ['line 1', 'line 2'].join($/)
    assert_equal(input, Execute.run('cat -', :stdin => input)[:stdout])
  end

  ################
  # RETURN VALUES
  ################

  def test_returns_hash_with_required_keys
    result = Execute.run('pwd')
    assert_kind_of(Hash, result)
    [:stdout, :stderr, :status].each {|x| result.has_key?(x)}
  end

  def test_shows_pwd
    assert_equal(Dir.pwd, Execute.run('pwd')[:stdout].strip)
  end

  def test_remote_host_return_value
    if @remote_test_host.nil?
      $stderr.puts("\ncould not find a remote host to test; skipping remote host tests.")
    else
      assert_match(Regexp.new("#{@remote_test_host}"),
                   Execute.run('hostname', :host => @remote_test_host))
    end
  end

  ################
  # HELPER METHODS
  ################

  def test_change_host_nil
    assert_equal(TEST_CMD, Execute.change_host(TEST_CMD, nil), "should not modify command if host is nil")
  end

  def test_change_host_empty
    assert_equal(TEST_CMD, Execute.change_host(TEST_CMD, ""), "should not modify command if host is empty string")
  end

  def test_change_host_normal
    host = "bogus"
    result = Execute.change_host(TEST_CMD, host)
    [/^ssh -Tq/, /-o PasswordAuthentication=no/,
     /-o StrictHostKeyChecking=no/, /-o ConnectTimeout=2/,
     Regexp.new("#{host}"), Regexp.new(%Q["#{TEST_CMD}"])].each do |re|
      assert_match(re, result, "failed to change host")
    end
  end

  def test_change_user_nil
    assert_equal(TEST_CMD, Execute.change_user(TEST_CMD, nil), "should not modify command if user is nil")
  end

  def test_change_user_empty
    assert_equal(TEST_CMD, Execute.change_user(TEST_CMD, ""), "should not modify command if user is empty string")
  end

  def test_change_user_normal
    user = "bogus"
    re = Regexp.new(%Q/^sudo su -lc "([^"]*)" #{user}$/)
    assert_match(re, Execute.change_user(TEST_CMD, user), "failed to change user")
  end
end
