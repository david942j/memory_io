#include <cstdio>
#include <iostream>
#include <string>
#include <unistd.h>

using std::cout;
using std::endl;
using std::string;

#define pause custom_pause
void pause() { scanf("%*c"); }
void handle_strings() {
  string empty;
  string inline_string("AAAABBBBCCCCDDD");
  string outline_string("abcdefghijklmnopqrstuvwxyz");
  printf("%p\n%p\n%p\n", &empty, &inline_string, &outline_string);
  pause();
  printf("%s\n", outline_string.c_str());
  pause();
}
void init() {
  setvbuf(stdout, 0, 2, 0);
  setvbuf(stderr, 0, 2, 0);
  setvbuf(stdin, 0, 2, 0);
  alarm(10);
}
#undef pause
int main() {
  init();
  handle_strings();
  return 0;
}
