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
  bool nextNumber(u64 &value) {
    int c = get();
    while (c != -1 && (c < '0' || c > '9')) c = get();
    if (c == -1) return false;
    value = 0;
    while (c >= '0' && c <= '9') {
      value = value * 10ULL + (u64)(c - '0');
      c = get();
    }
    return true;
  }
} scanner;

int main() {
  static char outputBuffer[1 << 17];
  int outputLength = 0;
  u64 leftHand, rightHand;
  while (scanner.nextNumber(leftHand)) {
    if (!scanner.nextNumber(rightHand)) break;
    u64 sum = leftHand + rightHand;
    char scratch[24];
    int scratchLength = 0;
    if (sum == 0) scratch[scratchLength++] = '0';
    while (sum > 0) {
      scratch[scratchLength++] = (char)('0' + (sum % 10ULL));
      sum /= 10ULL;
    }
    while (scratchLength > 0) {
      outputBuffer[outputLength++] = scratch[--scratchLength];
      if (outputLength >= (1 << 16)) {
        fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
        outputLength = 0;
      }
    }
    outputBuffer[outputLength++] = '\n';
    if (outputLength >= (1 << 16)) {
      fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
      outputLength = 0;
    }
  }
  fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
  return 0;
}
