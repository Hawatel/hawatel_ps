module HawatelPS
  module Windows
    class WmiCli
      ##
      # = Instance of Windows Management Instrumentation client
      #
      # Container of single WIN32OLE object wih parameters of this object
      #
      # @!attribute [r] wmi_ole_object
      #   @return [WIN32OLE] WMI Object
      # @!attribute [r] properties
      #   @return [Hash] Properties from WIN32OLE object
      class Instance
        attr_reader :wmi_ole_object, :properties

        # Create instance of WmiClient class with WIN32OLE object
        # @param wmi_ole_object [WIN32OLE] Single WMI32OLE object
        def initialize(wmi_ole_object)
          @wmi_ole_object = wmi_ole_object
          @properties = extract_props_to_hash(wmi_ole_object)
        end

        # Execute WIN32OLE method
        # @see https://msdn.microsoft.com/en-us/library/windows/desktop/aa393774
        # @param name [String] WMI method name assigned to WIN32OLE object
        # @example Object if from Win32_Process class and it has 'GetOwner' method
        #   wmi_object.execMethod('GetOwner')
        # @return [WIN32OLE]
        def execMethod(name)
          return @wmi_ole_object.execMethod_(name) if @wmi_ole_object.ole_respond_to?('execMethod_')
        rescue WIN32OLERuntimeError => ex
          raise WmiCliException, :exception => ex, :message => "Cannot invoke execMethod_('#{name}')"
        end

        private

        # Get property from WIN32OLE object
        # @param wmi_object [WIN32OLE] WMI object
        # @example
        #   extract_props_to_hash(wmi_object)
        # @return [Hash]
        def extract_props_to_hash(wmi_obj)
          properties = {}
          #binding.pry
          if wmi_obj.ole_respond_to?('properties_')
            wmi_obj.properties_.each do |property|
              properties[property.name.downcase.to_sym] = property.value
            end
            properties.freeze
          end
        end

      end
    end
  end
end