require File.dirname( __FILE__ ) + '/test_helper'
require 'mongrel_webdav_handler'

unit_tests do
  test "should create specified file and set 201 status and location header" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar.txt' }
    req_body = 'this is some text'
    collection = mock
    new_file = stub( :href => 'foo/bar.txt' )
    cmd = MongrelWebdavHandler::PutCommand.new( root_collection, user, params, req_body )
    root_collection.expects( :find_by_href ).with( 'foo' ).returns( collection )
    collection.expects( :put ).with( 'bar.txt', req_body ).returns( new_file )
    expected = { :status => 201, :headers => { 'Location' => 'foo/bar.txt' } }
    assert_equal expected, cmd.execute
  end
end