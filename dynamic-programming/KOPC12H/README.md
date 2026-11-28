# KOPC12H — K12-OE Numbers (SPOJ)

<https://www.spoj.com/problems/KOPC12H/>

## Problem

An OE number has a larger sum of even digits than odd digits. For each range from `a` to `b`, count how many integers in that inclusive range are OE numbers.

Input starts with the test count `T`. Each test has two integers `a` and `b`. Output one count per test.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 35 |
| Range endpoints | 1 to 100000000 |
| Judge limit | 100 ms to 1 s, 1536 MB |

Notation: the balance of a number is the even-digit sum minus the odd-digit sum, and an OE number has a positive balance.

Here is the sample input:

```
3
1 1
2 10
1 100000000
```

Here is the sample output:

```
0
4
38379932
```

## Idea

Counting qualifying numbers resembles walking a digit-by-digit decision tree while keeping a balance scale that tips toward even digits. Precompute how many digit endings succeed from each balance and remaining length, then walk the upper bound once. Answer a range by subtracting the count below its lower endpoint. Enumerating every integer in the range grows with the range size, while the digit walk stays tiny.

## Why It Works

1. Each digit changes the balance by its own value with a sign set by parity.
2. Adding zero digits at the front leaves the balance unchanged, so fixed-length counting is safe.
3. The precomputed `ways` table counts successful endings for each remaining length and starting balance.
4. Walking the upper bound fixes a smaller digit at the first differing position, then uses the table for the free suffix.
5. Adding one for the bound itself completes the inclusive count.
6. Subtracting the count up to `a` minus one gives the range answer.

| Term | Meaning |
|---|---|
| `ways` | successful endings by remaining length and balance |
| `differenceOffset` | shifts negative balances into array indexes |
| `differenceRange` | number of balance slots in each table row |
| `digitContribution` | signed contribution of one digit |
| `countUpTo` | count of qualifying numbers from zero to a bound |
| `runningDifference` | balance accumulated along the current prefix |

The table lists the values used by the digit walk.

A worked trace for the bound 10 follows.

```
tens digit 1: try smaller digit 0
  starting balance 0, one free digit
  successful endings 2, 4, 6, 8 -> four numbers
keep digit 1: balance becomes -1, not positive
countUpTo(10) = 4
```

The trace yields the sample answer 4 for the range 2 to 10, since 1 does not qualify.

## Code

**Input, buffer setup, and balance helper.** The reader loads stdin once and defines the digit contribution.

```nim
const flushBlockBytes = 1 shl 17
const maximumDigits = 10
const differenceOffset = 100
const differenceRange = 201

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

proc digitContribution(digitValue: int): int =
  if (digitValue mod 2) == 0:
    return digitValue
  return -digitValue
```

The scanner reads both range endpoints from the shared input string. The writer batches answers for all tests. The contribution helper encodes parity with one sign change.

**Completion table.** The precomputation fills counts for every remaining length and starting balance.

```nim
var ways = newSeq[seq[int]](maximumDigits + 1)
for remainingIndex in 0 .. maximumDigits:
  ways[remainingIndex] = newSeq[int](differenceRange)
for differenceIndex in 0 .. differenceRange - 1:
  if differenceIndex - differenceOffset > 0:
    ways[0][differenceIndex] = 1
for remainingCount in 1 .. maximumDigits:
  for differenceIndex in 0 .. differenceRange - 1:
    let currentDifference = differenceIndex - differenceOffset
    var completionCount = 0
    for digitValue in 0 .. 9:
      let nextDifference = currentDifference + digitContribution(digitValue)
      if nextDifference >= -differenceOffset and nextDifference <= differenceOffset:
        completionCount += ways[remainingCount - 1][nextDifference + differenceOffset]
    ways[remainingCount][differenceIndex] = completionCount
```

An empty ending succeeds when the balance is already positive. Each longer row adds one digit and sums ten shifted previous rows.

**Bound walk and range answers.** The digit walk uses the table and writes one answer per test.

```nim
proc countUpTo(limitValue: int): int =
  if limitValue <= 0:
    return 0
  var digits = newSeq[int]()
  var remainingValue = limitValue
  while remainingValue > 0:
    digits.add(remainingValue mod 10)
    remainingValue = remainingValue div 10
  var answerTotal = 0
  var runningDifference = 0
  var position = digits.len - 1
  while position >= 0:
    let currentDigit = digits[position]
    let remainingCount = position
    for smallerDigit in 0 .. currentDigit - 1:
      let nextDifference = runningDifference + digitContribution(smallerDigit)
      if nextDifference >= -differenceOffset and nextDifference <= differenceOffset:
        answerTotal += ways[remainingCount][nextDifference + differenceOffset]
    runningDifference += digitContribution(currentDigit)
    position -= 1
  if runningDifference > 0:
    answerTotal += 1
  return answerTotal

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let lowerBound = nextInt(inputData, scanPos)
  let upperBound = nextInt(inputData, scanPos)
  let answerValue = countUpTo(upperBound) - countUpTo(lowerBound - 1)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Digits are stored least significant first and read back in order. At each position, smaller digits contribute table entries and the chosen digit updates the running balance. The range answer is one subtraction.

## Complexity

Precomputation is fixed, and each range costs one short digit walk.

| Phase | Time | Space |
|---|---|---|
| Completion table | 10 lengths times 201 balances times 10 digits | 2010 counters |
| Bound walk | at most 9 positions times 10 digits | small digit list |
| Output | one line per test | block buffer |

Work per test does not depend on the range width.

| Measure | Big O |
|---|---|
| Time | O(precomputation plus test count times digits times ten) |
| Space | O(digits times balances) |

Testing every integer in the range would grow by 100000000 in the worst case; digit DP replaces that with a fixed walk.
