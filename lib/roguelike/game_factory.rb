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

