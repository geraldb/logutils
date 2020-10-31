# encoding: utf-8

###
#  to run use
#     ruby -I ./lib -I ./test test/test_version.rb


require 'helper'

class TestVersion < MiniTest::Test

  def test_version
    pp DateFormats::VERSION
    pp DateFormats.banner
    pp DateFormats.root
  end

end # class TestVersion
