module HawatelPS
  module Windows
    ##
    # = Process Fetch
    #
    # Provides functionality to fetch process information from raw source using WMI client.
    class ProcFetch
      class << self
        # Return attributes of all processes from WMI
        #
        # Each process has attributes which are standardized in this document:
        # https://msdn.microsoft.com/en-us/library/windows/desktop/aa394372
        # Each attribute name is converted to lowercase.
        #
        # @example Get process list (access to attributes by index array)
        #   processes = get_process()
        #   processes.each do | process |
        #     pid = process['processid']
        #     name = process['name']
        #     puts "#{pid.to_s.ljust(10)} #{name}"
        #   end
        #
        # @example Get process list (access to attributes by methods)
        #   processes = get_process()
        #   processes.each do | process |
        #     pid = process.processid
        #     name = process.name
        #     puts "#{pid.to_s.ljust(10)} #{name}"
        #   end
        #
        # @return [Array<Hash>]
        def get_process(args = nil)
          if args.nil?
            wql = prepare_wql("SELECT * FROM Win32_Process")
          else
            wql = prepare_wql('SELECT * FROM Win32_Process', args)
          end

          proc_table = Array.new

          @users_list = get_users
          @system_info = system_info
          @memory_total = @system_info[:totalvisiblememorysize]
          @system_idle_time = system_idle_time

          WmiCli.new.query(wql).each do |proc_instance|
            proc = extract_wmi_property(proc_instance)
            # if proces no longer exists it won't be added to the resulting array
            # sometimes it happens when the Win32_Process query returned process but
            # when this program tries invoke execMethod_ on it the WmiCli class raises an exception
            # because the process disappeared
            proc_table.push(proc) if !proc.nil?
          end
          proc_table
        end

        private

        # Prepare WMI Query Language
        # @param query [String] WQL string
        # @param args [Hash] conditions to WHERE clause (conditions are combined only with AND operator)
        # @option name [Type] :opt description
        # @example
        #   prepare_wql('SELECT * FROM Win32_Process')
        #   prepare_wql('SELECT * FROM Win32_Process', {:processid => 1020})
        #   prepare_wql('SELECT * FROM Win32_Process', {:name => 'notepad.exe', :executablepath => 'C:\\\\WINDOWS\\\\system32\\\\notepad.exe'})
        # @return [String] WQL string
        def prepare_wql(query, args = nil)
          if args.nil?
            return query
          else
            query += " WHERE "
            args.each_with_index do |(k, v), index|
              if index == 0 && args.length == 1
                query += "#{k.to_s.downcase} = '#{v}'"
              elsif index == args.length - 1
                query += "#{k.to_s.downcase} = '#{v}'"
              else
                query += "#{k.to_s.downcase} = '#{v}' AND "
              end
            end
            return query
          end
        end

        # Get property from WIN32OLE object about process
        # @param wmi_object [WmiCli::Instance] process instance represented by WMI object
        # @example
        #   extract_wmi_property(wmi_object)
        # @return [Hash]
        def extract_wmi_property(wmi_object)
          property_map = wmi_object.properties.dup
          property_map[:wmi_object] = wmi_object.wmi_ole_object
          property_map[:childs] = Array.new

          property_map[:sid] = get_owner_sid(wmi_object)

          get_owner(property_map)
          property_map[:availablevirtualsize] = get_avail_virtual_size(wmi_object)
          property_map[:memorypercent] = memory_percent(@memory_total, property_map[:workingsetsize])

          property_map[:cpupercent] = cpu_percent(cpu_time(
              :usermodetime => property_map[:usermodetime],
              :kernelmodetime => property_map[:kernelmodetime]))

          hash_value_to_string(property_map)

          property_map.delete(:status) if property_map.key?(:status)

          property_map
        end

        # Convert hash values to string if is the Integer type
        # @param hash [Hash]
        def hash_value_to_string(hash)
          hash.each {|k,v| hash[k] = v.to_s if v.is_a?(Integer)}
        end

        # Get users list from Win32_UserAccount class
        # @return [Hash] @users_list
        def get_users
          users_list = Hash.new
          WmiCli.new.query('SELECT * FROM Win32_UserAccount').each do |user|
            users_list[user.properties[:sid]] = user.properties if !user.nil?
          end
          users_list
        end

        # Find information about user
        # instance variable @users_list must be set {get_users}
        # @param property_map [Hash] Atributes of process
        def get_owner(property_map)
          property_map[:user] = nil
          property_map[:domain] = nil

          if !property_map[:sid].nil? and !@users_list[property_map[:sid]].nil?
            property_map[:user] = @users_list[property_map[:sid]][:name]
            property_map[:domain] = @users_list[property_map[:sid]][:domain]
          end
        end

        # Invoke GetOwnerSid method of the Win32_Process class
        # @see https://msdn.microsoft.com/pl-pl/library/windows/desktop/aa390460
        # @param wmi_object [WmiCli::Instance] process instance represented by WMI object
        # @return [String] SID of user
        # @reutrn [nil] if wmi_object no longer exists
        def get_owner_sid(wmi_object)
          # performance problem (it takes ~10 seconds but the native wmi takes similar time)
          owner = wmi_object.execMethod('GetOwnerSid')
          return owner.Sid if !owner.nil?
        rescue WmiCliException
          return nil
        end

        # Invoke GetAvailableVirtualSize method of the Win32_Process class
        # @see https://msdn.microsoft.com/en-us/library/windows/desktop/dn434274
        # @param wmi_object [WmiCli::Instance] process instance represented by WMI object
        # @return [String] AvailableVirtualSize from WMI
        # @reutrn [nil] if wmi_object no longer exists
        def get_avail_virtual_size(wmi_object)
          obj = wmi_object.execMethod('GetAvailableVirtualSize')
          return obj.AvailableVirtualSize.to_s if !obj.nil?
        rescue WmiCliException
          return nil
        end

        # System information from Win32_OperatingSystem class
        # @return [Hash]
        def system_info
          WmiCli.new.query('SELECT * FROM Win32_OperatingSystem').each do |result|
           return result.properties if !result.nil?
          end
        end

        # Return percent of memory usage by process
        # @return [String]
        def memory_percent(mem_total_kb, workingsetsize)
          if !mem_total_kb.nil? && !workingsetsize.nil? && mem_total_kb.to_i > 0
            rss_kb = workingsetsize.to_f / 1024
            return (rss_kb / mem_total_kb.to_f * 100).round(2).to_s
          end
        end

        # Calculate cpu time for System Idle Process
        # @return [Integer] system idle time in seconds
        def system_idle_time
          WmiCli.new.query("SELECT KernelModeTime FROM Win32_Process WHERE ProcessId = '0'").each do |idle|
            return (idle.properties[:kernelmodetime].to_i / 10000000)
          end
          return nil
        end

        # Calculate %CPU usage per process
        # @param cpu_time [String/Integer] CPU time consumed by process since system boot
        # @return [String] %CPU usage per process since system boot
        def cpu_percent(cpu_time)
          if !cpu_time.zero?
            return (( cpu_time.to_f  / @system_idle_time.to_f) * 100).round(2).to_s
          else
            return "0.0"
          end
        end

        # Reports processor use time, in seconds, for each process running on a computer.
        # @see https://msdn.microsoft.com/en-us/library/windows/desktop/aa394599(v=vs.85)
        # @param args [Hash] attributes
        # @option opt [String/Integer] User Mode Time
        # @option opt [String/Integer] Kernel Mode Time
        # @return [Integer] processor time for a process in seconds
        def cpu_time(args)
          return ((args[:usermodetime].to_i + args[:kernelmodetime].to_i) / 10000000)
        end
      end
    end
  end
end