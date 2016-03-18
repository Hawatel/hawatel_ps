module HawatelPS
  module Windows
    ##
    # = Process Control
    class ProcControl

      # Check current process status
      #
      # @example
      #   p = HawatelPS.search_by_name('notepad.exe')
      #   p.status
      #
      # @return [String] 'running' or 'not running'
      def status
        Process.kill 0, @proc_attrs[:processid].to_i
        return "running"
      rescue Errno::ESRCH
        return "not running"
      rescue Errno::EPERM
        return 'non-privilaged operation'
      end

      # Terminate process
      # @example
      #   p = HawatelPS.search_by_pid('1020')
      #   p.terminate
      # @return [Integer] return source: https://msdn.microsoft.com/en-us/library/windows/desktop/aa393907
      #   * Successful completion (0)
      #   * Process not found (1)
      #   * Access denied (2)
      #   * Insufficient privilege (3)
      #   * Unknown failure (8)
      #   * Path not found (9)
      #   * Invalid parameter (21)
      #   * Other (22–4294967295)
      def terminate
        return @proc_attrs[:wmi_object].Terminate if @proc_attrs[:wmi_object].ole_respond_to?('Terminate')
      rescue WIN32OLERuntimeError
        return 1
      end

    end
  end
end
