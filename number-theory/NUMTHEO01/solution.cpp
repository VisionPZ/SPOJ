#include <cstdio>
#include <cstdint>
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

static uint64_t nextUInt64(const std::string &data, size_t &pos) {
  while (pos < data.size() && (data[pos] < '0' || data[pos] > '9')) {
    pos++;
  }
  uint64_t value = 0;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    value = value * 10ULL + static_cast<uint64_t>(data[pos] - '0');
    pos++;
  }
  return value;
}

static void appendUInt64(std::string &outBuffer, uint64_t value) {
  char digits[24];
  int len = 0;
  if (value == 0) {
    digits[len++] = '0';
  } else {
    while (value > 0) {
      digits[len++] = static_cast<char>('0' + (value % 10ULL));
      value /= 10ULL;
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

  uint64_t queryCount = nextUInt64(inputData, scanPos);
  for (uint64_t queryIndex = 0; queryIndex < queryCount; queryIndex++) {
    uint64_t factorialLimit = nextUInt64(inputData, scanPos);
    uint64_t modulusValue = nextUInt64(inputData, scanPos);
    if (modulusValue <= 1ULL || factorialLimit >= modulusValue) {
      appendUInt64(outputBuffer, 0ULL);
      continue;
    }
    uint64_t productValue = 1ULL;
    for (uint64_t factor = 2ULL; factor <= factorialLimit; factor++) {
      productValue = static_cast<uint64_t>(
          (static_cast<unsigned __int128>(productValue) * factor) % modulusValue);
      if (productValue == 0ULL) {
        break;
      }
    }
    appendUInt64(outputBuffer, productValue);
  }
  if (!outputBuffer.empty()) {
    std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  }
  return 0;
}
