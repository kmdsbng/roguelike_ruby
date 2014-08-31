# -*- encoding: utf-8 -*-
class Roguelike::AbstractEnemy
  include Roguelike::Walkable
  attr_accessor :y, :x, :game, :life

  def initialize(game, y, x)
    @game = game
    @y, @x = y, x
    @life = Roguelike::Const::DEFAULT_LIFE
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
