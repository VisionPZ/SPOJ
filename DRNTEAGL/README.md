# DRNTEAGL — Duronto Eagle

## Problem

Find the planet farthest from the origin and report its one-based position in the input. Ties go to the planet that appears first.

Input: a case count `T`, then for each case a planet count `N` and `N` coordinate pairs.
Output: one line per case, formatted as `Case k: i`, where `k` is the case number.

| item | bound |
|---|---|
| test cases `T` | at most 100 |
| planets `N` | 1 to 50 |
| coordinates | -10000 to 10000 |
| judge limit | 500 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
2
3
4 0
0 5
2 2
4
2 3
1 1
5 5
-4 -1
```

```
Case 1: 2
Case 2: 3
```

## Idea

Imagine measuring the distance of each star from your home with a ruler. You only need to know which ruler reading is longest, so comparing squared readings works just as well.

The real algorithm is a single linear scan that keeps the largest squared distance. Each planet costs two multiplications, one addition, and one comparison.

## Why It Works

1. Distance is non-negative, and squaring is strictly increasing on non-negative values.
2. The planet with the largest squared distance is therefore the farthest planet.
3. Coordinates are at most 10000, so a squared distance is at most 2 times 10^8.
4. Using `int64` leaves no overflow risk and keeps the comparison exact.
5. Updating only on a strict increase keeps the earliest index on a tie.

| term | meaning |
|---|---|
| `bestDistance` | largest squared distance seen so far |
| `bestIndex` | one-based index of that planet |
| `distance` | `x` squared plus `y` squared for the current planet |
| `planetIndex` | one-based position in the current case |

Script-generated example for sample case 1:

```
planet 1  (4, 0)  distance squared = 16
planet 2  (0, 5)  distance squared = 25   <- largest
planet 3  (2, 2)  distance squared = 8
answer = Case 1: 2
```

If two planets both scored 25, the first one encountered would be kept.

## Code

**Constants and scanner.** Reads signed integers from one shared buffer.

```nim
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and inputData[pos] != '-' and
        (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return signValue * value
```

The scanner skips all separators, including line breaks. A leading minus is applied after the digits are read.

**Case loop.** Scans each planet and remembers the earliest farthest one.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = nextInt(inputData, pos)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let planetCount = nextInt(inputData, pos)
  var bestDistance: int64 = -1
  var bestIndex = 1
  for planetIndex in 1 .. planetCount:
    let xCoord = nextInt(inputData, pos)
    let yCoord = nextInt(inputData, pos)
    let distance = int64(xCoord) * int64(xCoord) + int64(yCoord) * int64(yCoord)
    if distance > bestDistance:
      bestDistance = distance
      bestIndex = planetIndex
  outputBuffer.add "Case "
  outputBuffer.add $caseIndex
  outputBuffer.add ": "
  outputBuffer.add $bestIndex
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Each coordinate is widened to `int64` before squaring. The strict `>` test is what preserves the first index on a tie. Output is buffered and flushed in 128 KiB blocks.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| planet scan | one pass per case | constant |
| output | one write per 128 KiB block | 128 KiB |

| measure | Big O |
|---|---|
| time | O(T * N) |
| space | O(input bytes) |

Computing a square root for every planet would be O(T * N) with a much larger constant. Squared distances give the same ranking with only integer arithmetic.
