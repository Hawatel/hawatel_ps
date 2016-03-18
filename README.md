[![Build Status](https://travis-ci.org/Hawatel/hawatel_ps.svg?branch=master)](https://travis-ci.org/Hawatel/hawatel_ps)
[![Code Climate](https://codeclimate.com/github/Hawatel/hawatel_ps/badges/gpa.svg)](https://codeclimate.com/github/Hawatel/hawatel_ps)
[![Test Coverage](https://codeclimate.com/github/Hawatel/hawatel_ps/badges/coverage.svg)](https://codeclimate.com/github/Hawatel/hawatel_ps/coverage)
[![Inline docs](http://inch-ci.org/github/Hawatel/hawatel_ps.svg?branch=master)](http://inch-ci.org/github/Hawatel/hawatel_ps)
[![Gem Version](https://badge.fury.io/rb/hawatel_ps.svg)](https://badge.fury.io/rb/hawatel_ps)

# HawatelPS

## Summary
**HawatelPS** (hawatel_ps) is a Ruby gem for retrieving information about **running processes**. It is easy to use, and you can get useful information about a process. You can `terminate`, `suspend`, `resume` and check the `status` of the process on Linux platform. On Windows platform, you can `terminate` and check the current `status` of the process.

* On Linux platform, the HawatelPS collects all information from pseudo-file system /proc, and it is **free from any gem dependencies**.
* On Windows platform the HawatelPS collects all information from WMI (Windows Management Instrumentation), and it is **free from any gem dependencies**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hawatel_ps'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hawatel_ps

## Example usage
###### Find process with specified PID
```ruby
process = HawatelPS.search_by_pid(123)
p process.name if !process.nil?
```
###### Get list all running processes
```ruby
processes = HawatelPS.proc_table
```
###### Find processes which matching a certain name
``` ruby
processes = HawatelPS.search_by_name('ruby')
processes.each do |process|
  p "PID: #{process.pid}"
end
```
###### Find processes where vmsize attribute is equal or greater than 2000 kb
```ruby
processes = HawatelPS.search_by_condition(attr => 'vmsize', oper => '>=', value => '2000')
processes.each do |process|
  p process.pid
end
```
###### Suspend processes which name matching with regular expression
``` ruby
processes = HawatelPS.search_by_name('/^ruby/')
processes.each do |process|
  p process.suspend
end
```
###### Resume stopped processes
``` ruby
processes = HawatelPS.search_by_condition(attr => 'state', oper => '==', value => 'stopped')
processes.each do |process|
  p process.resume
end
```
###### Terminate processes which using more that 60% CPU
``` ruby
processes = HawatelPS.search_by_condition(attr => 'cpu_percent', oper => '>', value => '60')
processes.each do |process|
  p process.terminate
end
```

## Process attributes
####  Linux 
**NOTE:** In case lack of permission to retrieving specified information, the attribute should return a string with the message "Permission denied."

| Attribute name        | Description  |
| ------------- |-------------| 
| cancelled_write_bytes | Cancelled write bytes. |
| childs |Childs of the process.|
| cmdline | Command line arguments. |
| cpu_percent |  Average percent cpu usage since start. | 
| cpu_time | Total cpu time. |
| ctime | Create process time. |
| cwd   | Current working directory. | 
| egid  |  Effective GID. |
| environ  | Environment of the process. |
| euid | Effective UID. |
| exe  | Filename of the executable.     |
| fsgidl |  File system GID. |
| fsuid |  File system UID. |
| limits |  Limits |
| listen_ports | List ports on which process listening. | 
| memory_percent | Percent total memory usage by process. |
| open_files | List open files by process (exclude /proc & /dev). |
| pid        |  Process id.  |
| ppid         | Process id of the parent process. |      
| rchar |  Chars read. |
| read_bytes | Bytes read. |
| rgid  | Real GID. |
| ruid | Real UID. |
| sgid  | Saved set GID. |
| state  | State of process (running, stopped, ….).      |
| stime | Kernel mode jiffies. |
| suid | Saved set UID. |
| syscr |  Read syscalls (numer of read  I/O operations). | 
| syscw | Write syscalls (numer of write I/O operations). |
| threads  | Numer of threads. |
| tty |  Controlling tty (terminal). |
| username | The user name of the owner of this process. |
| utime | User mode jiffies. |
| vmdata | Size of private data segments. |
| vmlib  | Size of shared library code. |
| vmrss |  Size of memory portions. |
| vmsize | Total program size. |
| vmswap | Amount of swap used by process. |
| wchar |  Chars written. |
| write_bytes | Bytes written. |

#### Windows

|         Attribute name       |  Description  
|-------------------------------|-------------
availablevirtualsize           |The free virtual address space available to this process.        
caption                        |Short description of an process one-line string.
childs                         |Childs of the process.              
commandline                    |Command line used to start a specific process, if applicable.
cpupercent                     |Average percent cpu usage since process start.          
creationclassname              |It is always Win32_Process
creationdate                   |Date the process begins executing.               
cscreationclassname            |It is always Win32_ComputerSystem.     
csname                         |Name of the scoping computer system.               
description                    |Description of a process.               
domain                         |The domain name under which this process is running.               
executablepath                 |Path to the executable file of the process.               
executionstate                 |It is always nil.               
handle                         |Process identifier.                  
handlecount                    |Total number of open handles owned by the process. HandleCount is the sum of the handles currently open by each thread in this process.                
installdate                    |Date an object is installed. The object may be installed without a value being written to this property.               
kernelmodetime                 |Time in kernel mode, in 100 nanosecond units. If this information is not available, use a value of 0 (zero)              
maximumworkingsetsize          |Maximum working set size of the process. The working set of a process is the set of memory pages visible to the process in physical RAM.                
memorypercent                  |Average percent memory usage by the process (with shared memory, equivalent to WorkingSet in TaskManager)               
minimumworkingsetsize          |Minimum working set size of the process. The working set of a process is the set of memory pages visible to the process in physical RAM.               
name                           |Name of the executable file responsible for the process, equivalent to the Image Name property in Task Manager.               
oscreationclassname            |It is always Win32_OperatingSystem.               
osname                         |Name of the scoping operating system.               
otheroperationcount            |Number of I/O operations performed that are not read or write operations.               
othertransfercount             |Amount of data transferred during operations that are not read or write operations.               
pagefaults                     |Number of page faults that a process generates.               
pagefileusage                  |Amount of page file space that a process is using currently. This value is consistent with the VMSize value in TaskMgr.exe.               
parentprocessid                |Unique identifier of the process that creates a process.               
peakpagefileusage              |Maximum amount of page file space used during the life of a process.                  
peakvirtualsize                |Maximum virtual address space a process uses at any one time. Using virtual address space does not necessarily imply corresponding use of either disk or main memory pages.               
peakworkingsetsize             |Peak working set size of a process.               
priority                       |Scheduling priority of a process within an operating system.               
privatepagecount               |Current number of pages allocated that are only accessible to the process represented by this Win32_Process instance.               
processid                      |Numeric identifier used to distinguish one process from another.               
quotanonpagedpoolusage         |Quota amount of nonpaged pool usage for a process.               
quotapagedpoolusage            |Quota amount of paged pool usage for a process.               
quotapeaknonpagedpoolusage     |Peak quota amount of nonpaged pool usage for a process.               
quotapeakpagedpoolusage        |Peak quota amount of paged pool usage for a process.               
readoperationcount             |Number of read operations performed.               
readtransfercount              |Amount of data read.               
sessionid                      |Unique identifier that an operating system generates when a session is created. A session spans a period of time from logon until logoff from a specific system.               
sid                            |The security identifier descriptor for the owner of this process.               
status                         |State of a process ('running' or 'not running')             
terminationdate                |Process was stopped or terminated. To get the termination time, a handle to the process must be held open. Otherwise, this property returns NULL.               
threadcount                    |Number of active threads in a process.               
user                           |The user name of the owner of this process.                  
usermodetime                   |Time in user mode, in 100 nanosecond units. If this information is not available, use a value of 0 (zero).               
virtualsize                    |Current size of the virtual address space that a process is using, not the physical or virtual memory actually used by the process.               
windowsversion                 |Version of Windows in which the process is running.                  
wmi_object                     |Native WMI Object represented by the process.               
workingsetsize                 |Amount of memory in bytes that a process needs to execute efficiently—for an operating system that uses page-based memory management.               
writeoperationcount            |Number of write operations performed.               
writetransfercount             |Amount of data written.    


## Contributing

See [CONTRIBUTING](CONTRIBUTING.md)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
