module SuperModel
  module Timestamp
    module Model
      def self.included(base)
        base.class_eval do
          attributes :created_at, :updated_at
          
          before_create :set_created_at
          before_save   :set_updated_at
        end
        
        private
        
          def set_created_at
            self.created_at = Time.now
          end
          
          def set_updated_at
            self.updated_at = Time.now
          end
      end
    end
  end
end