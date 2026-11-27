#include <cstdint>
#include <cstdio>
#include <string>

static const int flushBlockBytes = 1 << 17;

static std::string readInputBytes() {
  std::string data;
  char chunk[65536];
  size_t got;
  while ((got = std::fread(chunk, 1, sizeof(chunk), stdin)) > 0) {
    data.append(chunk, got);
  }
  return data;
}

static int64_t nextInt64(const std::string &data, size_t &pos) {
  while (pos < data.size() && (data[pos] < '0' || data[pos] > '9')) {
    pos++;
  }
  if (pos >= data.size()) {
    return 0;
  }
  int64_t value = 0;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    value = value * 10 + static_cast<int64_t>(data[pos] - '0');
    pos++;
  }
  return value;
}

static void appendInt64(std::string &outBuffer, int64_t value) {
  char digits[24];
  int len = 0;
  if (value == 0) {
    digits[len++] = '0';
  } else {
    while (value > 0) {
      digits[len++] = static_cast<char>('0' + (value % 10));
      value /= 10;
    }
  }
  while (len > 0) {
    outBuffer.push_back(digits[--len]);
  }
  outBuffer.push_back('\n');
  if (static_cast<int>(outBuffer.size()) >= flushBlockBytes) {
    std::fwrite(outBuffer.data(), 1, outBuffer.size(), stdout);
    outBuffer.clear();
  }
}

int main() {
  std::string inputData = readInputBytes();
  size_t scanPos = 0;
  std::string outputBuffer;
  outputBuffer.reserve(flushBlockBytes + 64);

  while (true) {
    int64_t sideLen = nextInt64(inputData, scanPos);
    if (sideLen == 0) {
      break;
    }
    int64_t squaresCount = sideLen * (sideLen + 1) * (2 * sideLen + 1) / 6;
    appendInt64(outputBuffer, squaresCount);
  }
  if (!outputBuffer.empty()) {
    std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  }
  return 0;
}
