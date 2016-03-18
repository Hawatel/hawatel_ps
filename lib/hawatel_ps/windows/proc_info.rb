module HawatelPS
  module Windows
    ##
    # = Process Information
    class ProcInfo < ProcControl
      # Process instance with attributes of that process
      # @param proc_attrs [Hash] attributes of the process
      # @return [void]
      def initialize(proc_attrs)
        @proc_attrs = proc_attrs
        define_attributes(proc_attrs)
      end

      # Make attributes of public.
      # Access to process attribute from an object instance by index of array.
      # @example
      #   p = ProcInfo.new(proc_attrs)
      #   puts p['processid']
      def [](key)
        key = key.to_s.downcase.to_sym if !key.is_a?(Symbol)
        @proc_attrs[key.downcase]
      end

      # Calls the given block once for each element in self, passing that element as a parameter.
      # @param &block
      # @example print all attributes of process
      #   p = ProcInfo.new(proc_attrs)
      #   proc.each {|key, val| puts "#{key} - #{val}"}
      # @return An Enumerator is returned if no block is given.
      def each(&block)
        @proc_attrs.each(&block)
      end

      # @see ProcInfo#define_attributes
      def metaclasses
        class << self; self; end
      end

      private
      # Make attributes of public.
      # Access  to process attribute from an object instance by public method where names of attributes are methods.
      # @example
      #   p = ProcInfo.new(proc_attrs)
      #   puts p.processid
      def define_attributes(hash)
        hash.each_pair do |key, value|
          metaclasses.send(:attr_reader, key.to_sym)
          instance_variable_set("@#{key}", value)
        end
      end
    end
  end
end