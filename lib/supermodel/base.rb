module SuperModel
  class Base    
    class UnknownRecord < SuperModelError; end
    class InvalidRecord < SuperModelError; end
        
    class << self
      
      attr_accessor_with_default(:primary_key, 'id') #:nodoc:
      
      def records
        @records ||= []
      end
      
      def raw_find(id) #:nodoc:
        records.find {|r| r.id == id } || raise(UnknownRecord)
      end
      
      # Find record by ID, or raise.
      def find(id)
        raw_find(id).try.dup 
      end
      alias :[] :find
    
      def first
        records[0].try.dup
      end
      
      def last
        records[-1].try.dup
      end
      
      def count
        records.length
      end
    
      def all
        records.dup
      end
      
      def update(id, data)
        find(id).update(data)
      end
      
      def destroy(id)
        find(id).destroy
      end
      
      # Removes all records and executes 
      # destory callbacks.
      def destroy_all
        records.dup.each {|r| r.destroy }
      end
      
      # Removes all records without executing
      # destroy callbacks.
      def delete_all
        records.clear
      end
      
      # Create a new record.
      # Example:
      #   create(:name => "foo", :id => 1)
      def create(atts = {})
        rec = self.new(atts)
        rec.save && rec
      end
      
      def method_missing(method_symbol, *arguments) #:nodoc:
        method_name = method_symbol.to_s

        if method_name =~ /^find_by_(\w+)!/
          send("find_by_#{$1}", *arguments) || raise(UnknownRecord)
        elsif method_name =~ /^find_by_(\w+)/
          records.find {|r| r.send($1) == arguments.first }
        else
          super
        end
      end
    end
    
    attr_accessor :attributes
    
    def initialize(attributes = {})
      @attributes = {}.with_indifferent_access
      load(attributes)
    end
    
    def clone
      cloned = attributes.reject {|k,v| k == self.class.primary_key }
      cloned = cloned.inject({}) do |attrs, (k, v)|
        attrs[k] = v.clone
        attrs
      end
      resource = self.class.new({})
      resource.prefix_options = self.prefix_options
      resource.send :instance_variable_set, '@attributes', cloned
      resource
    end
    
    def new?
      id.nil?
    end
    alias :new_record? :new?
    
    # Gets the <tt>\id</tt> attribute of the resource.
    def id
      attributes[self.class.primary_key]
    end

    # Sets the <tt>\id</tt> attribute of the resource.
    def id=(id)
      attributes[self.class.primary_key] = id
    end
    
    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && other.id == id)
    end

    # Tests for equality (delegates to ==).
    def eql?(other)
      self == other
    end
    
    def hash
      id.hash
    end
    
    def dup
      self.class.new.tap do |resource|
        resource.attributes = @attributes
      end
    end
    
    def save
      new? ? create : update
    end
    
    def save!
      save || raise(InvalidRecord)
    end
    
    def exists?
      !new?
    end
    
    def load(attributes)
      @attributes.merge!(attributes)
    end
    
    def update_attribute(name, value)
      self.send("#{name}=".to_sym, value)
      self.save
    end
    
    def update_attributes(attributes)
      load(attributes) && save
    end
    
    alias_method :respond_to_without_attributes?, :respond_to?
    
    def respond_to?(method, include_priv = false)
      method_name = method.to_s
      if attributes.nil?
        super
      elsif method_name =~ /(?:=|\?)$/ && attributes.include?($`)
        true
      else
        super
      end
    end
        
    def destroy
      self.class.records.delete(self)
      self
    end
    
    protected    
      def read_attribute(name)
        @attributes[name]
      end
      
      def write_attribute(name, value)
        @attributes[name] = value
      end
      
      def update
        resouce = self.class.raw_find(id)
        resource.send :instance_variable_set, '@attributes', attributes
      end
    
      def create
        self.class.records << self
      end
    
    private
      
      def method_missing(method_symbol, *arguments) #:nodoc:
        method_name = method_symbol.to_s

        if method_name =~ /(=|\?)$/
          case $1
          when "="
            attribute_will_change!($`)
            attributes[$`] = arguments.first
          when "?"
            attributes[$`]
          end
        else
          return attributes[method_name] if attributes.include?(method_name)
          super
        end
      end
  end
  
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include Observing, Validations, Scribe
  end
end