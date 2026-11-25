# MIXTURES — Mixtures (SPOJ)

<https://www.spoj.com/problems/MIXTURES/>

## Problem

Each case gives a row of mixtures, each with a color from 0 to 99. Merge neighboring mixtures until one remains, and find the smallest total smoke.

Mixing colors `a` and `b` yields color `(a + b) mod 100` and smoke `a * b`. The input has no leading test count; read cases until the stream ends. Each case starts with `n`, followed by `n` colors on the next line.

Input contract: one or more cases, each `n` then `n` integers from 0 to 99. Output contract: one line per case with the minimum integer smoke.

The bounds from the statement and the judge:

| Item | Bound |
|---|---|
| Mixtures per case `n` | 1 to 100 |
| Color value | 0 to 99 |
| Test cases | until end of input |
| Judge limit | 3000 ms, 1536 MB |

The value of `n` drives the design, since the work grows with the cube of `n`.

The sample case in full:

```
2
18 19
3
40 60 20
```

```
342
2400
```

The first case has one merge, so 18 times 19 gives 342.

## Idea

Treat the row as a chain of intervals and remember the best smoke for each span. The familiar image is a bracket that closes around a span of mixtures, choosing where to split it.

The algorithm is interval dynamic programming, also called the matrix-chain method. For each interval it tries every split point, combines two smaller answers, and keeps the minimum.

A prefix sum gives the color of any interval, so each split costs constant time. There are about `n^3` split trials, which is one million at `n = 100`.

Enumerating every merge order grows exponentially and fails at `n = 100`. Interval DP solves each subinterval once, then reuses that answer.

Takeaway: solve short intervals first, and each longer interval reuses them.

## Why It Works

1. Any full merge order has a last merge. That merge joins a left interval and a right interval.
2. The two sides never mix with each other before that last merge. Their smallest smokes are independent and add.
3. The color of an interval is the sum of its colors modulo 100. Only this residue affects later smoke.
4. The prefix array `prefixColors` gives any interval color with one subtraction and one `mod`.

The main terms of one split:

| Term | Meaning |
|---|---|
| `prefixColors` | running sum of colors, with an extra zero at the front |
| `rangeColor` | color of the whole interval, `(prefixColors[rightIndex + 1] - prefixColors[leftIndex]) mod colorModulus` |
| `leftColor` | color of the left part of a split |
| `candidateSmoke` | left answer plus right answer plus `leftColor * rightColor` |
| `bestSmoke` | smallest `candidateSmoke` over all split points |

Every split is a local sum, so the DP never rescans the colors.

A script-traced run on the second sample case:

```
colors: 40 60 20
prefix: 0 40 100 120
split 0: color 40*60 smoke 2400
dp[0][1] = 2400
split 1: color 60*20 smoke 1200
dp[1][2] = 1200
split 0: color 40*80 smoke 4400
split 1: color 0*20 smoke 2400
dp[0][2] = 2400
answer: 2400
```

The trace shows both splits of the full row, and the better one gives 2400.

## Code

The constants fix digit conversion, block size, color range, and worst-case size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const colorModulus = 100
const maxMixtures = 100
const largeSmoke = 1 shl 60
```

`colorModulus` is 100 because colors wrap at 100. `largeSmoke` exceeds any real smoke, so it starts each minimum search.

**Whole-stream reader and hand scanner.** One read, then digit parsing by index.

```nim
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

proc hasMoreTokens(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len:
    if data[scanIndex] >= '0' and data[scanIndex] <= '9':
      return true
    scanIndex += 1
  return false
```

`hasMoreTokens` finds the next digit, so blank lines and trailing spaces cannot desync the scan. `nextInt` builds each value without allocating a token. The scan position survives across calls as a `var` parameter.

**Block output writer.** One buffer, flushed at the block size.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the allocation, and the loop never writes per answer.

**Persistent work arrays.** Allocated once, reused for every case.

```nim
var smokeTable: array[maxMixtures, array[maxMixtures, int]]
var colors: array[maxMixtures, int]
var prefixColors: array[maxMixtures + 1, int]
```

Fixed arrays avoid per-case allocation, and no entry below the diagonal is read.

**Interval DP driver.** Fills the table by increasing window length, then emits each answer.

```nim
while hasMoreTokens(inputData, scanPos):
  let mixtureCount = nextInt(inputData, scanPos)
  prefixColors[0] = 0
  for colorIndex in 0..<mixtureCount:
    colors[colorIndex] = nextInt(inputData, scanPos)
    prefixColors[colorIndex + 1] = prefixColors[colorIndex] + colors[colorIndex]
  for leftIndex in 0..<mixtureCount:
    smokeTable[leftIndex][leftIndex] = 0
  var windowLength = 2
  while windowLength <= mixtureCount:
    var leftIndex = 0
    while leftIndex + windowLength <= mixtureCount:
      let rightIndex = leftIndex + windowLength - 1
      let rangeColor = (prefixColors[rightIndex + 1] - prefixColors[leftIndex]) mod colorModulus
      var bestSmoke = largeSmoke
      for splitIndex in leftIndex..<rightIndex:
        let leftColor = (prefixColors[splitIndex + 1] - prefixColors[leftIndex]) mod colorModulus
        let rightColor = (rangeColor - leftColor + colorModulus) mod colorModulus
        let candidateSmoke = smokeTable[leftIndex][splitIndex] + smokeTable[splitIndex + 1][rightIndex] + leftColor * rightColor
        if candidateSmoke < bestSmoke:
          bestSmoke = candidateSmoke
      smokeTable[leftIndex][rightIndex] = bestSmoke
      leftIndex += 1
    windowLength += 1
  appendOutput($(smokeTable[0][mixtureCount - 1]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`windowLength` starts at 2, so both parts of a split are already solved. `splitIndex` stops before `rightIndex`, so the right interval stays nonempty. The final write covers the tail after the loop.

## Complexity

The phases split by input, DP, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one digit pass per token | input bytes |
| One case DP | about n^3 / 6 split trials | about n^2 / 2 table entries |
| Output write | one write per 256 KiB block | 256 KiB |
| Total per case | `n^3` trials and one answer line | fixed arrays plus one buffer |

Input bytes dominate for many tiny cases; DP work dominates near `n = 100`.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(n^3) per case |
| Space | O(n^2) for the table, plus input bytes |

Enumerating merge orders costs O(Catalan(n)) time, which explodes at n = 100. Interval DP solves each subinterval once and finishes in O(n^3), so it stays fast at the upper bound.
