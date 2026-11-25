# SLEEP — Sleepwalker (SPOJ)
<https://www.spoj.com/problems/SLEEP/>

## Problem

A sleepwalker crosses a roof of tiles, following a path that repeats itself in smaller and smaller squares. One tile is missing. Given where the walk is observed and where the hole sits, count the steps until the fall.

Input: an integer t, then t cases separated by blank lines. Each case gives k, then the start coordinates x and y, then the hole coordinates. The roof side is 3 to the k. Output: one integer per case, the exact step count.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | t from input |
| Roof level k | 1 to 60 |
| Coordinates x and y | 1 to 3 to the k |
| Path length | 9 to the k steps |
| Judge time limit | 7000 ms |
| Judge memory limit | 1536 MB |

The path is far too long to walk step by step.

The sample input:

```
1
2
3 2
7 2
```

The sample output:

```
20
```

## Idea

Read the roof like a map that repeats nine neighborhoods inside each neighborhood, like a fractal drawn on paper. You never walk the path. You decode the tile's address into one digit per map level, then read off the step number.

The program converts each coordinate minus one to base 3. At each level, a pair of base-3 digits picks one of nine blocks. The block order gives one base-9 digit of the step count. Orientation flags track the reflections and swaps that the recursive path applies to deeper blocks. Subtracting the two step counts happens in base 9 with a borrow. Converting that difference to decimal uses chunks of 18 digits, because the answer exceeds 64 bits. A direct simulation would take 9 to the k steps.

A short address replaces an astronomical walk.

## Why It Works

Five facts carry the program.

1. The path on a 3 by 3 roof visits its nine tiles in a fixed order. The `blockOrder` table records that order as digits 0 through 8.
2. The roof level k splits every coordinate into k base-3 digits. Subtracting one first maps the range 1 to 3 to the k onto digit strings 0 to 3 to the k minus 1.
3. Deeper blocks appear rotated or reflected. The `blockTransform` codes switch a swap flag and complement flags, which the next level applies to both digits.
4. Each level contributes one base-9 digit, so the step count is a base-9 number. The hole minus the start uses a borrow of 9 per digit.
5. A base-9 number with 60 digits does not fit in a machine integer. Chunks of 18 digits are converted to decimal with precomputed powers of 9.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `xDigits`, `yDigits` | base-3 address of one coordinate minus one |
| `steps` | base-9 digits of the step count |
| `swapped` | whether the next level exchanges x and y |
| `xComplement`, `yComplement` | whether the next level mirrors an axis |
| `chunkPowers` | powers of 9 used for decimal conversion |

No floating point appears, so the answer is exact at every level.

A script traces the sample with k = 2.

```text
start (3,2): x-1=2 -> digits (0,2), y-1=1 -> digits (0,1)
  high block (row 0, col 0) -> digit 0, swap on
  low block after swap (row 2, col 1) -> digit 5
  step count base9 [0,5] = 5
hole (7,2): x-1=6 -> digits (2,0), y-1=1 -> digits (0,1)
  high block (row 0, col 2) -> digit 2, no swap
  low block (row 1, col 0) -> digit 7
  step count base9 [2,7] = 25
25 - 5 = 20 steps
```

The answer matches the sample output.

## Code

**Constants and reader.** Powers of 9 are precomputed once.

```nim
{.passC: "-O3".}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRoofLevel = 60
const chunkPowers: array[19, int64] = [
  1'i64, 9'i64, 81'i64, 729'i64, 6561'i64, 59049'i64, 531441'i64,
  4782969'i64, 43046721'i64, 387420489'i64, 3486784401'i64,
  31381059609'i64, 282429536481'i64, 2541865828329'i64,
  22876792454961'i64, 205891132094649'i64, 1853020188851841'i64,
  16677181699666569'i64, 150094635296999121'i64
]

const blockOrder: array[3, array[3, int]] = [
  [0, 1, 2],
  [7, 6, 3],
  [8, 5, 4]
]

const blockTransform: array[3, array[3, int]] = [
  [1, 1, 0],
  [2, 2, 0],
  [0, 3, 0]
]

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
```

`chunkPowers` stops at 9 to the 18, which is the largest chunk. `blockOrder` is indexed by row then column. The scanner skips blank lines between cases.

**Coordinate decoding.** A decimal value becomes base-3 digits of value minus one.

```nim
proc parseCoordinate(data: string, pos: var int, levelCount: int,
                      digits: var seq[int]) =
  for i in 0 .. levelCount:
    digits[i] = 0
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var usedLen = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    var carry = int(data[pos]) - firstDigitValue
    var i = 0
    while i < usedLen or carry > 0:
      let value = digits[i] * 10 + carry
      digits[i] = value mod 3
      carry = value div 3
      i += 1
    if i > usedLen:
      usedLen = i
    pos += 1
  var i = 0
  while digits[i] == 0:
    digits[i] = 2
    i += 1
  digits[i] -= 1
```

The first loop divides the decimal value by 3 digit by digit. The last loop borrows one, turning trailing zeros into twos. The result holds exactly `levelCount` digits.

**Step tracing.** Each level appends one base-9 digit.

```nim
proc traceSteps(xDigits: seq[int], yDigits: seq[int],
                levelCount: int, steps: var seq[int]) =
  var swapped = false
  var xComplement = false
  var yComplement = false
  for i in 0 .. levelCount - 1:
    let topIndex = levelCount - i - 1
    var colDigit = 0
    var rowDigit = 0
    if swapped:
      colDigit = yDigits[topIndex]
      rowDigit = xDigits[topIndex]
      if yComplement:
        colDigit = 2 - colDigit
      if xComplement:
        rowDigit = 2 - rowDigit
    else:
      colDigit = xDigits[topIndex]
      rowDigit = yDigits[topIndex]
      if xComplement:
        colDigit = 2 - colDigit
      if yComplement:
        rowDigit = 2 - rowDigit
    steps[i] = blockOrder[rowDigit][colDigit]
    let transform = blockTransform[rowDigit][colDigit]
    case transform
    of 1:
      swapped = not swapped
    of 2:
      swapped = not swapped
      xComplement = not xComplement
      yComplement = not yComplement
    of 3:
      xComplement = not xComplement
      yComplement = not yComplement
    else:
      discard
```

The loop walks from the most significant base-3 digit down. `topIndex` is `levelCount - i - 1`, so no digit is skipped. The transform codes update orientation for the next level. The cost is O(k).

**Difference and decimal output.** Big base-9 values are handled in chunks.

```nim
proc appendAnswer(startSteps: seq[int], holeSteps: seq[int], levelCount: int,
                  diffDigits: var seq[int], decimalDigits: var seq[int],
                  outputBuffer: var string) =
  var borrow = 0
  var i = levelCount - 1
  while i >= 0:
    var value = holeSteps[i] - startSteps[i] - borrow
    if value < 0:
      value += 9
      borrow = 1
    else:
      borrow = 0
    diffDigits[i] = value
    i -= 1
  var decimalLen = 1
  decimalDigits[0] = 0
  var chunkStart = 0
  var remaining = levelCount
  while remaining > 0:
    var chunkLen = 18
    if remaining < 18:
      chunkLen = remaining
    let chunkEnd = chunkStart + chunkLen
    var chunkValue: int64 = 0
    for k in chunkStart .. chunkEnd - 1:
      chunkValue = chunkValue * 9 + int64(diffDigits[k])
    let multiplier = chunkPowers[chunkLen]
    var carry = chunkValue
    var j = 0
    while j < decimalLen:
      let value = int64(decimalDigits[j]) * multiplier + carry
      decimalDigits[j] = int(value mod 10)
      carry = value div 10
      j += 1
    while carry > 0:
      decimalDigits[j] = int(carry mod 10)
      carry = carry div 10
      j += 1
    decimalLen = j
    chunkStart = chunkEnd
    remaining -= chunkLen
  i = decimalLen - 1
  while i >= 0:
    outputBuffer.add char(firstDigitValue + decimalDigits[i])
    i -= 1
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The borrow is 9 because digits live in base 9. Each chunk holds at most 18 digits, so `chunkValue` fits in 64 bits. Decimal digits are stored least significant first and printed in reverse.

**Driver.** Both addresses are decoded before subtraction.

```nim
let caseCount = nextInt(inputData, scanPos)
var xDigits = newSeq[int](maxRoofLevel + 1)
var yDigits = newSeq[int](maxRoofLevel + 1)
var startSteps = newSeq[int](maxRoofLevel)
var holeSteps = newSeq[int](maxRoofLevel)
var diffDigits = newSeq[int](maxRoofLevel)
var decimalDigits = newSeq[int](maxRoofLevel + 1)
var outputBuffer = ""
for caseIndex in 0 .. caseCount - 1:
  let roofLevel = nextInt(inputData, scanPos)
  parseCoordinate(inputData, scanPos, roofLevel, xDigits)
  parseCoordinate(inputData, scanPos, roofLevel, yDigits)
  traceSteps(xDigits, yDigits, roofLevel, startSteps)
  parseCoordinate(inputData, scanPos, roofLevel, xDigits)
  parseCoordinate(inputData, scanPos, roofLevel, yDigits)
  traceSteps(xDigits, yDigits, roofLevel, holeSteps)
  appendAnswer(startSteps, holeSteps, roofLevel, diffDigits, decimalDigits,
               outputBuffer)
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

Arrays are allocated once at the maximum level 60. The same arrays decode the start and then the hole. Each case costs four base-3 decodings and two traces.

## Complexity

Everything scales with the roof level k, not with the path length.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Coordinate decode | O(k) per coordinate | O(k) |
| Step trace | O(k) per point | O(k) |
| Base-9 subtraction | O(k) | O(k) |
| Decimal conversion | O(k) in chunks of 18 | O(k) |

k is at most 60, so the answer can hold 57 decimal digits.

| Measure | Big O |
| --- | --- |
| Time | O(k) per case |
| Space | O(k) per case |

Walking the path would cost O(9 to the k) steps, which is impossible for k = 60.
