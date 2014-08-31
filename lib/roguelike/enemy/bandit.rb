# -*- encoding: utf-8 -*-
class Roguelike::Enemy::Bandit < Roguelike::AbstractEnemy

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
      y_diff = @game.hero.y - @y
      y_distance = y_diff == 0 ? 0 : y_diff / y_diff.abs
      y_pats = [y_distance, 0].uniq
      x_diff = @game.hero.x - @x
      x_distance = x_diff == 0 ? 0 : x_diff / x_diff.abs
      x_pats = [x_distance, 0].uniq
      pats = y_pats.flat_map {|y| x_pats.map {|x| [y, x]}}
      pats.each {|y, x|
        break if self.walk_if_can(y, x)
      }
    end
  end

end

