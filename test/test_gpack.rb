require 'minitest/autorun'
require 'gpack'

class GpackTest < Minitest::Test
   def test_install
      Dir.chdir("./testdir")
      gpack(["uninstall"])
      gpack(["install"])
   end
end
