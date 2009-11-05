require 'abstract_unit'
require 'rack/mount/regexp/parser'

class TestRegexpParser < Test::Unit::TestCase
  RegexpParser = Rack::Mount::RegexpParser

  def setup
    @parser = RegexpParser.new
  end

  def test_slash
    assert_equal [char('/')], parse(/\//)
    assert_equal [char('/')], parse(%r{/})
    assert_equal [char('/')], parse(%r{\/})
  end

  def test_escaped_specials
    assert_equal [char('^')], parse(%r{\^})
    assert_equal [char('.')], parse(%r{\.})
    assert_equal [char('[')], parse(%r{\[})
    assert_equal [char(']')], parse(%r{\]})
    assert_equal [char('$')], parse(%r{\$})
    assert_equal [char('(')], parse(%r{\(})
    assert_equal [char(')')], parse(%r{\)})
    assert_equal [char('|')], parse(%r{\|})
    assert_equal [char('*')], parse(%r{\*})
    assert_equal [char('+')], parse(%r{\+})
    assert_equal [char('?')], parse(%r{\?})
    assert_equal [char('{')], parse(%r{\{})
    assert_equal [char('}')], parse(%r{\}})
    assert_equal [char('\\')], parse(%r{\\})
  end

  def test_characters
    assert_equal [
      char('f'),
      char('o'),
      char('o')
    ], parse(%r{foo})
  end

  def test_character_with_quantifier
    assert_equal [char('a', :quantifier => '*')], parse(%r{a*})
    assert_equal [char('a', :quantifier => '+')], parse(%r{a+})
    assert_equal [char('a', :quantifier => '?')], parse(%r{a?})
  end

  def test_group
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
      ])
    ], parse(%r{/foo(/bar)})
  end

  def test_group_with_quantifier
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
    ], parse(%r{/foo(/bar)?})
  end

  def test_noncapture_group
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
      ], :capture => false)
    ], parse(%r{/foo(?:/bar)})
  end

  private
    def parse(regexp)
      @parser.scan_str(regexp.source)
    end

    def char(value, options = {})
      char = RegexpParser::Character.new(value)
      char.quantifier = options.delete(:quantifier)
      char
    end

    def group(value, options = {})
      group = RegexpParser::Group.new(value)
      options.each { |k, v| group.send("#{k}=", v) }
      group
    end
end
