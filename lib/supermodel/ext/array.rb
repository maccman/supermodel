class Array
  unless defined?(deep_dup)
    def deep_dup
      Marshal.load(Marshal.dump(self))
    end
  end
end