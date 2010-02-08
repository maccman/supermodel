require "tempfile"
require "fileutils"

module SuperModel
  module Marshal
    def path
      @path || raise("Provide a path")
    end
    
    def path=(p)
      @path = p
    end
    
    def klasses
      @klasses ||= []
    end
    
    def load
      return unless path
      return unless File.exist?(path)
      records = []
      File.open(path, "rb") {|file|
        records = ::Marshal.load(file)
      }
      records.each {|r| r.class.records << r }
      true
    end
  
    def dump
      return unless path
      tmp_file = Tempfile.new("rbdump")
      tmp_file.binmode
      records  = klasses.map {|k| k.records }.flatten
      ::Marshal.dump(records, tmp_file)
      # Atomic serialization - so we never corrupt the db
      FileUtils.mv(tmp_file.path, path)
      true
    end
    
    extend self
    
    module Model
      def self.included(base)
        Marshal.klasses << base
      end
      
      def marshal_dump
        serializable_hash
      end

      def marshal_load(atts)
        # Can't call load, since class
        # isn't setup properly
        @attributes = atts
      end
    end
  end
end