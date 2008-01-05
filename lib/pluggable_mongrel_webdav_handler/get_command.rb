module PluggableMongrelWebdavHandler
  class GetCommand < Command
    def execute
      return { :status => 404 } if resource.nil?
      { :status => 200,  :body => params[ :request_method ] == :head ? nil : resource.content,
        :headers => { 'Content-Type' => resource.get_prop( 'DAV:', 'getcontenttype' ).last } }
    end
  end
end