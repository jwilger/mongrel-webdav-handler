module PluggableMongrelWebdavHandler
  class OptionsCommand < Command
    def execute
      allow = 'OPTIONS,GET,HEAD,PUT,DELETE,COPY,MOVE,MKCOL,PROPFIND,PROPPATCH,LOCK,UNLOCK'
      { :status => 200, :headers => { 'Allow' => allow } }
    end
  end
end