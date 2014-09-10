# -*- encoding: utf-8 -*-
class Roguelike::GameFactory
  def self.build_game
    game = Roguelike::Game.new
    game.hero = Roguelike::Hero.new(game, 2, 2)
    game.enemies = [
      Roguelike::Enemy::Bandit.new(game, 5, 5),
      Roguelike::Enemy::Bandit.new(game, 3, 5),
    ]
    game.map = generate_map
    game
  end

  def self.generate_map
    height = 20
    width = 30
    map = height.times.map {[0] * width}

    create_room(map, [1, 1], [18, 28])

    map

    #[
    #  [0, 0, 0, 0, 0, 0, 0, 0, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 1, 1, 1, 1, 1, 1, 1, 0],
    #  [0, 0, 0, 0, 0, 0, 0, 0, 0],
    #]
  end

  def self.create_room(map, top_left, bottom_right)
    top, left = top_left
    bottom, right = bottom_right

    (top..bottom).each {|y|
      (left..right).each {|x|
        map[y][x] = 1
      }
    }
  end
end

