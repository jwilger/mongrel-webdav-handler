class FilesystemWebdavHandler
  class Root
    def initialize( path )
      @path = path
    end
  
    def find_by_href( href )
      path = File.join( @path, href )
      if File.exist?( path )
        Resource.new( path, @path )
      else
        nil
      end
    end
    
    def copy( src_href, dest_href, options = {} )
      src = find_by_href( src_href )
      existing = find_by_href( dest_href )
      existing.delete unless existing.nil?
      src.copy_to( dest_href, options )
    end
    
    def move( src_href, dest_href )
      src = find_by_href( src_href )
      existing = find_by_href( dest_href )
      existing.delete unless existing.nil?
      src.move_to( dest_href )
    end
  end
end