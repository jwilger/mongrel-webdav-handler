require File.dirname( __FILE__ ) + '/test_helper'
require 'pluggable_mongrel_webdav_handler'

class CallRecordingProxy < Builder::BlankSlate
  def initialize( obj )
    @obj = obj
    @calls = []
  end
  
  def method_missing( meth, *args )
    @calls << { :method => meth, :args => args }
    @obj.send( meth, *args )
  end
  
  def __calls__
    @calls
  end
end

unit_tests do
  test "should set specified properties on resource and return appropriate " +
  "multistatus response" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :script_name => '/baz' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propertyupdate, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :set do
        xml.D :prop do
          xml.t :foo, 'some foo text'
          xml.bar 'some bar text', 'xmlns' => 'http://example.com/test2'
        end
      end
    end
    
    resource = stub( :href => 'foo/bar/', :collection? => true )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( resource )
    resource.expects( :set_prop ).with( 'http://example.com/test', 'foo', 'some foo text' ).returns( 200 )
    resource.expects( :set_prop ).with( 'http://example.com/test2', 'bar', 'some bar text' ).returns( 201 )
    
    cmd = PluggableMongrelWebdavHandler::ProppatchCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    
    expected_body = ''
    xml = Builder::XmlMarkup.new( :target => expected_body, :indent => 4 )
    xml.instruct!
    xml.multistatus 'xmlns' => 'DAV:', 'xmlns:a' => 'http://example.com/test',
      'xmlns:b' => 'http://example.com/test2' do
      xml.response do
        xml.href '/baz/foo/bar/'
        xml.propstat do
          xml.prop do
            xml.a :foo
          end
          xml.status 'HTTP/1.1 200 OK'
        end
        xml.propstat do
          xml.prop do
            xml.b :bar
          end
          xml.status 'HTTP/1.1 201 Created'
        end
      end
    end
    
    result = cmd.execute
    assert_equal 207, result[ :status ]
    assert_equal( { 'Content-Type' => 'text/xml; charset="utf-8"' }, result[ :headers ] )
    assert_equal expected_body, result[ :body ].read
  end
  
  test "should delete specified properties on resource and return appropriate " +
  "multistatus response" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :script_name => '/baz' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propertyupdate, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :remove do
        xml.D :prop do
          xml.t :foo
          xml.bar 'xmlns' => 'http://example.com/test2'
        end
      end
    end
    
    resource = stub( :href => 'foo/bar/', :collection? => true )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( resource )
    resource.expects( :remove_prop ).with( 'http://example.com/test', 'foo' ).returns( 200 )
    resource.expects( :remove_prop ).with( 'http://example.com/test2', 'bar' ).returns( 200 )
    
    cmd = PluggableMongrelWebdavHandler::ProppatchCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    
    expected_body = ''
    xml = Builder::XmlMarkup.new( :target => expected_body, :indent => 4 )
    xml.instruct!
    xml.multistatus 'xmlns' => 'DAV:', 'xmlns:a' => 'http://example.com/test',
      'xmlns:b' => 'http://example.com/test2' do
      xml.response do
        xml.href '/baz/foo/bar/'
        xml.propstat do
          xml.prop do
            xml.a :foo
          end
          xml.status 'HTTP/1.1 200 OK'
        end
        xml.propstat do
          xml.prop do
            xml.b :bar
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
  
  test "should process set and remove instructions in order" do
    root_collection = mock
    user = stub
    params = { :resource_href => 'foo/bar', :script_name => '/baz' }
    req_body = ''
    xml = Builder::XmlMarkup.new( :target => req_body, :indent => 4 )
    xml.instruct!
    xml.D :propertyupdate, 'xmlns:D' => 'DAV:', 'xmlns:t' => 'http://example.com/test' do
      xml.D :set do
        xml.D :prop do
          xml.t :foo, 'foo text'
        end
      end
      xml.D :remove do
        xml.D :prop do
          xml.t :foo
        end
      end
      xml.D :set do
        xml.D :prop do
          xml.t :foo, 'new foo text'
        end
      end
    end
    
    resource = stub( :href => 'foo/bar/', :collection? => true )
    call_prx = CallRecordingProxy.new( resource )
    root_collection.expects( :find_by_href ).with( 'foo/bar' ).returns( call_prx )
    resource.expects( :set_prop ).with( 'http://example.com/test', 'foo', 'foo text' ).returns( 200 )
    resource.expects( :remove_prop ).with( 'http://example.com/test', 'foo' ).returns( 200 )
    resource.expects( :set_prop ).with( 'http://example.com/test', 'foo', 'new foo text' ).returns( 200 )
    
    cmd = PluggableMongrelWebdavHandler::ProppatchCommand.new( root_collection, user, params, StringIO.new( req_body ) )
    cmd.execute
    
    assert_equal( { :method => :set_prop, :args => [ 'http://example.com/test', 'foo', 'foo text' ] }, call_prx.__calls__[ 0 ] )
    assert_equal( { :method => :remove_prop, :args => [ 'http://example.com/test', 'foo' ] }, call_prx.__calls__[ 1 ] )
    assert_equal( { :method => :set_prop, :args => [ 'http://example.com/test', 'foo', 'new foo text' ] }, call_prx.__calls__[ 2 ] )
  end
end