require 'rubygems'
require 'open4'

module Execute

  USE_SUDO_SU = false

  ########################################
  # PURPOSE:  Execute a command
  # INPUT:    Shell command; Hash of options
  #             :host => Host upon which this command should be invoked
  #             :stdin => Array or String to be piped to command's standard input
  #             :user => user name to become to execute the command
  # OUTPUT:   Hash with keys {:status, :stdout, :stderr}
  # NOTE:     Open4.spawn has great error handling, however, if process exit status
  #           does not match given set, you loose your stdout and stderr.
  #           This is poor for logging purposes.
  # NOTE:     This method uses Open4.spawn but tells it to not raise
  #           an Open4::SpawnError for any reason.  It simply returns the
  #           :status, :stdout, and :stderr in a Hash.
  #           In other words, use this when you desire to perform your own error handling.
  def Execute.run (cmd, options={})
    raise ArgumentError.new("cmd must be a String") unless cmd.kind_of?(String)
    raise ArgumentError.new("options must be a Hash") unless options.kind_of?(Hash)
    raise ArgumentError.new("invalid option key") unless options.keys.all? {|x| [:host, :stdin, :user].include?(x)}

    # if user specified then modify command to execute as a different user;
    # must have sudo permissions to do this
    cmd = Execute.change_user(cmd, options.delete(:user))

    # if host specified then modify command to execute on a different host;
    # must have ssh keys prepared to do this
    cmd = Execute.change_host(cmd, options.delete(:host))

    # Prepare standard IO
    stdout, stderr = '',''
    stdin = options.delete(:stdin)

    # delegate command to Open4::spawn method
    result = Open4.spawn(cmd, options.merge({0=>stdin, 1=>stdout, 2=>stderr, :status => true}))
    {:status => result.exitstatus, :stdout => stdout, :stderr => stderr}
  end

  ########################################
  # PURPOSE:  Execute a command; raise RuntimeError with specific message if exit status is not 0
  # INPUT:    Shell command; Hash of options
  #             :emsg => Error message to use
  #             :host => Host upon which this command should be invoked
  #             :status => true | Fixnum | Array of Fixnum
  #             :stdin => Array or String to be piped to command's standard input
  #             :user => user name to become to execute the command
  # OUTPUT:   Hash with keys {:status, :stdout, :stderr}
  # NOTE:     Use this when you want it to raise an exception when the program return
  #           status code does not match one of the ones you specifically
  #           approve (or 0 if not specified).  Your program will not get the Hash in this case.
  def Execute.run! (cmd, options={})
    raise ArgumentError.new("options must be a Hash") unless options.kind_of?(Hash)
    raise ArgumentError.new("invalid option key") unless options.keys.all? {|x| [:host, :stdin, :emsg, :status, :user].include?(x)}

    # prepare exit status handling
    valid_exit_values = options.delete(:status) || Array(0)
    unless valid_exit_values == true or valid_exit_values.kind_of?(Array)
      valid_exit_values = Array(valid_exit_values)
    end

    error_message = options.delete(:emsg) || cmd # populate error message with command string if not defined

    result = Execute.run(cmd, options)

    # check return status code
    exitstatus = result[:status]
    unless valid_exit_values == true or valid_exit_values.include?(exitstatus)
      raise RuntimeError.new("#{error_message}#{$/}#{result[:stderr]}#{$/}")
    end
    result
  end

  ################
  def Execute.change_user (cmd, user)
    case user
    when nil, ""
      cmd
    else
      if USE_SUDO_SU
        %Q[sudo su -lc "#{cmd}" #{user}]
      else
        %Q[sudo -u #{user} -H "#{cmd}"]
      end
    end
  end

  ########################################
  def Execute.change_host (cmd, host)
    case host
    when nil, "", "localhost"
      cmd
    else
      ssh_opts = "-Tq -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=2"
      #
      # NOTE:  It is very important to escape backslash character ('\') before
      #        escaping either the double quotes or the dollar sign
      #
      %Q[ssh #{ssh_opts} #{host} "#{cmd.gsub(/\\/,%q[\\\\\\]).gsub(/\"/, %q[\"]).gsub(/\$/, %q[\$])}"]
    end
  end
end
