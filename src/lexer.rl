#include <stdlib.h>
#include <sys/types.h>

#include "ast.h"
#include "token.h"

#include "grammar.h"
#include "grammar.c"

#define REPORT(NAME) printf("t: " #NAME " ")

#define EMPTY(CODE) REPORT(#CODE); Parse(parser, CODE, NULL, &program)
#define CAPTURE(CODE) REPORT(#CODE); Parse(parser, CODE, seg_new_token(ts, te), &program)

%%{
  machine segment_lexer;

  comment = '#' [^\n]* '\n';
  whitespace = [ \t]+;

  integer = ('+'|'-')?[0-9]+;
  float = ('+'|'-')?[0-9]+'.'[0-9]+;
  true = 'true';
  false = 'false';
  string = '"' [^"]* '"';

  nonws = ^whitespace;
  nonop = [^(:&|+\-*\/%\^\n\t ];
  istart = [^(){};.|,\n\t ];
  alpha_u = [a-zA-Z_];

  identifier = istart nonws* nonop;
  symbol = ':' identifier | ':' string;

  main := |*
    comment;

    integer => { CAPTURE(INTEGER); };
    float => { EMPTY(FLOAT); };
    true => { EMPTY(TRUE); };
    false => { EMPTY(FALSE); };
    string => { EMPTY(STRING); };
    symbol => { EMPTY(SYMBOL); };

    '(' => { EMPTY(LPAREN); };
    ')' => { EMPTY(RPAREN); };
    '{' => { EMPTY(LCURLY); };
    '}' => { EMPTY(RCURLY); };
    ';' => { EMPTY(SEMI); };
    '\n' => { EMPTY(NEWLINE); };
    '=' => { EMPTY(ASSIGNMENT); };
    '.' => { EMPTY(PERIOD); };
    '|' => { EMPTY(BAR); };
    ',' => { EMPTY(COMMA); };

    identifier '(' => { EMPTY(METHODNAME); };

    identifier ':' => { EMPTY(KEYWORD); };

    identifier? '&' => { CAPTURE(ANDLIKE); };
    identifier? '|' => { EMPTY(ORLIKE); };
    identifier? '+' => { CAPTURE(PLUSLIKE); };
    identifier? '-' => { EMPTY(MINUSLIKE); };
    identifier? '*' => { EMPTY(MULTLIKE); };
    identifier? '/' => { EMPTY(DIVLIKE); };
    identifier? '%' => { EMPTY(MODLIKE); };
    identifier? '^' => { EMPTY(EXPLIKE); };
    '!' => { EMPTY(NOTLIKE); };

    identifier => { CAPTURE(IDENTIFIER); };
    '@' identifier => { EMPTY(IVAR); };
    '%' identifier => { EMPTY(TVAR); };

    whitespace;
  *|;
}%%
/* Syntax Highlighting */

%% write data nofinal;

seg_statementlist_node *seg_parse(char *content, off_t length)
{
  /* Variables used by Ragel. */
  int cs, act;
  char *ts, *te;
  char *p = content;
  const char *pe = content + length;
  const char *eof = pe;

  /* Parser state */
  int lexer_error = 0;
  void *parser = ParseAlloc(malloc);
  seg_program_node program;
  program.root = NULL;

  %% write init;

  %% write exec;

  if (cs == segment_lexer_error) {
    lexer_error = 1;
  } else {
    Parse(parser, 0, NULL, &program);
  }

  ParseFree(parser, free);

  return program.root;
}
