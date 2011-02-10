module SuperModel
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator
      attr_reader :klass
      
      def validate_each(record, attribute, value)
        alternate = klass.find_by_attribute(attribute, value)
        return unless alternate
        record.errors.add(attribute, "must be unique", :default => options[:message])
      end
      
      def setup(klass)
        @klass = klass
      end
    end

    module ClassMethods

      # Validates that the specified attribute is unique.
      #   class Person < ActiveRecord::Base
      #     validates_uniquness_of :essay
      #   end
      #
      # Configuration options:
      # * <tt>:allow_nil</tt> - Attribute may be +nil+; skip validation.
      # * <tt>:allow_blank</tt> - Attribute may be blank; skip validation.
      # * <tt>:message</tt> - The error message to use for a <tt>:minimum</tt>, <tt>:maximum</tt>, or <tt>:is</tt> violation.  An alias of the appropriate <tt>too_long</tt>/<tt>too_short</tt>/<tt>wrong_length</tt> message.
      # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>).
      # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      def validates_uniqueness_of(*attr_names)
        validates_with UniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end