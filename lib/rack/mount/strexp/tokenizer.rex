class Rack::Mount::StrexpParser
macro
  RESERVED    \(|\)|:|\*
rule
  \\\\({RESERVED})       { [:CHAR,  @ss[1]] }
  (:|\\\*)([a-zA-Z_]\w*) { [:PARAM, @ss[2]] }
  \\\(                   { [:LPAREN, text]  }
  \\\)                   { [:RPAREN, text]  }
  .                      { [:CHAR,   text]  }
end
