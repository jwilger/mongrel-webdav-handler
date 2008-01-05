module PluggableMongrelWebdavHandler
  class Base < Mongrel::HttpHandler
    class << self
      attr_reader :root_collection_loader
      attr_reader :authenticater
      attr_reader :www_authenticate_header
      
      def load_root_collection( &blk )
        @root_collection_loader = blk
      end
      
      def authenticate( &blk )
        @authenticater = blk
      end
      
      def set_www_authenticate_header( str )
        @www_authenticate_header = str
      end
    end
    
    def process( request, response )
      root_collection = self.class.root_collection_loader.call
      params = extract_params( request.params )
      return unless user = authenticate_user( params, response )
      request_body = request.body.read
      command = get_command( root_collection, user, params, request_body )
      result = command.execute
      response.start( result[ :status ] ) do |head, body|
        set_headers( head, result, params )
        set_body( body, result )
      end
    end
    
    private
    
    def extract_params( params )
      {
        :script_name => params[ 'SCRIPT_NAME' ],
        :request_method => clean_request_method( params ),
        :resource_href => clean_resource_href( params ),
        :destination_href => clean_destination_href( params ),
        :authorization => clean_authorization( params ),
        :depth => clean_depth( params ),
        :overwrite => clean_overwrite( params ),
        :fragment => params[ 'FRAGMENT' ]
      }
    end
    
    def authenticate_user( params, response )
      user = self.class.authenticater.call( params[ :authorization ] )
      if user.nil?
        if params[ :request_method ] == :options
          user = :anonymous_options_request_allowed
        else
          response.start( 401 ) do |head, body|
            head[ 'WWW-Authenticate' ] = self.class.www_authenticate_header
          end
        end
      end
      user
    end
    
    def get_command( root_collection, user, params, request_body )
      command_class = case params[ :request_method ]
        when :options then OptionsCommand
        when :propfind then PropfindCommand
        when :proppatch then ProppatchCommand
        when :get,:head then GetCommand
        when :put then PutCommand
        when :delete then DeleteCommand
        when :mkcol then MkcolCommand
        when :move then MoveCommand
        when :copy then CopyCommand
        when :lock then LockCommand
        when :unlock then UnlockCommand
        else; Command
      end
      command_class.new( root_collection, user, params, request_body )
    end
    
    def set_headers( head, result, params )
      head[ 'DAV' ] = '1,2'
      head[ 'MS-Author-Via' ] = 'DAV'
      if result[ :headers ]
        result[ :headers ].each do |k,v|
          if k == 'Location'
            v = params[ :script_name ] + '/' + v
          end
          head[ k ] = v
        end
      end
    end
    
    def set_body( body, result )
      if result[ :body ]
        body.write( result[ :body ].read )
        result[ :body ].close
      end
    end
    
    def clean_request_method( params )
      params[ 'REQUEST_METHOD' ].downcase.to_sym
    end
    
    def clean_resource_href( params )
      params[ 'PATH_INFO' ].gsub( /(^\/|\/$)/, '' )
    end
    
    def clean_destination_href( params )
      return nil if params[ 'HTTP_DESTINATION' ].nil?
      return nil if params[ 'HTTP_DESTINATION' ].empty?
      prefix_pattern = /^https?:\/\/#{Regexp.escape( params[ 'HTTP_HOST' ] + params[ 'SCRIPT_NAME' ] )}\/?/
      params[ 'HTTP_DESTINATION' ].gsub( prefix_pattern, '' ).gsub( /(^\/|\/$)/, '' )
    end
    
    def clean_authorization( params )
      params[ 'HTTP_AUTHORIZATION' ]   ||
      params[ 'X-HTTP_AUTHORIZATION' ] ||
      params[ 'X_HTTP_AUTHORIZATION' ]
    end
    
    def clean_depth( params )
      return 0 unless params[ 'HTTP_DEPTH' ]
      if params[ 'HTTP_DEPTH' ] == 'infinity'
        :all
      else
        params[ 'HTTP_DEPTH' ].to_i
      end
    end
    
    def clean_overwrite( params )
      params[ 'HTTP_OVERWRITE' ].downcase == 't' rescue false
    end
  end
end