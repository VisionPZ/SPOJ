#include <cstdio>
#include <string>
#include <vector>

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

static bool nextInt64(const std::string &data, size_t &pos, long long &value) {
  while (pos < data.size() && data[pos] != '-' && (data[pos] < '0' || data[pos] > '9')) {
    pos++;
  }
  if (pos >= data.size()) {
    return false;
  }
  bool negative = false;
  if (data[pos] == '-') {
    negative = true;
    pos++;
  }
  unsigned long long magnitude = 0;
  bool anyDigit = false;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    magnitude = magnitude * 10ULL + static_cast<unsigned long long>(data[pos] - '0');
    pos++;
    anyDigit = true;
  }
  if (!anyDigit) {
    return nextInt64(data, pos, value);
  }
  value = negative ? -static_cast<long long>(magnitude) : static_cast<long long>(magnitude);
  return true;
}

static void appendLiteral(std::string &outBuffer, const char *text) {
  outBuffer.append(text);
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

  std::vector<long long> sequenceValues;
  std::vector<unsigned char> seenDifferences;

  long long rawLength = 0;
  while (nextInt64(inputData, scanPos, rawLength)) {
    if (rawLength <= 0) {
      break;
    }
    int caseLength = static_cast<int>(rawLength);
    if (static_cast<int>(sequenceValues.size()) < caseLength) {
      sequenceValues.resize(caseLength);
    }
    if (static_cast<int>(seenDifferences.size()) < caseLength) {
      seenDifferences.resize(caseLength, 0);
    }

    bool allRead = true;
    for (int idx = 0; idx < caseLength; idx++) {
      if (!nextInt64(inputData, scanPos, sequenceValues[idx])) {
        allRead = false;
        break;
      }
    }
    if (!allRead) {
      break;
    }

    bool isJolly = true;
    int distinctCount = 0;
    for (int idx = 0; idx + 1 < caseLength; idx++) {
      long long cur = sequenceValues[idx + 1];
      long long prev = sequenceValues[idx];
      unsigned long long diff = cur >= prev
          ? static_cast<unsigned long long>(cur) - static_cast<unsigned long long>(prev)
          : static_cast<unsigned long long>(prev) - static_cast<unsigned long long>(cur);
      if (diff == 0 || diff >= static_cast<unsigned long long>(caseLength) ||
          seenDifferences[static_cast<size_t>(diff)]) {
        isJolly = false;
      } else {
        seenDifferences[static_cast<size_t>(diff)] = 1;
        distinctCount++;
      }
    }
    if (distinctCount != caseLength - 1) {
      isJolly = false;
    }
    appendLiteral(outputBuffer, isJolly ? "Jolly\n" : "Not jolly\n");
    for (int diffIdx = 1; diffIdx < caseLength; diffIdx++) {
      seenDifferences[diffIdx] = 0;
    }
  }

  if (!outputBuffer.empty()) {
    std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  }
  return 0;
}
