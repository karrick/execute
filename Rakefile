# -*- mode: ruby; compile-command: "cd ~/Development/execute && send pri=cs && echo 'cd /tmp/karrick/execute && rake test' | ssh -Tq pri ssh -Tq cs"; -*-

GEM_NAME = File.basename(File.dirname(__FILE__))

require 'fileutils'
require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

task :default => [:test, :clean, :rdoc, :set_sane_file_permissions, :package]

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = GEM_NAME
  s.version           = "0.0.9"
  s.summary           = "Execute shell commands on remote hosts"
  s.author            = "Karrick S. McDermott"
  s.email             = "karrick@karrick.net"
  s.homepage          = "http://karrick.net"

  s.has_rdoc          = true
  # You should probably have a README of some kind. Change the filename
  # as appropriate
  # s.extra_rdoc_files  = %w(README)
  # s.rdoc_options      = %w(--main README)

  # Add any extra files to include in the gem (like your README)
  s.files             = %w(Rakefile README) + Dir.glob("{test,lib/**/*}")
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  s.add_dependency("SystemTimer", "~> 1.1.3")
  s.add_dependency("open4", "~> 1.0.1")

  # If your tests use any gems, include them here
  s.add_development_dependency("mocha") # for example
  s.add_development_dependency("flexmock/test_unit") # for example

  # If you want to publish automatically to rubyforge, you'll may need
  # to tweak this, and the publishing task below too.
  s.rubyforge_project = GEM_NAME
end

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec

  # Generate the gemspec file for github.
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end

# If you want to publish to RubyForge automatically, here's a simple
# task to help do that. If you don't, just get rid of this.
# Be sure to set up your Rubyforge account details with the Rubyforge
# gem; you'll need to run `rubyforge setup` and `rubyforge config` at
# the very least.
begin
  require "rake/contrib/sshpublisher"
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Release a new version of this gem"
      task :gem => [:package] do
        require 'rubyforge'
        rubyforge = RubyForge.new
        rubyforge.configure
        rubyforge.login
        rubyforge.userconfig['release_notes'] = spec.summary
        path_to_gem = File.join(File.dirname(__FILE__), "pkg", "#{spec.name}-#{spec.version}.gem")
        puts "Publishing #{spec.name}-#{spec.version.to_s} to Rubyforge..."
        rubyforge.add_release(spec.rubyforge_project, spec.name, spec.version.to_s, path_to_gem)
      end

      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
                           File.read(File.expand_path('~/.rubyforge/user-config.yml'))
                           )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/execute/" # Should be the same as the rubyforge project name
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end

#
# Sets sane file and directory permissions prior to packaging
# (necessary when developer's umask is restrictive)
task :set_sane_file_permissions do
  bin = File.join(File.dirname(__FILE__),'bin')
  system(%Q[find '#{File.dirname(__FILE__)}' -type d -print0 | xargs -0 -I % chmod 755 '%'])
  system(%Q[find '#{File.dirname(__FILE__)}' -type f -print0 | xargs -0 -I % chmod 644 '%'])
  system(%Q[find '#{bin}' -type f -print0 | xargs -0 -I % chmod 755 '%']) if File.directory?(bin)
end

desc "uninstall a gem"
task :uninstall do
  if $remove_all_versions
    system("gem list '#{spec.name}' -i >/dev/null && gem uninstall -a -I -x '#{spec.name}'")
  else
    system("gem list '#{spec.name}' -i >/dev/null && gem uninstall -v #{spec.version} -I -x '#{spec.name}'")
  end
  remove_gemspec
end

desc "install a gem"
task :install do
  pkg = Dir.glob(File.join(File.dirname(__FILE__), "pkg", "*.gem"))
  system("gem install -l '#{pkg}'")
  remove_gemspec
end

desc "uninstall and re-install a gem"
task :reinstall => [:uninstall, :install]

def remove_gemspec
  gemspec = File.join(File.dirname(__FILE__), "#{GEM_NAME}.gemspec")
  FileUtils.rm(gemspec) if File.file?(gemspec)
end
