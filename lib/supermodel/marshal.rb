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
      data = []
      File.open(path, "rb") do |file|
        begin
          data = ::Marshal.load(file)
        rescue => e
          if defined?(Bowline)
            Bowline::Logging.log_error(e)
          end
          # Lots of errors can occur during
          # marshaling - such as EOF etc
          return false
        end
      end
      data.each do |klass, records| 
        klass.marshal_records = records
      end
      true
    end
  
    def dump
      return unless path
      tmp_file = Tempfile.new("rbdump")
      tmp_file.binmode
      data = klasses.inject({}) {|hash, klass|
        hash[klass] = klass.marshal_records
        hash
      }
      ::Marshal.dump(data, tmp_file)
  	  tmp_file.close
      # Atomic serialization - so we never corrupt the db
      FileUtils.mv(tmp_file.path, path)
      true
    end
    
    extend self
    
    module Model
      def self.included(base)
        base.extend ClassMethods
        Marshal.klasses << base
      end
      
      def marshal_dump
        serializable_hash(self.class.marshal)
      end

      def marshal_load(atts)
        # Can't call load, since class
        # isn't setup properly
        @attributes         = atts.with_indifferent_access
        @changed_attributes = {}
      end
      
      module ClassMethods
        def marshal(options = nil)
          @marshal = options if options
          @marshal ||= {}
        end
        alias_method :marshal=, :marshal
                
        def marshal_records=(records)
          @records = records
        end
        
        def marshal_records
          @records
        end    
      end
    end
  end
end