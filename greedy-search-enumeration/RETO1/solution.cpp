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

  int64_t wordCount = nextInt64(inputData, scanPos);
  int64_t delay = nextInt64(inputData, scanPos);
  int64_t remainingCount = 1;
  int64_t previousTime = nextInt64(inputData, scanPos);

  for (int64_t idx = 1; idx < wordCount; idx++) {
    int64_t currentTime = nextInt64(inputData, scanPos);
    if (currentTime - previousTime > delay) {
      remainingCount = 1;
    } else {
      remainingCount++;
    }
    previousTime = currentTime;
  }

  std::string outputBuffer;
  outputBuffer.reserve(flushBlockBytes);
  outputBuffer.append(std::to_string(remainingCount));
  outputBuffer.push_back('\n');
  std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  return 0;
}
