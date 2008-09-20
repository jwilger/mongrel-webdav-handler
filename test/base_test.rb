require File.dirname( __FILE__ ) + '/test_helper'
require 'mongrel_webdav_handler'

unit_tests do
  methods = %w( OPTIONS HEAD GET PUT DELETE PROPFIND PROPPATCH MKCOL LOCK UNLOCK MOVE COPY FAKE )
  methods.each do |request_method|
    request_method_sym = request_method.downcase.to_sym
    command_class = case request_method_sym
      when :options then MongrelWebdavHandler::OptionsCommand
      when :head, :get then MongrelWebdavHandler::GetCommand
      when :put then MongrelWebdavHandler::PutCommand
      when :delete then MongrelWebdavHandler::DeleteCommand
      when :propfind then MongrelWebdavHandler::PropfindCommand
      when :proppatch then MongrelWebdavHandler::ProppatchCommand
      when :mkcol then MongrelWebdavHandler::MkcolCommand
      when :lock then MongrelWebdavHandler::LockCommand
      when :unlock then MongrelWebdavHandler::UnlockCommand
      when :copy then MongrelWebdavHandler::CopyCommand
      when :move then MongrelWebdavHandler::MoveCommand
      when :fake then MongrelWebdavHandler::Command
    end
    test "should respond to #{request_method} request using the appropriate command" do
      handler_class = Class.new( MongrelWebdavHandler::Base )
      root_collection = stub
      user = stub
      handler_class.load_root_collection { root_collection }
      handler_class.authenticate { |auth_header| user if auth_header == 'abc' }
      req_body = stub
      req_params = { 'REQUEST_METHOD' => request_method,
        'HTTP_AUTHORIZATION' => 'abc', 'PATH_INFO' => '/foo/bar',
        'SCRIPT_NAME' => '/baz', 'FRAGMENT' => 'ham',
        'HTTP_DESTINATION' => 'http://localhost:3000/baz/foo/baz/' ,
        'HTTP_HOST' => 'localhost:3000' }
      request = stub( :params => req_params,
        :body => req_body )
      command = mock
      expected_command_params = {
        :script_name => '/baz',
        :request_method => request_method_sym,
        :resource_href => 'foo/bar',
        :overwrite => false,
        :depth => 0,
        :authorization => 'abc',
        :destination_href => 'foo/baz',
        :fragment => 'ham'
      }
      command_class.expects( :new ).
        with( root_collection, user, expected_command_params, req_body ).
        returns( command )
      result = { :status => 200, :headers => { 'Allow' => 'GET,PUT' } }
      command.expects( :execute ).returns( result )
      response = mock
      response_head = mock
      response_body = mock
      response.expects( :start ).with( 200 ).yields( response_head, response_body )
      response_head.expects( :[]= ).with( 'DAV', '1,2' )
      response_head.expects( :[]= ).with( 'MS-Author-Via', 'DAV' )
      response_head.expects( :[]= ).with( 'Allow', 'GET,PUT' )
      response_body.expects( :write ).never
      handler = handler_class.new
      handler.process( request, response )
    end
  end
  
  test "should respond with 401 status if user is not authenticated" do
    handler_class = Class.new( MongrelWebdavHandler::Base )
    root_collection = stub
    handler_class.load_root_collection { root_collection }
    handler_class.authenticate { |auth_header| nil }
    handler_class.set_www_authenticate_header 'Basic(realm="nuts")'
    req_params = { 'REQUEST_METHOD' => 'GET',
      'HTTP_AUTHORIZATION' => 'abc', 'PATH_INFO' => '/foo/bar',
      'SCRIPT_NAME' => '/baz' }
    request = stub( :params => req_params,
      :body => StringIO.new( 'request text' ) )
    response = mock
    response_head = mock
    response_body = mock
    response.expects( :start ).with( 401 ).yields( response_head, response_body )
    response_head.expects( :[]= ).with( 'WWW-Authenticate', 'Basic(realm="nuts")' )
    response_body.expects( :write ).never
    handler = handler_class.new
    handler.process( request, response )
  end
  
  test "should not respond with 401 status if user is not authenticated but " +
  "it's an OPTIONS request (for MS clients)" do
    handler_class = Class.new( MongrelWebdavHandler::Base )
    root_collection = stub
    handler_class.load_root_collection { root_collection }
    handler_class.authenticate { |auth_header| nil }
    handler_class.set_www_authenticate_header 'Basic(realm="nuts")'
    req_body = stub
    req_params = { 'REQUEST_METHOD' => 'OPTIONS',
      'HTTP_AUTHORIZATION' => 'abc', 'PATH_INFO' => '/foo/bar',
      'SCRIPT_NAME' => '/baz' }
    request = stub( :params => req_params, :body => req_body )
    command = mock
    expected_command_params = {
      :script_name => '/baz',
      :request_method => :options,
      :resource_href => 'foo/bar',
      :overwrite => false,
      :depth => 0,
      :authorization => 'abc',
      :destination_href => nil,
      :fragment => nil
    }
    MongrelWebdavHandler::OptionsCommand.expects( :new ).
      with( root_collection, :anonymous_options_request_allowed,
        expected_command_params, req_body ).
      returns( command )
    result = { :status => 200, :headers => { 'Allow' => 'GET,PUT' } }
    command.expects( :execute ).returns( result )
    response = mock
    response_head = mock
    response_body = mock
    response.expects( :start ).with( 200 ).yields( response_head, response_body )
    response_head.expects( :[]= ).with( 'DAV', '1,2' )
    response_head.expects( :[]= ).with( 'MS-Author-Via', 'DAV' )
    response_head.expects( :[]= ).with( 'Allow', 'GET,PUT' )
    response_body.expects( :write ).never
    handler = handler_class.new
    handler.process( request, response )
  end
end