#include <algorithm>
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
  int64_t value = 0;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    value = value * 10 + static_cast<int64_t>(data[pos] - '0');
    pos++;
  }
  return value;
}

int main() {
  std::string inputData = readInputBytes();
  size_t scanPos = 0;

  int64_t elementCount = nextInt64(inputData, scanPos);
  int64_t distinctValues[4] = {0, 0, 0, 0};
  int distinctCount = 0;

  for (int64_t idx = 0; idx < elementCount; idx++) {
    int64_t currentValue = nextInt64(inputData, scanPos);
    bool alreadySeen = false;
    for (int slot = 0; slot < distinctCount; slot++) {
      if (distinctValues[slot] == currentValue) {
        alreadySeen = true;
        break;
      }
    }
    if (!alreadySeen && distinctCount < 4) {
      distinctValues[distinctCount] = currentValue;
      distinctCount++;
    }
  }

  bool canEqualize = false;
  if (distinctCount <= 2) {
    canEqualize = true;
  } else if (distinctCount == 3) {
    std::sort(distinctValues, distinctValues + 3);
    canEqualize = (distinctValues[0] + distinctValues[2] == 2 * distinctValues[1]);
  }

  std::string outputBuffer;
  outputBuffer.reserve(flushBlockBytes);
  outputBuffer.append(canEqualize ? "Si\n" : "No\n");
  std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  return 0;
}
