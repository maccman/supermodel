module SuperModel
  module Redis
    module ClassMethods
      def redis
        @redis ||= ::Redis.new
      end
      
      def indexes(*indexes)
        @indexes ||= []
        @indexes += indexes.map(&:to_s)
      end
      
      def serialize(*attributes)
        @serialize ||= []
        @serialize += attributes.map(&:to_s)
      end      
      
      def redis_key(*args)
        args.unshift(self.name.downcase)
        args.join(":")
      end
      
      def find(id)
        if redis.set_member?(redis_key, id)
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
        item_ids = redis.set_members(redis_key(key, value))
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
      def destroy
        return if new?

        destroy_indexes
        redis.set_delete(self.class.redis_key, self.id)
      
        attributes.keys.each do |key|
          redis.delete(redis_key(key))
        end
      end
    
      protected
        def destroy_indexes
          known_indexes.each do |index|
            old_attribute = changes[index].try(:first) || send(index)
            redis.set_delete(self.class.redis_key(index, old_attribute), id)
          end
        end
      
        def create_indexes
          known_indexes.each do |index|
            new_attribute = send(index)
            redis.set_add(self.class.redis_key(index, new_attribute), id)
          end
        end
    
        def generate_id
          redis.incr(self.class.redis_key(:uid))
        end
      
        def known_indexes
          attributes.keys & self.class.indexes
        end
      
        def redis
          self.class.redis
        end
    
        def redis_key(*args)
          self.class.redis_key(id, *args)
        end
      
        def serialized_attributes
          self.class.serialize
        end
      
        def serialize_attribute(key, value)
          return value unless serialized_attributes.include?(key)
          value.to_json
        end
      
        def deserialize_attribute(key, value)
          return value unless serialized_attributes.include?(key)
          JSON.parse(value)
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
    
        def create
          self.id ||= generate_id
          self.new_record = false
          redis_set
          create_indexes
          redis.set_add(self.class.redis_key, self.id)
          save_previous_changes
          self.id
        end
      
        def update
          destroy_indexes
          redis_set
          create_indexes
          save_previous_changes
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