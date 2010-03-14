module SuperModel
  module Redis
    module ClassMethods
      def self.extended(base)
        base.class_eval do
          class_inheritable_array :indexed_attributes
          self.indexed_attributes = []
          class_inheritable_array :serialized_attributes
          self.serialized_attributes = []
        end
      end
      
      def namespace
        @namespace ||= self.name.downcase
      end
      
      def namespace=(namespace)
        @namespace = namespace
      end
      
      def redis
        @redis ||= ::Redis.new
      end
      
      def indexes(*indexes)
        self.indexed_attributes += indexes.map(&:to_s)
      end
      
      def serialize(*attributes)
        self.serialized_attributes += attributes.map(&:to_s)
      end
      
      def redis_key(*args)
        args.unshift(self.namespace)
        args.join(":")
      end
      
      def find(id)
        if redis.set_member?(redis_key, id.to_s)
          existing(:id => id)
        else
          raise(UnknownRecord)
        end
      end
      
      def first
        all.first
      end
      
      def last
        all.last
      end
      
      def exists?(id)
        redis.set_member?(redis_key, id.to_s)
      end
      
      def count
        redis.set_count(redis_key)
      end
      
      def all
        from_ids(redis.set_members(redis_key))
      end
      
      def delete_all
        raise "Not implemented"
      end
      
      def find_by_attribute(key, value)
        item_ids = redis.set_members(redis_key(key, value.to_s))
        return if item_ids.empty?
        existing(:id => item_ids.first)
      end
      
      protected
        def from_ids(ids)
          ids.map {|id| existing(:id => id) }
        end
        
        def existing(atts = {})
          item = self.new(atts)
          item.new_record = false
          item.redis_get
          item
        end
    end
    
    module InstanceMethods
      # Redis integers are stored as strings
      def id
        super.try(:to_s)
      end
    
      protected      
        def raw_destroy
          return if new?

          destroy_indexes
          redis.set_delete(self.class.redis_key, self.id)
      
          attributes.keys.each do |key|
            redis.delete(redis_key(key))
          end
        end
      
        def destroy_indexes
          indexed_attributes.each do |index|
            old_attribute = changes[index].try(:first) || send(index)
            redis.set_delete(self.class.redis_key(index, old_attribute), id)
          end
        end
      
        def create_indexes
          indexed_attributes.each do |index|
            new_attribute = send(index)
            redis.set_add(self.class.redis_key(index, new_attribute), id)
          end
        end
    
        def generate_id
          redis.incr(self.class.redis_key(:uid))
        end

        def indexed_attributes
          attributes.keys & self.class.indexed_attributes
        end
      
        def redis
          self.class.redis
        end
    
        def redis_key(*args)
          self.class.redis_key(id, *args)
        end
      
        def serialized_attributes
          self.class.serialized_attributes
        end
      
        def serialize_attribute(key, value)
          return value unless serialized_attributes.include?(key)
          value.to_json
        end
      
        def deserialize_attribute(key, value)
          return value unless serialized_attributes.include?(key)
          value && JSON.parse(value)
        end
      
        def redis_set
          serializable_hash.each do |(key, value)|
            redis.set(redis_key(key), serialize_attribute(key, value))
          end
        end
      
        def redis_get
          known_attributes.each do |key|
            result = deserialize_attribute(key, redis.get(redis_key(key)))
            send("#{key}=", result)
          end
        end
        public :redis_get
    
        def raw_create
          redis_set
          create_indexes
          redis.set_add(self.class.redis_key, self.id)
        end
      
        def raw_update
          destroy_indexes
          redis_set
          create_indexes
        end
    end
    
    module Model
      def self.included(base)
        base.send :include, InstanceMethods
        base.send :extend,  ClassMethods
      end
    end
  end
end
