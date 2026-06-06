#include <moonbit.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

moonbit_bytes_t shell_exec(const char* command) {
  FILE* pipe = _popen(command, "r");
  if (!pipe) {
    return moonbit_make_bytes(0, 0);
  }
  char buf[4096];
  size_t total = 0;
  while (fgets(buf, sizeof(buf), pipe)) {
    total += strlen(buf);
  }
  _pclose(pipe);

  pipe = _popen(command, "r");
  if (!pipe) return moonbit_make_bytes(0, 0);

  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(total, 0);
  size_t pos = 0;
  while (fgets(buf, sizeof(buf), pipe)) {
    size_t len = strlen(buf);
    memcpy(bytes + pos, buf, len);
    pos += len;
  }
  _pclose(pipe);
  return (moonbit_bytes_t)bytes;
}
