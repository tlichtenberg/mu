class Mu
module Helper
    
  def error msg
      $stderr.puts "!! #{msg}"
  end

  def msg msg, level=Logger::INFO
     caller[0] =~ /`([^']*)'/ and method = $1
     if caller[0].include?("mu")
       clz = caller[0][caller[0].index("mu")..caller[0].length]
     else
       clz = caller[0]
     end

     $log.add(level, "#{method} | #{msg}")
     # $log.add(level, "(#{clz}) | #{msg}")
  end

  def ask
      gets.strip
  end

  def shift key, argv
      val = argv.shift
      raise "missing value for #{key}" if val.nil?
      val
  end

  def format_float(spaces=2,arg=0.0)
    if !arg.nil?
      return sprintf("%.#{spaces}f", arg)
    else
      return ""
    end
  end

  def to_boolean(value="false")
     return false if value.nil?
     return true if value.downcase == "true"
     return false
  end

  # IO.readlines
  def get_file_as_string_array(filename)
   arr = []
   f = File.open(filename, "r")
   f.each_line do |line|
     arr.push line
   end
   return arr
  end

end
end # Mu
