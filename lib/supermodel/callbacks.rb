module SuperModel
  module Callbacks
    extend ActiveResource::Concern
    extend ActiveModel::Callbacks
    
    included do
      define_model_callbacks :create, :save, :update, :destroy
      %w( create save update destroy ).each do |method|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{method}_with_callbacks(*args, &block)
            _run_#{method}_callbacks do
              #{method}_without_notifications(*args, &block)
            end
          end
        EOS
        alias_method_chain(method, :callbacks)
      end
    end
  end
end