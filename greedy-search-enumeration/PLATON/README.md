# PLATON — Platon and Socrates (SPOJ)

<https://www.spoj.com/problems/PLATON/>

## Problem

Two distinct whole numbers lie strictly between two given ends. One person hears only their product and another hears only their sum. Four truthful remarks narrow the choices, and the task is to list every pair that still fits.

Write `x` and `y` for the numbers, with `x < y`. Write `p = x*y` for the product and `s = x+y` for the sum. Write `count(p)` for how many pairs in the range give product p. The range is open: `l < x < y < r`, so both ends are excluded.

Input: `t`, then `t` lines with `l r`. Output: one line `case i`, one line with the pair count, then one line `x y` per pair, ordered by increasing sum.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 2000 |
| Range ends `l`, `r` | 1 <= l < r <= 5000 |
| Range width `r - l` | below 200 |
| Candidate pairs per case | at most 19 503 |
| Language | C++ (the judge refuses Nim for this problem) |
| Judge limit | 15 s, 1536 MB |

The width bound drives the design, since a case touches fewer than 20 000 pairs.

The sample case:

```
2
1 10
2 8
```

```
case 1
0
case 2
0
```

Both sample ranges are too narrow, so neither leaves a surviving pair.

## Idea

Cross off pairs the way you cross names off a list after each clue. A product that points to one pair is crossed off, because its owner would have known the answer at once.

The program makes four passes over all candidate pairs in the open range. A hash table holds product counts, and small arrays indexed by sum hold the results of each remark. Each pass touches at most 19 503 pairs once, so a case costs O(W^2) time.

Recounting a product by rescanning every pair would repeat that work for each pair. The hash table counts all products in a single pass instead.

One shared hash table and three sum arrays carry the whole puzzle.

## Why It Works

1. Platon's first remark says his product occurs more than once in the open range.
2. Socrates knew this before hearing Platon. Every split of his sum must have an ambiguous product, and his sum must split at least twice.
3. After that remark, Platon knows the sum is one of those surviving sums. His product points to exactly one pair with such a sum.
4. Socrates then looks at his sum. Exactly one split of that sum has a product that let Platon know.

The terms used in the four passes:

| Term | Meaning |
|---|---|
| `p = x*y` | the product Platon hears |
| `s = x+y` | the sum Socrates hears |
| `count(p)` | how many pairs in the open range yield product p |
| good sum | a sum whose every split has `count(p)` above one |
| good pair | a pair whose product appears once among good-sum pairs |
| winner | a good sum with exactly one good pair |

Each term matches one sentence of the dialogue, in the same order.

A traced example for the open range (1, 100):

```
range (1, 100), so x and y run from 2 to 99
candidate pairs 4753
product 52 has pairs (2, 26) and (4, 13), so Platon cannot know yet
sum 17 splits into (2, 15), (3, 14), (4, 13), (5, 12), (6, 11), (7, 10), (8, 9)
all seven products are ambiguous, so sum 17 survives the second remark
product 52 points to only one surviving sum: 17
sum 17 has only one pair whose product survives: (4, 13)
final answer (4, 13)
```

The open ends matter: 2 is inside the range for this case, and (4, 13) is the only survivor.

## Code

**Input and scanner.** The program reads all input once, then walks digits by index.

```cpp
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
```

A single `fread` loop fills `inputData`. `nextInt` skips separators and never allocates a token. The scan cost is linear in the input bytes.

**Product counts.** A stamped hash table counts every product in one pass.

```cpp
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
```

`stamp` separates cases without clearing the table. Linear probing ends at an empty slot. Counting each product once keeps the pass at O(W^2).

**Sum arrays and buffered output.** Three arrays track sums and one buffer collects answers.

```cpp
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
```

Sum indexes stay below 10 000, so fixed arrays replace a map. The output buffer flushes in 256 KiB blocks and never writes per pair.

**Four filtered passes.** The main loop applies the four remarks in order.

```cpp
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
```

The first two lines turn each input case into the open range. The four passes add counts, reject bad sums, bump good products, and keep one winner per sum. Each pass is O(W^2).

## Complexity

One case costs four passes over fewer than 20 000 pairs.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | 4 MiB buffer |
| Product counts | one pass over pairs | 2^17 hash slots |
| Filtering | three passes over pairs | 10 001 sum entries |
| Output | one write per block | 256 KiB buffer |

The table shows that no phase depends on a second data structure over pairs.

| Measure | Big O |
|---|---|
| Time per case | O((r-l)^2) |
| Space | O(2^17 + r-l) |

A program that recounted products for every pair would need O(W^4) work and would time out on wide cases.
