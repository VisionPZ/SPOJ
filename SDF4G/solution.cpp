#include <cstdio>
#include <string>
#include <vector>

typedef unsigned __int128 u128;

static const int flushBlockBytes = 1 << 17;

static std::string readInputBytes() {
  std::string data;
  char chunk[4096];
  size_t got;
  while ((got = std::fread(chunk, 1, sizeof(chunk), stdin)) > 0) {
    data.append(chunk, got);
  }
  return data;
}

static bool nextLimitToken(const std::string &data, size_t &pos, u128 &limitVal, bool &isNegative) {
  while (pos < data.size() && data[pos] != '-' && (data[pos] < '0' || data[pos] > '9')) {
    pos++;
  }
  if (pos >= data.size()) {
    return false;
  }
  isNegative = false;
  if (data[pos] == '-') {
    isNegative = true;
    pos++;
  }
  limitVal = 0;
  while (pos < data.size() && data[pos] >= '0' && data[pos] <= '9') {
    limitVal = limitVal * 10 + static_cast<u128>(data[pos] - '0');
    pos++;
  }
  return true;
}

static void appendText(std::string &outBuf, const char *text) {
  outBuf.append(text);
  if (static_cast<int>(outBuf.size()) >= flushBlockBytes) {
    std::fwrite(outBuf.data(), 1, outBuf.size(), stdout);
    outBuf.clear();
  }
}

static void appendU128(std::string &outBuf, u128 value) {
  char digits[48];
  int len = 0;
  if (value == 0) {
    digits[len++] = '0';
  } else {
    while (value > 0) {
      digits[len++] = static_cast<char>('0' + static_cast<int>(value % 10));
      value /= 10;
    }
  }
  while (len > 0) {
    outBuf.push_back(digits[--len]);
  }
  outBuf.push_back(' ');
  if (static_cast<int>(outBuf.size()) >= flushBlockBytes) {
    std::fwrite(outBuf.data(), 1, outBuf.size(), stdout);
    outBuf.clear();
  }
}

int main() {
  std::string inputData = readInputBytes();
  size_t scanPos = 0;
  u128 limitVal = 0;
  bool isNegative = false;
  if (!nextLimitToken(inputData, scanPos, limitVal, isNegative)) {
    return 0;
  }

  std::string outBuf;
  outBuf.reserve(flushBlockBytes + 64);
  if (!isNegative) {
    appendText(outBuf, "0 ");
    if (limitVal >= 1) {
      std::vector<u128> queue;
      queue.reserve(65536);
      u128 firstTop = limitVal < 9 ? limitVal : 9;
      for (u128 digit = 1; digit <= firstTop; digit++) {
        queue.push_back(digit);
      }
      size_t head = 0;
      while (head < queue.size()) {
        u128 cur = queue[head++];
        appendU128(outBuf, cur);
        u128 lastDigit = cur % 10;
        if (lastDigit > 0) {
          u128 lowDigit = lastDigit - 1;
          if (cur <= (limitVal - lowDigit) / 10) {
            queue.push_back(cur * 10 + lowDigit);
          }
        }
        if (lastDigit < 9) {
          u128 highDigit = lastDigit + 1;
          if (cur <= (limitVal - highDigit) / 10) {
            queue.push_back(cur * 10 + highDigit);
          }
        }
      }
    }
  }

  appendText(outBuf, "\nAilafyuU\n");
  if (!outBuf.empty()) {
    std::fwrite(outBuf.data(), 1, outBuf.size(), stdout);
  }
  return 0;
}
