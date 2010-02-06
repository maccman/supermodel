module SuperModel
  module Scriber    
    class Observer
      include Singleton
      
      def after_create(rec)
        rec.class.record(:create, rec.attributes)
      end
      
      def after_update(rec)
        changed_to = rec.previous_changes.inject({}) {|hash, (key, (from, to))| 
          hash[key] = to
          hash 
        }
        rec.class.record(:update, changed_to)
      end
      
      def after_destroy
        rec.class.record(:destroy, rec.id)
      end
      
      def update(observed_method, object) #:nodoc:
        send(observed_method, object) if respond_to?(observed_method)
      end

      def observed_class_inherited(subclass) #:nodoc:
        subclass.add_observer(self)
      end
    end
    
    def klasses
      @klasses ||= []
    end
    module_function :klasses
    
    module Model
      def self.included(base)
        Scriber.klasses << base
        base.extend ClassMethods
        base.add_observer(Observer.instance)
      end
      
      module ClassMethods
        def scribe_play(type, data) #:nodoc:
          case type
          when :create  then create(data)
          when :destroy then destroy(data)
          when :update  then update(data)
          else
            method = "scribe_play_#{type}"
            send(method) if respond_to?(method)
          end
        end
      
        def record(type, data = nil)
          ::Scriber.record(self, type, data)
        end
      end
    end
  end
end