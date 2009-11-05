require 'abstract_unit'
require 'rack/mount/regexp/parser'

class TestRegexpParser < Test::Unit::TestCase
  RegexpParser = Rack::Mount::RegexpParser

  def setup
    @parser = RegexpParser.new
  end

  def test_parse
    regexp = %r{/foo}
    assert_equal [
      char('/'),
      char('f'),
      char('o'),
      char('o')
    ], @parser.scan_str(regexp.source)

    regexp = %r{/foo(/bar)?}
    assert_equal [
      char('/'),
      char('f'),
      char('o'),
      char('o'),
      group([
        char('/'),
        char('b'),
        char('a'),
        char('r')
      ], :quantifier => '?')
    ], @parser.scan_str(regexp.source)
  end

  private
    def char(value)
      RegexpParser::Character.new(value)
    end

    def group(value, options = {})
      group = RegexpParser::Group.new(value)
      group.quantifier = options.delete(:quantifier)
      group
    end
end
