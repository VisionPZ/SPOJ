# RANGZER2 — ZEROES IN RANGE V2 (SPOJ)

<https://www.spoj.com/problems/RANGZER2/>

## Problem

Count how many digit zeroes appear when writing every whole number from a lower bound to an upper bound. Answer each range separately.

Input starts with the test count t. Each following line holds two bounds a and b with a at most b. Print one count per line.

| item | bound |
|---|---|
| test count t | 1 to 1000 |
| bounds a, b | 1 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

A range can span a billion numbers, so enumerating its members is out of the question.

Sample input:

```
2
1 10
1 100
```

Sample output:

```
1
11
```

The answer for 1 to 10 is the single zero in 10.

## Idea

Counting zeroes by place value is like tallying street numbers with a fixed digit slot held at zero. For each place, split the count into complete blocks and a partial block, then add the zeroes in each piece. A digit DP would walk every position with state flags, while this formula uses a few divisions per place. Subtract the count up to a-1 from the count up to b.

## Why It Works

1. Leading zeroes are not written, so a place contributes nothing until higher digits exist.
2. Each complete block of ten to the place value puts zero in that place once.
3. In the partial block, zero appears either for the whole place value or for the remainder plus one.
4. Summing over places counts every written zero once.
5. The difference of two prefix counts gives the requested range.

| term | meaning |
|---|---|
| `placeValue` | ten raised to the position being counted |
| `higherPart` | digits left of the current place |
| `currentDigit` | digit sitting at the current place |
| `lowerPart` | digits right of the current place |

The four terms are exactly the inputs to the place-value count.

A script trace for both sample ranges:

```
range 1..10: place 1 gives 1 zero, place 10 gives 0, total 1
range 1..100: place 1 gives 10 zeros, place 10 gives 1, place 100 gives 0, total 11
```

The trace matches both sample outputs.

## Code

**Input and scanner.** The reader loads the test count and both bounds of each case.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

Whitespace between numbers is ignored.
Bounds are positive, so no sign handling is needed.
Each case consumes exactly two integers.

**Place-value count.** A few divisions give the zeroes at each digit position.

```nim
proc countZerosUpTo(limit: int64): int64 =
  var zeroTotal: int64 = 0
  var placeValue: int64 = 1
  while placeValue <= limit:
    let higherPart = limit div (placeValue * 10)
    let currentDigit = (limit div placeValue) mod 10
    let lowerPart = limit mod placeValue
    if higherPart > 0:
      if currentDigit == 0:
        zeroTotal = zeroTotal + (higherPart - 1) * placeValue + lowerPart + 1
      else:
        zeroTotal = zeroTotal + higherPart * placeValue
    placeValue = placeValue * 10
  return zeroTotal
```

The higher part gates out leading zeroes.
A zero digit adds the remainder plus one.
All arithmetic uses 64-bit values.

**Range output.** Each answer subtracts the prefix before the lower bound.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rangeStart = int64(nextInt(inputData, scanPos))
  let rangeEnd = int64(nextInt(inputData, scanPos))
  let rangeZeros = countZerosUpTo(rangeEnd) - countZerosUpTo(rangeStart - 1)
  appendOutput($rangeZeros)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The lower bound minus one removes earlier numbers.
Answers are appended as complete lines.
One final flush clears the buffer.

## Complexity

Work splits into input reading and a short loop per prefix count.

| phase | time | space |
|---|---|---|
| input read | one pass over the input | one input string |
| prefix count | ten places per count | a few scalars |
| output | one line per case | block buffer |

Each case costs two short prefix counts.

| measure | Big O |
|---|---|
| time | O(t log b) |
| space | O(1) beyond input and output |

Writing every number would cost O(b-a) per case instead.
The place-value count stays fast for billion-wide ranges.
