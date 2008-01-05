module PluggableMongrelWebdavHandler
  class PutCommand < Command
    def execute
      self.resource = parent_collection.put( resource_name, request_body )
      { :status => 201, :headers => { 'Location' => resource.href } }
    end
  end
end