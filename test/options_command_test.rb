require File.dirname( __FILE__ ) + '/test_helper'
require 'pluggable_mongrel_webdav_handler'

unit_tests do
  test "should return allow header specifying which methods the specified " +
  "resource supports" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    cmd = PluggableMongrelWebdavHandler::OptionsCommand.new( root_collection, user, params, req_body )
    expected = { :status => 200,
      :headers => { 'Allow' => 'OPTIONS,GET,HEAD,PUT,DELETE,COPY,MOVE,MKCOL,PROPFIND,PROPPATCH,LOCK,UNLOCK' } }
    assert_equal expected, cmd.execute
  end
end