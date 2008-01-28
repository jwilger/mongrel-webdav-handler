module PluggableMongrelWebdavHandler
  class ProppatchCommand < Command
    def execute
      body = request_body.read
      proppatch_xml = REXML::Document.new( body ).root
      dav_namespace = proppatch_xml.namespaces.index( 'DAV:' )
      if dav_namespace == 'xmlns'
        properties = proppatch_xml.get_elements( "//prop/*" )
      else
        properties = proppatch_xml.get_elements( "//#{dav_namespace}:prop/*" )
      end
      next_namespace = 'a'
      prop_namespaces = { 'xmlns' => 'DAV:' }
      results = []
      properties.each do |el|
        status = case el.parent.parent.name
          when 'set'
            resource.set_prop( el.namespace, el.name, el.text )
          when 'remove'
            resource.remove_prop( el.namespace, el.name )
          end
        unless prop_namespaces.index( el.namespace )
          prop_namespaces[ next_namespace ] = el.namespace
          next_namespace = next_namespace.succ
        end
        namespace_id = prop_namespaces.index( el.namespace )
        results << { :ns => namespace_id, :name => el.name, :status => status }
      end
      multistatus = ''
      xml = Builder::XmlMarkup.new( :target => multistatus, :indent => 4 )
      xml.instruct!
      multistatus_namespaces = { 'xmlns' => 'DAV:' }
      prop_namespaces.keys.each do |k|
        multistatus_namespaces[ "xmlns:#{k}" ] = prop_namespaces[ k ] unless k == 'xmlns'
      end
      xml.multistatus multistatus_namespaces do
        xml.response do
          xml.href params[ :script_name ] + '/' + resource.href
          results.each do |result|
            xml.propstat do
              xml.prop do
                tag_name = result[ :ns ] == 'xmlns' ? '' : "#{result[ :ns ]}:"
                tag_name += result[ :name ]
                xml.tag! tag_name
              end
              case result[ :status ]
              when 200
                xml.status 'HTTP/1.1 200 OK'
              when 201
                xml.status 'HTTP/1.1 201 Created'
              end
            end
          end
        end
      end
      { :status => 207, :headers => { 'Content-Type' => 'text/xml; charset="utf-8"' }, :body => StringIO.new( multistatus ) }
    end
  end
end