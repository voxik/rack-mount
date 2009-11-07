class Rack::Mount::RegexpParser
rule
  expression: branch { result = Expression.new(val[0]) }

  branch: branch atom quantifier {
            val[1].quantifier = val[2]
            result = Node.new(val[0], val[1])
          }
        | branch atom { result = Node.new(val[0], val[1]) }
        | atom quantifier {
            val[0].quantifier = val[1]
            result = val[0]
          }
        | atom

  atom: group
      | LBRACK bracket_expression RBRACK { result = CharacterRange.new(val[1]) }
      | LBRACK L_ANCHOR bracket_expression RBRACK { result = CharacterRange.new(val[2]); result.negate = true }
      | CHAR_CLASS { result = CharacterRange.new(val[0]) }
      | DOT { result = CharacterRange.new(val[0]) }
      | anchor { result = Anchor.new(val[0]) }
      | CHAR { result = Character.new(val[0]) }

  bracket_expression: bracket_expression CHAR { result = val.join }
                    | CHAR

  group: LPAREN expression RPAREN { result = Group.new(val[1]) }
       | LPAREN QMARK COLON expression RPAREN { result = Group.new(val[3]); result.capture = false }
       | LPAREN QMARK NAME expression RPAREN { result = Group.new(val[3]); result.name = val[2] }

  anchor: L_ANCHOR
        | R_ANCHOR

  quantifier: STAR
            | PLUS
            | QMARK
            | LCURLY CHAR CHAR CHAR RCURLY { result = val.join }
            | LCURLY CHAR RCURLY { result = val.join }
end

---- header
require 'rack/mount/regexp/tokenizer'

---- inner

def parse_regexp(regexp)
  unless regexp.is_a?(RegexpWithNamedGroups)
    regexp = RegexpWithNamedGroups.new(regexp)
  end

  expression = scan_str(regexp.source)
  expression.ignorecase = regexp.casefold?

  unless Const::SUPPORTS_NAMED_CAPTURES
    @capture_index = 0
    tag_captures!(regexp.names, expression)
  end

  expression
end

def tag_captures!(names, group)
  group.each do |child|
    if child.is_a?(Group)
      if child.capture
        child.name = names[@capture_index]
        @capture_index += 1
      end
      tag_captures!(names, child)
    elsif child.is_a?(Array)
      tag_captures!(names, child)
    end
  end
end


class Node < Struct.new(:left, :right)
  def flatten
    if left.is_a?(Node)
      left.flatten + [right]
    else
      [left, right]
    end
  end
end

class Expression < Array
  attr_accessor :ignorecase

  def initialize(ary)
    if ary.is_a?(Node)
      super(ary.flatten)
    else
      super([ary])
    end
  end

  def casefold?
    ignorecase
  end
end

class Group < Struct.new(:value)
  attr_accessor :quantifier, :capture, :name

  def initialize(*args)
    @capture = true
    super
  end

  def to_regexp
    value.map { |e| e.regexp_source }.join
  end

  def regexp_source
    "(#{capture ? '' : '?:'}#{value.map { |e| e.regexp_source }.join})#{quantifier}"
  end

  def capture?
    capture
  end

  def ==(other)
    self.value == other.value &&
      self.quantifier == other.quantifier &&
      self.capture == other.capture &&
      self.name == other.name
  end
end

class Anchor < Struct.new(:value)
end

class CharacterRange < Struct.new(:value)
  attr_accessor :negate, :quantifier

  def regexp_source
    if value == '.' || value == '\d'
      "#{value}#{quantifier}"
    else
      "[#{negate && '^'}#{value}]#{quantifier}"
    end
  end

  def include?(char)
    Regexp.compile("^#{regexp_source}$") =~ char.to_s
  end

  def ==(other)
    self.value == other.value &&
      self.negate == other.negate &&
      self.quantifier == other.quantifier
  end
end

class Character < Struct.new(:value)
  attr_accessor :quantifier

  def regexp_source
    "#{value}#{quantifier}"
  end

  def ==(other)
    self.value == other.value &&
      self.quantifier == other.quantifier
  end
end
