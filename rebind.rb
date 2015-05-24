# Returns the user's operating system.
# If not recognized, returns :unknown_os
# @author Jiangcheng Oliver Chu
def get_os
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    return :Windows
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    return :Mac
  elsif RbConfig::CONFIG['host_os'] =~ /linux/
    return :Linux
  elsif RbConfig::CONFIG['host_os'] =~ /bsd/
    return :BSD
  else
    return :unknown_os
  end
end

def windows_rebind(unix_command)
  if unix_command != :run_nothing && get_os == :Windows
    case unix_command
      when 'pwd'
        return 'cd'
      else
        pieces = ArgParser.new.parse(unix_command)
        unless pieces.empty?
          command = pieces[0]
          args = pieces.drop(1)
          if command == 'whereis'
            return 'where ' + args.join(' ')
          elsif command == 'cat' && pieces.length == 2
            file = File.open(pieces[1], 'r')
            println(file.read)
            file.close
          else
            prefs = Prefs.new('preferences.ini')
            if prefs.has_key?('cygwin-utils')
              cygwin_utils = Set.new(prefs['cygwin-utils'].split(','))
            else
              cygwin_utils = Set.new
            end
            if cygwin_utils.include?(command)
              cyg_path = Prefs.new('preferences.ini')['cygwin-path']
              return "#{File.join(cyg_path, command).gsub('/', '\\')} " + args.join(' ')
            end
            return unix_command
          end
        end
    end
  end
  return :run_nothing
end

def unix_rebind(command)
  pieces = ArgParser.new.parse(command)
  if pieces[0] == 'cd' && pieces.length == 2
    Dir.chdir(pieces[1])
    return :run_nothing
  end
  return command
end

def rebind(command)
  return windows_rebind(unix_rebind(command))
end

