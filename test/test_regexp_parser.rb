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

  def test_bracket_expression
    assert_equal [range('a-z')], parse(%r{[a-z]})
    assert_equal [range('0-9')], parse(%r{[0-9]})
    assert_equal [range('abc')], parse(%r{[abc]})
  end

  def test_negated_bracket_expression
    assert_equal [range('abc', :negate => true)], parse(%r{[^abc]})
    assert_equal [range('/.?', :negate => true)], parse(%r{[^/\.\?]})
  end

  def test_bracket_expression_with_quantifier
    assert_equal [range('a-z', :quantifier => '+')], parse(%r{[a-z]+})
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

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_named_group
      assert_equal [
        char('/'),
        char('f'),
        char('o'),
        char('o'),
        group([
          char('b'),
          char('a'),
          char('z')
        ], :name => 'bar')
      ], parse(eval('%r{/foo(?<bar>baz)}'))
    end
  end

  private
    def parse(regexp)
      @parser.scan_str(regexp.source)
    end

    def char(value, options = {})
      char = RegexpParser::Character.new(value)
      options.each { |k, v| char.send("#{k}=", v) }
      char
    end

    def range(value, options = {})
      range = RegexpParser::CharacterRange.new(value)
      options.each { |k, v| range.send("#{k}=", v) }
      range
    end

    def group(value, options = {})
      group = RegexpParser::Group.new(value)
      options.each { |k, v| group.send("#{k}=", v) }
      group
    end
end
