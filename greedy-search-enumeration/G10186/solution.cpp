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

static std::string nextToken(const std::string &data, size_t &pos) {
  while (pos < data.size() && static_cast<unsigned char>(data[pos]) <= ' ') {
    pos++;
  }
  if (pos >= data.size()) {
    return "";
  }
  size_t tokenStart = pos;
  while (pos < data.size() && static_cast<unsigned char>(data[pos]) > ' ') {
    pos++;
  }
  return data.substr(tokenStart, pos - tokenStart);
}

static bool nextIntToken(const std::string &data, size_t &pos, int &value) {
  while (pos < data.size() && data[pos] != '-' && (data[pos] < '0' || data[pos] > '9')) {
    pos++;
  }
  if (pos >= data.size()) {
    return false;
  }
  bool neg = false;
  if (data[pos] == '-') {
    neg = true;
    pos++;
  }
  int acc = 0;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    acc = acc * 10 + (data[pos] - '0');
    pos++;
  }
  value = neg ? -acc : acc;
  return true;
}

static bool isPrimeValue(int value) {
  if (value < 2) {
    return false;
  }
  for (int divisor = 2; divisor * divisor <= value; divisor++) {
    if (value % divisor == 0) {
      return false;
    }
  }
  return true;
}

static void appendInt(std::string &buf, int value) {
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
    buf.push_back(digits[--len]);
  }
}

int main() {
  std::string inputData = readInputBytes();
  size_t scanPos = 0;
  std::string outputBuffer;
  outputBuffer.reserve(flushBlockBytes);

  int participantCount = 0;
  while (nextIntToken(inputData, scanPos, participantCount)) {
    std::vector<std::string> names(participantCount);
    for (int idx = 0; idx < participantCount; idx++) {
      names[idx] = nextToken(inputData, scanPos);
    }
    std::vector<int> enteredValues(participantCount);
    for (int idx = 0; idx < participantCount; idx++) {
      nextIntToken(inputData, scanPos, enteredValues[idx]);
    }
    int targetValue = 0;
    nextIntToken(inputData, scanPos, targetValue);

    int bestDiff = -1;
    int bestIndex = 0;
    for (int idx = 0; idx < participantCount; idx++) {
      int currentValue = enteredValues[idx];
      int neighborValue = 0;
      if (participantCount == 1) {
        neighborValue = 0;
      } else if (idx == participantCount - 1) {
        neighborValue = enteredValues[idx - 1];
      } else {
        neighborValue = enteredValues[idx + 1];
      }
      int raw = isPrimeValue(currentValue)
          ? (currentValue + neighborValue)
          : (currentValue - neighborValue);
      int resultValue = raw < 0 ? -raw : raw;
      int diff = resultValue - targetValue;
      if (diff < 0) {
        diff = -diff;
      }
      if (bestDiff < 0 || diff < bestDiff) {
        bestDiff = diff;
        bestIndex = idx;
      }
    }

    outputBuffer.append(names[bestIndex]);
    outputBuffer.push_back(' ');
    appendInt(outputBuffer, enteredValues[bestIndex]);
    outputBuffer.push_back('\n');
    if (static_cast<int>(outputBuffer.size()) >= flushBlockBytes) {
      std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
      outputBuffer.clear();
    }
  }
  if (!outputBuffer.empty()) {
    std::fwrite(outputBuffer.data(), 1, outputBuffer.size(), stdout);
  }
  return 0;
}
