require 'win32ole'
require 'hawatel_ps/windows/wmi/wmi_instance'
require 'hawatel_ps/windows/wmi/wmi_exception'

module HawatelPS
  module Windows
    ##
    # = Windows Management Instrumentation Client
    #
    # This is wrapper for WMI with limited functionalities (only call queries)
    class WmiCli
      # Init WMI namespace
      # @param namespace [String] WMI namespace
      def initialize(namespace = nil)
        @namespace = namespace.nil? ? 'root/cimv2' : namespace
        @session = nil
      end

      # Call WMI query
      # @param wql_query [String] WMI Query Language string
      # @example
      #   WmiCli.new.query('SELECT * FROM Win32_Process')
      # @raise [WmiCliException] if WQL Query is wrong
      # @return [WmiCli::Instance]
      def query(wql_query)
        connect_to_namespace
        results = @session.ExecQuery(wql_query)

        return create_wmi_ole_instances(results)
      rescue WIN32OLERuntimeError => ex
        raise WmiCliException, :exception => ex, :message => "Wrong result from WQL Query = '#{wql_query}'."
      end

      private

      # Connect to the WMI on the local server
      # @example
      #   connect_to_namespace
      # @raise [WIN32OLERuntimeError] if problem with connection to the local server
      # @return [WIN32OLE]
      def connect_to_namespace
        if @session.nil?
          locator = WIN32OLE.new("WbemScripting.SWbemLocator")
          @session = locator.ConnectServer('.', @namespace)
        end
      rescue WIN32OLERuntimeError => ex
        raise WmiCliException, :exception => ex, :message => "Cannot connect to namespace '#{@namespace}'."
      end

      # Create the WMI32OLE instance from a data set.
      # @param dataset [WMI32OLE] List of WMI objects
      # @example
      #   results = @session.ExecQuery(wql_query)
      #   wmi_ole_instances = create_wmi_ole_instances(results)
      # @return [Array<WmiCli::Instance>]
      def create_wmi_ole_instances(dataset)
        instances = []
        dataset.each do |wmi_object|
          instances.push(Instance.new(wmi_object))
        end
        instances
      end
    end
  end
end