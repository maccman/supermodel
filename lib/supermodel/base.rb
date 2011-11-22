module SuperModel
  class Base    
    class_attribute :known_attributes
    self.known_attributes = []
    
    class << self
      attr_accessor(:primary_key) #:nodoc:
      
      def primary_key
        @primary_key ||= 'id'
      end
      
      def collection(&block)
        @collection ||= Class.new(Array)
        @collection.class_eval(&block) if block_given?
        @collection
      end

      def attributes(*attributes)
        self.known_attributes |= attributes.map(&:to_s)
      end
      
      def records
        @records ||= {}
      end
      
      def find_by_attribute(name, value) #:nodoc:
        item = records.values.find {|r| r.send(name) == value }
        item && item.dup
      end
      
      def find_all_by_attribute(name, value) #:nodoc:
        items = records.values.select {|r| r.send(name) == value }
        collection.new(items.deep_dup)
      end
      
      def raw_find(id) #:nodoc:
        records[id] || raise(UnknownRecord, "Couldn't find #{self.name} with ID=#{id}")
      end
      
      # Find record by ID, or raise.
      def find(id)
        item = raw_find(id)
        item && item.dup
      end
      alias :[] :find
    
      def first
        item = records.values[0]
        item && item.dup
      end
      
      def last
        item = records.values[-1]
        item && item.dup
      end
      
      def exists?(id)
        records.has_key?(id)
      end
      
      def count
        records.length
      end
    
      def all
        collection.new(records.values.deep_dup)
      end
      
      def select(&block)
        collection.new(records.values.select(&block).deep_dup)
      end
      
      def update(id, atts)
        find(id).update_attributes(atts)
      end
      
      def destroy(id)
        find(id).destroy
      end
      
      # Removes all records and executes 
      # destroy callbacks.
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
      
      def create!(*args)
        create(*args) || raise(InvalidRecord)
      end
      
      def method_missing(method_symbol, *args) #:nodoc:
        method_name = method_symbol.to_s

        if method_name =~ /^find_by_(\w+)!/
          send("find_by_#{$1}", *args) || raise(UnknownRecord)
        elsif method_name =~ /^find_by_(\w+)/
          find_by_attribute($1, args.first)
        elsif method_name =~ /^find_or_create_by_(\w+)/
          send("find_by_#{$1}", *args) || create($1 => args.first)
        elsif method_name =~ /^find_all_by_(\w+)/
          find_all_by_attribute($1, args.first)
        else
          super
        end
      end
    end
    
    attr_accessor :attributes
    attr_writer   :new_record
    
    def known_attributes
      self.class.known_attributes | self.attributes.keys.map(&:to_s)
    end
    
    def initialize(attributes = {})
      @new_record = true
      @attributes = {}.with_indifferent_access
      @attributes.merge!(known_attributes.inject({}) {|h, n| h[n] = nil; h })
      @changed_attributes = {}
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
    alias_method :persisted?, :exists?
    
    def load(attributes) #:nodoc:
      return unless attributes
      attributes.each do |(name, value)| 
        self.send("#{name}=".to_sym, value) 
      end
    end
    
    def reload
      return self if new?
      item = self.class.find(id)
      load(item.attributes)
      return self
    end
    
    def update_attribute(name, value)
      self.send("#{name}=".to_sym, value)
      self.save
    end
    
    def update_attributes(attributes)
      load(attributes) && save
    end
    
    def update_attributes!(attributes)
      update_attributes(attributes) || raise(InvalidRecord)
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
      
      def raw_destroy
        self.class.records.delete(self.id)
      end
      
      def raw_create
        self.class.records[self.id] = self.dup
      end
      
      def create
        self.id ||= generate_id
        self.new_record = false
        raw_create
        self.id
      end
      
      def raw_update
        item = self.class.raw_find(id)
        item.load(attributes)
      end
      
      def update
        raw_update
        true
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
    extend  ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Dirty, Observing, Callbacks, Validations
    include Association::Model
  end
end