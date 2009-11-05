class Rack::Mount::RegexpParser
rule
  expression: branch { result = Expression.new(val[0].flatten) }

  branch: branch atom quantifier {
            val[1].quantifier = val[2]
            result = Node.new(val[0], val[1])
          }
        | branch atom { result = Node.new(val[0], val[1]) }
        | atom

  atom: group
      | CHAR { result = Character.new(val[0]) }

  group: LPAREN expression RPAREN { result = Group.new(val[1]) }

  quantifier: QMARK
end

---- header
require 'rack/mount/regexp/tokenizer'

---- inner

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
end

class Group < Struct.new(:value)
  attr_accessor :quantifier

  def ==(other)
    self.value == other.value &&
      self.quantifier == other.quantifier
  end
end

class Character < Struct.new(:value)
  attr_accessor :quantifier

  def ==(other)
    self.value == other.value &&
      self.quantifier == other.quantifier
  end
end
