require 'swissper/version'
require 'swissper/player'
require 'swissper/bye'
require 'graph_matching'

module Swissper
  def self.pair(players, options = {})
    Pairer.new(options).pair(players)
  end

  class Pairer
    def initialize(options = {})
      @delta_key = options[:delta_key] || :delta
      @side_key = option[:side_key] || 0
      @exclude_key = options[:exclude_key] || :exclude
      @bye_delta = options[:bye_delta] || -1
    end

    def pair(player_data)
      @player_data = player_data
      graph.maximum_weighted_matching(true).edges.map do |pairing|
        [players[pairing[0]], players[pairing[1]]]
      end
    end

    private

    attr_reader :delta_key, :side_key, :exclude_key, :bye_delta

    def graph
      edges = [].tap do |e|
        players.each_with_index do |player, i|
          players.each_with_index do |opp, j|
            e << [i, j, delta(player,opp)] if permitted?(player, opp)
          end
        end
      end
      GraphMatching::Graph::WeightedGraph.send('[]', *edges)
    end

    def permitted?(a, b)
      targets(a).include?(b) && targets(b).include?(a)
    end

    #Modified this formula to add a weight for pairing people with mis-matched sides.
    #Currently this formula is weighted such that it will pair up to +/- 2 for side parity
    #(However it will still favor other players at the same rank and +/- 1 more)
    #Changing the size of the delta multiplier changes this- could potentially be set-able,
    #But with this criteria only 0.15% of time will anyone play mistmatched sides (barring byes)
    def delta(a, b)
      0 - (delta_value(a) - delta_value(b))*3 - side_delta(a,b)
    end

    def targets(player)
      players - [player] - excluded_opponents(player)
    end

    def delta_value(player)
      return player.send(delta_key) if player.respond_to?(delta_key)
      return bye_delta if player == Swissper::Bye

      0
    end

    def side_delta(player_a, player_b)
        return 0 unless player_a.respond_to?(side_key) && player_b.respond_to?(side_key)
            if player_a.send(side_key) * player_b.send(side_key) > 0
                return 8**(min([player_a.send(side_key), player_b.send(side_key)]))
            else
                return 0
            end
        end
    end

    def excluded_opponents(player)
      return player.send(exclude_key) if player.respond_to?(exclude_key)

      []
    end

    def players
      @players ||= @player_data.clone.tap do |data|
        data << Swissper::Bye unless data.length.even?
      end.shuffle
    end
  end
end
