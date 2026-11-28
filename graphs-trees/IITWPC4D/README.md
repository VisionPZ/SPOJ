# IITWPC4D — Arrangement Validity (SPOJ)

<https://www.spoj.com/problems/IITWPC4D/>

## Problem

Given, for each position, how many taller people stand before it, decide whether one height arrangement is possible. If exactly one arrangement exists, print it; otherwise print -1.

Input begins with T. Each case gives n, then n counts A[i], where A[i] counts people before position i with greater height. Print "Test : k" on its own line, then either the n heights or -1.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| people n | 1 to 100000 |
| count A[i] | 0 to n |
| judge limit | 3000 ms, 1536 MB |

A valid count sequence always determines one permutation, so -1 means a count exceeds the number of earlier positions.

Sample input:

```
2
3
0 1 1
3
0 1 0
```

Sample output:

```
Test : 1
3 1 2
Test : 2
2 1 3
```

## Idea

Fill positions from right to left, like dealing cards from the bottom of a shuffled deck. At position i, choose the rank that leaves exactly A[i] taller ranks for the earlier positions.

The algorithm is inversion-sequence reconstruction with a Fenwick tree for k-th order statistics. Each position costs O(log n) tree steps. Scanning all permutations would cost n factorial work even for tiny inputs. The greedy right-to-left choice is forced, so a valid sequence has exactly one answer.

Order statistics turn a global uniqueness question into one rank lookup per position.

## Why It Works

1. Heights form a permutation of 1 through n, so each rank appears exactly once.
2. When position i is filled, ranks for positions 1 through i are still unused.
3. Exactly A[i] of those unused ranks must exceed the height at position i.
4. Therefore the height at i is the (i - A[i])-th smallest unused rank.
5. A count of i or more asks for a rank outside the available set, so the case is invalid.
6. The inversion sequence of a permutation is unique, so no other arrangement can match a valid sequence.

| term | meaning |
|---|---|
| `greaterCounts` | given inversion sequence A |
| `wantedRank` | i minus A[i], the rank to select |
| `fenwickTree` | Fenwick counts of unused ranks |
| `chosenHeight` | selected rank placed at position i |

The table names follow the loops in the code.

The worked trace uses A = 0 1 1 from the sample:

```
position 3: wantedRank = 3 - 1 = 2, select rank 2 -> height 2
position 2: wantedRank = 2 - 1 = 1, select rank 1 -> height 1
position 1: wantedRank = 1 - 0 = 1, select rank 1 -> height 3
arrangement: 3 1 2
```

The trace reproduces the first sample answer.

Invalid counts are detected before any rank is removed. The tree stays consistent until a bad count is found.

## Code

**Input and rank selection.** The reader loads all tokens, and the Fenwick tree supports k-th smallest queries.

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

proc selectRank(fenwickTree: seq[int], treeSize: int, wantedRank: int): int =
  var step = 1
  while step shl 1 <= treeSize:
    step = step shl 1
  var nodeIndex = 0
  var covered = 0
  while step > 0:
    let candidate = nodeIndex + step
    if candidate <= treeSize and covered + fenwickTree[candidate] < wantedRank:
      nodeIndex = candidate
      covered += fenwickTree[candidate]
    step = step div 2
  return nodeIndex + 1
```

Binary lifting descends from the highest power of two.
Each step skips a subtree that is too small.
The query cost is logarithmic in n.

**Right-to-left reconstruction.** Each case removes one rank per position and writes the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var greaterCounts = newSeq[int](personCount)
  for personIndex in 0 .. personCount - 1:
    greaterCounts[personIndex] = nextInt(inputData, scanPos)
  appendOutput("Test : " & $(caseIndex + 1))
  outputBuffer.add '\n'
  var fenwickTree = newSeq[int](personCount + 1)
  for rank in 1 .. personCount:
    fenwickTree[rank] += 1
    let parentRank = rank + (rank and -rank)
    if parentRank <= personCount:
      fenwickTree[parentRank] += fenwickTree[rank]
  var heights = newSeq[int](personCount)
  var arrangementValid = true
  var position = personCount
  while position >= 1 and arrangementValid:
    let wantedRank = position - greaterCounts[position - 1]
    if wantedRank < 1 or wantedRank > position:
      arrangementValid = false
    else:
      let chosenHeight = selectRank(fenwickTree, personCount, wantedRank)
      heights[position - 1] = chosenHeight
      var updateRank = chosenHeight
      while updateRank <= personCount:
        fenwickTree[updateRank] -= 1
        updateRank += updateRank and -updateRank
    position -= 1
  if not arrangementValid:
    appendOutput("-1")
  else:
    for personIndex in 0 .. personCount - 1:
      if personIndex > 0:
        appendOutput(" ")
      appendOutput($heights[personIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Tree initialization costs one linear pass.
Removing a rank keeps future selections correct.
Output is buffered and flushed once after the loop.

## Complexity

Each case builds a Fenwick tree and performs one selection and one removal per position.

| phase | time | space |
|---|---|---|
| input read | one pass over all counts | one input string |
| tree build | one pass over n ranks | n integer slots |
| reconstruction | n rank queries and removals | n integer slots |
| output | two buffered lines per case | block buffer |

Rank queries dominate, and each one climbs a tree of height log n.

| measure | Big O |
|---|---|
| time | O(n log n) per case |
| space | O(n) per case |

Testing all permutations would grow factorially, while rank selection settles each position in logarithmic time.
