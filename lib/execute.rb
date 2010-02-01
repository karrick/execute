require 'rubygems'
require 'open4'

module Execute
  extend self

  ########################################
  # PURPOSE:  Execute a command
  # INPUT:    Shell command; Hash of options
  #             :host => Host upon which this command should be invoked
  #             :stdin => Array or String to be piped to command's standard input
  # OUTPUT:   Hash with keys {:status, :stdout, :stderr}
  # NOTE:     Open4::spawn has great error handling, however, if process exit status
  #           does not match given set, you loose your stdout and stderr.
  #           This is poor for logging purposes.
  # NOTE:     This method uses Open4::spawn but tells it to not raise
  #           an Open4::SpawnError for any reason.  It simply returns the
  #           :status, :stdout, and :stderr in a Hash.
  def run (cmd, options={})
    raise ArgumentError.new("cmd must be a String") unless cmd.kind_of?(String)
    raise ArgumentError.new("options must be a Hash") unless options.kind_of?(Hash)
    raise ArgumentError.new("invalid option key") unless options.keys.all? {|x| [:host, :stdin].include?(x)}

    # execute via ssh if not this computer
    unless options[:host].nil? or options[:host].empty? or options[:host] == 'localhost'
      cmd = convert_to_ssh_command(cmd, options[:host])
    end

    # Prepare standard IO
    stdout, stderr = '',''
    stdin = options[:stdin]

    # delegate command to Open4::spawn method
    result = Open4::spawn(cmd, options.merge({0=>stdin, 1=>stdout, 2=>stderr, :status => true}))
    {:status => result.exitstatus, :stdout => stdout, :stderr => stderr}
  end

  ########################################
  # PURPOSE:  Execute a command; raise RuntimeError with specific message if exit status is not 0
  # INPUT:    Shell command; Hash of options
  #             :emsg => Error message to use
  #             :host => Host upon which this command should be invoked
  #             :status => true | Fixnum | Array of Fixnum
  #             :stdin => Array or String to be piped to command's standard input
  # OUTPUT:   Hash with keys {:status, :stdout, :stderr}
  def run! (cmd, options={})
    raise ArgumentError.new("cmd must be a String") unless cmd.kind_of?(String)
    raise ArgumentError.new("options must be a Hash") unless options.kind_of?(Hash)
    raise ArgumentError.new("invalid option key") unless options.keys.all? {|x| [:host, :stdin, :emsg, :status].include?(x)}

    # prepare exit status handling
    valid_exit_values = options.delete(:status) || Array(0)
    unless valid_exit_values == true or valid_exit_values.kind_of?(Array)
      valid_exit_values = Array(valid_exit_values)
    end

    error_message = options.delete(:emsg) || cmd # populate error message with command string if not defined

    # delegate command to execute method
    result = run(cmd, options)

    # check return status code
    exitstatus = result[:status]
    unless valid_exit_values == true or valid_exit_values.include?(exitstatus)
      raise RuntimeError.new("#{error_message}#{$/}#{result[:stderr]}#{$/}")
    end
    result
  end

  ################
  private
  ################

  ########################################
  # PURPOSE:  Convert a shell command to a new command to invoke original command on a remote host
  # INPUT:    Command string
  # OUTPUT:   Escaped command string, prefixed with ssh invocation
  def convert_to_ssh_command (cmd, host)
    raise ArgumentError.new("Expected cmd to be a non-empty String") unless cmd.to_s.length != 0
    raise ArgumentError.new("Expected host to be a non-empty String") unless host.to_s.length != 0

    ssh_opts = "-Tq -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=2"

    #
    # NOTE:  It is very important to escape backslash character ('\') before
    #        escaping either the double quotes or the dollar sign
    #
    %Q[ssh #{ssh_opts} #{host} "#{cmd.gsub(/\\/,%q[\\\\\\]).gsub(/\"/, %q[\"]).gsub(/\$/, %q[\$])}"]
  end
end
