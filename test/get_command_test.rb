require File.dirname( __FILE__ ) + '/test_helper'
require 'pluggable_mongrel_webdav_handler'

unit_tests do
  test "should send contents of specified file with 200 status and set " +
  "content type header" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar.txt' }
    req_body = ''
    file = stub( :content => 'some content' )
    file.expects( :get_prop ).with( 'DAV:', 'getcontenttype' ).returns( [ 200, 'text/plain' ] )
    root_collection.expects( :find_by_href ).with( 'foo/bar.txt' ).returns( file )
    cmd = PluggableMongrelWebdavHandler::GetCommand.new( root_collection, user, params, req_body )
    expected = { :status => 200, :headers => { 'Content-Type' => 'text/plain' }, :body => 'some content' }
    assert_equal expected, cmd.execute
  end
  
  test "should respond with 404 if specified resource does not exist" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar.txt' }
    req_body = ''
    root_collection.expects( :find_by_href ).with( 'foo/bar.txt' ).returns( nil )
    cmd = PluggableMongrelWebdavHandler::GetCommand.new( root_collection, user, params, req_body )
    expected = { :status => 404 }
    assert_equal expected, cmd.execute
  end
  
  test "should not return resource body if this is a HEAD request" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar.txt', :request_method => :head }
    req_body = ''
    file = stub( :content_type => 'text/plain' )
    file.expects( :get_prop ).with( 'DAV:', 'getcontenttype' ).returns( [ 200, 'text/plain' ] )
    root_collection.expects( :find_by_href ).with( 'foo/bar.txt' ).returns( file )
    cmd = PluggableMongrelWebdavHandler::GetCommand.new( root_collection, user, params, req_body )
    expected = { :status => 200, :headers => { 'Content-Type' => 'text/plain' }, :body => nil }
    assert_equal expected, cmd.execute
  end
end