<https://www.spoj.com/problems/VPL0_D/>

## Problem

Shouri lists wishes in order and the table lists grapes in order. Pick matching values that keep both orders. Maximize the sum of picked values. Break ties by the larger count. Report the sum and count, or 0 0 when no value matches.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| wish length K | 1 to N |
| grape count N | 1 to 1000 |
| value range | 1 to 10000 |
| judge limit | 1000 ms, 1536 MB |

A picked set is a common subsequence of both lists, and its power is the sum of its values.

Sample input:

```
3
3 3
1 2 3
3 2 1
3 3
2 4 5
3 2 5
5 7
3 3 3 4 5
4 5 3 8 3 12 3
```

Sample output:

```
Scenario #1: 3 1
Scenario #2: 7 2
Scenario #3: 9 3
```

## Idea

Think of two stacks of numbered cards: you may take a card only when the same number sits on both stacks in the same order. The weighted LCS table keeps the best sum for each pair of prefixes. Each cell compares skipping a wish, skipping a grape, and matching the two current values.

The sum drives the choice, so a larger match always beats smaller alternatives; equal sums keep the longer subsequence.

## Why It Works

1. A cell (i, j) covers the first i wishes and the first j grapes.
2. Skipping the i-th wish leaves `previousSum[j]`; skipping the j-th grape leaves `currentSum[grapeIndex - 1]`.
3. Matching equal values adds the value to the best result for the prefixes before both.
4. A strict sum gain wins; on equal sums the longer subsequence wins.
5. The last cell holds the optimum for the whole lists.

| term | meaning |
|---|---|
| `priorities` | Shouri's ordered wish values |
| `grapes` | the ordered grape values on the table |
| `previousSum` | best sum for prefixes ending at the previous wish |
| `pairedSum` | best sum when the two current values match |

For the third sample case, 3 3 3 scores 9 with three grapes, while 4 5 also scores 9 with two.

The tie rule selects the three-grape group, matching the sample output.

## Code

**Input and scanning.** All values of one case are read before the table starts.

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
```

The scanner ignores line breaks and extra spaces.
Two arrays hold the two lists for the current case.

**Weighted subsequence table.** Two rows replace the full K by N table.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let priorityCount = nextInt(inputData, scanPos)
  let grapeCount = nextInt(inputData, scanPos)
  var priorities = newSeq[int](priorityCount)
  var grapes = newSeq[int](grapeCount)
  for priorityIndex in 0 .. priorityCount - 1:
    priorities[priorityIndex] = nextInt(inputData, scanPos)
  for grapeIndex in 0 .. grapeCount - 1:
    grapes[grapeIndex] = nextInt(inputData, scanPos)

  var previousSum = newSeq[int64](grapeCount + 1)
  var previousLength = newSeq[int](grapeCount + 1)
  var currentSum = newSeq[int64](grapeCount + 1)
  var currentLength = newSeq[int](grapeCount + 1)

  for priorityIndex in 1 .. priorityCount:
    currentSum[0] = 0
    currentLength[0] = 0
    for grapeIndex in 1 .. grapeCount:
      var bestSum = previousSum[grapeIndex]
      var bestLength = previousLength[grapeIndex]
      if currentSum[grapeIndex - 1] > bestSum or
         (currentSum[grapeIndex - 1] == bestSum and currentLength[grapeIndex - 1] > bestLength):
        bestSum = currentSum[grapeIndex - 1]
        bestLength = currentLength[grapeIndex - 1]
      if priorities[priorityIndex - 1] == grapes[grapeIndex - 1]:
        let pairedSum = previousSum[grapeIndex - 1] + int64(priorities[priorityIndex - 1])
        let pairedLength = previousLength[grapeIndex - 1] + 1
        if pairedSum > bestSum or (pairedSum == bestSum and pairedLength > bestLength):
          bestSum = pairedSum
          bestLength = pairedLength
      currentSum[grapeIndex] = bestSum
      currentLength[grapeIndex] = bestLength
    swap previousSum, currentSum
    swap previousLength, currentLength

  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $previousSum[grapeCount] & " " & $previousLength[grapeCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Sums use 64 bits to hold thousands of values up to 10000.
Row swapping keeps memory at two rows of N entries.
One final flush writes every labelled answer line.

## Complexity

Each cell does a constant number of comparisons.

| phase | time | space |
|---|---|---|
| input read | one pass over both lists | two case arrays |
| table fill | K times N cell updates | four rows of N entries |
| output | one labelled line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(KN) per case |
| space | O(N) |

Enumerating every pair of subsequences would need exponential time.

The rolling rows keep the weighted LCS rule fast even at N = 1000.
