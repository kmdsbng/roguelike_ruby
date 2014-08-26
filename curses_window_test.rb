# -*- encoding: utf-8 -*-
require 'curses'

def main
  Curses.init_screen

  begin
    win = Curses::Window.new(10, 20, 0, 0)

    win.setpos(9, 0)
    win.scrollok(true)
    win.setscrreg(0, 10)
    count = 8
    while ((count -= 1) > 0)
      str = win.getstr
      win.deleteln
      win.addstr(str)
      win.scroll
      win.setpos(9, 0)
    end

  ensure
    Curses.close_screen
  end

end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  # {spec of the implementation}
end

