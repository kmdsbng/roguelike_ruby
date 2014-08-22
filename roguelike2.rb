# -*- encoding: utf-8 -*-
require 'curses'

def main
  Curses.init_screen
  @map = [
    [0, 0, 0, 0, 0],
    [0, 1, 1, 1, 0],
    [0, 1, 1, 1, 0],
    [0, 1, 1, 1, 0],
    [0, 0, 0, 0, 0],
  ]

  begin
    @y = 2
    @x = 2
    while true
      Curses.clear
      draw_map
      draw_cursor
      @input = wait_input
      break unless @input
    end

  ensure
    Curses.close_screen
  end
end

def draw_map
  @map.each_with_index {|cols, y|
    cols.each_with_index {|map_type, x|
      Curses.setpos(y, x)
      chr = case map_type
            when 1 then ?.
            when 0 then ?#
            end
      Curses.addstr(chr)
    }
  }
end

def draw_cursor
  s = "@"
  Curses.setpos(@y, @x)
  Curses.addstr(s)

  Curses.setpos(Curses.lines - 1, 0)
  Curses.addstr("Y:#{@y} X:#{@x} input:#{@input}")

  Curses.refresh
end

def wait_input
  input = Curses.getch
  return nil if input == 27 || input == 'q' # <ESC> key

  case input
  when 'h' then move_left(1)
  when 'j' then move_down(1)
  when 'k' then move_up(1)
  when 'l' then move_right(1)
  end

  input
end

def movable?(y, x)
  @map[y][x] == 1
end

def move_left(n)
  if movable?(@y, @x - n)
    @x -= n
  end
end

def move_right(n)
  if movable?(@y, @x + n)
    @x += n
  end
end

def move_up(n)
  if movable?(@y - n, @x)
    @y -= n
  end
end

def move_down(n)
  if movable?(@y + n, @x)
    @y += n
  end
end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  # {spec of the implementation}
end
