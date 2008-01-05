$:.unshift( File.expand_path( File.dirname( __FILE__ ) + '/../lib' ) )
$:.unshift( File.expand_path( File.dirname( __FILE__ ) + '/../vendor/mocha/lib' ) )
$:.unshift( File.expand_path( File.dirname( __FILE__ ) + '/../vendor/dust/lib' ) )
require 'test/unit'
require 'mocha'
require 'dust'

class Test::Unit::TestCase
  disallow_setup!
end