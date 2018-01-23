#!/bin/env ruby

$VERBOSE=nil

class Colors
   COLOR1 = "\e[1;36;40m"
   COLOR2 = "\e[1;35;40m"
   NOCOLOR = "\e[0m"
   RED = "\e[1;31;40m"
   GREEN = "\e[1;32;40m"
   DARKGREEN = "\e[0;32;40m"
   YELLOW = "\e[1;33;40m"
   DARKCYAN = "\e[0;36;40m"
end

class String
   def color(color)
      return color + self + Colors::NOCOLOR
   end
end


puts "Hello World".color(Colors::RED)

puts ("HI"+"GUY").color(Colors::RED)
