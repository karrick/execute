# -*- mode: ruby; compile-command: "rake test"; -*-

require 'test/unit'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

class Test::Unit::TestCase

  FIXTURES_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

  ################
  # HELPER FUNCTIONS
  ################

  def array_hash_test (array_of_hashes)
    # given Array of Hashes, each possessing :in and :exp key/value pairs,
    # yield value of :in to called, and assert that result matches :exp value
    array_of_hashes.each do |e|
      assert_equal(e[:exp], yield(e[:in]), "CASE: #{e[:in].inspect}")
    end
  end

  def using (*filenames)
    raise "filenames = #{filenames.inspect}" unless filenames.kind_of?(Array)
    filenames.flatten!

    pwd = Dir.pwd
    filenames.each do |x|
      fixture = File.join(FIXTURES_DIR, File.basename(x))
      FileUtils.cp(fixture, pwd)
    end
  end
end
