# -*- encoding: utf-8 -*-
$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'curses'
require 'pry'
require 'roguelike'

def main
  Curses.init_screen

  begin
    @logs = []
    @world_window = Curses::Window.new(60, 200, 0, 0)
    write_log('game start')
    game = Roguelike::GameFactory.build_game
    while true
      draw_world(game)
      @input = wait_input
      break unless @input
      next if @input == Roguelike::Const::INVALID_KEY
      break unless apply_input(@input, game, game.hero)
      action_enemies(game)
    end
  ensure
    Curses.close_screen
  end
end

def write_log(log)
  return unless @logs # TODO: move to logger object
  @logs.unshift(log.to_s)
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
  when ?h then Roguelike::Const::LEFT
  when ?j then Roguelike::Const::DOWN
  when ?k then Roguelike::Const::UP
  when ?l then Roguelike::Const::RIGHT
  when ?y then Roguelike::Const::LEFT_UP
  when ?u then Roguelike::Const::RIGHT_UP
  when ?b then Roguelike::Const::LEFT_DOWN
  when ?n then Roguelike::Const::RIGHT_DOWN
  when ?. then Roguelike::Const::TAP
  else         Roguelike::Const::INVALID_KEY
  end
end

def apply_input(input, game, hero)
  return false if hero.dead?

  y_distance, x_distance = parse_distance(input)
  if !y_distance
    write_log("Y:#{hero.y} X:#{hero.x} input:#{@input}")
    return true
  end

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
  when Roguelike::Const::LEFT       then [0,  -1]
  when Roguelike::Const::DOWN       then [1,   0]
  when Roguelike::Const::UP         then [-1,  0]
  when Roguelike::Const::RIGHT      then [0,   1]
  when Roguelike::Const::LEFT_UP    then [-1, -1]
  when Roguelike::Const::RIGHT_UP   then [-1,  1]
  when Roguelike::Const::LEFT_DOWN  then [1,  -1]
  when Roguelike::Const::RIGHT_DOWN then [1,   1]
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

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  describe Roguelike::GameFactory do
    before do
      @game = Roguelike::GameFactory.build_game
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

  describe Roguelike::Game do
    describe "direction_input?" do
      it "judge true if LEFT" do
        expect(Roguelike::Game.direction_input?(Roguelike::Const::LEFT)).to eq(true)
      end

      it "judge false if without directions" do
        expect(Roguelike::Game.direction_input?(10)).to eq(false)
      end
    end

    describe "enemies" do
      before do
        @game = Roguelike::Game.new
        @enemy = Roguelike::Enemy::Bandit.new(@game, 1, 1)
        @game.enemies = [@enemy]
      end

      it "destroy enemy" do
        @game.destroy_enemy(@enemy)
        expect(@game.enemies).to be_empty
      end
    end
  end

  describe Roguelike::Walkable do
    class WalkableSample
      include Roguelike::Walkable

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
      @game = Roguelike::Game.new
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

  describe Roguelike::Hero do
    before do
      @game = Roguelike::Game.new
      @hero = Roguelike::Hero.new(@game, 2, 3)
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
        @game.enemies << Roguelike::Enemy::Bandit.new(@game, 2, 4)
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
        @enemy = Roguelike::Enemy::Bandit.new(@game, 2, 4)
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

  describe Roguelike::AbstractEnemy do
    before do
      @game = Roguelike::Game.new
      @enemy = Roguelike::Enemy::Bandit.new(@game, 2, 3)
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

  describe Roguelike::Enemy::Bandit do
    before do
      @game = Roguelike::Game.new
      @map = [
        [0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 0],
        [0, 1, 1, 1, 1, 0],
        [0, 1, 1, 1, 1, 0],
        [0, 0, 0, 0, 0, 0],
      ]
      @game.map = @map
      @enemy = Roguelike::Enemy::Bandit.new(@game, 2, 3)
      @game.enemies << @enemy
    end

    context "when hero is near," do
      before do
        @hero = Roguelike::Hero.new(@game, 2, 4)
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
        @hero = Roguelike::Hero.new(@game, 1, 1)
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

      it "walk to hero" do
        @enemy.action
        expect(@enemy.position).to eq([1, 2])
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
      @game = Roguelike::Game.new
      @game.map = @map
      @hero = Roguelike::Hero.new(@game, 2, 3)
    end

    it 'apply LEFT as left' do
      apply_input(Roguelike::Const::LEFT, @game, @hero)
      expect(@hero.position).to eq([2, 2])
    end

    it 'apply DOWN as down' do
      apply_input(Roguelike::Const::DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 3])
    end

    it 'apply UP as up' do
      apply_input(Roguelike::Const::UP, @game, @hero)
      expect(@hero.position).to eq([1, 3])
    end

    it 'apply RIGHT as right' do
      apply_input(Roguelike::Const::RIGHT, @game, @hero)
      expect(@hero.position).to eq([2, 4])
    end

    it 'apply LEFT_UP as left-up' do
      apply_input(Roguelike::Const::LEFT_UP, @game, @hero)
      expect(@hero.position).to eq([1, 2])
    end

    it 'apply RIGHT_UP as right-up' do
      apply_input(Roguelike::Const::RIGHT_UP, @game, @hero)
      expect(@hero.position).to eq([1, 4])
    end

    it 'apply LEFT_DOWN as left-down' do
      apply_input(Roguelike::Const::LEFT_DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 2])
    end

    it 'apply RIGHT_DOWN as right-down' do
      apply_input(Roguelike::Const::RIGHT_DOWN, @game, @hero)
      expect(@hero.position).to eq([3, 4])
    end

    it 'can tap' do
      apply_input(Roguelike::Const::TAP, @game, @hero)
      expect(@hero.position).to eq([2, 3])
    end


  end

end

