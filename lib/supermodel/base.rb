module SuperModel
  class Base    
    include ActiveModel::Dirty
        
    class << self
      attr_accessor_with_default(:primary_key, 'id') #:nodoc:
      
      def attributes(*attributes)
        @known_attributes = attributes
      end
      
      def known_attributes
        @known_attributes ||= []
      end
      
      def records
        @records ||= []
      end
      
      def raw_find(id) #:nodoc:
        records.find {|r| r.id == id } || raise(UnknownRecord)
      end
      
      # Find record by ID, or raise.
      def find(id)
        item = raw_find(id)
        item && item.dup
      end
      alias :[] :find
    
      def first
        item = records[0]
        item && item.dup
      end
      
      def last
        item = records[-1]
        item && item.dup
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
      
      def method_missing(method_symbol, *args) #:nodoc:
        method_name = method_symbol.to_s

        if method_name =~ /^find_by_(\w+)!/
          send("find_by_#{$1}", *args) || raise(UnknownRecord)
        elsif method_name =~ /^find_by_(\w+)/
          records.find {|r| r.send($1) == args.first }
        elsif method_name =~ /^find_or_create_by_(\w+)/
          send("find_by_#{$1}", *args) || create($1 => args.first)
        else
          super
        end
      end
    end
    
    attr_accessor :attributes
    
    def known_attributes
      self.class.known_attributes + self.attributes.keys.map(&:to_s)
    end
    
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
      self.class.new(cloned)
    end
    
    def new?
      id.nil?
    end
    alias :new_record? :new?
    
    # Gets the <tt>\id</tt> attribute of the item.
    def id
      attributes[self.class.primary_key]
    end

    # Sets the <tt>\id</tt> attribute of the item.
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
      self.class.new.tap do |base|
        base.attributes = @attributes.dup
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
    
    def load(attributes) #:nodoc:
      @attributes.merge!(attributes)
    end
    
    def update_attribute(name, value)
      self.send("#{name}=".to_sym, value)
      self.save
    end
    
    def update_attributes(attributes)
      load(attributes) && save
    end
    
    def has_attribute?(name)
      @attributes.has_key?(name)
    end
    
    alias_method :respond_to_without_attributes?, :respond_to?
    
    def respond_to?(method, include_priv = false)
      method_name = method.to_s
      if attributes.nil?
        super
      elsif known_attributes.include?(method_name)
        true
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
      
      def generate_id
        object_id
      end
      
      def create
        self.id ||= generate_id
        self.class.records << self.dup
        save_previous_changes
      end
      
      def update
        item = self.class.raw_find(id)
        item.load(attributes)
        save_previous_changes
      end
      
      def save_previous_changes
        @previously_changed = changes
        changed_attributes.clear
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
          return nil if known_attributes.include?(method_name)
          super
        end
      end
  end
  
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include Observing, Validations, Callbacks
  end
end