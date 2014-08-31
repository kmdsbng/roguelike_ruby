# -*- encoding: utf-8 -*-
class Roguelike::Game
  attr_accessor :hero, :map, :enemies

  def self.direction_input?(input)
    Roguelike::Const::DIRECTION_SET.include?(input)
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
