# Commands with execution logic and descriptions.
# This class should not be instantiated, but its
# subclasses can.
# @author Jiangcheng Oliver Chu
class Command
  def initialize(name, args_taken, aliases, flags)
    @name = name
    @args_taken = args_taken
    @has_varargs = true
    @aliases = aliases
    init_flags(flags)
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

  def flag?(arg)
    return arg.start_with?('--')
  end

  def init_flags(flags)
    @flags = {}
    flags.each do |name|
      @flags[name] = false
    end
  end
 
  def write_flags(args)
    args.each do |arg|
      if flag?(arg)
        status = set_flag(arg)
        if status == :failure
          return arg
        else
          args.delete(arg)
        end
      end
    end
    return :success
  end

  def has_flag?(flag_name)
    return @flags.has_key?(flag_name)
  end

  def flag_active?(flag_name)
    if !has_flag?(flag_name)
      raise Exception.new("No such flag: #{flag_name}")
    else
      return @flags[flag_name]
    end
  end

  def set_flag(flag_name)
    if !has_flag?(flag_name)
      return :failure
    else
      @flags[flag_name] = true
      return :success
    end
  end

  def reset_flags
    @flags.each_key do |name|
      @flags[name] = false
    end
  end

  def check_args(args)
    if !@has_varargs && @args_taken.length != args.length
      println(@name, 'takes', @args_taken.length, "arguments, not #{args.length}.")
      return :failure
    else
      return :success
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
    if !@aliases.empty?
      docs += "\n  Aliases: " + @aliases.join(', ')
    end
    if !@flags.empty?
      docs += "\n  Flags: " + @flags.keys.join(', ')
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

# Command for exiting this program.
# @author Jiangcheng Oliver Chu
class ExitCommand < Command
  def initialize(chosen_alias)
    @name = chosen_alias
    @args_taken = []
    @has_varargs = false
    @aliases = ['quit', 'bye', 'exit'].delete_if { |command| command == @name }
    @flags = []
  end

  def get_desc
    return 'Exits this program.'
  end

  def execute(*args)
    exit
  end
end

# Command for viewing arguments as the script sees them.
class ParseArgsCommand < Command
  def initialize
    @name = 'parseargs'
    @args_taken = []
    @has_varargs = true
    @aliases = []
    @flags = []
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
    @flags = []
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
      println('  - For specific details, type: help <command name>')
      println('  - Commands take arguments separated by whitespace.')
      println('  - Arguments can be quoted if they contain spaces.')
      println('  - Use a single quote to run system commands, like \'ls -a')
    end
  end
end

class CountLinesCommand < Command
  def initialize
    @name = 'count'
    @args_taken = []
    @has_varargs = true
    @aliases = []
    @ignore_extensions = ['.class', '.form']
    init_flags(['--ignore-blank-lines'])
  end

  def get_desc
    return 'Counts lines in files, given filepath(s) as arguments.'\
           "\n  If given 1 directory, counts files in that directory & its subdirectories."
  end

  def ignore?(path)
    @ignore_extensions.each do |ext|
      if path.end_with?(ext)
        return true
      end
    end
    return false
  end

  def count_all(root, partial_path='')
    total = 0
    full_path = File.join(root, partial_path)
    entries = Dir.entries(full_path)
    entries.each do |path|
      new_full_path = File.join(full_path, path)
      new_partial_path = File.join(partial_path, path)
      if File.file?(new_full_path)
        unless ignore?(path)
          count = count_lines("#{new_full_path}", flag_active?('--ignore-blank-lines'))
          print_count(string_tail(new_partial_path), count)
          total += count
        end
      else
        if !path.start_with?('.')
          total += count_all(root, new_partial_path)
        end
      end
    end
    return total
  end

  def count_lines(file, should_ignore_blanks)
    if should_ignore_blanks
      count = 0
      IO.readlines(file).each do |line|
        if !line.strip.empty?
          count += 1
        end
      end
      return count
    else
      return IO.readlines(file).length
    end
  end

  def print_total(total)
    if flag_active?('--ignore-blank-lines')
      println("#{total} total lines (ignoring blanks)")
    else
      println("#{total} total lines")
    end
  end

  def print_count(path, count)
    if flag_active?('--ignore-blank-lines')
      println("#{path}\t#{count} lines (ignoring blanks)")
    else
      println("#{path}\t#{count} lines")
    end
  end

  def execute(*args)
    status = write_flags(args)
    if status != :success
      println(status, 'is not accepted by this command.')
      return
    end
    total = 0
    if args.length == 1 && !File.file?(args[0])
      print_total(count_all(args[0]))
    else
      args.each do |path|
        if !File.exist?(path)
          println(path, '   <file doesn\'t exist>')
        elsif !File.file?(path)
          println(path, '   <directory>')
        else
          if flag_active?('--ignore-blank-lines')
            count = count_lines(path, true)
          else
            count = count_lines(path, false)
          end
          print_count(path, count)
          total += count
        end
      end
      if args.length > 1
        print_total(total)
      end
    end
    reset_flags
  end
end

class MakeCommand < Command
  def initialize(name, compile_step, compile_vars, desc)
    @name = name
    @compile_step = compile_step
    @args_taken = compile_vars
    @has_varargs = false
    @aliases = []
    @flags = []
    @desc = desc
  end

  def get_desc
    return @desc
  end

  def execute(*args)
    status = check_args(args)
    compile_command = String.new(@compile_step)
    if status != :failure
      for i in 0..(args.length - 1)
        compile_command.gsub!(/\$#{@args_taken[i]}/, args[i])
      end
      run_sys_command(compile_command)
    end
  end
end

class RunCommand < Command
  def initialize(name, run_step, run_vars, desc)
    @name = name
    @run_step = run_step
    @args_taken = run_vars
    @has_varargs = false
    @aliases = []
    @flags = []
    @desc = desc
    @run_macro_regex = /@toClassName\((.*?)\)/
  end

  def get_desc
    return @desc
  end

  def to_class_macro(rel_file_name)
    if rel_file_name.end_with?('.class')
      rel_file_name[-6..-1] = ''
    elsif rel_file_name.end_with?('.java')
      rel_file_name[-5..-1] = ''
    end
    return rel_file_name.gsub('/', '.')
  end

  def get_match_data(run_command)
    return run_command.match(@run_macro_regex)
  end

  def expand_run_macros(run_command)
    match_data = get_match_data(run_command)
    while match_data
      if match_data[0] && match_data[1] && run_command =~ /@toClassName/
        run_command.gsub!(match_data[0], to_class_macro(match_data[1]))
      else
        throw Exception.new("Cannot expand run macros: #{run_command}")
      end
      match_data = get_match_data(run_command)
    end
    return run_command
  end

  def execute(*args)
    status = check_args(args)
    run_command = String.new(@run_step)
    if status != :failure
      for i in 0..(args.length - 1)
        run_command.gsub!(/\$#{@args_taken[i]}/, args[i])
      end
      saved_dir = Dir.pwd
      should_move = saved_dir != args[0]
      if should_move
        println('Temporarily moving you to project directory...')
        Dir.chdir(args[0])
      end
      run_sys_command(expand_run_macros(run_command))
      if should_move
        Dir.chdir(saved_dir)
      end
    end
  end

  private :expand_run_macros, :to_class_macro, :get_match_data
end

class ViewOSCommand < Command
  def initialize
    @name = 'os'
    @args_taken = []
    @has_varargs = false
    @aliases = []
    @flags = []
  end

  def get_desc
    return 'Returns name of current OS.'
  end

  def execute(*args)
    status = check_args(args)
    if status != :failure
      println(get_os.id2name)
    end
  end
end

class ElevateCommand < Command
  def initialize
    @name = 'elevate'
    @args_taken = ['filename']
    @has_varargs = false
    @aliases = []
    @flags = []
  end

  def get_desc
    return 'Restores read/write permissions to the file.'
  end

  def execute(*args)
    status = check_args(args)
    if status != :failure
      file_name = args[0]
      begin
        file = File.open(file_name, 'wb+')
        file.close
      rescue StandardError => e
        case get_os
          when :Windows
            run_sys_command("attrib -r #{file_name}")
          when :Linux, :Mac, :BSD
            run_sys_command("chmod a+rw #{file_name}")
          else
            println('Could not set permissions.')
        end
      end
    end
  end
end

class SetPrefCommand < Command
  def initialize
    @name = 'setpref'
    @args_taken = ['preference-name']
    @has_varargs = false
    @aliases = []
    @flags = []
  end

  def get_desc
    return "Activate a preference. The following are possible arguments:\n" \
           "    autoshell (run system commands without ' prefix)\n" \
           "    cyg-bind  (bind all Cygwin commands)"
  end

  def all_cyg_active
    println("All bound Cygwin programs are active.")
  end

  def execute(*args)
    status = check_args(args)
    if status != :failure
      case args[0]
        when 'autoshell'
          prefs = Prefs.new('preferences.ini')
          prefs['autoshell'] = '1'
          prefs.save
          println('Autoshell activated.')
        when 'cyg-bind'
          print('Enter the path of your Cygwin installation: ')
          path = gets
          if path
            path.chomp!
            prefs = Prefs.new('preferences.ini')
            if path.end_with?('bin') || path.end_with?('bin/')
              full_path = path
            else
              full_path = File.join(path, 'bin')
            end
            utils = Dir.entries(full_path).reject do |entry|
              directory?(entry) || !entry.end_with?('.exe')
            end
            utils.map! do |entry|
              entry[0..-5]
            end
            prefs['cygwin-path'] = full_path
            prefs['cygwin-utils'] = utils.join(',')
            prefs.save
            println("The following cygwin utilities have been bound:\n" \
                    "#{utils.join(', ')}")
            println("Access them with ' or use autoshell.\n")
            answer = yes_no_prompt("You may also choose to ignore certain Cygwin programs.\n" \
                                   "Are there any Cygwin utilities you want to ignore right now?")
            if answer == :yes
              print('Type in the names of the programs, separated by spaces: ')
              names = gets
              if names
                names.chomp!
                name_array = ArgParser.new.parse(names)
                name_array.map! do |name|
                  if name.end_with? '.exe'
                    name[0..-5]
                  else
                    name
                  end
                end
                name_array.each do |name|
                  if !utils.delete(name)
                    println("Skipped #{name} because it doesn't exist.")
                  else
                    println("Added ignore rule for #{name}.")
                  end
                end
                prefs['cygwin-utils'] = utils.join(',')
                prefs.save
                println('The Cygwin programs you wanted are now active.')
              else
                all_cyg_active
              end
            else
              all_cyg_active
            end
          else
            println("\nAction cancelled.")
          end
        else
          println("#{args[0]} is not a valid preference.")
      end
    end
  end
end

