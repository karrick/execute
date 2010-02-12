# -*- compile-command: "rake test"; -*-

require File.join(File.dirname(__FILE__), "test_helpers.rb")
require 'execute'

class TestExecute < Test::Unit::TestCase

  REMOTE_HOSTS = %w[soma]
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
    @remote_user = 'e3'
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

  ################
  # HELPER METHOD -- CHANGE HOST
  ################

  def test_change_host_nil
    assert_equal(TEST_CMD, Execute.change_host(TEST_CMD, nil), "should not modify command if host is nil")
  end

  def test_change_host_empty
    assert_equal(TEST_CMD, Execute.change_host(TEST_CMD, ""), "should not modify command if host is empty string")
  end

  def test_change_host_normal
    host = @remote_test_host
    result = Execute.change_host(TEST_CMD, host)
    [/ssh -Tq/, /-o PasswordAuthentication=no/,
     /-o StrictHostKeyChecking=no/, /-o ConnectTimeout=2/,
     Regexp.new("#{host}"), Regexp.new(%Q["#{TEST_CMD}"])].each do |re|
      assert_match(re, result, "failed to change host")
    end
  end

  ################
  # HELPER METHOD -- CHANGE USER
  ################

  def test_change_user_nil
    assert_equal(TEST_CMD, Execute.change_user(TEST_CMD, nil), "should not modify command if user is nil")
  end

  def test_change_user_empty
    assert_equal(TEST_CMD, Execute.change_user(TEST_CMD, ""), "should not modify command if user is empty string")
  end

  ################
  # BEHAVIOR TESTS -- CHANGE HOST AND / OR USER
  ################

  def test_change_user_sets_user
    host = @remote_test_host ; user = @remote_user
    assert_equal(user, Execute.run!('whoami', :host => host, :user => user)[:stdout].strip,
                 "failed to change user")
  end

  def test_change_user_sets_home_directory
    host = @remote_test_host ; user = @remote_user
    assert_equal("/home/#{user}", Execute.run!('pwd', :host => host, :user => user)[:stdout].strip,
                 "failed to set user's home directory")
  end

  def test_change_user_sets_home_env
    host = @remote_test_host ; user = @remote_user
    assert_equal("/home/#{user}", Execute.run!('echo $HOME', :host => host, :user => user)[:stdout].strip,
                 "failed to set user's HOME")
  end

  def test_change_host_actually_changes_host
    host = @remote_test_host ; user = @remote_user
    assert_match(%r/#{host}/, Execute.run!('hostname', :host => host)[:stdout].strip,
                 "failed to change host")
  end

  def test_change_host_and_user_actually_changes_host
    host = @remote_test_host ; user = @remote_user
    assert_match(%r/#{host}/, Execute.run!('hostname', :host => host, :user => user)[:stdout].strip,
                 "failed to change host")
  end
end
