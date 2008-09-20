module MongrelWebdavHandler
  class Command
    def initialize( root_collection, user, params, request_body )
      @root_collection = root_collection
      @user = user
      @params = params
      @request_body = request_body
    end
    
    def execute
      { :status => 405 }
    end
    
    private
    
    attr_reader :root_collection
    attr_reader :user
    attr_reader :params
    attr_reader :request_body
    attr_writer :resource
    attr_writer :destination
    
    def resource
      @resource ||= @root_collection.find_by_href( @params[ :resource_href ] )
    end
    
    def destination
      @destination ||= @root_collection.find_by_href( @params[ :destination_href ] )
    end
    
    def parent_collection
      if @parent_collection.nil?
        href = @params[ :resource_href ].sub( /\/?[^\/]*$/, '' )
        @parent_collection = @root_collection.find_by_href( href )
      end
      @parent_collection
    end
    
    def destination_parent
      if @destination_parent.nil?
        href = @params[ :destination_href ].sub( /\/?[^\/]*$/, '' )
        @destination_parent = @root_collection.find_by_href( href )
      end
      @destination_parent
    end
    
    def resource_name
      @params[ :resource_href ].split( '/' ).last
    end
  end
end