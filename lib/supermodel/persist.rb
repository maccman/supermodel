module SuperModel
  module Persist
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
        records = Marshal.load(file)
      }
      records.flatten.each {|r| r.class.records << r }
      true
    end
  
    def dump
      return unless path
      records = klasses.map {|k| k.records }
      File.open(path, "wb+") {|file|
        Marshal.dump(records, file)
      }
      true
    end
    
    extend self
    
    module Model
      def self.included(base)
        Persist.klasses << base
      end
      
      def marshal_dump
        @attributes
      end

      def marshal_load(attributes)
        @attributes = attributes
      end
    end
  end
end