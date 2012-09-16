#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

module GPL
  # Environment
  module Constants
    CALMA4_PATH = File.join(ENV['HOME'], '/Documents/calma4')
    HELP_PATH = File.join(CALMA4_PATH, 'help')
    TOOL_PATH = File.join(CALMA4_PATH, 'tool')
  end
end

module GDSDocuments
  include GPL::Constants

  def strip_ext(name)
    
  end
  
  def folders
    Dir.entries(CALMA4_PATH).select { |name|
      name != '.' and name != '..' and
      File.directory?(File.join(CALMA4_PATH, name))
    }
  end
  module_function :folders

  def entries(folder, strip_extension = false)
    return [] unless folders.include?(folder)
    result = Dir.entries(File.join(CALMA4_PATH, folder)).select { |base|
      /^\./ !~ base and 
      File.file?(File.join(CALMA4_PATH, folder, base))
    }
    if strip_extension
      result = result.collect { |base| File.basename(base, '.*') }
    end
    result
  end
  module_function :entries

  def lines_named(path)
    lines = []
    File.open(path) { |fd|
      fd.each_line("\r") {|line| lines.push(line.chomp)}
    }
    lines
  end    
  
  def contents(folder, basename)
    full_path = File.join(CALMA4_PATH, folder, basename)
    return [] unless File.file?(full_path)
    lines_named(full_path)
  end
  module_function :contents
end


module GPLHelp
  include GPL::Constants
  include GDSDocuments
  
  $_basename_dict = nil
  $_command_infos = nil
  $_commands      = nil
  $_rev_dict       = nil  
  
  def tool_filenames
    #entries('tool', true)
    entries('tool')
  end

  def help_basenames
    entries('help', true)
  end

  def command_path_named(basename)
    File.join(HELP_PATH, basename + '.HP')
  end

  def command_lines_named(basename)
    lines_named(command_path_named(basename))
  end
  
  def infos
    if $_basename_dict.nil?
      $_command_infos = []
      $_basename_dict = {}
      help_basenames.each { |basename|
        lines = command_lines_named(basename)
        info = commands_info(lines, basename)
        $_command_infos.push(info)
      }
    end
    $_command_infos
  end

  # return value is Hash. key names are:
  # :commands, :function?, :command?
  def commands_info(lines, basename)
    info = {:basename => basename,
      :commands => nil, :function? => false, :command? => false}
    lines.each { |line|
      if basename.size == 10
        if (/^([A-Z0-9_]+)\s+\d\d\/\d\d\/\d\d$/ =~ line) == 0
          real = Regexp.last_match[1]
          #puts "real: #{real}"
          if real.size >= basename.size
            unless info[:commands]
              info[:commands] = Array.new
            end
            info[:commands].push(real)            
          end
        end
      end
      if /\*+ COMMAND \*+/ =~ line
        info[:command?] = true
      end
      if /\*+ FUNCTION \*+/ =~ line
        info[:function?] = true
      end
      if /\t\t\t([A-Z0-9]+)\s/ =~ line
        unless info[:commands]
          info[:commands] = Array.new
        end
        info[:commands].push(Regexp.last_match[1])
      end
    }
    if info[:commands]
      info[:commands] = info[:commands].grep(Regexp.new('^' + basename)).uniq.sort
    end
    if info[:commands]
      if info[:commands].size == 0
        info[:commands] = nil
      elsif info[:commands].size == 1
        if info[:basename] == info[:commands][0]
          info[:commands] = nil
        end
      end
    end
    info.dup
  end  
  
  def rev_dict_from(info_array)
    rev_dict = {}
    info_array.each { |info|
      if not info[:commands].nil? 
        info[:commands].each { |real| 
          rev_dict[real] = info[:basename]
        }
      else
        rev_dict[info[:basename]] = info[:basename]
      end
    }
    rev_dict
  end

  def load_commands    
    $rev_dict = rev_dict_from(infos)
  end
  
  def basename_from(command)
    if $rev_dict.nil? or $rev_dict == {}
      load_commands
    end
    $rev_dict[command]
  end

  def private_commands(symbol, patterns = nil, filename = nil, only = false)
    if only
      rev_symbol = (symbol == :command?) ? :function? : :command?
      subinfos = infos.select {|info|
        info[symbol] == true and
        info[rev_symbol] == false
      }
    else
      subinfos = infos.select {|info| info[symbol] == true}
    end
    cmds = rev_dict_from(subinfos).keys.sort
    if not patterns.nil? and patterns.size > 0 then
      return cmds.grep(Regexp.new(cdos_pat_to_ruby_pat(patterns)))
    end
    cmds
  end

  def cdos_pat_to_ruby_pat(cdos_pat)
    newpat = cdos_pat.upcase
    newpat.gsub!(/\*/, '.')
    newpat.gsub!(/\-/, '.+')
    '^' + newpat + '$'
  end
end

include GPLHelp

module GPL
  
  def commands(patterns = nil, filename = nil)
    private_commands(:command?, patterns, filename)
  end
  module_function :commands

  def commands_only(patterns = nil, filename = nil)
    private_commands(:command?, patterns, filename, true)
  end
  module_function :commands_only
  
  def functions(patterns = nil, filename = nil)
    private_commands(:function?, patterns, filename)
  end
  module_function :functions

  def functions_only(patterns = nil, filename = nil)
    private_commands(:function?, patterns, filename, true)
  end
  module_function :functions_only

  def commands_and_functions
    (commands  + functions).flatten.uniq
  end
  module_function :commands_and_functions

  def help_contents(pat)
    name = pat.upcase
    basename = basename_from(name)
    if not basename.nil?
      return command_lines_named(basename)
    else
      []
    end
  end
  module_function :help_contents

  def help(pat)
    contents = help_contents(pat)
    if contents.size != 0
      puts contents
    else
      puts "help '#{name}' not found"
    end
  end
  module_function :help

  def open(helpname)
    name = helpname.upcase
    basename = basename_from(name)
    if not basename.nil?
      path = command_path_named(basename)
      cmd = ['open', "'" + path + "'"].join(' ')
      system(cmd)
    else
      puts "help '#{name}' not found"
    end
  end
  module_function :open


end

