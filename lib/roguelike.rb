# -*- encoding: utf-8 -*-
require 'set'

module Roguelike
end

module Roguelike::Const
  INVALID_KEY = 0
  LEFT_UP = 1
  UP = 2
  RIGHT_UP = 3
  LEFT = 4
  RIGHT = 6
  LEFT_DOWN = 7
  DOWN = 8
  RIGHT_DOWN = 9
  TAP = 10

  DIRECTION_SET = Set.new([LEFT_UP, UP, RIGHT_UP, LEFT, RIGHT, LEFT_DOWN, DOWN, RIGHT_DOWN])

  DEFAULT_LIFE = 15

end

require 'roguelike/walkable'

require 'roguelike/hero'

require 'roguelike/abstract_enemy'
require 'roguelike/enemy'
require 'roguelike/enemy/bandit'

require 'roguelike/game'
require 'roguelike/game_factory'

