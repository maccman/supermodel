require "active_support/core_ext/string/inflections.rb"

module SuperModel
  module Association
    module ClassMethods
      def belongs_to(model)
        model = model.to_s
        model_name = model.classify
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{model}                                          # def user
            #{model_name}.find(#{model}_id)                     #   User.find(user_id)
          end                                                   # end
                                                                # 
          def #{model}?                                         # def user?
            #{model}_id && #{model_name}.exists?(#{model}_id)   #   user_id && User.exists?(user_id)
          end                                                   # end
                                                                # 
          def #{model}=(model)                                  # def user=(model)
            self.#{model}_id = (model && model.id)              #   self.user_id = (model && model.id)
          end                                                   # end
        EOS
      end
    end
    
    module Model
      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end