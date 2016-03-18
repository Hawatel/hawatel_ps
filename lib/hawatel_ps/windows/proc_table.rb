module HawatelPS
  module Windows
    ##
    # = Process Table
    class ProcTable
      class << self

        # Return attributes of searched process based on pid
        # @example
        #   search_by_pid(1761)
        # @param [Integer] pid of process
        # @return [ProcInfo]
        def search_by_pid(pid)
          find_by_pid(pid)
          @proc_table.each do |process|
            return process if process.processid.to_s == pid.to_s
          end
          return nil
        end


        # Return attributes of searched process based on name or cmdline
        # @example
        #   search_by_name('java.exe')
        #   search_by_name('/^regex/')
        # @param process_name[String] name of process
        # @return [Array<ProcInfo>]
        def search_by_name(process_name)
          if process_name =~ /^\/.*\/$/
            process_name.slice!(0)
            process_name = Regexp.new(/#{process_name.chop}/)
            find_all
          else
            find_by_name(process_name)
          end

          process_list = Array.new

          @proc_table.each do |process|
            if process_name.is_a? Regexp
              process_list << process if process.name =~ process_name || process.commandline =~ process_name
            else
              process_list << process if process.name.to_s.downcase == "#{process_name.to_s.downcase}" || process.commandline.to_s.downcase == "#{process_name.to_s.downcase}"
            end
          end

          process_list = nil if process_list.empty?

          return process_list
        end

        # Return attributes of searched by process
        #
        # @example
        #   search_by_condition(:attrs => 'workingsetsize', :oper => '<', value => '10000')
        #
        # @param args[Hash] attributes for search condition
        #   @attrs [String], name of process attribute (first expression for if)
        #   @oper  [String], operatator, available options: >,<,>=,<=,==,!=
        #   @value [String], value comparable (second expression for if)
        #
        # @return [Array<ProcInfo>]
        def search_by_condition(args)
          find_all

          attrs = args[:attr]
          oper  = args[:oper]
          value = args[:value]
          process_list = Array.new
          @proc_table.each do |process|
            if oper == '>'
              process_list << process if process[:"#{attrs}"] > value
            elsif oper == '<'
              process_list << process if process[:"#{attrs}"] < value
            elsif oper == '>='
              process_list << process if process[:"#{attrs}"] >= value
            elsif oper == '<='
              process_list << process if process[:"#{attrs}"] <= value
            elsif oper == '=='
              process_list << process if process[:"#{attrs}"] == value
            elsif oper == '!='
              process_list << process if process[:"#{attrs}"] != value
            end
          end

          process_list = nil if process_list.empty?

          return process_list
        end

        # Return all process instances
        # @return [Array<ProcInfo>]
        def proc_table
          find_all
          return @proc_table
        end

        private
        # Refresh processes array by pid
        def find_by_pid(pid)
          @proc_table = Array.new
          ProcFetch.get_process(:processid => pid).each do |proc_attrs|
            @proc_table.push(ProcInfo.new(proc_attrs))
          end
          childs_tree
        end

        # Refresh processes array by name
        def find_by_name(name)
          @proc_table = Array.new
          ProcFetch.get_process({:name => name}).each do |proc_attrs|
            @proc_table.push(ProcInfo.new(proc_attrs))
          end
          childs_tree
        end

        # Refresh processes array
        def find_all
          @proc_table = Array.new
          ProcFetch.get_process.each do |proc_attrs|
            @proc_table.push(ProcInfo.new(proc_attrs))
          end
          childs_tree
        end

        # Get process childs
        def childs_tree
          @proc_table.each do |proc_parent|
            @proc_table.each do |proc_child|
              if proc_parent.processid === proc_child.parentprocessid
                proc_parent[:childs].push(proc_child)
              end
            end
          end
        end

      end
    end
  end
end