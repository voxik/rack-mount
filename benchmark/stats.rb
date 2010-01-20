require 'rack/mount'

EchoApp = lambda { |env| [200, {'Content-Type' => 'text/html'}, ['OK']] }

module GraphRecognitionKeys
  attr_accessor :_recognition_keys

  private
    def build_recognition_keys
      @_recognition_keys
    end
end


class Array
  def all_permutations
    a = []
    (0..size).each { |n| _each_permutation(n) { |e| a << e } }
    a
  end

  def _each_permutation(n)
    if size < n or n < 0
    elsif n == 0
      yield([])
    else
      self[1..-1]._each_permutation(n - 1) do |x|
        (0...n).each do |i|
          yield(x[0...i] + [first] + x[i..-1])
        end
      end
      self[1..-1]._each_permutation(n) do |x|
        yield(x)
      end
    end
  end
  protected :_each_permutation
end

class MapReduce
  class StepIterator
    include Enumerable

    def initialize(enum, step = 1, offset = 0)
      @enum, @step, @offset = enum, step, offset
    end

    def each
      @enum.each_with_index do |element, index|
        if (index + @offset) % @step == 0
          yield element
        end
      end
    end
  end

  attr_accessor :initial
  attr_accessor :map, :reduce
  attr_accessor :threads

  Identity = lambda { |e| e }

  Reduce = lambda { |result, (key, value)|
    result[key] = value
    result
  }

  def initialize
    @initial = {}
    @map = Identity
    @reduce = Reduce
    @threads = 1
  end

  def process(enum)
    (0...threads).to_a.map { |index|
      Thread.new {
        StepIterator.new(enum, threads, index).map { |element|
          [element, @map.call(element)]
        }
      }
    }.inject(initial.dup) { |result, thread|
      thread.join.value.each { |pair|
        @reduce.call(result, pair)
      }
      result
    }
  end
end


class GraphReport
  def initialize(routes)
    @routes = routes
  end

  def full_report
    @full_report ||= begin
      job = MapReduce.new

      job.initial = {}

      job.map = lambda do |permutation|
        $stderr.write "Permutation: #{permutation.inspect}" if $VERBOSE

        graph = routes(permutation).instance_variable_get('@recognition_graph')

        {
          :key_count => permutation.size,
          :graph_height => graph.height,
          :graph_average => graph.average_height
        }
      end

      job.threads = 8

      job.process key_set.to_a.all_permutations
    end
  end

  def filtered_by_max_height
    @filtered_by_max_height ||= select_minimum_statistic(full_report, :graph_height)
  end

  def filtered_by_avg_height
    @filtered_by_avg_height ||= select_minimum_statistic(filtered_by_max_height.last, :graph_average)
  end

  def filtered_by_key_count
    @filtered_by_key_count ||= select_minimum_statistic(filtered_by_max_height.last, :key_count)
  end

  def good_choices
    @good_choices ||= [filtered_by_max_height.first, format_report(filtered_by_max_height.last)]
  end

  def better_choices
    @best_choices ||= [filtered_by_avg_height.first, format_report(filtered_by_avg_height.last)]
  end

  def best_choices
    @best_choices ||= [filtered_by_key_count.first, format_report(filtered_by_key_count.last)]
  end

  def statistical_choices
    @statistical_choices ||= analyzer.report
  end

  def inspect
    <<-EOS
    Graph Report:
      Key count (#{best_choices.first}):      #{best_choices.last.map(&:inspect).join(', ') }
      Average height (#{better_choices.first}): #{better_choices.last.map(&:inspect).join(', ') }
      Statistical: #{statistical_choices.map(&:inspect).join(', ') }
    EOS
  end

  private
    def select_minimum_statistic(report, stat)
      report_min = report.inject(1/0.0) { |min, (_, stats)| min > stats[stat] ? stats[stat] : min }
      return report_min, report.select { |_, stats| stats[stat] == report_min }
    end

    def format_report(report)
      report.inject([]) { |choices, (keys, _)|
        choices << keys
        choices
      }
    end

    def analyzer
      @routes.instance_variable_get('@recognition_key_analyzer')
    end

    def key_set
      @key_set ||= Set.new(analyzer.possible_keys.map(&:keys).flatten)
    end

    def routes(keys)
      routes = @routes.dup
      routes.extend(GraphRecognitionKeys)
      routes._recognition_keys = keys
      routes.rehash
      routes
    end
end
