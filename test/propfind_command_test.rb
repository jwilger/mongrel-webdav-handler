require File.dirname( __FILE__ ) + '/test_helper'
require 'mongrel_webdav_handler'

unit_tests do
  test "should set 404 status if resource does not exist" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propfind, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :prop do
        xml.D :resourcetype
      end
    end
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( nil )
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    assert_equal( { :status => 404 }, cmd.execute )
  end
  
  test "should set 400 status and do nothing if request body contains " +
  "non-well-formed XML" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = '<not></wellformed>'
    resource = stub
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( resource )
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    expected = { :status => 400 }
    assert_equal expected, cmd.execute
  end
  
  test "should set 400 status and do nothing if request body includes an " +
  "empty namespace declaration" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propfind, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :prop do
        xml.D :resourcetype
        xml.t :someprop, 'xmlns:v' => ''
      end
    end
    resource = stub
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( resource )
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    assert_equal( { :status => 400 }, cmd.execute )
  end
  
  test "should set 207 status and return requested properties in a " +
  "multistatus response for the specified collection with a depth of 0" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :depth => 0, :script_name => '/baz' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propfind, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test',
      'xmlns:u' => 'http://example.com/test2' do
      xml.D :prop do
        xml.D :resourcetype
        xml.D :getcontentlength
        xml.t :someprop
        xml.u :emptyprop
        xml.t :forbiddenprop
        xml.t :notfoundprop
      end
    end
    
    collection = stub( :href => 'foo/bar/', :collection? => true )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( collection )
    collection.expects( :get_children ).with( 0 ).returns( [] )
    collection.expects( :get_prop ).with( 'DAV:', 'getcontentlength' ).returns( [ 200, '50' ] )
    collection.expects( :get_prop ).with( 'http://example.com/test', 'someprop' ).returns( [ 200, 'some <value>' ] )
    collection.expects( :get_prop ).with( 'http://example.com/test2', 'emptyprop' ).returns( [ 200, nil ] )
    collection.expects( :get_prop ).with( 'http://example.com/test', 'forbiddenprop' ).returns( [ 403, nil ] )
    collection.expects( :get_prop ).with( 'http://example.com/test', 'notfoundprop' ).returns( [ 404, nil ] )
    
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    
    expected_body = ''
    xml = Builder::XmlMarkup.new( :target => expected_body, :indent => 4 )
    xml.instruct!
    xml.multistatus 'xmlns' => 'DAV:', 'xmlns:a' => 'http://example.com/test',
      'xmlns:b' => 'http://example.com/test2' do
      xml.response do
        xml.href '/baz/foo/bar/'
        xml.propstat do
          xml.prop do
            xml.resourcetype do
              xml.collection
            end
            xml.getcontentlength '50'
            xml.a :someprop, 'some <value>'
            xml.b :emptyprop
          end
          xml.status 'HTTP/1.1 200 OK'
        end
        xml.propstat do
          xml.prop do
            xml.a :forbiddenprop
          end
          xml.status 'HTTP/1.1 403 Forbidden'
        end
        xml.propstat do
          xml.prop do
            xml.a :notfoundprop
          end
          xml.status 'HTTP/1.1 404 Not Found'
        end
      end
    end
    
    result = cmd.execute
    assert_equal 207, result[ :status ]
    assert_equal( { 'Content-Type' => 'text/xml; charset="utf-8"' }, result[ :headers ] )
    assert_equal expected_body, result[ :body ].read
  end
  
  test "should set 207 status and return requested properties in a " +
  "multistatus response for the specified collection and all children with " +
  "a depth of :all" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :depth => :all, :script_name => '/baz' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propfind, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :prop do
        xml.D :resourcetype
        xml.t :someprop
      end
    end
    
    collection = stub( :href => 'foo/bar/', :collection? => true )
    child_a = stub( :href => 'foo/bar/child_a', :collection? => true )
    child_b = stub( :href => 'foo/bar/child_a/child_b', :collection? => false )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( collection )
    collection.expects( :get_children ).with( :all ).returns( [ child_a, child_b ] )
    collection.expects( :get_prop ).with( 'http://example.com/test', 'someprop' ).returns( [ 200, 'some <value>' ] )
    child_a.expects( :get_prop ).with( 'http://example.com/test', 'someprop' ).returns( [ 200, 'some <value> child_a' ] )
    child_b.expects( :get_prop ).with( 'http://example.com/test', 'someprop' ).returns( [ 200, 'some <value> child_b' ] )
    
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    
    expected_body = ''
    xml = Builder::XmlMarkup.new( :target => expected_body, :indent => 4 )
    xml.instruct!
    xml.multistatus 'xmlns' => 'DAV:', 'xmlns:a' => 'http://example.com/test' do
      xml.response do
        xml.href '/baz/foo/bar/'
        xml.propstat do
          xml.prop do
            xml.resourcetype do
              xml.collection
            end
            xml.a :someprop, 'some <value>'
          end
          xml.status 'HTTP/1.1 200 OK'
        end
      end
      xml.response do
        xml.href '/baz/foo/bar/child_a'
        xml.propstat do
          xml.prop do
            xml.resourcetype do
              xml.collection
            end
            xml.a :someprop, 'some <value> child_a'
          end
          xml.status 'HTTP/1.1 200 OK'
        end
      end
      xml.response do
        xml.href '/baz/foo/bar/child_a/child_b'
        xml.propstat do
          xml.prop do
            xml.resourcetype {}
            xml.a :someprop, 'some <value> child_b'
          end
          xml.status 'HTTP/1.1 200 OK'
        end
      end
    end
    
    result = cmd.execute
    assert_equal 207, result[ :status ]
    assert_equal( { 'Content-Type' => 'text/xml; charset="utf-8"' }, result[ :headers ] )
    assert_equal expected_body, result[ :body ].read
  end
  
  test "should set 207 status and return default DAV properties in a " +
  "multistatus response for the specified collection with a depth of 0 and " +
  "an empty request body" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :depth => 0, :script_name => '/baz' }
    req_body = ''
    fixed_time = Time.now
    collection = stub( :href => 'foo/bar', :collection? => false )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( collection )
    collection.expects( :get_children ).with( 0 ).returns( [] )
    collection.expects( :get_prop ).with( 'DAV:', 'creationdate' ).returns( [ 200, fixed_time.xmlschema ] )
    collection.expects( :get_prop ).with( 'DAV:', 'displayname' ).returns( [ 200, 'bar' ] )
    collection.expects( :get_prop ).with( 'DAV:', 'getcontentlength' ).returns( [ 200, 50 ] )
    collection.expects( :get_prop ).with( 'DAV:', 'getcontenttype' ).returns( [ 200, 'text/plain' ] )
    collection.expects( :get_prop ).with( 'DAV:', 'getetag' ).returns( [ 200, 'abc-def-ghi' ] )
    collection.expects( :get_prop ).with( 'DAV:', 'getlastmodified' ).returns( [ 200, fixed_time.httpdate ] )
    
    
    cmd = MongrelWebdavHandler::PropfindCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    
    expected_body = ''
    xml = Builder::XmlMarkup.new( :target => expected_body, :indent => 4 )
    xml.instruct!
    xml.multistatus 'xmlns' => 'DAV:' do
      xml.response do
        xml.href '/baz/foo/bar'
        xml.propstat do
          xml.prop do
            xml.resourcetype {}
            xml.creationdate fixed_time.xmlschema
            xml.displayname 'bar'
            xml.getcontentlength 50
            xml.getcontenttype 'text/plain'
            xml.getetag 'abc-def-ghi'
            xml.getlastmodified fixed_time.httpdate
          end
          xml.status 'HTTP/1.1 200 OK'
        end
      end
    end
    
    result = cmd.execute
    assert_equal 207, result[ :status ]
    assert_equal( { 'Content-Type' => 'text/xml; charset="utf-8"' }, result[ :headers ] )
    assert_equal expected_body, result[ :body ].read
  end
end