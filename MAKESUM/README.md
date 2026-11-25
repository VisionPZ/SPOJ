# MAKESUM — MAKESUM (SPOJ)

<https://www.spoj.com/problems/MAKESUM/>

## Problem

Given the sorted list of all pairwise sums of some natural numbers, recover the lexicographically smallest set of numbers that produces those sums.

The first integer is `M`, the count of pairwise sums. The next `M` integers are those sums in sorted order. The answer is the recovered numbers in sorted order, separated by spaces.

The statement gives these bounds:

| item | bound |
|---|---|
| numbers N | up to 50 |
| each number | up to 100000 |
| pairwise sums M | N times (N minus 1) divided by 2 |
| judge limit | 201 ms, 1536 MB |

The small count of sums permits trying the smallest possible first number.

Sample input:

```
6
2 2 2 3 3 3
```

Sample output:

```
1 1 1 2
```

## Idea

Think of the smallest sum as a handshake between the two smallest numbers, like the first two people in a line shaking hands.

Fix the smallest number and the smallest remaining sum reveals the next number by subtraction. Consume every pair sum formed with that new number. If all sums are consumed exactly, the candidate works, and trying candidates in order gives the lexicographically smallest answer.

Enumerating every possible number set costs exponential time. The greedy subtraction tests one candidate in linear time and rejects wrong ones early. The takeaway is to peel off sums from smallest to largest.

## Why It Works

1. The smallest pairwise sum equals the two smallest numbers added together.
2. With the smallest number fixed, the smallest unused sum reveals the next number.
3. Adding a new number creates one pair sum with each earlier number, and all must exist.
4. A negative multiplicity means the candidate cannot produce the given sums.
5. Trying the smallest number in increasing order yields the lexicographically smallest valid set.

The main terms are listed here:

| term | meaning |
|---|---|
| `sortedSums` | pairwise sums in increasing order |
| `distinctSums` | one entry per unique sum value |
| `targetCounts` | required multiplicity of each unique sum |
| `candidateFirst` | trial value for the smallest number |

Stamps let one trial reuse the count arrays without clearing them.

A script trace for the sample uses candidate first number one:

| step | smallest unused sum | new number | pair sums consumed |
|---|---|---|---|
| 2 | 2 | 1 | 2 |
| 3 | 2 | 1 | 2, 2 |
| 4 | 3 | 2 | 3, 3, 3 |

All six sums are consumed, so the answer is `1 1 1 2`.

Guard: a new number below the previous number rejects the candidate at once.

## Code

**Input and sorting.** The reader loads the sums, sorts them, and recovers the number count.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sumCount = nextInt(inputData, scanPos)
if sumCount == 0:
  appendOutput("1")
  outputBuffer.add '\n'
  stdout.write outputBuffer
  outputBuffer.setLen 0
  quit(0)

var sortedSums = newSeq[int](sumCount)
var largestSum = 0
for sumIndex in 0 .. sumCount - 1:
  sortedSums[sumIndex] = nextInt(inputData, scanPos)
  if sortedSums[sumIndex] > largestSum:
    largestSum = sortedSums[sumIndex]
for sumIndex in 1 .. sumCount - 1:
  let currentSum = sortedSums[sumIndex]
  var previousIndex = sumIndex - 1
  while previousIndex >= 0 and sortedSums[previousIndex] > currentSum:
    sortedSums[previousIndex + 1] = sortedSums[previousIndex]
    previousIndex -= 1
  sortedSums[previousIndex + 1] = currentSum

var totalNumbers = 1
while totalNumbers * (totalNumbers - 1) div 2 < sumCount:
  totalNumbers += 1
```

Insertion sort avoids a platform-specific comparator.
The triangular count recovers how many numbers to print.
A zero sum count is handled as a single number.

**Count index.** Unique sums are compressed into arrays and a direct lookup table.

```nim
var distinctSums = newSeq[int](0)
var targetCounts = newSeq[int](0)
for sumIndex in 0 .. sumCount - 1:
  if sumIndex > 0 and sortedSums[sumIndex] == sortedSums[sumIndex - 1]:
    targetCounts[targetCounts.len - 1] += 1
  else:
    distinctSums.add sortedSums[sumIndex]
    targetCounts.add 1

var sumLookup = newSeq[int](largestSum + 1)
for lookupIndex in 0 .. largestSum:
  sumLookup[lookupIndex] = -1
for distinctIndex in 0 .. distinctSums.len - 1:
  sumLookup[distinctSums[distinctIndex]] = distinctIndex

var usedStamp = newSeq[int](distinctSums.len)
var usedCount = newSeq[int](distinctSums.len)
var trialNumber = 0
var smallestSum = sortedSums[0]
var candidateFirst = 1
```

Compression collapses repeated sums into one counter.
The lookup maps a sum value to its counter in constant time.
Stamps mark which trial owns each counter value.

**Greedy reconstruction.** Each trial peels the smallest sum and consumes all newly formed pairs.

```nim
while candidateFirst <= smallestSum div 2:
  trialNumber += 1
  var foundNumbers = newSeq[int](1)
  foundNumbers[0] = candidateFirst
  var lookupCursor = 0
  var validTrial = true

  while foundNumbers.len < totalNumbers and validTrial:
    while lookupCursor < distinctSums.len:
      let distinctIndex = lookupCursor
      let alreadyUsed = if usedStamp[distinctIndex] == trialNumber: usedCount[distinctIndex] else: 0
      if targetCounts[distinctIndex] - alreadyUsed > 0:
        break
      lookupCursor += 1
    if lookupCursor >= distinctSums.len:
      validTrial = false
      break
    let chosenSum = distinctSums[lookupCursor]
    let nextNumber = chosenSum - candidateFirst
    if nextNumber < foundNumbers[foundNumbers.len - 1]:
      validTrial = false
      break
    foundNumbers.add nextNumber
    for earlierIndex in 0 .. foundNumbers.len - 2:
      let pairSum = foundNumbers[earlierIndex] + nextNumber
      if pairSum < 0 or pairSum > largestSum:
        validTrial = false
        break
      let distinctIndex = sumLookup[pairSum]
      if distinctIndex < 0:
        validTrial = false
        break
      let alreadyUsed = if usedStamp[distinctIndex] == trialNumber: usedCount[distinctIndex] else: 0
      if targetCounts[distinctIndex] - alreadyUsed <= 0:
        validTrial = false
        break
      if usedStamp[distinctIndex] != trialNumber:
        usedStamp[distinctIndex] = trialNumber
        usedCount[distinctIndex] = 0
      usedCount[distinctIndex] += 1

  if validTrial:
    for numberIndex in 0 .. foundNumbers.len - 1:
      if numberIndex > 0:
        appendOutput(" ")
      appendOutput($foundNumbers[numberIndex])
    outputBuffer.add '\n'
    stdout.write outputBuffer
    outputBuffer.setLen 0
    quit(0)
  candidateFirst += 1

appendOutput("-1")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The lookup cursor only moves forward as sums are consumed.
A missing or exhausted pair sum rejects the trial immediately.
The first valid trial is printed, which is the lexicographically smallest set.

## Complexity

Sorting and candidate trials determine the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over M sums | one input string |
| sort and compress | M log M comparisons | arrays of M entries |
| greedy trials | up to half the smallest sum | two stamp arrays |
| output | one line | block buffer |

Wrong trials usually fail after two or three numbers.

| measure | Big O |
|---|---|
| time | O(M log M) per successful trial |
| space | O(M) |

Enumerating all number sets would cost exponential time. Subtracting the smallest sum recovers one number per step, which is the takeaway.
