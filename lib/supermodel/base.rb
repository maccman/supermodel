module SuperModel
  class Base    
    include ActiveModel::Dirty
    class_inheritable_array :known_attributes
    self.known_attributes = []
    
    class << self
      attr_accessor_with_default(:primary_key, 'id') #:nodoc:

      def attributes(*attributes)
        self.known_attributes += attributes.map(&:to_s)
      end
      
      def records
        @records ||= []
      end
      
      def find_by_attribute(name, value) #:nodoc:
        records.find {|r| r.send(name) == value }
      end
      
      def raw_find(id) #:nodoc:
        find_by_attribute(:id, id) || raise(UnknownRecord)
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
      
      def update(id, atts)
        find(id).update_attributes(atts)
      end
      
      def destroy(id)
        find(id).destroy
      end
      
      # Removes all records and executes 
      # destory callbacks.
      def destroy_all
        all.each {|r| r.destroy }
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
          find_by_attribute($1, args.first)
        elsif method_name =~ /^find_or_create_by_(\w+)/
          send("find_by_#{$1}", *args) || create($1 => args.first)
        else
          super
        end
      end
    end
    
    attr_accessor :attributes
    attr_writer :new_record
    
    def known_attributes
      self.class.known_attributes + self.attributes.keys.map(&:to_s)
    end
    
    def initialize(attributes = {})
      @new_record = true
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
      @new_record || false
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
        base.attributes = attributes
        base.new_record = new_record?
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
      attributes.each {|(name, value)| 
        self.send("#{name}=".to_sym, value) 
      }
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
        
    def raw_destroy
      self.class.records.delete(self)
    end
    
    def destroy
      raw_destroy
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
      
      def raw_create
        self.class.records << self.dup
      end
      
      def create
        self.id ||= generate_id
        self.new_record = false
        raw_create
        save_previous_changes
        self.id
      end
      
      def raw_update
        item = self.class.raw_find(id)
        item.load(attributes)
      end
      
      def update
        raw_update
        save_previous_changes
        true
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
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Observing, Validations, Callbacks
  end
end