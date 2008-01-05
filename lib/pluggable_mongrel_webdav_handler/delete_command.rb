module PluggableMongrelWebdavHandler
  class DeleteCommand < Command
    def execute
      return { :status => 405 } unless params[ :fragment ].nil?
      return { :status => 404 } if resource.nil?
      resource.delete
      { :status => 204 }
    end
  end
end