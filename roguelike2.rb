# -*- encoding: utf-8 -*-
require 'curses'
require 'pry'

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
      next if @input == Game::INVALID_KEY
      break unless apply_input(@input, game, game.hero)
      action_enemies(game)
    end
  ensure
    Curses.close_screen
  end
end

def write_log(log)
  return unless @logs # TODO: move to logger object
  @logs.unshift(log)
  @logs.pop if @logs.size > 10
end

def draw_log
  Array(@logs).each_with_index {|line, i|
    @world_window.setpos(29 - i, 0)
    @world_window.addstr(line)
  }
end

def draw_world(game)
  clear_world
  draw_map(game.map)
  draw_enemies(game.enemies)
  draw_hero(game.hero)
  draw_log
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
  else         Game::INVALID_KEY
  end
end

def apply_input(input, game, hero)
  return false if hero.dead?

  y_distance, x_distance = parse_distance(input)
  return true if !y_distance
  if hero.walk_if_can(y_distance, x_distance)
    write_log("Y:#{hero.y} X:#{hero.x} input:#{@input}")
  else
    enemy = hero.detect_enemy(y_distance, x_distance)
    if enemy
      damage = hero.atack_to(enemy)
      write_log("#{enemy.name}を攻撃。#{damage}のダメージを与えた。")
      if enemy.dead?
        write_log("#{enemy.name}は死んだ。")
        game.destroy_enemy(enemy)
      end
    end
  end

  true
end

def parse_distance(input)
  case input
  when Game::LEFT       then [0,  -1]
  when Game::DOWN       then [1,   0]
  when Game::UP         then [-1,  0]
  when Game::RIGHT      then [0,   1]
  when Game::LEFT_UP    then [-1, -1]
  when Game::RIGHT_UP   then [-1,  1]
  when Game::LEFT_DOWN  then [1,  -1]
  when Game::RIGHT_DOWN then [1,   1]
  end
end

def action_enemies(game)
  game.enemies.each {|e|
    result = e.action
    write_log result if result
    if game.hero.dead?
      write_log "あなたは死んでしまった..."
      break
    end
  }
end

class Game
  require 'set'

  INVALID_KEY = 0
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

  def detect_enemy(y, x)
    @enemies.detect {|e| [e.y, e.x] == [y, x]}
  end

  def on_enemy?(y, x)
    !!detect_enemy(y, x)
  end

  def on_hero?(y, x)
    !@hero.nil? && [@hero.y, @hero.x] == [y, x]
  end

  def destroy_enemy(enemy)
    @enemies.delete(enemy)
  end

end

module Walkable
  def walk_if_can(y_distance, x_distance)
    if walkable?(@y + y_distance, @x + x_distance)
      @y, @x = @y + y_distance, @x + x_distance
      true
    else
      false
    end
  end

  def walkable?(y, x)
    @game.map[y][x] == 1 && !@game.on_enemy?(y, x) && !@game.on_hero?(y, x)
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
    @life = self.initial_life
  end

  def initial_life
    Game::DEFAULT_LIFE
  end

  def atack_to(enemy)
    damage = (0..6).to_a.sample
    enemy.damage(damage)
    damage
  end

  def detect_enemy(y_distance, x_distance)
    @game.detect_enemy(@y + y_distance, @x + x_distance)
  end

  def damage(n)
    @life -= n
    @life = [@life, 0].max
  end

  def dead?
    @life == 0
  end

end

class AbstractEnemy
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

  def hero_nearby?
    [(@y - @game.hero.y).abs, (@x - @game.hero.x).abs].max <= 1
  end

  def atack_to_hero
    damage = try_atack
    @game.hero.damage(damage)
    damage
  end

  def try_atack
    (0..self.power).to_a.sample
  end

  def name
    raise "Implement name"
  end

  def power
    raise "Implement power"
  end

  def action
    raise "Implement action"
  end

end

class Bandit < AbstractEnemy

  def initialize(game, y, x)
    super
    @life = initial_life
  end

  def name
    'Bandit'
  end

  def initial_life
    10
  end

  def power
    1
  end

  def action
    if hero_nearby?
      damage = atack_to_hero
      "#{self.name}から#{damage}のダメージを受けた"
    else
      nil
    end
  end

end

class GameFactory
  def self.build_game
    game = Game.new
    game.hero = Hero.new(game, 2, 2)
    game.enemies = [
      Bandit.new(game, 5, 5),
      Bandit.new(game, 3, 5),
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

    describe "enemies" do
      before do
        @game = Game.new
        @enemy = Bandit.new(@game, 1, 1)
        @game.enemies = [@enemy]
      end

      it "destroy enemy" do
        @game.destroy_enemy(@enemy)
        expect(@game.enemies).to be_empty
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
      expect(@walker.walk_if_can(0, -1)).to eq(true)
      expect(@walker.position).to eq([2, 2])
    end

    it "moves up" do
      expect(@walker.walk_if_can(-1, 0)).to eq(true)
      expect(@walker.position).to eq([1, 3])
    end

    it "can not move wall" do
      expect(@walker.walk_if_can(2, 0)).to eq(false)
      expect(@walker.position).to eq([2, 3])
    end

  end

  describe Hero do
    before do
      @game = Game.new
      @hero = Hero.new(@game, 2, 3)
      @game.hero = @hero
    end

    it "has game" do
      expect(@hero.game).to_not be_nil
    end

    it "has default life" do
      expect(@hero.life).to eq(15)
    end

    describe "detect enemy" do
      before do
        @game.enemies << Bandit.new(@game, 2, 4)
      end

      it "detect enemy" do
        expect(@hero.detect_enemy(0, 1)).not_to be_nil
      end

      it "detect no enemy" do
        expect(@hero.detect_enemy(1, 1)).to be_nil
      end

    end

    context "on hero" do
      it "detect hero" do
        expect(@game.on_hero?(2, 3)).to eq(true)

      end

      it "detect no hero" do
        expect(@game.on_hero?(2, 4)).to eq(false)
      end
    end

    describe "atack_to" do
      before do
        @enemy = Bandit.new(@game, 2, 4)
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

    describe "damage" do
      it "can damage" do
        @hero.damage(3)
        expect(@hero.life).to eq(@hero.initial_life - 3)
      end

      context "overkill" do
        before do
          @hero.damage(@hero.life + 1)
        end

        it "has 0 life" do
          expect(@hero.life).to eq(0)
        end

        it "is dead" do
          expect(@hero.dead?).to eq(true)
        end
      end
    end
  end

  describe AbstractEnemy do
    before do
      @game = Game.new
      @enemy = Bandit.new(@game, 2, 3)
      @game.enemies << @enemy
    end

    it "has game" do
      expect(@enemy.game).to_not be_nil
    end

    it "has default life" do
      expect(@enemy.life).to eq(@enemy.initial_life)
    end

    context "on enemy" do
      it "detect enemy" do
        expect(@game.on_enemy?(2, 3)).to eq(true)
      end

      it "detect no enemy" do
        expect(@game.on_enemy?(2, 4)).to eq(false)
      end
    end

    describe "damage" do
      it "can damage" do
        @enemy.damage(3)
        expect(@enemy.life).to eq(@enemy.initial_life - 3)
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

  describe Bandit do
    before do
      @game = Game.new
      @enemy = Bandit.new(@game, 2, 3)
      @game.enemies << @enemy
    end

    context "when hero is near," do
      before do
        @hero = Hero.new(@game, 2, 4)
        @game.hero = @hero
        class << @hero
          attr_accessor :__damage_called

          def damage(_n)
            @__damage_called = true
          end
        end
      end

      it "detect near hero" do
        expect(@enemy.hero_nearby?).to eq(true)
      end

      it "atack to near hero" do
        @enemy.atack_to_hero
        expect(@hero.__damage_called).to eq(true)
      end

      it "atack when action with closing hero" do
        @enemy.action
        expect(@hero.__damage_called).to eq(true)
      end

      it "return atack result" do
        result = @enemy.action
        expect(result.empty?).to eq(false)
      end
    end

    context "when hero is not near," do
      before do
        @hero = Hero.new(@game, 1, 1)
        @game.hero = @hero
        class << @hero
          attr_accessor :__damage_called

          def damage(_n)
            @__damage_called = true
          end
        end
      end

      it "detect no hero" do
        expect(@enemy.hero_nearby?).to eq(false)
      end

      it "do not atack when action with closing hero" do
        @enemy.action
        expect(@hero.__damage_called).not_to eq(true)
      end

      it "return no result" do
        result = @enemy.action
        expect(result).to eq(nil)
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
      apply_input(Game::LEFT, @game, @hero)
      expect(@hero.position).to eq([2, 2])
    end

    it 'apply DOWN as down' do
      apply_input(Game::DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 3])
    end

    it 'apply UP as up' do
      apply_input(Game::UP, @game, @hero)
      expect(@hero.position).to eq([1, 3])
    end

    it 'apply RIGHT as right' do
      apply_input(Game::RIGHT, @game, @hero)
      expect(@hero.position).to eq([2, 4])
    end

    it 'apply LEFT_UP as left-up' do
      apply_input(Game::LEFT_UP, @game, @hero)
      expect(@hero.position).to eq([1, 2])
    end

    it 'apply RIGHT_UP as right-up' do
      apply_input(Game::RIGHT_UP, @game, @hero)
      expect(@hero.position).to eq([1, 4])
    end

    it 'apply LEFT_DOWN as left-down' do
      apply_input(Game::LEFT_DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 2])
    end

    it 'apply RIGHT_DOWN as right-down' do
      apply_input(Game::RIGHT_DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 4])
    end

  end

end

