## Problem

Read a table of shortest distances between towns. Print every pair of neighbouring towns. Two towns are neighbouring when no third town lies on a shortest path between them. Each pair uses the smaller town number first. Pairs appear in increasing order, and a blank line separates consecutive test cases.

| Quantity | Bound |
| --- | --- |
| Towns per case | 1 to 200 |
| Distance entry | 0 to 200 |
| Test cases | not bounded by the statement |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

With 200 towns, a case has at most 19,900 candidate pairs.

## Idea

Test each town pair against the distance table. A third town lies on a shortest path when its two distances add up to the direct distance. The program checks each pair once and stops at the first such town. The table already holds shortest distances, so no path search is needed. Cost: at most n − 2 towns checked per pair, which is O(n³) work per case.

## Why It Works

For towns i, j and k, equality in the sum below means k lies on a shortest path from i to j. The table holds shortest distances, so that equality is the whole test. The code skips k = i and k = j, because d[i][i] = 0 makes the equality true for every pair. One intermediate town rejects a pair; none accepts it. The loops visit i and then j in increasing order, so the printed pairs are sorted.

```
d[i][k]    distance from town i to town k
d[k][j]    distance from town k to town j
d[i][j]    direct distance from town i to town j
```

Each line describes one term of the tested equality.

The generator writes this sample case and checks its exact output:

```
0 1 2
1 0 3
2 3 0
```

```
1 2
1 3
```

The pair 2 3 is absent because town 1 splits its distance into 1 + 2 = 3.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop ends at end of input. The scanner skips every non-digit, so blank lines between cases cost nothing. Parsing is linear in the number of digits.

```nim
var outputBuffer = ""

proc flushOutput() =
  stdout.write outputBuffer
  outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc appendPair(leftTown, rightTown: int) =
  outputBuffer.add $(leftTown)
  outputBuffer.add ' '
  outputBuffer.add $(rightTown)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
```

The flush bound is 256 KiB. One buffer serves all pairs, so the program writes once per block instead of once per pair. The cost is one appended string per pair.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  var distances = newSeq[int](nodeCount * nodeCount)
  for i in 0..<nodeCount:
    for j in 0..<nodeCount:
      distances[i * nodeCount + j] = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput "\n"
  for i in 0..<nodeCount:
    for j in i + 1..<nodeCount:
      let directDistance = distances[i * nodeCount + j]
      var hasIntermediate = false
      for k in 0..<nodeCount:
        if k == i or k == j:
          continue
        if distances[i * nodeCount + k] + distances[k * nodeCount + j] == directDistance:
          hasIntermediate = true
          break
      if not hasIntermediate:
        appendPair i + 1, j + 1

flushOutput()
```

The pair loop starts at i + 1, so each pair is printed once. Skipping k = i and k = j avoids a false intermediate town. The nested loops cost O(n³) per case, and the final flush releases the last block.

## Complexity

Reading and parsing take time linear in the input size and use one input buffer. Storing the distance table uses O(n²) space per case. The neighbour search takes O(n³) time per case and adds no other large structure. Writing pairs takes time linear in the pair count and uses one 256 KiB output buffer.

The total is O(t · n³) time and O(n² + input size) space. Enumerating every simple route between two towns would grow exponentially; one addition per town replaces that search.
