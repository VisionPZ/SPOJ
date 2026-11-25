# FUCT_FOR_FATNUM — Fat number (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_FATNUM/>

## Problem

A fat number is one whose digit sum equals its digit product, like 123 because 1+2+3 = 6 = 1×2×3. Each test gives two numbers a and b, and the task is to print every fat number between them inclusive, in ascending order, on one space-separated line.

Input starts with a test count. Each test line holds two integers a and b, in either order. Output holds one line per test.

| Item | Bound |
|---|---|
| Test count | 1 ≤ t ≤ 1000 |
| a, b | 0 ≤ a, b ≤ 10,000,000 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
2
8 15
2000 1
```

```
8 9
1 2 3 4 5 6 7 8 9 22 123 132 213 231 312 321 1124 1142 1214 1241 1412 1421
```

## Idea

Fat numbers are rare because a digit product grows by multiplication while a digit sum grows by addition, so only short numbers made mostly of 1s ever qualify. Instead of testing all 10 million values, the program lists every digit multiset of size at most 7, keeps the ones whose sum equals their product, and permutes those into numbers. That costs about 11,000 multiset checks once at startup, leaving 182 fat numbers. Each query then costs two binary searches plus the printed numbers. Testing every value in a range costs up to 10 million digit scans per query.

## Why It Works

1. A number with a 0 digit has product 0 and sum at least 1, so it is never fat.
2. Each digit 2 or more multiplies the product by at least 2 but adds at most 9 to the sum, so the product outruns the sum quickly.
3. A fat number up to 10,000,000 has at most 7 digits, because 10,000,000 itself contains zeros.
4. Digit sum and digit product depend only on how many of each digit appear, so a multiset fully describes its fat numbers.
5. The prune `nextProduct <= nextSum + 9 * (digitsLeft - taken)` drops a branch when even all-9 fill-ins cannot raise the sum to the product.
6. The finished list holds 182 numbers, the largest being 7211111, so binary search finds each range in a few steps.

| Term | Meaning |
|---|---|
| `collectMultisets` | walks digit counts 1..9 and tests sum against product |
| `buildPermutations` | turns one fat multiset into every number it spells |
| `fatNumbers` | sorted list of all fat numbers |
| `lowerBound` | first position in the list reaching a target |
| `rangeStart`, `rangeStop` | sorted ends of the query range |

The enumeration touches each multiset once, before any query runs.

A script-traced example from `gen.py`:

```
range 2000 1 becomes 1..2000
fat in range: 1 2 3 4 5 6 7 8 9 22 123 132 213 231 312 321 1124 1142 1214 1241 1412 1421
```

The trace matches the second sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxDigits = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
Values are non-negative, so no sign branch is needed.
Scanning costs one pass over the consumed characters.

**Fat-number enumeration.** This block builds the sorted master list once.

```nim
proc collectMultisets(digit: int, digitsLeft: int, digitSum: int, digitProduct: int, digitCounts: var array[1..9, int]) =
  if digit == 10:
    if digitSum > 0 and digitSum == digitProduct:
      buildPermutations(digitCounts, maxDigits - digitsLeft, 0)
    return
  var taken = 0
  while taken <= digitsLeft:
    digitCounts[digit] = taken
    let nextSum = digitSum + taken * digit
    let nextProduct = digitProduct * intPow(digit, taken)
    if nextProduct <= nextSum + 9 * (digitsLeft - taken):
      collectMultisets(digit + 1, digitsLeft - taken, nextSum, nextProduct, digitCounts)
    digitCounts[digit] = 0
    taken += 1

var digitCounts: array[1..9, int]
collectMultisets(1, maxDigits, 0, 1, digitCounts)
sort(fatNumbers, cmp)
```

The recursion fixes how many of each digit 1..9 appear, one digit at a time.
The prune keeps only branches where the sum can still reach the product.
`maxDigits - digitsLeft` counts the placed digits, so empty slots add nothing.
The whole build runs once and touches about 11,000 multisets.

**Binary search.** This block finds where a range starts and ends in the list.

```nim
proc lowerBound(values: seq[int], target: int): int =
  var leftIndex = 0
  var rightIndex = values.len
  while leftIndex < rightIndex:
    let middleIndex = (leftIndex + rightIndex) div 2
    if values[middleIndex] < target:
      leftIndex = middleIndex + 1
    else:
      rightIndex = middleIndex
  return leftIndex
```

`lowerBound(fatNumbers, rangeStop + 1)` gives the first position past the range.
Each search halves the 182-entry list, so it takes under eight steps.

**Query loop.** This block swaps ends, searches, and prints the slice.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  var rangeStart = nextInt(inputData, scanPos)
  var rangeStop = nextInt(inputData, scanPos)
  if rangeStart > rangeStop:
    let swapValue = rangeStart
    rangeStart = rangeStop
    rangeStop = swapValue
  var firstIndex = lowerBound(fatNumbers, rangeStart)
  var lastIndex = lowerBound(fatNumbers, rangeStop + 1)
  var printedAny = false
  while firstIndex < lastIndex:
    if printedAny:
      appendOutput(" ")
    appendOutput($(fatNumbers[firstIndex]))
    printedAny = true
    firstIndex += 1
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The swap handles a reversed range like `2000 1`.
An empty range prints a newline.
Each printed number costs one buffer append.

## Complexity

Startup builds the fat list once; queries only search and print.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Enumeration | about 11,000 multiset checks | 182 numbers |
| Queries | O(log 182) search plus output per test | block buffer |

Every phase stays small at t = 1000.

| Measure | Big O |
|---|---|
| Time | O(N + t log F + output), F = 182 |
| Space | O(N) for the input buffer |

Scanning every value in a range costs O(t × (b − a)) digit checks, up to 10 billion; the multiset list makes each query a search.
