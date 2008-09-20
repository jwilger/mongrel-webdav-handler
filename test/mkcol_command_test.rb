require File.dirname( __FILE__ ) + '/test_helper'
require 'mongrel_webdav_handler'

unit_tests do
  test "should create specified collection" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    parent = mock
    new_collection = stub( :href => 'foo/bar' )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( nil )
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( parent )
    parent.expects( :make_collection ).with( 'bar' ).returns( new_collection )
    cmd = MongrelWebdavHandler::MkcolCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    expected = { :status => 201, :headers => { 'Location' => 'foo/bar' } }
    assert_equal expected, cmd.execute
  end
  
  test "should set 405 status if resource href points to an existing resource" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    existing = stub
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( existing )
    cmd = MongrelWebdavHandler::MkcolCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    expected = { :status => 405 }
    assert_equal expected, cmd.execute
  end
  
  test "should set 409 status if parent collection is missing" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( nil )
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( nil )
    cmd = MongrelWebdavHandler::MkcolCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    expected = { :status => 409 }
    assert_equal expected, cmd.execute
  end
  
  test "should set 415 status if request body is not blank" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = 'not blank'
    cmd = MongrelWebdavHandler::MkcolCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    expected = { :status => 415 }
    assert_equal expected, cmd.execute
  end
end