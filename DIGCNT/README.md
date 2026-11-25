# DIGCNT — digit count (SPOJ)

<https://www.spoj.com/problems/DIGCNT/>

## Problem

Count how many times each nonzero digit appears when writing every integer from `a` to `b`. Read pairs until `a` is zero, then report nine tallies per pair.

Each query line holds two integers `a` and `b` with 1 ≤ a, b ≤ 10^16. A line with a = 0 ends the input. For each query, print nine counts for digits 1 through 9, separated by single spaces.

| item | bound |
|---|---|
| queries | up to 500 |
| endpoints a, b | 1 to 10^16 |
| reported digits | 1 to 9 |
| judge limit | 1000 ms, 1536 MB |

The largest endpoint drives the design, since a query may span 10^16 integers.

Sample input:

```
1 10
0 0
```

Sample output:

```
2 1 1 1 1 1 1 1 1
```

## Idea

Counting digits in a range is like counting house numbers on a whole street, one street block at a time. Use a place-value formula that counts one digit at one power of ten in constant time, then add the nine answers.

The algorithm is positional digit counting. For each place value 1, 10, 100, and so on, split the limit into a higher part, the current digit, and a lower part. That split gives the count of a digit at that place in O(1), so one query costs nine times the number of decimal places, at most 153 operations. Enumerating every integer in the range would take 10^16 steps and cannot finish. Each query costs a few dozen integer operations and stays quick.

## Why It Works

1. A number from 1 to `limit` has one digit at each place value up to `limit`.
2. At place value p, the digit cycles every 10p numbers, giving complete cycles and a partial cycle.
3. The higher part counts complete cycles before the current block.
4. The current digit decides whether the partial cycle adds a full block of p, a partial block, or nothing.
5. Subtracting the tally for a − 1 from the tally for b yields the range tally.
6. Digits 1 through 9 never appear as leading zeros, so no correction is needed.

| term | meaning |
|---|---|
| `placeValue` | current power of ten, starting at 1 |
| `higherPart` | quotient by the next larger place value |
| `currentDigit` | digit sitting at `placeValue` in the limit |
| `lowerPart` | remainder below `placeValue` |

These four values determine one digit tally without visiting any number in the range.

The oracle trace for the statement range 1024 through 1032 gives:

```
10 7 3 1 1 1 1 1 1
```

The trace matches the statement, which reports ten 1s, seven 2s, and three 3s.

The product `placeValue * 10` stays below 10^17 for a 10^16 limit, so int64 holds every intermediate. Endpoints may arrive in either order, and the code swaps them before counting.

## Code

**Input and scanning.** The reader loads all stdin, then the hand scanner extracts each endpoint.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const lastTrackedDigit = 9

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

The loop appends a newline to every input line.
The scanner skips separators and builds each number from single digits.
A zero endpoint never reaches the counting code.

**Place-value tally.** One procedure counts a digit from 1 up to a limit.

```nim
proc countDigit(limitValue: int64, digitValue: int): int64 =
  if limitValue <= 0:
    return 0
  var placeValue: int64 = 1
  while placeValue <= limitValue:
    let higherPart = limitValue div (placeValue * 10)
    let currentDigit = (limitValue div placeValue) mod 10
    let lowerPart = limitValue mod placeValue
    if currentDigit > digitValue:
      result += (higherPart + 1) * placeValue
    elif currentDigit == digitValue:
      result += higherPart * placeValue + lowerPart + 1
    else:
      result += higherPart * placeValue
    placeValue *= 10
```

The loop visits one power of ten per step.
Three branches cover every relation between the current digit and the target.
All arithmetic uses int64 to hold counts near 10^17.

**Output and main loop.** Each pair produces nine tallies on one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let lowerInput = nextInt(inputData, scanPos)
  if lowerInput == 0:
    break
  let upperInput = nextInt(inputData, scanPos)
  var rangeStart = int64(lowerInput)
  var rangeEnd = int64(upperInput)
  if rangeStart > rangeEnd:
    let swapValue = rangeStart
    rangeStart = rangeEnd
    rangeEnd = swapValue
  for digitValue in 1 .. lastTrackedDigit:
    if digitValue > 1:
      appendOutput(" ")
    let digitTotal = countDigit(rangeEnd, digitValue) - countDigit(rangeStart - 1, digitValue)
    appendOutput($digitTotal)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The buffer flushes in large blocks, not once per number.
Range subtraction turns a prefix tally into an interval tally.
A final flush writes any remaining bytes.

## Complexity

Each query processes nine digits and at most 17 place values.

| phase | time | space |
|---|---|---|
| input read | one pass over all query lines | one input string |
| digit tally | 9 × 17 place values per query | constant |
| output | one line per query | block buffer |

The input string dominates memory use, while counting uses fixed space.

| measure | Big O |
|---|---|
| time | O(q × 9 × log b) |
| space | O(input size) |

Here q is the query count and b is the largest endpoint.
Enumerating every integer would cost O(b − a) per query and could not finish.
