require 'base64'
$:.unshift( File.expand_path( File.dirname( __FILE__ ) + '/../../../../lib' ) )
require 'mongrel_webdav_handler'

class FilesystemWebdavHandler < MongrelWebdavHandler::Base
  def initialize( root_dir )
    @root_dir = root_dir
  end
  
  load_root_collection { FilesystemWebdavHandler::Root.new( @root_dir ) }
  
  authenticate do |auth_header|
    u,p = Base64.decode64( ( auth_header || '' ).
      sub( /^Basic\s+/, '' ) ).split( ':', 2 )
    if u == 'test' && p == 'test'
      :user
    else
      nil
    end
  end
  
  set_www_authenticate_header 'Basic realm="Filesystem WebDAV Example"'
end

require 'filesystem_webdav_handler/resource'
require 'filesystem_webdav_handler/root'
