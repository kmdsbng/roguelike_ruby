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
    @hero = Hero.new(@map, 2, 2)
    while true
      draw_world(@hero)
      @input = wait_input
      break unless @input
      apply_input(@input, @hero)
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

class Game
  attr_accessor :hero, :map
end

class Hero
  def initialize(game, y, x)
    @game = game
    @map = game.map
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
  describe Game do
    before do
      @game = Game.new
    end

    pending do

      it "has a hero" do
        expect(@game.hero).to_not be_nil
      end

      it "has a map" do
        expect(@game.map).to_not be_nil
      end

    end
  end

  describe Hero do
    before do
      @map = [
        [0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 0],
        [0, 0, 0, 0, 0, 0],
      ]
      @game = Game.new
      @game.map = @map
      @hero = Hero.new(@game, 2, 3)
    end

    it "player in default position" do
      expect(@hero.position).to eq([2, 3])
    end

    it "player y" do
      expect(@hero.y).to eq(2)
    end

    it "player x" do
      expect(@hero.x).to eq(3)
    end

    it "player moves left" do
      @hero.move_left(1)
      expect(@hero.position).to eq([2, 2])
    end

    it "player moves up" do
      @hero.move_up(1)
      expect(@hero.position).to eq([1, 3])
    end

    it "player moves right" do
      @hero.move_right(1)
      expect(@hero.position).to eq([2, 4])
    end

    it "player moves down" do
      @hero.move_down(1)
      expect(@hero.position).to eq([3, 3])
    end

    it "player can not move wall" do
      @hero.move_down(2)
      expect(@hero.position).to eq([2, 3])
    end

    it "has game" do
      expect(@hero.game).to_not be_nil
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
      @game = Game.new
      @game.map = @map
      @hero = Hero.new(@game, 2, 3)
    end

    it 'apply "h" as left' do
      apply_input('h', @hero)
      expect(@hero.position).to eq([2, 2])
    end

    it 'apply "j" as up' do
      apply_input('j', @hero)
      expect(@hero.position).to eq([3, 3])
    end

    it 'apply "k" as down' do
      apply_input('k', @hero)
      expect(@hero.position).to eq([1, 3])
    end

    it 'apply "l" as right' do
      apply_input('l', @hero)
      expect(@hero.position).to eq([2, 4])
    end
  end

end
