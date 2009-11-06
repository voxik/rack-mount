class Rack::Mount::RegexpParser
rule
  \^          { [:L_ANCHOR, text] }
  \\A         { [:L_ANCHOR, text] }
  \$          { [:R_ANCHOR, text] }
  \\Z         { [:R_ANCHOR, text] }

  <(\w+)>     { [:NAME, @ss[1]] }

  \(          { [:LPAREN,  text] }
  \)          { [:RPAREN,  text] }
  \[          { [:LBRACK,  text] }
  \]          { [:RBRACK,  text] }
  \{          { [:LCURLY,  text] }
  \{          { [:RCURLY,  text] }

  \.          { [:DOT, text] }
  \?          { [:QMARK, text] }
  \+          { [:PLUS,  text] }
  \*          { [:STAR,  text] }
  \:          { [:COLON, text] }

  \\(.)       { [:CHAR, @ss[1]] }
  .           { [:CHAR, text] }
end
