require File.dirname( __FILE__ ) + '/test_helper'
require 'pluggable_mongrel_webdav_handler'

unit_tests do
  test "should move specified resource to destination, return status of 201 " +
  "and set location header to href of new resource" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :destination_href => 'foo/baz' }
    req_body = ''
    parent = stub
    new_resource = stub( :href => 'foo/baz' )
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( parent )
    root_collection.expects( :find_by_href ).with( 'foo/baz' ).returns( nil )
    root_collection.expects( :move ).with( 'foo/bar', 'foo/baz' ).returns( new_resource )
    cmd = PluggableMongrelWebdavHandler::MoveCommand.new( root_collection, user, params, req_body )
    expected = { :status => 201, :headers => { 'Location' => 'foo/baz' } }
    assert_equal expected, cmd.execute
  end
  
  test "move to an existing destination with overwrite header set to false " +
  "should return a 412 status and do nothing" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :destination_href => 'foo/baz', :overwrite => false }
    req_body = ''
    parent = stub
    existing_dest = stub
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( parent )
    root_collection.expects( :find_by_href ).with( 'foo/baz' ).returns( existing_dest )
    cmd = PluggableMongrelWebdavHandler::MoveCommand.new( root_collection, user, params, req_body )
    expected = { :status => 412 }
    assert_equal expected, cmd.execute
  end
  
  test "move to an existing destination with overwrite header set to true " +
  "should return a 204 status code and perform the copy" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :destination_href => 'foo/baz', :overwrite => true }
    req_body = ''
    parent = stub
    existing_dest = stub
    new_resource = stub( :href => 'foo/baz' )
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( parent )
    root_collection.expects( :find_by_href ) .with( 'foo/baz' ).returns( existing_dest )
    root_collection.expects( :move ).with( 'foo/bar', 'foo/baz' ).returns( new_resource )
    cmd = PluggableMongrelWebdavHandler::MoveCommand.new( root_collection, user, params, req_body )
    expected = { :status => 204 }
    assert_equal expected, cmd.execute
  end
  
  test "move to a collection that doesn't exist should return a 409 status" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :destination_href => 'bar/baz', :overwrite => false }
    req_body = ''
    root_collection.expects( :find_by_href ).with( 'bar' ).returns( nil )
    cmd = PluggableMongrelWebdavHandler::MoveCommand.new( root_collection, user, params, req_body )
    expected = { :status => 409 }
    assert_equal expected, cmd.execute
  end
end