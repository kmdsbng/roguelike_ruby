# -*- encoding: utf-8 -*-
module Roguelike::Walkable
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

