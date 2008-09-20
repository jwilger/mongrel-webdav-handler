require 'time'
require 'fileutils'

class FilesystemWebdavHandler
  class Resource
    def initialize( path, root_path  )
      @root_path = root_path
      @path = path
    end
  
    def get_prop( namespace, property )
      value = if namespace == 'DAV'
        case property
        when 'creationdate'
          File.mtime( @path ).xmlschema
        when 'displayname'
          File.basename( @path )
        when 'getcontentlength'
          File.size( @path )
        when 'getcontenttype'
          if collection?
            'http/unix-directory'
          else
            'application/x-binary'
          end
        when 'getetag'
          ( `md5 #{@path}` ).split( /\s/ ).last
        when 'getlastmodified'
          File.mtime( @path ).httpdate
        else
          nil
        end
      else
        nil
      end
      [ ( value.nil? ? 404 : 200 ), value ]
    end
  
    def set_prop( *args )
      403
    end
  
    def remove_property( *args )
      403
    end
  
    def get_children( depth )
      if depth > 0 && collection?
        next_depth = ( depth == :all ) ? :all : ( depth - 1 )
        dir = Dir.new( @path )
        children = dir.entries.reject { |e| e == '.' || e == '..' }
        children = children.map { |c| Resource.new( File.join( @path, c ), @root_path ) }
        if next_depth == :all || next_depth > 0
          children.dup.each do |c|
            c.get_children( next_depth ).each do |gc|
              children.push( gc )
            end
          end
        end
        children
      else
        []
      end
    end
  
    def make_collection( name )
      path = File.join( @path, name )
      FileUtils.mkdir( path )
      Resource.new( path, @root_path )
    end
  
    def put( name, content )
      path = File.join( @path, name )
      File.open( path, 'w' ) do |f|
        f.write( content )
      end
      Resource.new( path, @root_path )
    end
  
    def delete
      FileUtils.rm_rf( @path )
    end
  
    def href
      val = @path.sub( /^#{Regexp.escape( @root_path )}\/?/, '' )
      parts = val.split( '/' ).map { |p| CGI::escape( p ).gsub( /(%20|\+)/, ' ' ) }
      val = parts.join( '/' )
      if collection? && val != ''
        val = '/' + val + '/'
      end
      val
    end
  
    def content
      File.open( @path, 'r' )
    end
  
    def collection?
      File.directory?( @path )
    end
    
    def copy_to( dest_href, options )
      dest_path = File.join( @root_path, dest_href )
      if collection? && options[ :shallow ]
        FileUtils.mkdir( dest_path )
      else
        FileUtils.cp_r( @path, dest_path )
      end
      Resource.new( dest_path, @root_path )
    end
    
    def move_to( dest_href )
      dest_path = File.join( @root_path, dest_href )
      FileUtils.mv( @path, dest_path )
      Resource.new( dest_path, @root_path )
    end
  end
end