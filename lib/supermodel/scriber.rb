module SuperModel
  module Scriber
    def klasses
      @klasses ||= []
    end
    module_function :klasses
    
    class Observer < ActiveModel::Observer
      def self.observed_classes
        Scriber.klasses
      end
      
      def after_create(rec)
        record(:create, rec.attributes)
      end
      
      def after_update(rec)
        record(:update, rec.previously_changed_attributes)
      end
      
      def after_destroy
        record(:destroy, rec.id)
      end
      
      protected      
        def record(type, *data, &block) #:nodoc:
          ::Scriber.record(self, type, data)
        end
    end
    
    module Model
      def self.extended(base)
        Scriber.klasses << base
      end

      def run_scriber(type, data) #:nodoc:
        case type
        when :create  then create(data)
        when :destroy then destroy(data)
        when :update  then update(data)
        end
      end
    end
  end
end