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
  u64 bucketBase = scanner.nextNumber();
  u64 bucketExponent = scanner.nextNumber();
  u64 roomCount = scanner.nextNumber();
  u64 powerBase = bucketBase % roomCount;
  u64 powerResult = 1 % roomCount;
  u64 exponentCursor = bucketExponent;
  while (exponentCursor > 0) {
    if ((exponentCursor & 1ULL) != 0) powerResult = (powerResult * powerBase) % roomCount;
    powerBase = (powerBase * powerBase) % roomCount;
    exponentCursor >>= 1;
  }
  u64 extraBuckets = powerResult;
  u64 mangoRemainder = 0;
  if (extraBuckets > 0) {
    u64 partitionCount = scanner.nextNumber();
    for (u64 partitionIndex = 0; partitionIndex < partitionCount; partitionIndex++) {
      u64 mangoAmount = scanner.nextNumber();
      mangoRemainder = (mangoRemainder + mangoAmount % extraBuckets) % extraBuckets;
    }
  }
  char line[32];
  int lineLength = 0;
  char scratch[24];
  int scratchLength = 0;
  u64 value = extraBuckets;
  if (value == 0) scratch[scratchLength++] = '0';
  while (value > 0) { scratch[scratchLength++] = (char)('0' + (value % 10ULL)); value /= 10ULL; }
  while (scratchLength > 0) line[lineLength++] = scratch[--scratchLength];
  line[lineLength++] = ' ';
  scratchLength = 0;
  value = mangoRemainder;
  if (value == 0) scratch[scratchLength++] = '0';
  while (value > 0) { scratch[scratchLength++] = (char)('0' + (value % 10ULL)); value /= 10ULL; }
  while (scratchLength > 0) line[lineLength++] = scratch[--scratchLength];
  line[lineLength++] = '\n';
  fwrite(line, 1, (size_t)lineLength, stdout);
  return 0;
}
