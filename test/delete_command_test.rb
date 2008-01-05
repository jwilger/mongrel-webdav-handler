require File.dirname( __FILE__ ) + '/test_helper'
require 'pluggable_mongrel_webdav_handler'

unit_tests do
  test "should set return status of 404 and do nothing if specified " +
  "resource does not exist" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    cmd = PluggableMongrelWebdavHandler::DeleteCommand.new( root_collection, user, params, req_body )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( nil )
    expected = { :status => 404 }
    assert_equal expected, cmd.execute
  end
  
  test "should delete the specified resource and set a 204 status" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    resource = mock
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( resource )
    resource.expects( :delete )
    cmd = PluggableMongrelWebdavHandler::DeleteCommand.new( root_collection, user, params, req_body )
    expected = { :status => 204 }
    assert_equal expected, cmd.execute
  end
  
  test "should set status to 405 and do nothing if fragment is not nil" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :fragment => 'baz' }
    req_body = ''
    cmd = PluggableMongrelWebdavHandler::DeleteCommand.new( root_collection, user, params, req_body )
    expected = { :status => 405 }
    assert_equal expected, cmd.execute
  end
end