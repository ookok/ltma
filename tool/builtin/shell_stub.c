#include <moonbit.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
  #define POPEN _popen
  #define PCLOSE _pclose
#else
  #define POPEN popen
  #define PCLOSE pclose
#endif

moonbit_bytes_t shell_exec(const char* command) {
  FILE* pipe = POPEN(command, "r");
  if (!pipe) {
    return moonbit_make_bytes(0, 0);
  }
  char buf[4096];
  size_t total = 0;
  while (fgets(buf, sizeof(buf), pipe)) {
    total += strlen(buf);
  }
  PCLOSE(pipe);

  pipe = POPEN(command, "r");
  if (!pipe) return moonbit_make_bytes(0, 0);

  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(total, 0);
  size_t pos = 0;
  while (fgets(buf, sizeof(buf), pipe)) {
    size_t len = strlen(buf);
    memcpy(bytes + pos, buf, len);
    pos += len;
  }
  PCLOSE(pipe);
  return (moonbit_bytes_t)bytes;
}
