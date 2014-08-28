# -*- encoding: utf-8 -*-
require 'curses'

def main
  Curses.init_screen

  begin
    @logs = []
    @world_window = Curses::Window.new(60, 200, 0, 0)
    write_log('game start')
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
  @logs.unshift(log)
  @logs.pop if @logs.size > 10
  @logs.each_with_index {|line, i|
    @world_window.setpos(39 - i, 0)
    @world_window.addstr(line)
  }
end

def draw_world(game)
  clear_world
  draw_map(game.map)
  draw_enemies(game.enemies)
  draw_hero(game.hero)
end

def clear_world
  @world_window.clear
end

def draw_map(map)
  map.each_with_index {|cols, y|
    cols.each_with_index {|map_type, x|
      @world_window.setpos(y, x * 2)
      chr = case map_type
            when 1 then ?.
            when 0 then ?#
            end
      @world_window.addstr(chr)
    }
  }
end

def draw_enemies(enemies)
  s = "$"
  enemies.each {|e|
    @world_window.setpos(e.y, e.x * 2)
    @world_window.addstr(s)
  }

end

def draw_hero(hero)
  s = "@"
  @world_window.setpos(hero.y, hero.x * 2)
  @world_window.addstr(s)
  write_log("Y:#{hero.y} X:#{hero.x} input:#{@input}")

end

def wait_input
  input = @world_window.getch
  case input
  when 27 then nil # <ESC>
  when ?q then nil
  when ?h then Game::LEFT
  when ?j then Game::DOWN
  when ?k then Game::UP
  when ?l then Game::RIGHT
  when ?y then Game::LEFT_UP
  when ?u then Game::RIGHT_UP
  when ?b then Game::LEFT_DOWN
  when ?n then Game::RIGHT_DOWN
  end
end

def apply_input(input, hero)
  case input
  when Game::LEFT       then hero.walk_if_can(0,  -1)
  when Game::DOWN       then hero.walk_if_can(1,   0)
  when Game::UP         then hero.walk_if_can(-1,  0)
  when Game::RIGHT      then hero.walk_if_can(0,   1)
  when Game::LEFT_UP    then hero.walk_if_can(-1, -1)
  when Game::RIGHT_UP   then hero.walk_if_can(-1,  1)
  when Game::LEFT_DOWN  then hero.walk_if_can(1,  -1)
  when Game::RIGHT_DOWN then hero.walk_if_can(1,   1)
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

  DEFAULT_LIFE = 15

  attr_accessor :hero, :map, :enemies

  def self.direction_input?(input)
    DIRECTION_SET.include?(input)
  end

  def initialize
    @enemies = []
  end

end

module Walkable
  def walk_if_can(y_distance, x_distance)
    if walkable?(@y + y_distance, @x + x_distance)
      @y, @x = @y + y_distance, @x + x_distance
    end
  end

  def walkable?(y, x)
    @game.map[y][x] == 1
  end

  def position
    [@y, @x]
  end

end

class Hero
  include Walkable

  attr_accessor :game, :y, :x, :life

  def initialize(game, y, x)
    @game = game
    @y, @x = y, x
    @life = Game::DEFAULT_LIFE
  end

  def atack_to(enemy)
    damage = (0..6).to_a.sample
    enemy.damage(damage)
    damage
  end

end

class Enemy
  include Walkable

  attr_accessor :y, :x, :game, :life

  def initialize(game, y, x)
    @game = game
    @y, @x = y, x
    @life = Game::DEFAULT_LIFE
  end

  def damage(n)
    @life -= n
    @life = [@life, 0].max
  end

  def dead?
    @life == 0
  end

end

class GameFactory
  def self.build_game
    game = Game.new
    game.hero = Hero.new(game, 2, 2)
    game.enemies = [
      Enemy.new(game, 5, 5)
    ]
    game.map = generate_map
    game
  end

  def self.generate_map
    [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
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

    it "has enemies" do
      expect(@game.enemies).not_to be_empty
    end

    describe "Game's hero" do
      it "has game" do
        expect(@game.hero.game).to eq(@game)
      end
    end

    describe "Game's enemies" do
      it "have game" do
        expect(@game.enemies.map {|e| !!e.game}.all?).to eq(true)
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

  describe Walkable do
    class WalkableSample
      include Walkable

      attr_accessor :game, :map, :y, :x

      def initialize(game, y, x)
        @game, @y, @x = game, y, x
      end
    end

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
      @walker = WalkableSample.new(@game, 2, 3)
    end

    it "is in default position" do
      expect(@walker.position).to eq([2, 3])
    end

    it "has y" do
      expect(@walker.y).to eq(2)
    end

    it "has x" do
      expect(@walker.x).to eq(3)
    end

    it "moves left" do
      @walker.walk_if_can(0, -1)
      expect(@walker.position).to eq([2, 2])
    end

    it "moves up" do
      @walker.walk_if_can(-1, 0)
      expect(@walker.position).to eq([1, 3])
    end

    it "can not move wall" do
      @walker.walk_if_can(2, 0)
      expect(@walker.position).to eq([2, 3])
    end

  end

  describe Hero do
    before do
      @game = Game.new
      @hero = Hero.new(@game, 2, 3)
    end

    it "has game" do
      expect(@hero.game).to_not be_nil
    end

    it "has default life" do
      expect(@hero.life).to eq(15)
    end

    describe "atack_to" do
      before do
        @enemy = Enemy.new(@game, 2, 4)
        class << @enemy
          attr_accessor :__damage_called

          def damage(_n)
            @__damage_called = true
          end
        end
      end

      it "can atack to Enemy" do
        @hero.atack_to(@enemy)
        expect(@enemy.__damage_called).to eq(true)
      end
    end
  end

  describe Enemy do
    before do
      @game = Game.new
      @enemy = Enemy.new(@game, 2, 3)
    end

    it "has game" do
      expect(@enemy.game).to_not be_nil
    end

    it "has default life" do
      expect(@enemy.life).to eq(15)
    end

    describe "damage" do
      it "can damage" do
        @enemy.damage(3)
        expect(@enemy.life).to eq(12)
      end

      context "overkill" do
        before do
          @enemy.damage(@enemy.life + 1)
        end

        it "has 0 life" do
          expect(@enemy.life).to eq(0)
        end

        it "is dead" do
          expect(@enemy.dead?).to eq(true)
        end
      end
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

    it 'apply LEFT as left' do
      apply_input(Game::LEFT, @hero)
      expect(@hero.position).to eq([2, 2])
    end

    it 'apply DOWN as down' do
      apply_input(Game::DOWN, @hero)
      expect(@hero.position).to eq([3, 3])
    end

    it 'apply UP as up' do
      apply_input(Game::UP, @hero)
      expect(@hero.position).to eq([1, 3])
    end

    it 'apply RIGHT as right' do
      apply_input(Game::RIGHT, @hero)
      expect(@hero.position).to eq([2, 4])
    end

    it 'apply LEFT_UP as left-up' do
      apply_input(Game::LEFT_UP, @hero)
      expect(@hero.position).to eq([1, 2])
    end

    it 'apply RIGHT_UP as right-up' do
      apply_input(Game::RIGHT_UP, @hero)
      expect(@hero.position).to eq([1, 4])
    end

    it 'apply LEFT_DOWN as left-down' do
      apply_input(Game::LEFT_DOWN, @hero)
      expect(@hero.position).to eq([3, 2])
    end

    it 'apply RIGHT_DOWN as right-down' do
      apply_input(Game::RIGHT_DOWN, @hero)
      expect(@hero.position).to eq([3, 4])
    end

  end


end
