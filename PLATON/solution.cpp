#include <cstdio>

static const int flushBlockBytes = 1 << 18;
static const int hashBits = 17;
static const int hashSize = 1 << hashBits;
static const int hashMask = hashSize - 1;
static const int maxSum = 10000;

static char inputData[1 << 22];
static int inputLen = 0;
static int scanPos = 0;

static int nextInt() {
  while (scanPos < inputLen && (inputData[scanPos] < '0' || inputData[scanPos] > '9'))
    scanPos++;
  int value = 0;
  while (scanPos < inputLen && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
    value = value * 10 + inputData[scanPos] - '0';
    scanPos++;
  }
  return value;
}

static int hashKeys[hashSize];
static int hashValues[hashSize];
static int hashStamps[hashSize];
static int currentStamp = 0;

static int hashSlot(int value) {
  long long mixed = (long long)value * 2654435761LL;
  return (int)((mixed >> 32) & hashMask);
}

static int bumpCount(int value, int stamp) {
  int at = hashSlot(value);
  for (;;) {
    if (hashStamps[at] != stamp) {
      hashStamps[at] = stamp;
      hashKeys[at] = value;
      hashValues[at] = 1;
      return 1;
    }
    if (hashKeys[at] == value) {
      hashValues[at]++;
      return hashValues[at];
    }
    at = (at + 1) & hashMask;
  }
}

static int lookupCount(int value, int stamp) {
  int at = hashSlot(value);
  for (;;) {
    if (hashStamps[at] != stamp) return 0;
    if (hashKeys[at] == value) return hashValues[at];
    at = (at + 1) & hashMask;
  }
}

static int sumSplitCount[maxSum + 1];
static int sumBadCount[maxSum + 1];
static int sumWinnerCount[maxSum + 1];
static int winnerLow[maxSum + 1];
static int winnerHigh[maxSum + 1];

static char outputBuffer[flushBlockBytes + 64];
static int outputLen = 0;

static void flushOutput() {
  fwrite(outputBuffer, 1, outputLen, stdout);
  outputLen = 0;
}

static void appendChar(char c) {
  outputBuffer[outputLen++] = c;
  if (outputLen >= flushBlockBytes) flushOutput();
}

static void appendText(const char *text) {
  while (*text) appendChar(*text++);
}

static void appendInt(int value) {
  char digits[16];
  int n = 0;
  if (value == 0) digits[n++] = '0';
  while (value > 0) {
    digits[n++] = (char)('0' + value % 10);
    value /= 10;
  }
  while (n > 0) appendChar(digits[--n]);
}

int main() {
  for (;;) {
    int got = (int)fread(inputData + inputLen, 1, (int)sizeof(inputData) - inputLen, stdin);
    if (got <= 0) break;
    inputLen += got;
    if (inputLen >= (int)sizeof(inputData)) break;
  }
  int caseCount = nextInt();
  for (int caseIndex = 1; caseIndex <= caseCount; caseIndex++) {
    int rangeLow = nextInt() + 1;
    int rangeHigh = nextInt() - 1;
    int sumLow = 2 * rangeLow + 1;
    int sumHigh = 2 * rangeHigh - 1;
    for (int s = sumLow; s <= sumHigh; s++) {
      sumSplitCount[s] = 0;
      sumBadCount[s] = 0;
      sumWinnerCount[s] = 0;
    }
    currentStamp++;
    int productStamp = currentStamp;
    for (int x = rangeLow; x <= rangeHigh; x++)
      for (int y = x + 1; y <= rangeHigh; y++)
        bumpCount(x * y, productStamp);
    for (int x = rangeLow; x <= rangeHigh; x++)
      for (int y = x + 1; y <= rangeHigh; y++) {
        int total = x + y;
        sumSplitCount[total]++;
        if (lookupCount(x * y, productStamp) == 1) sumBadCount[total]++;
      }
    currentStamp++;
    int winnerStamp = currentStamp;
    for (int x = rangeLow; x <= rangeHigh; x++)
      for (int y = x + 1; y <= rangeHigh; y++) {
        int total = x + y;
        if (sumSplitCount[total] > 1 && sumBadCount[total] == 0) bumpCount(x * y, winnerStamp);
      }
    for (int x = rangeLow; x <= rangeHigh; x++)
      for (int y = x + 1; y <= rangeHigh; y++) {
        int total = x + y;
        if (sumSplitCount[total] > 1 && sumBadCount[total] == 0 && lookupCount(x * y, winnerStamp) == 1) {
          sumWinnerCount[total]++;
          winnerLow[total] = x;
          winnerHigh[total] = y;
        }
      }
    int pairCount = 0;
    for (int s = sumLow; s <= sumHigh; s++)
      if (sumSplitCount[s] > 1 && sumBadCount[s] == 0 && sumWinnerCount[s] == 1) pairCount++;
    appendText("case ");
    appendInt(caseIndex);
    appendChar('\n');
    appendInt(pairCount);
    appendChar('\n');
    for (int s = sumLow; s <= sumHigh; s++)
      if (sumSplitCount[s] > 1 && sumBadCount[s] == 0 && sumWinnerCount[s] == 1) {
        appendInt(winnerLow[s]);
        appendChar(' ');
        appendInt(winnerHigh[s]);
        appendChar('\n');
      }
  }
  flushOutput();
  return 0;
}
