require 'abstract_unit'

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
    assert_equal [char('a', :quantifier => '?')], parse(%r{a?})
    assert_equal [char('a', :quantifier => '{3}')], parse(%r{a{3}})
    assert_equal [char('a', :quantifier => '{3,4}')], parse(%r{a{3,4}})
  end

  def test_anchors
    assert_equal [
      anchor('^'),
      char('f'),
      char('o'),
      char('o')
    ], parse(%r{^foo})

    assert_equal [
      anchor('\A'),
      char('f'),
      char('o'),
      char('o')
    ], parse(%r{\Afoo})

    assert_equal [
      char('f'),
      char('o'),
      char('o'),
      anchor('$')
    ], parse(%r{foo$})

    assert_equal [
      char('f'),
      char('o'),
      char('o'),
      anchor('\Z')
    ], parse(%r{foo\Z})
  end

  def test_wild_card_range
    assert_equal [
      char('f'),
      range('.'),
      range('.'),
      char('k')
    ], parse(%r{f..k})

    result = parse(%r{f..k})
    assert result[0].include?('f')
    assert !result[0].include?('F')
    assert result[1].include?('u')
    assert result[2].include?('c')
    assert result[3].include?('k')
  end

  def test_digit_range
    assert_equal [range('\d'), char('s')], parse(%r{\ds})
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

  def test_named_group
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = eval('%r{/foo(?<bar>baz)}')
    else
      regexp = %r{/foo(?:<bar>baz)}
    end

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
    ], parse(regexp)
  end

  def test_nested_named_group
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = eval('%r{a((?<b>c))?}')
    else
      regexp = %r{a((?:<b>c))?}
    end

    assert_equal [
      char('a'),
      group([
        group([char('c')], :name => 'b')
      ], :quantifier => '?')
    ], parse(regexp)
  end

  def test_ignorecase_option
    re = parse(/abc/i)
    assert re.casefold?
  end

  private
    def parse(regexp)
      @parser.parse_regexp(regexp)
    end

    def anchor(value)
      RegexpParser::Anchor.new(value)
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
