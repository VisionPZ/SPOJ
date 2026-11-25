# ROADNET — Road net (SPOJ)

<https://www.spoj.com/problems/ROADNET/>

## Problem

A table gives shortest distances between every pair of towns. Two towns are neighbors when no third town lies on a shortest route between them; list all such pairs.

Input: `t` cases separated by blank lines. Each starts with `n`, followed by `n` rows of `n` distances. Output: all neighbouring pairs, one per line, with the smaller town first. Consecutive cases get a blank line between them.

The bounds from the statement:

| Item | Bound |
|---|---|
| Towns `n` | 1 ≤ n ≤ 200 |
| Distances | non-negative integers ≤ 200 |
| Pair order | increasing inside a pair, sorted across pairs |
| Judge limit | 5000 ms, 1536 MB |

The table already holds shortest distances, so the road graph never needs rebuilding.

The sample input and output:

```
1
3
0 1 2
1 0 3
2 3 0
```

```
1 2
1 3
```

## Idea

Use the distance table as the map: a town sits between two others when the direct distance equals the sum through it. Think of checking whether a stop lies on the way, not merely near the route.

The program reads the matrix, then tests every pair against every third town. If `dist[i][k] + dist[k][j] == dist[i][j]` for some `k`, town `k` lies on a shortest route, so the pair is not neighbouring. Otherwise the pair prints.

The triple loop costs O(n³), about 8 × 10^6 integer operations at `n = 200`. Enumerating every shortest path would blow up far more quickly.

The triangle equality in the table decides each pair without rebuilding any roads.

## Why It Works

Four facts carry the test.

1. The statement guarantees that equality `dist[A][B] = dist[A][C] + dist[C][B]` means `C` lies on a shortest A-to-B route.
2. A neighbouring pair has no such town, so scanning all `k` settles the question.
3. The loops use `i < j`, which prints each pair once and keeps the numbers increasing. Row-major order makes the output sorted.
4. Cases after the first get one leading blank line, matching the required separator byte for byte.

The values the program uses:

| Term | Meaning |
|---|---|
| `distances` | flat `n × n` matrix of shortest distances |
| `directDistance` | the candidate distance from town `i` to town `j` |
| `hasIntermediate` | true when some town lies on a shortest route |
| `appendPair` | writes one sorted neighbour pair |

The equality test is the whole decision rule.

A script-traced example with the sample matrix:

```
       1   2   3
  1    0   1   2
  2    1   0   3
  3    2   3   0

pair (1,2): k=3 -> 2 + 3 = 5 != 1  -> neighbour
pair (1,3): k=2 -> 1 + 3 = 4 != 2  -> neighbour
pair (2,3): k=1 -> 1 + 2 = 3 == 3  -> town 1 is on the route -> skip

output: 1 2
        1 3
```

## Code

**Setup and scanner.** The input is read once into one buffer.

```nim
{.push checks: off.}

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

`nextInt` walks the buffer by index and skips blank lines between cases. The matrix is stored flat, so row `i` starts at `i * nodeCount`.

**Output helpers.** A flush helper, a text helper, and a pair writer share one buffer.

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

`appendPair` writes the two town numbers and a newline. Each helper flushes at 256 KiB, keeping writes rare.

**Case loop.** Each pair tests every third town, then prints if none qualifies.

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

The matrix read costs O(n²). The `k` loop skips the two endpoints and breaks on the first witness. A blank line precedes every case except the first. The final flush covers the tail.

## Complexity

Each case reads a matrix, then runs three nested loops.

| Phase | Time | Space |
|---|---|---|
| Input read | O(n²) matrix entries | input bytes + O(n²) |
| Pair tests | O(n³) triple loop | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n³), n ≤ 200 | O(n²) |

At 200 towns the triple loop runs about eight million times.

| Measure | Big O |
|---|---|
| Time | O(n³) per case |
| Space | O(n²) for the distance matrix |

Reconstructing all shortest paths would cost much more than this direct equality test.

Listing every shortest path to decide adjacency can grow exponentially. The triangle equality answers each pair with one short loop.
