#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string.h>
#include "prog.h"
#include "parser.h"

int main()
{
  // https://stackoverflow.com/questions/2602013/read-whole-ascii-file-into-c-stdstring
  std::ifstream t("example.smc");
  std::stringstream buffer;
  buffer << t.rdbuf();
  string program = buffer.str();
  Parser p;
  p.parse_program(program);
}
