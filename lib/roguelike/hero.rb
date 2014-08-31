# -*- encoding: utf-8 -*-
class Roguelike::Hero
  include Roguelike::Walkable

  attr_accessor :game, :y, :x, :life

  def initialize(game, y, x)
    @game = game
    @y, @x = y, x
    @life = self.initial_life
  end

  def initial_life
    Roguelike::Const::DEFAULT_LIFE
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

