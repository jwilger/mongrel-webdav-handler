module MongrelWebdavHandler
  class UnlockCommand < Command
    def execute
      { :status => 200 }
    end
  end
end