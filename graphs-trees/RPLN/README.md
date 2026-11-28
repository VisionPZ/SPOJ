# RPLN — Negative Score (SPOJ)
<https://www.spoj.com/problems/RPLN/>

## Problem

List the scores from evaluation A through evaluation B and take the smallest one. Scores can be negative, so the smallest value drives the answer.

Input starts with the case count T. Each case gives N and Q, then N scores, then Q queries with two endpoints A and B. Print `Scenario #i:` for each case, then one minimum per query on its own line.

| Constraint | Value |
| --- | --- |
| Cases T | 1 to 100 |
| Evaluations N | 1 to 100000 |
| Queries Q | 1 to 100000 |
| Score | -1000000000 to 1000000000 |
| Query range | 1 <= A <= B <= N |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
2
5 3
1 2 3 4 5
1 5
1 3
2 4
5 3
1 -2 -4 3 -5
1 5
1 3
2 4
```

```
Scenario #1:
1
1
2
Scenario #2:
-5
-4
-4
```

## Idea

Overlapping pairs of blocks answer each range in one step, like reading a ladder of precomputed answers instead of rescanning the list.

The program builds a sparse table. Level zero holds the scores. Level k stores minima over spans of length 2 to the k. A query reads two overlapping spans and takes the smaller value. Building costs one pass per level. Each query costs one comparison. Scanning the range for every query costs O(N) each and is far slower. Precompute once, then answer in constant time.

## Why It Works

1. Every range of length L splits into two spans of length 2 to the k, where k is the largest power of two fitting in L.
2. The two spans overlap or touch, so their union covers the whole range.
3. Taking the smaller of the two span minima gives the minimum over the union.
4. `logTable` maps a span length to its level in constant time.
5. `nextInt` reads minus signs, so negative scores parse correctly.

| Term | Meaning |
| --- | --- |
| `sparseTable` | stored minima for every level and start index |
| `logTable` | level selected for a range length |
| `scoreCount` | number of evaluations in one case |
| `queryLevel` | level used by one query |

A script-generated check uses scores 1, -2, -4, 3, -5. Level one stores -2, -4, -4, -5. Level two stores -4 and -5. The range 1 to 5 has length 5, so k is 2. The two spans are positions 0 to 3 and 1 to 4. Their minima are -4 and -5, and the answer is -5.

## Code

**Input and scanner.** The hand reader loads the whole stream and parses signed integers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
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
```

The minus branch handles signed scores.
Each call advances one token.
No line boundary matters to the parser.

**Output writer.** One buffer collects all case headers and query answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in fixed blocks.
Small outputs flush once at the end.
No write happens per number.

**Table build.** Each level halves the span length by pairing blocks from the level below.

```nim
let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let scoreCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var logTable = newSeq[int](scoreCount + 1)
  var levelIndex = 2
  while levelIndex <= scoreCount:
    logTable[levelIndex] = logTable[levelIndex div 2] + 1
    levelIndex += 1
  let levelCount = logTable[scoreCount] + 1
  var sparseTable = newSeq[int64](levelCount * scoreCount)
  var scoreIndex = 0
  while scoreIndex < scoreCount:
    sparseTable[scoreIndex] = int64(nextInt(inputData, scanPos))
    scoreIndex += 1
  var tableLevel = 1
  while tableLevel < levelCount:
    let spanLength = 1 shl tableLevel
    let halfSpan = spanLength div 2
    var blockStart = 0
    while blockStart + spanLength <= scoreCount:
      let leftValue = sparseTable[(tableLevel - 1) * scoreCount + blockStart]
      let rightValue = sparseTable[(tableLevel - 1) * scoreCount + blockStart + halfSpan]
      if leftValue < rightValue:
        sparseTable[tableLevel * scoreCount + blockStart] = leftValue
      else:
        sparseTable[tableLevel * scoreCount + blockStart] = rightValue
      blockStart += 1
    tableLevel += 1
```

The table uses one flat sequence.
Each level stores one minimum per valid start.
`int64` keeps every stored score exact.

**Query sweep.** Each query reads two overlapping spans and writes one line.

```nim
  appendOutput("Scenario #" & $(caseIndex + 1) & ":\n")
  var queryIndex = 0
  while queryIndex < queryCount:
    let leftEnd = nextInt(inputData, scanPos) - 1
    let rightEnd = nextInt(inputData, scanPos) - 1
    let rangeLength = rightEnd - leftEnd + 1
    let queryLevel = logTable[rangeLength]
    let jumpLength = 1 shl queryLevel
    let firstValue = sparseTable[queryLevel * scoreCount + leftEnd]
    let secondValue = sparseTable[queryLevel * scoreCount + rightEnd - jumpLength + 1]
    if firstValue < secondValue:
      appendOutput($firstValue)
    else:
      appendOutput($secondValue)
    appendOutput("\n")
    queryIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Endpoints convert from one-based input to zero-based storage.
The second span ends at the right endpoint.
The final flush emits the remaining bytes.

## Complexity

Table build scans each level once, and queries read two cells each.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over N scores | one input string |
| Table build | N times log N comparisons | N log N stored minima |
| Query sweep | one comparison per query | one output buffer |

| Measure | Big O |
| --- | --- |
| Build time | O(N log N) |
| Query time | O(1) |
| Space | O(N log N) |

Scanning each range directly would cost O(N) per query instead of O(1).

Precompute a sparse table once, then answer every minimum query with two reads.
