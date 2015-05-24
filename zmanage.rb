=begin
Z-Manage: Project management tool in Ruby
@author Jiangcheng Oliver Chu
=end

require_relative 'argparser'
require_relative 'commands'
require_relative 'rebind'

def string_tail(str)
  if str.empty?
    return ''
  else
    return str[1..-1]
  end
end

def println(*args)
  args.each do |arg|
    print arg
      print ' '
  end
  puts ''
end

def debugln(*args)
  print 'DEBUG: '
  println(*args)
end

def print_header(message)
  println('======= ', message, ' =======')
end

def run_sys_command(sys_command)
  if sys_command != :run_nothing
    begin
      println(`#{sys_command}`)
    rescue StandardError => e
      println("Running the system command `#{sys_command}' failed:")
      println(e.inspect)
    end
  end
end

def main
 print_header('Z-Manage')
 println('Type help for assistance & available commands.')
 all_commands = {
   'exit' => ExitCommand.new('exit'),
   'quit' => ExitCommand.new('quit'),
   'bye' => ExitCommand.new('bye'),
   'parseargs' => ParseArgsCommand.new,
   'help' => nil,
   'count' => CountLinesCommand.new,
   'os' => ViewOSCommand.new,
   'jmake' => MakeCommand.new(
                'jmake',
                'javac -cp "$classpath" "$classpath/$relfile"',
                ['classpath', 'relfile'],
                "Compiles Java source using `classpath' and main file `relfile'.\n" \
                "  Example: jmake '/home/joe/projects/java' mypackage/Main.java"
              ),
   'elevate' => ElevateCommand.new
 }
 all_commands['help'] = HelpCommand.new(all_commands)
 parser = ArgParser.new
 while true
   print '> '
   query = gets
   if !query
     # Exit when user presses ^C
     exit
   end
   query = query.chomp
   if query.start_with?('\'')
     sys_command = rebind(query[1..-1])
     run_sys_command(sys_command)
     next
   end
   pieces = parser.parse(query)
   if !query.strip.empty? && !pieces.empty?
     command = pieces[0]
     args = pieces.drop(1)
     if all_commands.has_key?(command)
       all_commands[command].execute(*args)
     else
       println("'#{command}'", "is not a valid command.\nTo see all commands, type the command: help")
     end
   end
 end
end

main

