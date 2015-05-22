=begin
Z-Manage: Project management tool in Ruby
@author Jiangcheng Oliver Chu
=end

class ArgParser
  def initialize; end

  def parse(command_invoked)
    is_inside_whitespace = false
    is_inside_single_quote = false
    is_inside_double_quote = false
    is_copying_next = false
    args = []
    buffer = ''
    command_invoked.each_char do |c|
      case c
        when ' ', "\t"
          if is_inside_single_quote || is_inside_double_quote
            buffer += ' '
          elsif !is_inside_whitespace
            args.push(buffer)
            buffer = ''
            is_inside_whitespace = true
          end
        when '"'
          if is_inside_single_quote
            buffer += '"'
          elsif is_inside_double_quote
            if !is_copying_next
              args.push(buffer)
              buffer = ''
              is_inside_double_quote = false
            else
              buffer += '"'
              is_copying_next = false
            end
          else
            is_inside_double_quote = true
          end
          is_inside_whitespace = false
        when '\''
          if is_inside_single_quote
            if !is_copying_next
              args.push(buffer)
              buffer = ''
              is_inside_single_quote = false
            else
              buffer += '\''
              is_copying_next = false
            end
          elsif is_inside_double_quote
            buffer += '\''
          else
            is_inside_single_quote = true
          end
          is_inside_whitespace = false
        when '\\'
          if is_copying_next
            buffer += '\\'
            is_copying_next = false
          else
            is_copying_next = true
          end
          is_inside_whitespace = false
        else
          buffer += c
          is_inside_whitespace = false
      end
    end
    if !buffer.empty?
      args.push(buffer)
    end
    return args.delete_if { |arg| arg.empty? }
  end
end

class Command
  def initialize(name, args_taken, aliases)
    @name = name
    @args_taken = args_taken
    @has_varargs = true
    @aliases = aliases
  end

  # Abstract method get_desc, should be overwritten.
  def get_desc
    return 'This command has no description.'
  end

  # Abstract method execute, should be overwritten.
  def execute(*args)
    check_args(args)
    println('Command', @name, 'not yet implemented.')
  end

  def check_args(args)
    if !@has_varargs
      println(@name, 'takes', @args_taken.length, 'arguments, not', args.length, '.')
    end
  end

  def get_names
    return [@name] + @aliases
  end

  def get_docs
    docs = 'Usage: ' + @name + ' '
    if @has_varargs
      docs += "<variable arguments>\n"
    else
      docs += @args_taken.join(' ') + "\n"
    end
    docs += '  ' + get_desc
    if @aliases.length > 0
      docs += "\n  Aliases: " + @aliases.join(', ')
    end
    return docs
  end

  def aliases
    @aliases
  end

  def set_name(name)
    @name = name
  end
end

class ExitCommand < Command
  def initialize(chosen_alias)
    @name = chosen_alias
    @args_taken = []
    @has_varargs = false
    @aliases = ['quit', 'bye', 'exit'].delete_if { |command| command == @name }
  end

  def get_desc
    return 'Exits this program.'
  end

  def execute(*args)
    exit
  end
end

class ParseArgsCommand < Command
  def initialize
    @name = 'parseargs'
    @args_taken = []
    @has_varargs = true
    @aliases = []
  end

  def get_desc
    return '(for debugging) Parses command line arguments into array.'
  end

  def execute(*args)
    println(args)
  end
end

class HelpCommand < Command
  def initialize(all_commands)
    @name = 'help'
    @args_taken = []
    @has_varargs = true
    @aliases = []
    @all_commands = all_commands
    @sorted_commands = @all_commands.keys.sort.join(', ')
  end

  def get_desc
    return 'Displays all commands. If given an argument, displays help for that command.'
  end

  def execute(*args)
    if !args.empty?
      command = args[0]
      if @all_commands.has_key?(command)
        println(@all_commands[command].get_docs)
      else
        println("'#{command}' is not a valid command.")
      end
    else
      println('All commands:', @sorted_commands)
      println('  For specific details, type: help <command name>')
      println('  (Commands take arguments separated by whitespace.')
      println('   Arguments can be quoted if they contain spaces.)')
    end
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

def main
 print_header('Z-Manage')
 println('Type help for assistance & available commands.')
 all_commands = {
   'exit' => ExitCommand.new('exit'),
   'quit' => ExitCommand.new('quit'),
   'bye' => ExitCommand.new('bye'),
   'parseargs' => ParseArgsCommand.new,
   'help' => nil
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

