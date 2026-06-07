#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#include <sys/stat.h>
#include <io.h>
#else
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#endif

// ---- Directory listing ----
// Returns newline-separated filenames in a directory, or empty Bytes on error/empty

MOONBIT_FFI_EXPORT
moonbit_bytes_t fs_list_dir(const char* path) {
  if (!path) return moonbit_make_bytes(0, 0);

  size_t total = 0;
  int count = 0;

#ifdef _WIN32
  char pattern[4096];
  int plen = snprintf(pattern, sizeof(pattern), "%s/*", path);
  if (plen <= 0 || plen >= (int)sizeof(pattern) - 1)
    return moonbit_make_bytes(0, 0);
  struct _finddata_t fd;
  intptr_t handle = _findfirst(pattern, &fd);
  if (handle == -1) return moonbit_make_bytes(0, 0);
  do {
    if (fd.name[0] == '.' && (fd.name[1] == '\0' ||
                              (fd.name[1] == '.' && fd.name[2] == '\0')))
      continue;
    total += strlen(fd.name) + 1;
    count++;
  } while (_findnext(handle, &fd) == 0);
  _findclose(handle);
#else
  DIR* dir = opendir(path);
  if (!dir) return moonbit_make_bytes(0, 0);
  struct dirent* entry;
  while ((entry = readdir(dir)) != NULL) {
    if (entry->d_name[0] == '.' && (entry->d_name[1] == '\0' ||
                                    (entry->d_name[1] == '.' &&
                                     entry->d_name[2] == '\0')))
      continue;
    total += strlen(entry->d_name) + 1;
    count++;
  }
  closedir(dir);
#endif

  if (count == 0) return moonbit_make_bytes(0, 0);

  uint8_t* bytes = (uint8_t*)moonbit_make_bytes(total, 0);
  size_t pos = 0;

#ifdef _WIN32
  handle = _findfirst(pattern, &fd);
  do {
    if (fd.name[0] == '.' && (fd.name[1] == '\0' ||
                              (fd.name[1] == '.' && fd.name[2] == '\0')))
      continue;
    size_t len = strlen(fd.name);
    memcpy(bytes + pos, fd.name, len);
    pos += len;
    bytes[pos++] = '\n';
  } while (_findnext(handle, &fd) == 0);
  _findclose(handle);
#else
  dir = opendir(path);
  while ((entry = readdir(dir)) != NULL) {
    if (entry->d_name[0] == '.' && (entry->d_name[1] == '\0' ||
                                    (entry->d_name[1] == '.' &&
                                     entry->d_name[2] == '\0')))
      continue;
    size_t len = strlen(entry->d_name);
    memcpy(bytes + pos, entry->d_name, len);
    pos += len;
    bytes[pos++] = '\n';
  }
  closedir(dir);
#endif

  return (moonbit_bytes_t)bytes;
}

// ---- File modification time ----
// Returns modification time in milliseconds since epoch, or -1 on error

MOONBIT_FFI_EXPORT
int64_t fs_get_mtime(const char* path) {
  if (!path) return -1;

#ifdef _WIN32
  struct _stat64 st;
  if (_stat64(path, &st) != 0) return -1;
#else
  struct stat st;
  if (stat(path, &st) != 0) return -1;
#endif

  return (int64_t)st.st_mtime * 1000LL;
}
