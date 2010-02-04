module SuperModel
  module Validations
    extend  ActiveSupport::Concern
    include ActiveModel::Validations

    included do
      alias_method_chain :save, :validation
    end
  
    def save_with_validation(options = nil)
      perform_validation = case options
        when Hash
          options[:validate] != false
        when NilClass
          true
        end
      end
    
      if perform_validation && valid? || !perform_validation
        save_without_validation
        true
      else
        false
      end
    rescue ResourceInvalid => error
      false
    end
  end
end