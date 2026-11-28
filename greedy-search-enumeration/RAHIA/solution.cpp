#include <cstdio>
#include <cstddef>

typedef unsigned long long u64;

struct Scanner {
  static const int BufferSize = 1 << 16;
  char buffer[BufferSize];
  int position = 0;
  int length = 0;
  int get() {
    if (position >= length) {
      length = (int)fread(buffer, 1, BufferSize, stdin);
      position = 0;
      if (length == 0) return -1;
    }
    return buffer[position++];
  }
  u64 nextNumber() {
    int c = get();
    while (c != -1 && (c < '0' || c > '9')) c = get();
    u64 value = 0;
    while (c >= '0' && c <= '9') {
      value = value * 10ULL + (u64)(c - '0');
      c = get();
    }
    return value;
  }
} scanner;

int main() {
  u64 elementCount = scanner.nextNumber();
  bool possible = true;
  for (u64 index = 0; index < elementCount; index++) {
    u64 currentValue = scanner.nextNumber();
    if (currentValue < index) possible = false;
  }
  if (possible) fwrite("YES\n", 1, 4, stdout);
  else fwrite("NO\n", 1, 3, stdout);
  return 0;
}
