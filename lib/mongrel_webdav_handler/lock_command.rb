module MongrelWebdavHandler
  class LockCommand < Command
    def execute
      { :status => 200 }
    end
  end
end