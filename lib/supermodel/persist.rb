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
      File.open(path, "rb") {|file|
        Marshal.load(file)
      }
    end
  
    def dump
      return unless path
      File.open(path, "wb+") {|file|
        Marshal.dump(klasses, file)
      }
    end
    
    extend self
    
    module Model
      def self.included(base)
        Persist.klasses << base
      end
    end
  end
end