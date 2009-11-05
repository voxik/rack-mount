class Rack::Mount::RegexpParser
rule
  # \\\.      { [:CHAR, '\.']}
  # \\\(      { [:CHAR, '\(']}
  # \\\)      { [:CHAR, '\)']}

  # \?<([^>]+)>  { [:NAME, @ss[1]] }
  # \?:<([^>]+)> { [:NAME, @ss[1]] }

  # \\[0-9]   { [:BACKREF,  text] }
  # \\A       { [:L_ANCHOR, text] }
  # \\Z       { [:R_ANCHOR, text] }
  # \^        { [:L_ANCHOR, text] }
  # \$        { [:R_ANCHOR, text] }

  \(        { [:LPAREN,  text] }
  \)        { [:RPAREN,  text] }
  # \[        { [:LBRACK,  text] }
  # \]        { [:RBRACK,  text] }
  # \{        { [:LCURLY,  text] }
  # \{        { [:RCURLY,  text] }

  # \.        { [:DOT, text] }
  \?        { [:QMARK,  text] }
  # \+        { [:PLUS,  text] }
  # \-        { [:MINUS,  text] }
  # \*        { [:STAR,  text] }

  .           { [:CHAR, text] }

  # \\?(.)            { [:CHAR, @ss[1]] }
  # (?:\\(.)|(.))     { [:CHAR, @ss[1] || @ss[2]] }
end
