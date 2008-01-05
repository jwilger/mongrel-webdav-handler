module PluggableMongrelWebdavHandler
  class CopyCommand < Command
    def execute
      return { :status => 409 } if destination_parent.nil?
      need_overwrite = !destination.nil?
      return { :status => 412 } if need_overwrite && !params[ :overwrite ]
      options = ( params[ :depth ] == 0 ) ? { :shallow => true } : {}
      new_resource = root_collection.copy( params[ :resource_href ], params[ :destination_href ], options )
      if need_overwrite
        { :status => 204 }
      else
        { :status => 201, :headers => { 'Location' => new_resource.href } }
      end
    end
  end
end