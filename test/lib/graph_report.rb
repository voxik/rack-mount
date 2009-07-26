class GraphReport
  def initialize(possible_keys)
    @possible_keys = possible_keys
  end

  def full_report
    @full_report ||= begin
      report = {}
      uniq_keys.all_permutations.each do |permutation|
        graph = graph(permutation)
        report[permutation] = {
          :key_count => permutation.size,
          :graph_height => graph.height,
          :graph_average => graph.average_height
        }
      end
      report
    end
  end

  def filtered_by_max_height
    @filtered_by_max_height ||= filter_minimum_statistic(full_report, :graph_height)
  end

  def filtered_by_avg_height
    @filtered_by_avg_height ||= filter_minimum_statistic(filtered_by_max_height, :graph_average)
  end

  def filtered_by_key_count
    @filtered_by_key_count ||= filter_minimum_statistic(filtered_by_avg_height, :key_count)
  end

  def good_choices
    @good_choices ||= format_report(filtered_by_max_height)
  end

  def better_choices
    @best_choices ||= format_report(filtered_by_avg_height)
  end

  def best_choices
    @best_choices ||= format_report(filtered_by_key_count)
  end

  def message
    <<-EOS
    Graph Report for: #{uniq_keys.join(', ')}
      Best: #{best_choices.map(&:inspect).join(', ')}
      Better: #{better_choices.map(&:inspect).join(', ')}
      Good: #{good_choices.map(&:inspect).join(', ')}
    EOS
  end

  private
    def filter_minimum_statistic(report, stat)
      min = report.inject(1/0.0) { |min, (_, stats)| min > stats[stat] ? stats[stat] : min }
      report.select { |_, stats| stats[stat] == min }
    end

    def format_report(report)
      report.inject([]) { |choices, (keys, _)|
        choices << keys
        choices
      }
    end

    def uniq_keys
      @possible_keys.map(&:keys).flatten.uniq
    end

    def graph(keys)
      graph = Rack::Mount::Multimap.new
      @possible_keys.each do |possible_key|
        graph_keys = keys.map { |k| possible_key[k] }
        Rack::Mount::Utils.pop_trailing_nils!(graph_keys)
        graph_keys.map! { |k| k || /.+/ }
        graph[*graph_keys] = true
      end
      graph
    end
end
