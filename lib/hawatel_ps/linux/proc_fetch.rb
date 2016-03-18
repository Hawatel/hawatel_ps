module HawatelPS
  module Linux
    class ProcFetch
      class << self

        # Genererate ProcInfo objects list
        #
        # @example
        #  get_process.each do |process|
        #   p process.pid
        #  end
        #
        # @return [Array<ProcInfo>] - list current running processes
        def get_process
          proc_table = Array.new
          memtotal   = memory_total
          sockets    = open_ports
          Dir.foreach("/proc").each do |pid|
             if is_numeric?(pid)
               attrs = Hash.new
               attrs[:pid] = pid.to_i
               attrs[:cwd] = process_cwd(pid)
               attrs[:username] = process_username(pid)
               attrs[:cmdline]  = process_cmdline(pid)
               attrs[:ctime]    = process_ctime(pid)
               attrs[:limits]   = process_limits(pid)
               attrs[:environ]  = process_env(pid)
               attrs[:childs]   = Array.new
               process_io(attrs)
               process_files(attrs, sockets)
               process_status(attrs)
               process_stat(attrs)
               attrs[:memory_percent] = memory_percent(attrs, memtotal)
               proc_table << attrs
             end
          end
          return proc_table
        end

        private
        # @see https://www.kernel.org/doc/Documentation/filesystems/proc.txt Table 1-2
        # Get process attributes from /proc/<pid>/status file and save in Hash container
        #
        # @example
        #  process_status(Hash)
        # @param attrs [Hash] hash list contains process attributes
        def process_status(attrs)
          status_file = "/proc/#{attrs[:pid]}/status"
          File.foreach(status_file).each do |attr|
            if attr =~ /Name:/
              attrs[:name] = attr.split(' ')[1]
            elsif attr =~ /PPid:/
              attrs[:ppid] = attr.split(' ')[1].to_i
            elsif attr =~ /State:/
              attrs[:state] = attr.split(' ')[2].to_s.chop[1..-1]
            elsif attr =~ /Uid:/
              attrs[:ruid] = attr.split(' ')[1].to_i
              attrs[:euid] = attr.split(' ')[2].to_i
              attrs[:suid] = attr.split(' ')[3].to_i
              attrs[:fsuid] = attr.split(' ')[4].to_i
            elsif attr =~ /Gid:/
              attrs[:gid] = attr.split(' ')[1].to_i
              attrs[:egid] = attr.split(' ')[2].to_i
              attrs[:sgid] = attr.split(' ')[3].to_i
              attrs[:fsgid] = attr.split(' ')[4].to_i
            elsif attr =~ /Threads:/
              attrs[:threads] = attr.split(' ')[1].to_i
            elsif attr =~ /VmSize:/
              attrs[:vmsize] = attr.split(' ')[1].to_i
            elsif attr =~ /VmRSS:/
              attrs[:vmrss] = attr.split(' ')[1].to_i
            elsif attr =~ /VmData:/
              attrs[:vmdata] = attr.split(' ')[1].to_i
            elsif attr =~ /VmSwap:/
              attrs[:vmswap] = attr.split(' ')[1].to_i
            elsif attr =~ /VmLib:/
              attrs[:vmlib] = attr.split(' ')[1].to_i
            end
          end
        end

        # @note read access to io file are restricted only to owner of process
        # Read I/O attributes from /proc/<pid>/io file and save in attrs container
        #
        # @example
        #  attrs = Hash.new
        #  process_io(Hash)
        #  p attrs[:wchar]
        #
        # @param attrs [Hash] hash list contains process attributes
        def process_io(attrs)
          process_io_set_nil(attrs)
          io_file = "/proc/#{attrs[:pid]}/io"
          if File.readable?(io_file)
            File.foreach(io_file).each do |attr|
              name = attr.split(' ')[0].chop
              attrs[:"#{name}"] = attr.split(' ')[1].to_i
            end
          end
        end

        # Set default value for i/o attributes in attrs container
        #
        # @param attrs [Hash] hash list contains process attributes
        def process_io_set_nil(attrs)
          ['rchar','wchar','syscr','syscw','read_bytes','write_bytes','cancelled_write_bytes'].each do |attr|
            attrs[:"#{attr}"] = 'Permission denied'
          end
        end

        # @see https://www.kernel.org/doc/Documentation/filesystems/proc.txt
        # Read statistics from /proc/<pid>/stat file and save in attrs container
        #
        # @example
        #  container = Hash.new
        #  process_stat(container)
        #
        # @param attrs [Hash] hash list contains process attributes
        def process_stat(attrs)
          stat_file = "/proc/#{attrs[:pid]}/stat"
          if File.readable?(stat_file)
            File.foreach(stat_file).each do |line|
              attr = line.split(' ')
              attrs[:utime] = attr[13].to_i
              attrs[:stime] = attr[14].to_i
              attrs[:cpu_time] = (attrs[:utime] +  attrs[:stime])
              attrs[:cpu_percent] = cpu_percent({:cpu_time => attrs[:cpu_time], :proc_uptime => attr[21].to_i })
            end
          end
        end

        # Get ctime of process from pid file timestamp
        #
        # @example
        #  process_ctime(122)
        #
        # @param pid [Fixnum] process pid
        # @return [aTime]
        def process_ctime(pid)
          pid_dir = "/proc/#{pid}"
          (Dir.exist?(pid_dir)) ? File.ctime(pid_dir) : 0
        end

        # @note read access to cwd file are restricted only to owner of process
        # Get current work directory
        #
        # @example
        #  process_cwd(323)
        #
        # @param pid [Fixnum] process pid
        # @return [String]
        def process_cwd(pid)
          cwd_file = "/proc/#{pid}/cwd"
          (File.readable?(cwd_file)) ? File.readlink(cwd_file) : 'Permission denied'
        end

        # @note read access to io file are restricted only to owner of process
        # Get command line arguments
        #
        # @example
        #  process_cmdline(312)
        #
        # @param pid [Fixnum] process pid
        # @return [String]
        def process_cmdline(pid)
          cmdline_file = "/proc/#{pid}/cmdline"
          if File.readable?(cmdline_file)
            File.foreach(cmdline_file).each do |line|
              return line
            end
          else
            'Permission denied'
          end
        end

        # Get soft and hard limits for process from limits file
        #
        # @example
        #  p = process_limits('312')
        #
        #  p.limits.each do |limit|
        #    puts "#{limit[name]} #{limit[:soft]} #{limit[:hard]}"
        #  end
        #
        # @param pid [Fixnum] process pid
        # @return [Array<Hash>]
        def process_limits(pid)
          limits_file = "/proc/#{pid}/limits"
          limits_list = Array.new
          if File.readable?(limits_file)
            File.foreach(limits_file).each do |line|
              next if (line =~ /Limit/)
              line_split = line.split(' ')
              if line.split(' ')[1] == 'processes'
                lname = "#{line_split[1]}"
                lsoft = "#{line_split[2]} #{line_split[4]}"
                lhard = "#{line_split[3]} #{line_split[4]}"
              else
                lname = "#{line_split[1]}_#{line_split[2]}"
                if line.split(' ')[5]
                  lsoft = "#{line_split[3]} #{line_split[5]}"
                  lhard = "#{line_split[4]} #{line_split[5]}"
                else
                  lsoft = "#{line_split[3]}"
                  lhard = "#{line_split[4]}"
                end
              end
              limits_attrs = { :name => "#{lname}", :soft => "#{lsoft}", :hard => "#{lhard}" }
              limits_list << limits_attrs
            end
          else
            limits_list = ['Permission denied']
          end
          limits_list
        end

        # @note read access to fd directory are restricted only to owner of process
        # Get & set open files and sockets from fd directory in attrs container
        #
        # @param attrs [Hash] hash list contains process attributes
        # @param sockets [Array<Hash>] list sockets from /proc/net/tcp /proc/net/udp file
        def process_files(attrs, sockets)
          fd_dir  = "/proc/#{attrs[:pid]}/fd"
          files   = Array.new
          ports   = Array.new
          if File.readable?(fd_dir)
            Dir.foreach(fd_dir).each do |fd|
              if is_numeric?(fd)
                file = File.readlink("#{fd_dir}/#{fd}")
                attrs[:tty] = file if fd == '0'
                if file =~ /^\// && file !~ /^\/(dev|proc)/
                  files << file
                elsif file =~ /socket/
                  net_listen = compare_socket(file, sockets)
                  if net_listen; ports << net_listen end
                end
              end
            end
            attrs[:open_files] = files
            attrs[:listen_ports] = ports
          else
            attrs[:open_files] = 'Permission denied'
            attrs[:listen_ports] = 'Permission denied'
            attrs[:tty] = 'Permission denied'
          end
        end

        # Match socket id from /proc/<pid>/fd with /proc/net/(tcp|udp)
        #
        # @return [String] containing matched protocol,ip and port (example: tcp:127.0.0.1:8080)
        def compare_socket(file, sockets)
          sockets.each do |socket|
            return "#{socket[:protocol]}:#{socket[:address]}:#{socket[:port]}" if file =~ /#{socket[:id]}/
          end
          return nil
        end

        # @note read access to fd directory are restricted only to owner of process
        # Get environment variables from environ file
        #
        # @example
        #  process_cmdline(312)
        #
        # @param pid [Fixnum] process pid
        # @return [String]
        def process_env(pid)
          environ_file = "/proc/#{pid}/environ"
          if File.readable?(environ_file)
            File.foreach(environ_file).each do |line|
              return line.split("\x0")
            end
          else
            'Permission denied'
          end
        end

        # Calculate %CPU usage per process
        #
        # @param attrs [Hash] hash list contains process attributes
        #  @option proc_uptime [Integer] - process uptime
        #  @option cpu_time [Integer] total cpu time spend in kernel and user mode
        # @return [Float] average process cpu usage from start
        def cpu_percent(attrs)
          hertz = cpu_tck
          sec = uptime - attrs[:proc_uptime] / hertz
          if attrs[:cpu_time] > 0 && sec > 0
            cpu = (attrs[:cpu_time] * 1000 / hertz) / sec
            "#{cpu / 10}.#{cpu % 10}".to_f
          else
            return 0.0
          end
        end

        # Check if object is numeric
        #
        # @example
        #  is_numeric?('2323')
        #
        # @return [Boolen]
        def is_numeric?(obj)
          obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
        end

        # Return the number of clock ticks
        #
        # @example
        #  cpu_tck()
        #
        # @return [Integer]
        def cpu_tck
          `getconf CLK_TCK`.to_i
        rescue
          return 100
        end

        # Get process uid and return username from passwd file
        #
        # @example
        #  process_username(132)
        #
        # @param pid [Fixnum] process pid
        # @return [String]
        def process_username(pid)
          uid = File.stat("/proc/#{pid}").uid
          File.foreach('/etc/passwd').each do |line|
            if line.split(':')[2] == "#{uid}"
              return line.split(':')[0]
            end
          end
        end

        # Get list open tcp/upd ports from net/tcp and net/udp file and replace to decimal
        #
        # @example
        #  sockets = open_ports()
        #  sockets.each do |socket|
        #     puts "#{socket[:address]} #{socket[:port]}"
        #  end
        #
        # @return [Array<Hash>] list all used tcp/udp sockets
        def open_ports
          socket_list  = Array.new
          ['tcp','udp'].each do |protocol|
            File.foreach("/proc/net/#{protocol}").each do |line|
              hex_port = line.split(' ')[1].split(':')[1]
              hex_ip   = line.split(' ')[1].split(':')[0].scan(/../)
              socketid = line.split(' ')[9]
              if hex_port =~ /$$$$/
                hex_ip.map! { |e| e.to_i(16) }
                socket_attrs = { :address => "#{hex_ip[3]}.#{hex_ip[2]}.#{hex_ip[1]}.#{hex_ip[0]}",
                                 :port => hex_port.to_i(16),
                                 :protocol => protocol,
                                 :id => socketid }
                socket_list << socket_attrs
              end
            end
          end
          return socket_list
        end

        # Return system uptime in second
        #
        # @example
        #  uptime()
        #
        # @return [Integer]
        def uptime
          File.foreach('/proc/uptime').each do |line|
            return line.split[0].to_i
          end
        end

        # Calculate percent of memory usage by process
        #
        # @example
        #  memory_percent(container,'')
        #
        # @param attrs [Hash] hash list contains process attributes
        # @option :vmrss [Fixnum] rss memory allocated by process
        # @param memtotal [Integer] total usable RAM
        # @return [Float]
        def memory_percent(attrs, memtotal)
          if attrs[:vmrss]
            return (attrs[:vmrss].to_f / memtotal.to_f * 100).round(2)
          else
            nil
          end
        end

        # Get total physical memory (RAM) size
        #
        # @example
        #  memory_total
        #
        # @return [Integer]
        def memory_total
          File.foreach('/proc/meminfo').each do |line|
            return line.split(' ')[1].to_i if line =~ /MemTotal:/
          end
        end

      end
    end
  end
end