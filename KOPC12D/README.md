# KOPC12D — K12-Generating Big Numbers II (SPOJ)

<https://www.spoj.com/problems/KOPC12D/>

## Problem

Place every required digit into positions of a decimal number so that digit `d` never sits at a position divisible by `d`. Positions count from the units digit as 1. Fill unused places with zeros and report the shortest possible length.

Input starts with the test count `T`. Each test has eight counts, for digits 2 through 9. Output one length per test.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 50 |
| Count per digit | 0 to 20 |
| Digits supplied | 2 through 9 |
| Judge limit | 1000 ms, 1536 MB |

Notation: `L` is the number length, and zero divided into any position counts as a legal filler.

Here is the sample input:

```
2
2 0 2 0 0 0 0 0
20 20 20 20 20 20 20 20
```

Here is the sample output:

```
5
160
```

## Idea

Fitting digits into positions resembles assigning guests to numbered seats, where a guest skips every seat whose number is a multiple of their digit. For a set of digits, the blocked seats are the common multiples of that set, so the useful positions are `L` minus those multiples. Hall's theorem says that checking every subset of digits settles feasibility. Scan candidate lengths and take the smallest one that passes all subset checks.

## Why It Works

1. Digit `d` may use any position from 1 to `L` except multiples of `d`.
2. A position is blocked for a whole set of digits when it is a multiple of their least common multiple.
3. The number of positions usable by that set is `L` minus `L` divided by the least common multiple.
4. Hall's theorem requires every set of copies to have at least as many usable positions as copies.
5. The tightest sets take all copies of chosen digit types, so only 255 subsets need checking.
6. For a subset with period `m` and `s` copies, the smallest working length satisfies `L` minus `L` divided by `m` at least `s`.
7. The answer is the largest of those smallest lengths, with a floor of one for all-zero input.

| Term | Meaning |
|---|---|
| `digitCounts` | copies required for each digit from 2 to 9 |
| `totalInstances` | total copies across all digits |
| `subsetMask` | one of the 255 non-empty digit sets |
| `requiredPositions` | copies demanded by the current subset |
| `forbiddenPeriod` | least common multiple of the subset digits |
| `lengthCandidate` | smallest length satisfying one subset |
| `bestLength` | largest requirement across subsets |

The table names the values used by the subset sweep.

A worked trace of the first sample case follows.

```
counts: two 2s and two 4s, total four copies
subset {2,4}: period 4, four copies needed
L=4: usable positions 4 - 4/4 = 3, too few
L=5: usable positions 5 - 5/4 = 4, fits
answer 5
```

The trace gives 5, matching the sample. A single digit 2 with 20 copies needs 39 places, since 39 holds 20 odd positions.

## Code

**Input and buffer setup.** The reader loads stdin once and defines the buffered writer and divisor helper.

```nim
const flushBlockBytes = 1 shl 17
const digitKinds = 8
const subsetCount = 256

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc greatestCommonDivisor(firstValue: int, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainderValue = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainderValue
  return leftValue
```

The scanner skips spaces and line breaks between counts. The divisor helper supports least common multiples for every subset. The writer flushes after a large block.

**Subset sweep and answer.** The code checks all digit sets and keeps the largest requirement.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var digitCounts = newSeq[int](digitKinds)
  var totalInstances = 0
  for digitIndex in 0 .. digitKinds - 1:
    digitCounts[digitIndex] = nextInt(inputData, scanPos)
    totalInstances += digitCounts[digitIndex]
  var bestLength = 1
  let searchLimit = 2 * totalInstances + 16
  for subsetMask in 1 .. subsetCount - 1:
    var requiredPositions = 0
    var forbiddenPeriod = 1
    for digitIndex in 0 .. digitKinds - 1:
      if (subsetMask and (1 shl digitIndex)) != 0:
        requiredPositions += digitCounts[digitIndex]
        let digitValue = digitIndex + 2
        forbiddenPeriod = forbiddenPeriod div
          greatestCommonDivisor(forbiddenPeriod, digitValue) * digitValue
    if requiredPositions == 0:
      continue
    var lengthCandidate = 1
    while lengthCandidate - lengthCandidate div forbiddenPeriod < requiredPositions:
      lengthCandidate += 1
      if lengthCandidate > searchLimit:
        break
    if lengthCandidate > bestLength:
      bestLength = lengthCandidate
  appendOutput($bestLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each subset adds its digit counts and builds one period by least common multiples. The inner scan stops at the first length with enough usable positions. The answer is the maximum over all subsets.

## Complexity

Only 255 subsets are examined per test, and each scan is short.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input text | one input string |
| Subset scan | 255 subsets, each a short length walk | eight counts |
| Answer write | one line per test | block buffer |

Work per test depends on the copy total, which never exceeds 160.

| Measure | Big O |
|---|---|
| Time per test | O(255 times copy total) |
| Space per test | O(1) |

Trying every assignment of digits to positions would grow far faster than the subset sweep.
