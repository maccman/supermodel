module SuperModel
  module Dirty
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    included do
      %w( create update ).each do |method|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{method}_with_dirty(*args, &block)
            result = #{method}_without_dirty(*args, &block)
            save_previous_changes
            result
          end
        EOS
        alias_method_chain(method, :dirty)
      end
    end
        
    def save_previous_changes
      @previously_changed = changes
      @changed_attributes.clear
    end
  end
end
