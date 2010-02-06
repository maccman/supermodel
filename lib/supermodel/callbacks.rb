module SuperModel
  module Callbacks
    extend ActiveSupport::Concern

    included do
      instance_eval do
        extend ActiveModel::Callbacks
        define_model_callbacks :create, :save, :update, :destroy
      end
      
      %w( create save update destroy ).each do |method|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{method}_with_callbacks(*args, &block)
            _run_#{method}_callbacks do
              #{method}_without_callbacks(*args, &block)
            end
          end
        EOS
        alias_method_chain(method, :callbacks)
      end
    end
  end
end