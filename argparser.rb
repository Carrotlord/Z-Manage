# Argument parsing including escaped quotes.
# A backslash that is not a valid escape sequence
# is treated as a literal backslash.
# @author Jiangcheng Oliver Chu
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
          if is_copying_next
            buffer += '\\'
            is_copying_next = false
          end
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
          if is_copying_next
            buffer += '\\'
            is_copying_next = false
          end
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

