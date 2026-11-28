# EDIT — Edit Distance Again (SPOJ)

<https://www.spoj.com/problems/EDIT/>

## Problem

Given lines of Latin letters without spaces, make each line alternate case at every step. Find the smallest number of case flips required.

Input consists of one word per line until end of file. Output one integer per line: the minimum number of case changes for that word.

This table lists the constraints and judge limits.

| item | bound |
|---|---|
| word length `L` | 1 <= L <= 1000 |
| alphabet | `A-Z`, `a-z` |
| judge limit | 1000 ms, 1536 MB, 50000 B |

Every line is independent and fits easily in linear time.

Sample input:

```
AaAaB
ABaa
a
```

Sample output:

```
0
2
0
```

## Idea

Checking a word against an alternating pattern is like laying two checkerboard strips over a row of tiles and counting mismatches. Only two valid alternating patterns exist for any length `L`: one starting with uppercase and one starting with lowercase. Count how many positions disagree with the uppercase-first pattern in `O(L)` time; the other pattern disagrees at the exact remaining positions.

A dynamic program over cases works too, but counting mismatches directly avoids any state transitions and finishes in one pass.

## Why It Works

1. An alternating chain is fixed completely by the case of its first letter.
2. Position `offset` (0-indexed) needs uppercase in the uppercase-first pattern when `offset` is even and lowercase when `offset` is odd.
3. The lowercase-first pattern requires the opposite case at every position, so `mismatchLowerStart = lineLength - mismatchUpperStart`.
4. Each mismatch costs one flip, and no two mismatches interfere, so the minimum cost is `min(mismatchUpperStart, mismatchLowerStart)`.

This table maps each formula term to its role in the pass.

| term | meaning |
|---|---|
| `lineLength` | number of letters in the current word |
| `mismatchUpperStart` | positions disagreeing with `A a A a ...` |
| `mismatchLowerStart` | positions disagreeing with `a A a A ...` |
| `minChanges` | smaller of the two mismatch counts |

One scan computes both counts without visiting any character twice.

Worked example for `ABaa` (`lineLength = 4`):

```
offset     : 0 1 2 3
letter     : A B a a
upper-first: U l U l  -> mismatches at offsets 1, 2 -> 2
lower-first: l U l U  -> mismatches at offsets 0, 3 -> 2
minimum    : min(2, 2) = 2
```

Both patterns need 2 flips, so the answer is 2.

## Code

**Bulk input and block output.** Reads stdin once into one string and flushes output in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Using one `inputData` buffer avoids per-line object churn during scanning. Flushing at `flushBlockBytes` keeps memory bounded while avoiding per-line write overhead.

**Token scan and parity mismatch count.** Walks `inputData` by index, counts uppercase-first mismatches per word, and emits the smaller of the two counts.

```nim
var scanPos = 0
while scanPos < inputData.len:
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  var lineStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n' and inputData[scanPos] != '\r' and inputData[scanPos] != ' ':
    scanPos += 1
  let lineLength = scanPos - lineStart
  var mismatchUpperStart = 0
  for offset in 0 .. lineLength - 1:
    let ch = inputData[lineStart + offset]
    let isUpper = ch >= 'A' and ch <= 'Z'
    let expectUpper = (offset and 1) == 0
    if isUpper != expectUpper:
      mismatchUpperStart += 1
  let mismatchLowerStart = lineLength - mismatchUpperStart
  let minChanges = if mismatchUpperStart < mismatchLowerStart: mismatchUpperStart else: mismatchLowerStart
  appendOutput($minChanges)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

Skipping `\r` and spaces guards against Windows line endings or trailing blanks. The inner loop runs `lineLength` times and visits each byte once in `O(1)` work.

## Complexity

This table summarizes time and space per phase for total input size `N`.

| phase | time | space |
|---|---|---|
| bulk read | O(N) | O(N) |
| mismatch scan | O(N) | O(1) |
| buffered output | O(lines) | O(1) |

The whole program runs in a single linear pass over the input bytes.

This table states the overall Big O bounds.

| measure | big O |
|---|---|
| time | O(N) |
| space | O(N) |

Even an explicit two-state DP visits every character once, so the parity count matches the optimal `O(N)` bound with minimal constant factor.
