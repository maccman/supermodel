module SuperModel
  module Timestamp
    module Model
      def self.included(base)
        base.class_eval do
          attributes :created_at, :updated_at
          
          before_create :set_created_at
          before_save   :set_updated_at
        end
      end
        
      def touch
        set_updated_at
        save!
      end
      
      def created_at=(time)
        write_attribute(:created_at, parse_time(time))
      end

      def updated_at=(time)
        write_attribute(:updated_at, parse_time(time))
      end
      
      private
        def parse_time(time)
          return time unless time.is_a?(String)
          if Time.respond_to?(:zone) && Time.zone
            Time.zone.parse(time)
          else
            Time.parse(time)
          end
        end

        def current_time
          if Time.respond_to?(:current)
            Time.current
          else
            Time.now
          end
        end
      
        def set_created_at
          self.created_at = current_time
        end
        
        def set_updated_at
          self.updated_at = current_time
        end
    end
  end
end