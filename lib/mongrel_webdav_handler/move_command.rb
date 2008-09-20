module MongrelWebdavHandler
  class MoveCommand < Command
    def execute
      return { :status => 409 } if destination_parent.nil?
      need_overwrite = !destination.nil?
      return { :status => 412 } if need_overwrite && !params[ :overwrite ]
      new_resource = root_collection.move( params[ :resource_href ], params[ :destination_href ] )
      if need_overwrite
        { :status => 204 }
      else
        { :status => 201, :headers => { 'Location' => new_resource.href } }
      end
    end
  end
end