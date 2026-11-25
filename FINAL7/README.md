# FINAL7 — Spider Man (SPOJ)

<https://www.spoj.com/problems/FINAL7/>

## Problem

Cycles of vertices can be split. A move replaces one cycle of size x by two cycles of sizes p and x - p, with 1 <= p < x. A player with no move loses. Cycles are added one at a time, and after each addition we report who wins.

Input: one line with the test count, then one line with all cycle sizes. Output: 1 when the first player wins, otherwise 2, one result per test.

| Item | Bound |
|---|---|
| Tests | 1 to 100000 |
| Cycle size | 1 to 10^9 |
| Judge limit | 1000 ms |

A cycle of size one contributes nothing, since it cannot be split.

Sample input:

```
3
1 2 3
```

Sample output:

```
2
1
1
```

## Idea

Think of piles that only split, where each pile contributes a small coin that cancels in pairs. Sprague-Grundy theory gives each cycle a nim value. Size one has value zero. A larger size takes the mex of values from every split.

For even x, every split gives two piles of the same parity, so their values cancel to zero and the mex is one. For odd x, every split gives opposite parities, so their values combine to one and the mex is zero. Thus only even cycles contribute one. Keep a running xor and toggle it for each even size. Each test costs O(1) time.

## Why It Works

1. A single vertex has no move, so its Grundy value is zero.
2. For even x, both split parts share parity, so their Grundy values xor to zero; the mex is one.
3. For odd x, the split parts differ in parity, so their values xor to one; the mex is zero.
4. Disjoint games combine by xor, so a nonzero running value means the first player wins.

| Term | Meaning |
|---|---|
| `Grundy value` | nim value of one cycle |
| `mex` | smallest value absent from the reachable set |
| `nimValue` | xor of all current cycle values |
| `parity` | remainder of a size modulo two |

The running xor updates once per added cycle, so history needs no storage.

Script-generated example from `gen.py`:

```
cycle size 1 grundy 0 nim 0 answer 2
cycle size 2 grundy 1 nim 1 answer 1
cycle size 3 grundy 0 nim 1 answer 1
```

The traced answers match the sample output `2 1 1`.

## Code

**Input scanner and output buffer.** This block reads input into one string and provides index-based scanning.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and consumes decimal digits by index. `nextToken` handles string tokens. The buffer flushes at 128 KiB.

**Running nim value.** This block toggles the xor and prints the winner after each test.

```nim
let testCount = nextInt(inputData, scanPos)
var nimValue = 0
for testIndex in 0..<testCount:
  let cycleSize = nextInt(inputData, scanPos)
  nimValue = nimValue xor (1 - (cycleSize and 1))
  if nimValue != 0:
    appendOutput("1\n")
  else:
    appendOutput("2\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The expression `1 - (cycleSize and 1)` is one for even sizes and zero for odd sizes. No cycle list is stored, so memory stays flat.

## Complexity

One pass over the sizes determines every answer.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Nim update | one xor per test | single value |
| Output | one write per 128 KiB block | block buffer |

Auxiliary space does not grow with the test count.

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) for input, O(1) auxiliary |

Enumerating every split of every cycle would cost O(sum of sizes), impossible near 10^9.
