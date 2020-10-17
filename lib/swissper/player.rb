module Swissper
  class Player
    attr_accessor :delta, :exclude

    def initialize
      @delta = 0
      @exclude = []
      @side_balance = 0
    end
  end
end
