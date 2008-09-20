require 'rexml/document'

module MongrelWebdavHandler
  class PropfindCommand < Command
    def generate_response( resource )
      results = {}
      @requested_properties.each do |el|
        if el.namespace == 'DAV:' && el.name == 'resourcetype'
          status, content = 200, nil
        else
          status, content = resource.get_prop( el.namespace, el.name )
        end
        unless @prop_namespaces.index( el.namespace )
          @prop_namespaces[ @next_namespace ] = el.namespace
          @next_namespace = @next_namespace.succ
        end
        namespace_id = @prop_namespaces.index( el.namespace )
        results[ status ] ||= []
        results[ status ] << { :ns => namespace_id, :name => el.name, :content => content }
      end
      response = ''
      xml = Builder::XmlMarkup.new( :target => response, :indent => 4, :margin => 1 )
      xml.response do
        xml.href params[ :script_name ] + '/' + resource.href
        results.keys.sort.each do |status|
          xml.propstat do
            xml.prop do
              results[ status ].each do |prop_result|
                if prop_result[ :ns ] == 'xmlns' && prop_result[ :name ] == 'resourcetype'
                  xml.resourcetype do
                    xml.collection if resource.collection?
                  end
                else
                  tag_name = prop_result[ :name ]
                  tag_name = prop_result[ :ns ] + ':' + tag_name unless prop_result[ :ns ] == 'xmlns'
                  if prop_result[ :content ]
                    xml.tag! tag_name, prop_result[ :content ]
                  else
                    xml.tag! tag_name
                  end
                end
              end
            end
            case status
            when 200
              xml.status 'HTTP/1.1 200 OK'
            when 403
              xml.status 'HTTP/1.1 403 Forbidden'
            when 404
              xml.status 'HTTP/1.1 404 Not Found'
            end
          end
        end
      end
      return response
    end
    
    def execute
      body = request_body.read
      return { :status => 404 } if resource.nil?
      return { :status => 400 } if body =~ /xmlns(:\w+)?=""/
      if body.empty?
        default_request_body = ''
        xml = Builder::XmlMarkup.new( :target => default_request_body )
        xml.instruct!
        xml.propfind 'xmlns' => 'DAV:' do
          xml.prop do
            xml.resourcetype
            xml.creationdate
            xml.displayname
            xml.getcontentlength
            xml.getcontenttype
            xml.getetag
            xml.getlastmodified
          end
        end
        propfind_xml = REXML::Document.new( default_request_body ).root
      else
        propfind_xml = REXML::Document.new( body ).root
      end
      @dav_namespace = propfind_xml.namespaces.index( 'DAV:' )
      if @dav_namespace == 'xmlns'
        @requested_properties = propfind_xml.get_elements( "prop/*" )
      else
        @requested_properties = propfind_xml.get_elements( "#{@dav_namespace}:prop/*" )
      end
      @next_namespace = 'a'
      @prop_namespaces = { 'xmlns' => 'DAV:' }
      @results = {}
      requested_resources = [ resource ] + resource.get_children( params[ :depth ] )
      responses = requested_resources.map { |r| generate_response( r ) }
      
      multistatus = ''
      xml = Builder::XmlMarkup.new( :target => multistatus, :indent => 4 )
      xml.instruct!
      multistatus_namespaces = { 'xmlns' => 'DAV:' }
      @prop_namespaces.keys.each do |k|
        multistatus_namespaces[ "xmlns:#{k}" ] = @prop_namespaces[ k ] unless k == 'xmlns'
      end
      xml.multistatus multistatus_namespaces do
        responses.each do |response|
          xml << response
        end
      end
      { :status => 207, :headers => { 'Content-Type' => 'text/xml; charset="utf-8"' }, :body => StringIO.new( multistatus ) }
    rescue REXML::ParseException
      { :status => 400 }
    end
  end
end