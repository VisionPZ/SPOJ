## Problem

Choose `n` marbles from an endless supply of `k` colors. Every color must appear at least once. Equal marbles do not differ, and order does not matter. Print the number of possible selections for each test case.

| Limit | Value |
|-------|-------|
| Test cases `T` | at most 100 |
| Marbles `n` | 1 to 1,000,000 |
| Colors `k` | 1 to `n` |
| Answer | fits a signed 64-bit integer |
| Time | 1000 ms |
| Memory | 1536 MB |

A selection is fully described by the count of marbles in each color.

## Idea

Place the `n` marbles in a row and put `k - 1` dividers into the `n - 1` gaps between them. This is the stars and bars method (count identical items by placing dividers between them). The answer is the number of divider placements, C(`n - 1`, `k - 1`).

Each case costs O(`r`) arithmetic steps, where `r` is the smaller of `k - 1` and `n - k`.

## Why It Works

Give every color one marble first. The leftover `n - k` marbles can go to any color, and counting those distributions gives C(`n - 1`, `k - 1`).

Binomial coefficients are symmetric, so C(`n - 1`, `k - 1`) also equals C(`n - 1`, `n - k`). The program loops `r` times, with `r` set to `min(k - 1, n - k)`. This keeps the loop short and delays overflow.

After `step` rounds the running value equals C(`n - 1`, `step`). Each round multiplies by `n - step` and divides by `step`.

- `n - step` supplies the next descending factor.
- `step` removes one factor of the denominator.
- `ways` holds the quotient after each division.

Worked example for `n = 30` and `k = 7`, with 29 gaps and 6 dividers:

| step | factor `n - step` | `ways` after division |
|------|-------------------|------------------------|
| 0 | - | 1 |
| 1 | 29 | 29 |
| 2 | 28 | 406 |
| 3 | 27 | 3654 |
| 4 | 26 | 23751 |
| 5 | 25 | 118755 |
| 6 | 24 | 475020 |

The last row equals the sample answer for this case.

## Code

```
const flushBlockBytes = 1 shl 17
```

The output buffer flushes after 131,072 bytes. This caps memory and removes per-number writes.

```
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value
```

The scanner walks one buffered copy of the input. It skips whitespace, then builds each value one digit at a time. It allocates nothing per token and costs O(input length).

```
proc combineCount(marbleCount, colorCount: int): int64 =
  var chosenColors = colorCount
  if marbleCount - chosenColors < chosenColors - 1:
    chosenColors = marbleCount - chosenColors + 1
  var ways: int64 = 1
  for step in 1 .. chosenColors - 1:
    ways = ways * int64(marbleCount - step) div int64(step)
  return ways
```

The loop runs `chosenColors - 1` times, which equals `min(k - 1, n - k)`. The swap uses binomial symmetry before the loop starts. Multiplication happens before division so each step stays exact for answers that fit the target type. The loop costs O(`r`) time and O(1) space.

```
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  var marbleCount = nextInt(inputData, scanPos)
  var colorCount = nextInt(inputData, scanPos)
  outputBuffer.add $combineCount(marbleCount, colorCount)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The driver reads all input into one buffer before scanning. The loop runs `caseCount` times, once per case. The final write flushes the tail that stayed below the block size. Input and output each cost one linear pass.

## Complexity

Reading the input takes O(input length) time and O(input length) space. Each case takes O(`r`) time and O(1) extra space. Writing takes O(output length) time and at most the block size of extra space.

Total time is O(input length + output length + `T * r`). Total space is O(input length + block size). A factorial program overflows, and a Pascal DP costs O(`n * k`) time and O(`n * k`) space.
