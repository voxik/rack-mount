class Rack::Mount::RegexpParser
rule
  # \\\.      { [:CHAR, '\.']}
  # \\\(      { [:CHAR, '\(']}
  # \\\)      { [:CHAR, '\)']}

  # \\[0-9]   { [:BACKREF,  text] }
  # \\A       { [:L_ANCHOR, text] }
  # \\Z       { [:R_ANCHOR, text] }
  # \^        { [:L_ANCHOR, text] }
  # \$        { [:R_ANCHOR, text] }

  <(\w+)>     { [:NAME, @ss[1]] }

  \(          { [:LPAREN,  text] }
  \)          { [:RPAREN,  text] }
  # \[        { [:LBRACK,  text] }
  # \]        { [:RBRACK,  text] }
  # \{        { [:LCURLY,  text] }
  # \{        { [:RCURLY,  text] }

  # \.        { [:DOT, text] }
  # \-        { [:MINUS,  text] }

  \?          { [:QMARK, text] }
  \+          { [:PLUS,  text] }
  \*          { [:STAR,  text] }
  \:          { [:COLON, text] }

  \\(.)       { [:CHAR, @ss[1]] }
  .           { [:CHAR, text] }

  # \\?(.)            { [:CHAR, @ss[1]] }
  # (?:\\(.)|(.))     { [:CHAR, @ss[1] || @ss[2]] }
end
