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
        rec.class.record(:create, rec.attributes)
      end
      
      def after_update(rec)
        rec.class.record(:update, rec.previously_changed_attributes)
      end
      
      def after_destroy
        rec.class.record(:destroy, rec.id)
      end      
    end
    
    module Model
      def self.extended(base)
        Scriber.klasses << base
      end

      def load_scribe(type, data) #:nodoc:
        case type
        when :create  then create(data)
        when :destroy then destroy(data)
        when :update  then update(data)
          method = "load_scripbe_#{type}"
          send(method) if respond_to?(method)
        end
      end
      
      def record(type, data)
        ::Scriber.record(self, type, data)
      end
    end
  end
end