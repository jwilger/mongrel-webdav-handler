module PluggableMongrelWebdavHandler
  class MkcolCommand < Command
    def execute
      return { :status => 415 } unless request_body.read.empty?
      return { :status => 405 } unless resource.nil?
      return { :status => 409 } if parent_collection.nil?
      self.resource = parent_collection.make_collection( resource_name )
      { :status => 201, :headers => { 'Location' => resource.href } }
    end
  end
end