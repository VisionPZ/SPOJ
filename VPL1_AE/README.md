# VPL1_AE — Winter Crush (SPOJ)
<https://www.spoj.com/problems/VPL1_AE/>

## Problem

Elizabeth walks between positions with probabilities set by path joy and snow. For each query, start from each listed position, let T steps pass, and report the position with the highest probability. Ties go to the smallest position, and an isolated start reports -1.

Input starts with C test cases. Each case gives N and M, then M undirected paths with x, y, joy, and snow. A line gives Q, followed by Q queries with time T, count qi, and qi starting positions.

Output prints Scenario #i and a blank line for each case. Each query then prints qi answers on one line.

The input bounds are:

| item | bound |
|---|---|
| test cases C | 1 to 20 |
| positions N | 1 to 100 |
| paths M | 0 to N(N-1)/2 |
| time T | 1 to 2000 |
| query count Q | up to 10 |
| starts per query qi | up to 100 |
| joy and snow | 1 to 100 |
| judge limit | 5000 ms, 1536 MB |

Path weight is joy divided by snow. The probability of a path from x to y is that weight divided by the sum of weights of all paths leaving x.

Sample input:

```
2
3 3
0 1 10 2
0 2 1 8
1 2 100 1
2
1 1 0
2 1 0
4 5
0 1 10 2
1 3 2 3
0 2 4 8
2 1 1 10
2 3 1 1
2
2 1 2
10 2 0 3
```

Sample output:

```
Scenario #1:

1
2

Scenario #2:

1
0 0

```

## Idea

Pass probability like a baton through a graph, where each stop splits the baton among its outgoing paths. Build a stochastic transition matrix, then use binary exponentiation to apply T steps at once.

Precompute the powers by squaring once per case, and multiply each query's one-hot rows by the needed powers. Precomputation costs O(N^3 log T), and each starting position costs O(N^2 log T).

Stepping T times for every start would multiply that work by T. One set of powers serves every query in the case.

## Why It Works

1. Each undirected path contributes weight joy divided by snow to both endpoints.
2. Row x of the transition matrix holds those weights divided by the total weight leaving x.
3. An isolated position has no outgoing weight, so every start there produces a zero row and answer -1.
4. The distribution after T steps from start s is the one-hot row at s multiplied by the transition matrix T times.
5. Binary exponentiation writes T as powers of two, so about log T matrix products replace T steps.
6. All starts in one query share the same powers, so they are processed as a block of rows.
7. Comparing with a small tolerance treats near-equal floating values as ties and keeps the smallest index.

The main terms are:

| term | meaning |
|---|---|
| `neighborWeights` | joy divided by snow for each undirected path |
| `transition` | row-stochastic probability matrix |
| `powers` | transition matrix raised to powers of two |
| `multiplyRowsMatrix` | applies one power to every start row |
| `probabilityEpsilon` | tolerance used when picking the maximum |

A short script over the first sample gives these distributions:

| steps from 0 | at 0 | at 1 | at 2 | answer |
|---|---|---|---|---|
| 1 | 0.000 | 0.976 | 0.024 | 1 |
| 2 | 0.046 | 0.024 | 0.930 | 2 |

The weight from 0 to 1 is 10/2 = 5, and the weight from 0 to 2 is 1/8 = 0.125.
The first split is 5/5.125 and 0.125/5.125, which explains the 0.976 value.
Floating comparison uses a tolerance so exact ties keep the smallest position.

## Code

**Input and helpers.** The reader loads the whole case before any matrix work.

```nim
const flushBlockBytes = 1 shl 17
const probabilityEpsilon = 1e-12

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

The scanner skips whitespace between tokens.
The tolerance absorbs rounding noise in close probabilities.
Output is buffered until a block fills or the program ends.

**Matrix products.** Flat arrays hold both matrix factors and results.

```nim
proc multiplyMatrices(left, right: seq[float], size: int): seq[float] =
  result = newSeq[float](size * size)
  for row in 0 .. size - 1:
    let rowBase = row * size
    for middle in 0 .. size - 1:
      let leftValue = left[rowBase + middle]
      if leftValue == 0.0:
        continue
      let middleBase = middle * size
      for column in 0 .. size - 1:
        result[rowBase + column] = result[rowBase + column] + leftValue * right[middleBase + column]

proc multiplyRowsMatrix(rows, matrix: seq[float], rowCount, size: int): seq[float] =
  result = newSeq[float](rowCount * size)
  for row in 0 .. rowCount - 1:
    let rowBase = row * size
    for source in 0 .. size - 1:
      let sourceValue = rows[rowBase + source]
      if sourceValue == 0.0:
        continue
      let sourceBase = source * size
      for target in 0 .. size - 1:
        result[rowBase + target] = result[rowBase + target] + sourceValue * matrix[sourceBase + target]
```

Zero entries are skipped before the inner loop.
The first procedure squares transition powers.
The second procedure advances all starts in a query at once.

**Case setup.** Paths become a stochastic matrix, then powers of two are stored.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let positionCount = nextInt(inputData, scanPos)
  let pathCount = nextInt(inputData, scanPos)
  var neighborWeights = newSeq[seq[float]](positionCount)
  for position in 0 .. positionCount - 1:
    neighborWeights[position] = newSeq[float](positionCount)
  for pathIndex in 0 .. pathCount - 1:
    let firstPosition = nextInt(inputData, scanPos)
    let secondPosition = nextInt(inputData, scanPos)
    let joy = float(nextInt(inputData, scanPos))
    let snow = float(nextInt(inputData, scanPos))
    let weight = joy / snow
    neighborWeights[firstPosition][secondPosition] = weight
    neighborWeights[secondPosition][firstPosition] = weight

  let queryCount = nextInt(inputData, scanPos)
  var queryTimes = newSeq[int](queryCount)
  var queryStarts = newSeq[seq[int]](queryCount)
  var largestTime = 0
  for queryIndex in 0 .. queryCount - 1:
    queryTimes[queryIndex] = nextInt(inputData, scanPos)
    let startingCount = nextInt(inputData, scanPos)
    if queryTimes[queryIndex] > largestTime:
      largestTime = queryTimes[queryIndex]
    queryStarts[queryIndex] = newSeq[int](startingCount)
    for startIndex in 0 .. startingCount - 1:
      queryStarts[queryIndex][startIndex] = nextInt(inputData, scanPos)

  var transition = newSeq[float](positionCount * positionCount)
  for position in 0 .. positionCount - 1:
    var totalWeight = 0.0
    for neighbor in 0 .. positionCount - 1:
      totalWeight = totalWeight + neighborWeights[position][neighbor]
    if totalWeight > 0.0:
      for neighbor in 0 .. positionCount - 1:
        transition[position * positionCount + neighbor] = neighborWeights[position][neighbor] / totalWeight

  var bitCount = 0
  while (1 shl bitCount) <= largestTime:
    bitCount += 1
  var powers = newSeq[seq[float]](bitCount)
  if bitCount > 0:
    powers[0] = transition
    for bitIndex in 1 .. bitCount - 1:
      powers[bitIndex] = multiplyMatrices(powers[bitIndex - 1], powers[bitIndex - 1], positionCount)
```

Each path fills both symmetric entries.
An isolated row stays all zero.
The largest query time sets the number of powers.

**Answering queries.** One-hot rows advance through the set bits of T.

```nim
  appendOutput("Scenario #" & $(caseIndex + 1) & ":")
  outputBuffer.add "\n\n"
  for queryIndex in 0 .. queryCount - 1:
    let starts = queryStarts[queryIndex]
    var rows = newSeq[float](starts.len * positionCount)
    for startIndex in 0 .. starts.len - 1:
      let startPosition = starts[startIndex]
      if startPosition >= 0 and startPosition < positionCount:
        rows[startIndex * positionCount + startPosition] = 1.0
    var elapsed = queryTimes[queryIndex]
    var bitIndex = 0
    while elapsed > 0:
      if (elapsed and 1) == 1:
        rows = multiplyRowsMatrix(rows, powers[bitIndex], starts.len, positionCount)
      elapsed = elapsed shr 1
      bitIndex += 1
    for startIndex in 0 .. starts.len - 1:
      let rowBase = startIndex * positionCount
      var bestPosition = -1
      var bestProbability = 0.0
      for position in 0 .. positionCount - 1:
        let probability = rows[rowBase + position]
        if probability > bestProbability + probabilityEpsilon:
          bestProbability = probability
          bestPosition = position
      if startIndex > 0:
        appendOutput(" ")
      appendOutput($bestPosition)
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each start begins with probability one at its own position.
Out-of-range starts keep a zero row and answer -1.
Answers for one query share a single output line.

## Complexity

Matrix powering dominates a case.

| phase | time | space |
|---|---|---|
| input read | one pass over edges and queries | one input string |
| matrix squaring | log T products of N by N | log T matrices |
| query advance | qi row updates per set bit | one row block |
| output | qi answers per query | block buffer |

All queries reuse the same stored powers.

| measure | Big O |
|---|---|
| time | O(N^3 log T + Q qi N^2 log T) |
| space | O(N^2 log T) |

Advancing T times for every start would add a factor of T.
One squaring chain per case serves every query, and that ends the work.
