module SuperModel
  module Redis
    module ClassMethods
      def self.extended(base)
        base.class_eval do
          class_inheritable_array :indexed_attributes
          self.indexed_attributes = []
                    
          class_inheritable_hash :redis_options
          self.redis_options = {}
        end
      end
      
      def namespace
        @namespace ||= self.name.downcase
      end
      
      def namespace=(namespace)
        @namespace = namespace
      end
      
      def redis
        @redis ||= ::Redis.connect(redis_options)
      end
      
      def indexes(*indexes)
        self.indexed_attributes += indexes.map(&:to_s)
      end
            
      def redis_key(*args)
        args.unshift(self.namespace)
        args.join(":")
      end
      
      def find(id)
        if redis.sismember(redis_key, id.to_s)
          existing(:id => id)
        else
          raise UnknownRecord, "Couldn't find #{self.name} with ID=#{id}"
        end
      end
      
      def first
        item_ids = redis.sort(redis_key, :order => "ASC", :limit => [0, 1])
        item_id  = item_ids.first
        item_id && existing(:id => item_id)        
      end
      
      def last
        item_ids = redis.sort(redis_key, :order => "DESC", :limit => [0, 1])
        item_id  = item_ids.first
        item_id && existing(:id => item_id)        
      end
      
      def exists?(id)
        redis.sismember(redis_key, id.to_s)
      end
      
      def count
        redis.scard(redis_key)
      end
      
      def all
        from_ids(redis.sort(redis_key))
      end
      
      def select
        raise "Not implemented"
      end
      
      def delete_all
        raise "Not implemented"
      end
      
      def find_by_attribute(key, value)
        item_ids = redis.sort(redis_key(key, value.to_s))
        item_id  = item_ids.first
        item_id && existing(:id => item_id)
      end
      
      def find_all_by_attribute(key, value)
        from_ids(redis.sort(redis_key(key, value.to_s)))
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
      protected
        def raw_destroy
          return if new?

          destroy_indexes
          redis.srem(self.class.redis_key, self.id)
          redis.del(redis_key)
        end
      
        def destroy_indexes
          indexed_attributes.each do |index|
            old_attribute = changes[index].try(:first) || send(index)
            redis.srem(self.class.redis_key(index, old_attribute), id)
          end
        end
      
        def create_indexes
          indexed_attributes.each do |index|
            new_attribute = send(index)
            redis.sadd(self.class.redis_key(index, new_attribute), id)
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
      
        def redis_set
          redis.set(redis_key, serializable_hash.to_json)
        end
      
        def redis_get
          load(ActiveSupport::JSON.decode(redis.get(redis_key)))
        end
        public :redis_get
    
        def raw_create
          redis_set
          create_indexes
          redis.sadd(self.class.redis_key, self.id)
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