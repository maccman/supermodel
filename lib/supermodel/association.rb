require "active_support/core_ext/string/inflections.rb"

module SuperModel
  module Association
    module ClassMethods
      def belongs_to(to_model, options = {})
        to_model    = to_model.to_s
        class_name  = options[:class_name]  || to_model.classify
        foreign_key = options[:foreign_key] || "#{to_model}_id"
        primary_key = options[:primary_key] || "id"
        
        attributes foreign_key
        
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{to_model}                                             # def user
            #{foreign_key} && #{class_name}.find(#{foreign_key})      #   user_id && User.find(user_id)
          end                                                         # end
                                                                      # 
          def #{to_model}?                                            # def user?
            #{foreign_key} && #{class_name}.exists?(#{foreign_key})   #   user_id && User.exists?(user_id)
          end                                                         # end
                                                                      # 
          def #{to_model}=(object)                                    # def user=(model)
            self.#{foreign_key} = (object && object.#{primary_key})   #   self.user_id = (model && model.id)
          end                                                         # end
        EOS
      end
      
      def has_many(to_model, options = {})
        to_model    = to_model.to_s
        class_name  = options[:class_name]  || to_model.classify
        foreign_key = options[:foreign_key] || "#{model_name.singular}_id"
        primary_key = options[:primary_key] || "id"
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{to_model}                                             # def user
            #{class_name}.find_all_by_attribute(                      #   User.find_all_by_attribute(
              :#{foreign_key},                                        #    :task_id,
              #{primary_key}                                          #    id
            )                                                         #   )
          end                                                         # end
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