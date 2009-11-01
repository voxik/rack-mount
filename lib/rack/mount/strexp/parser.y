class Rack::Mount::StrexpParser
rule
  target: expr { result = "\\A#{val}\\Z" }

  expr: expr token { result = val }
      | token

  token: PARAM {
           name = val[0].to_sym
           requirement = requirements[name]
           result = Const::REGEXP_NAMED_CAPTURE % [name, requirement]
         }
       | GLOB {
           name = val[0].to_sym
           result = Const::REGEXP_NAMED_CAPTURE % [name, '.+']
         }
       | LPAREN expr RPAREN { result = "(#{val[1]})?" }
       | CHAR { result = Regexp.escape(val[0]) }
end

---- header ----
require 'rack/mount/strexp/tokenizer'
