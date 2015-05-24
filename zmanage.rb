=begin
Z-Manage: Project management tool in Ruby
@author Jiangcheng Oliver Chu
=end

require 'set'

require_relative 'argparser'
require_relative 'commands'
require_relative 'rebind'

def directory?(path)
  return File.exist?(path) && !File.file?(path)
end

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

def yes_no_again
  println('Please answer with yes or no.')
end

def yes_no_prompt(prompt)
  answer = :unknown
  while answer == :unknown
    print(prompt, ' (yes/no) ')
    reply = gets
    if reply
      case reply
        when 'yes'
          answer = :yes
        when 'no'
          answer = :no
        else
          if reply.empty?
            yes_no_again
          else
            first_letter = reply[0].downcase
            if first_letter == 'y'
              println('Your answer was interpreted as \'yes\'')
              answer = :yes
            elsif first_letter == 'n'
              println('Your answer was interpreted as \'no\'')
              answer = :no
            else
              yes_no_again
            end
          end
      end
    else
      exit
    end
  end
  return answer
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

def create_files(dir, files={})
  files.each_key do |file_name|
    File.open(File.join(dir, file_name), 'w') do |file|
      file.write(files[file_name])
    end
  end
end

class Prefs
  def initialize(file_name)
    @path = File.join('zmanage-prefs', file_name)
    entries = IO.readlines(@path)
    @lines = {}
    entries.each do |entry|
      unless entry.strip.empty?
        key, value = entry.split('=')
        if !key || !value
          println("Bad preference entry detected: #{entry}")
        else
          @lines[key] = value.chomp
        end
      end
    end
  end

  def has_key?(key)
    return @lines.has_key?(key)
  end

  def [](key)
    return @lines[key]
  end

  def []=(key, value)
    @lines[key] = value
  end

  def save
    File.open(@path, 'w') do |file|
      file.write('')
    end
    File.open(@path, 'a') do |file|
      @lines.each_key do |key|
        file.write("#{key}=#{@lines[key]}\n")
      end
    end
  end
end

def run_query(query)
  if get_os == :Windows
    sys_command = rebind(query)
  else
    sys_command = unix_rebind(query)
  end
  run_sys_command(sys_command)
end

def main
  print_header('Z-Manage')
  should_save_prefs = true
  if !File.exist?('zmanage-prefs') || !directory?('zmanage-prefs')
    println('(You still need to setup your preferences folder, and you don\'t seem to be in')
    println(' the folder where you extracted this program. Your preferences won\'t be saved')
    println(' until then.)')
    should_save_prefs = false
  elsif !File.exist?('zmanage-prefs/location.ini')
    println('Setting up preferences...')
    create_files('zmanage-prefs', {
      'location.ini' => "location=#{Dir.pwd}",
      'preferences.ini' => 'autoshell=0'
    })
  end
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
    'elevate' => ElevateCommand.new,
    'setpref' => SetPrefCommand.new
  }
  all_commands['help'] = HelpCommand.new(all_commands)
  parser = ArgParser.new
  prefs = Prefs.new('preferences.ini')
  while true
    print '> '
    query = gets
    if !query
      # Exit when user presses ^C
      exit
    end
    query = query.chomp
    if query.start_with?('\'')
      new_query = query[1..-1]
      run_query(new_query)
      next
    end
    pieces = parser.parse(query)
    if !query.strip.empty? && !pieces.empty?
      command = pieces[0]
      args = pieces.drop(1)
      if all_commands.has_key?(command)
        all_commands[command].execute(*args)
      else
        if Prefs.new('preferences.ini')['autoshell'] == '1'
          run_query(query)
          next
        end
        println("'#{command}'", "is not a valid command.\nTo see all commands, type the command: help")
      end
    end
  end
end

main

