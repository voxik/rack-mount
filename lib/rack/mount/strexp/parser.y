class Rack::Mount::StrexpParser
rule
  expr: expr token { result = "#{val[0]}#{val[1]}" }
     | token

  token: PARAM {
          name = val[0].to_sym
          requirement = requirements[name]
          result = Const::REGEXP_NAMED_CAPTURE % [name, requirement]
        }
     | LPAREN expr RPAREN { result = "(#{val[1]})?" }
     | CHAR { result = val[0] }
end

---- header ----
require 'rack/mount/strexp/tokenizer'
