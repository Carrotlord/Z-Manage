require 'irb'

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

def environment
  return binding()
end

def unix_rebind(unix_command)
  pieces = ArgParser.new.parse(unix_command)
  if pieces.empty?
    return :run_nothing
  end
  command = pieces[0]
  if command == 'cd' && pieces.length == 2
    Dir.chdir(pieces[1])
    return :run_nothing
  elsif command == 'irb' && pieces.length == 1
    env = environment
    println('(exit REPL using `exit\')')
    ctrl_flow_stmt = ''
    loop do
      should_print = true
      if ctrl_flow_stmt.empty?
        print('Ruby REPL> ')
      else
        print('Ruby REPL* ')
      end
      answer = gets
      if !answer || answer.strip == 'exit'
        break
      end
      answer.strip!
      is_require_stmt = answer.start_with?('require') || answer.start_with?('load')
      begin
        if is_require_stmt
          env.eval("#{answer}")
        else
          begin
            if ctrl_flow_stmt.empty?
              result_str = env.eval("_ = #{answer}")
            else
              # If the following line fails, add more
              # to the control flow statement until it
              # is valid.
              env.eval("#{ctrl_flow_stmt}")
              # Success:
              ctrl_flow_stmt = ''
              should_print = false
            end
          rescue SyntaxError => e
            ctrl_flow_stmt += "#{answer};"
            begin
              env.eval("#{ctrl_flow_stmt}")
            rescue SyntaxError => e
              next
            end
            ctrl_flow_stmt = ''
            should_print = false
          end
        end
      rescue StandardError => e
        println(e.inspect)
      end
      if !is_require_stmt && should_print
        println(result_str)
      end
    end
    return :run_nothing
  end
  return command
end

def rebind(command)
  return windows_rebind(unix_rebind(command))
end

