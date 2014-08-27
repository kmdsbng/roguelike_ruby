# -*- encoding: utf-8 -*-
require 'curses'

def main
  Curses.init_screen

  begin
    @log_window = Curses::Window.new(20, 200, 0, 30)
    @log_window.scrollok(true)
    @log_window.setscrreg(0, 20)
    game = GameFactory.build_game
    while true
      draw_world(game)
      @input = wait_input
      break unless @input
      apply_input(@input, game.hero)
    end

  ensure
    Curses.close_screen
  end
end

def write_log(log)
  @log_window.scroll
  @log_window.setpos(19, 0)
  @log_window.addstr(log)
end

def draw_world(game)
  clear_world
  draw_map(game.map)
  draw_cursor(game.hero)
end

def clear_world
  Curses.clear
end

def draw_map(map)
  map.each_with_index {|cols, y|
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

def draw_cursor(hero)
  s = "@"
  Curses.setpos(hero.y, hero.x)
  Curses.addstr(s)

  Curses.setpos(Curses.lines - 1, 0)
  Curses.addstr("Y:#{hero.y} X:#{hero.x} input:#{@input}")
  write_log("Y:#{hero.y} X:#{hero.x} input:#{@input}")

  Curses.refresh
end

def wait_input
  input = Curses.getch
  return nil if input == 27 || input == 'q' # <ESC> key
  input
end

def apply_input(input, hero)
  case input
  when 'h' then hero.move_left(1)
  when 'j' then hero.move_down(1)
  when 'k' then hero.move_up(1)
  when 'l' then hero.move_right(1)
  end
end

class Game
  require 'set'

  LEFT_UP = 1
  UP = 2
  RIGHT_UP = 3
  LEFT = 4
  RIGHT = 6
  LEFT_DOWN = 7
  DOWN = 8
  RIGHT_DOWN = 9

  DIRECTION_SET = Set.new([LEFT_UP, UP, RIGHT_UP, LEFT, RIGHT, LEFT_DOWN, DOWN, RIGHT_DOWN])

  def self.direction_input?(input)
    DIRECTION_SET.include?(input)
  end

  attr_accessor :hero, :map
end

class Hero
  attr_accessor :game, :y, :x
  def initialize(game, y, x)
    @game = game
    @y, @x = y, x
  end

  def position
    [@y, @x]
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

  def movable?(y, x)
    @game.map[y][x] == 1
  end

end

class GameFactory
  def self.build_game
    game = Game.new
    game.hero = Hero.new(game, 2, 2)
    game.map = generate_map
    game
  end

  def self.generate_map
    [
      [0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0],
      [0, 1, 1, 1, 0],
      [0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0],
    ]
  end
end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  describe GameFactory do
    before do
      @game = GameFactory.build_game
    end

    it "has a hero" do
      expect(@game.hero).to_not be_nil
    end

    it "has a map" do
      expect(@game.map).to_not be_nil
    end

    describe "Game's hero" do
      it "has game" do
        expect(@game.hero.game).to eq(@game)
      end
    end

  end

  describe Game do
    describe "direction_input?" do
      it "judge true if LEFT" do
        expect(Game.direction_input?(Game::LEFT)).to eq(true)
      end

      it "judge false if without directions" do
        expect(Game.direction_input?(10)).to eq(false)
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
