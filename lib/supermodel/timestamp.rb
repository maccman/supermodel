module SuperModel
  module Timestamp
    module Model
      def self.included(base)
        base.class_eval do
          attributes :created_at, :updated_at
          
          before_create :set_created_at
          before_save   :set_updated_at
        end
        
        def touch
          set_updated_at
          save!
        end
        
        private
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
end