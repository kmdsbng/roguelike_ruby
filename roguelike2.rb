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
    @user = User.new(@map, 2, 2)
    while true
      draw_world(@user)
      @input = wait_input
      break unless @input
      apply_input(@input, @user)
    end

  ensure
    Curses.close_screen
  end
end

def draw_world(user)
  clear_world
  draw_map
  draw_cursor(user)
end

def clear_world
  Curses.clear
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

def draw_cursor(user)
  s = "@"
  Curses.setpos(user.y, user.x)
  Curses.addstr(s)

  Curses.setpos(Curses.lines - 1, 0)
  Curses.addstr("Y:#{user.y} X:#{user.x} input:#{@input}")

  Curses.refresh
end

def wait_input
  input = Curses.getch
  return nil if input == 27 || input == 'q' # <ESC> key
  input
end

def apply_input(input, user)
  case input
  when 'h' then user.move_left(1)
  when 'j' then user.move_down(1)
  when 'k' then user.move_up(1)
  when 'l' then user.move_right(1)
  end
end

class User
  def initialize(map, y, x)
    @map = map
    @y, @x = y, x
  end

  def position
    [@y, @x]
  end

  def y; position[0] end
  def x; position[1] end

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

  def movable?(y, x)
    @map[y][x] == 1
  end

end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/

  describe 'roguelike' do
    describe User do
      before do
        @map = [
          [0, 0, 0, 0, 0, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 0, 0, 0, 0],
        ]
        @user = User.new(@map, 2, 3)
      end

      it "player in default position" do
        expect(@user.position).to eq([2, 3])
      end

      it "player y" do
        expect(@user.y).to eq(2)
      end

      it "player x" do
        expect(@user.x).to eq(3)
      end

      it "player moves left" do
        @user.move_left(1)
        expect(@user.position).to eq([2, 2])
      end

      it "player moves up" do
        @user.move_up(1)
        expect(@user.position).to eq([1, 3])
      end

      it "player moves right" do
        @user.move_right(1)
        expect(@user.position).to eq([2, 4])
      end

      it "player moves down" do
        @user.move_down(1)
        expect(@user.position).to eq([3, 3])
      end

      it "player can not move wall" do
        @user.move_down(2)
        expect(@user.position).to eq([2, 3])
      end
    end


    describe 'apply_input' do
      before do
        @map = [
          [0, 0, 0, 0, 0, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 0, 0, 0, 0, 0],
        ]
        @user = User.new(@map, 2, 3)
      end

      it 'apply "h" as left' do
        apply_input('h', @user)
        expect(@user.position).to eq([2, 2])
      end

      it 'apply "j" as up' do
        apply_input('j', @user)
        expect(@user.position).to eq([3, 3])
      end

      it 'apply "k" as down' do
        apply_input('k', @user)
        expect(@user.position).to eq([1, 3])
      end

      it 'apply "l" as right' do
        apply_input('l', @user)
        expect(@user.position).to eq([2, 4])
      end
    end
  end
end
