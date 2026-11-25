# MRECAMAN — Recaman's Sequence (SPOJ)

<https://www.spoj.com/problems/MRECAMAN/>

## Problem

Build a sequence where step m subtracts m from the last value when that lands on a fresh positive number, and adds m in every other case. For each requested index k, print the value stored at k.

Input contract: each line holds one integer k, and the line -1 ends the file without producing output. Output contract: print one integer per query line, in the order the queries appear.

The bounds from the statement:

| item | bound |
|---|---|
| index k | 0 to 500000 |
| query count | as many lines as the file holds |
| judge limit | 1000 ms, 1536 MB |

Step 3 lands on zero, which is not positive, so the rule adds instead.

Sample input:

```
7
10000
-1
```

Sample output:

```
20
18658
```

## Idea

Fill the sequence once, like labelling every shelf before answering any question about a shelf. The algorithm is a direct simulation that records used values in an array. Each step costs constant work, so the build up to the largest query costs O(max k). Starting over for every query would repeat the same prefix many times. One shared build answers all queries.

## Why It Works

1. The value at step m depends only on the value at step m - 1 and on earlier values.
2. A backward move is legal only when it is positive and absent from the used set.
3. Any other case forces the forward move by m.
4. Marking each chosen value keeps the membership test exact.
5. Growing the used array on demand keeps every index in range.

The terms behind the simulation:

| term | meaning |
|---|---|
| `sequenceValues` | value recorded for each index |
| `usedValues` | membership array for values already placed |
| `candidateValue` | the backward value tested at one step |
| `useAddition` | flag choosing the forward move |

The backward test rejects zero, so no value repeats.

A traced prefix of the sequence:

```
step  previous  candidate  decision  value
1     0          -1         add       1
2     1          -1         add       3
3     3           0         add       6
4     6           2         subtract  2
5     2          -3         add       7
6     7           1         add       13
7     13          6         add       20
```

The trace reaches index 7 with value 20, matching the first sample answer.

## Code

**Input and sentinel handling.** The reader collects every query and finds the largest index.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc hasMoreNumbers(data: string, pos: int): bool =
  var index = pos
  while index < data.len:
    if data[index] >= '0' and data[index] <= '9':
      return true
    index += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The minus branch reads the -1 sentinel correctly.
The scan stops when no digit remains.
The buffer flushes whole blocks rather than single lines.

**Sequence build and answers.** Simulation runs once up to the largest request.

```nim
var requestedIndices = newSeq[int](0)
var largestIndex = 0
while hasMoreNumbers(inputData, scanPos):
  let queryIndex = nextInt(inputData, scanPos)
  if queryIndex == -1:
    break
  requestedIndices.add queryIndex
  if queryIndex > largestIndex:
    largestIndex = queryIndex

var sequenceValues = newSeq[int](largestIndex + 1)
var usedValues = newSeq[bool](1)
sequenceValues[0] = 0
usedValues[0] = true
for stepIndex in 1 .. largestIndex:
  let previousValue = sequenceValues[stepIndex - 1]
  var candidateValue = previousValue - stepIndex
  var useAddition = false
  if candidateValue <= 0:
    useAddition = true
  elif candidateValue < usedValues.len:
    if usedValues[candidateValue]:
      useAddition = true
  if useAddition:
    candidateValue = previousValue + stepIndex
  sequenceValues[stepIndex] = candidateValue
  if candidateValue >= usedValues.len:
    usedValues.setLen(candidateValue + 1)
  usedValues[candidateValue] = true

for queryIndex in requestedIndices:
  appendOutput($(sequenceValues[queryIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Zero is rejected by the strict positive test.
The used array grows before a large value is marked.
Every query reads its answer in constant time.

## Complexity

Build cost dominates the run.

| phase | time | space |
|---|---|---|
| input read | one pass over query lines | query list and input string |
| sequence build | one step per index up to max k | value and membership arrays |
| output | one line per query | block buffer |

The build touches each index once, so query count adds only cheap lookups.

| measure | Big O |
|---|---|
| time | O(max k + number of queries) |
| space | O(max k) |

Restarting the simulation per query would multiply the work by the query count.
One shared build keeps every answer within the judge limit.
