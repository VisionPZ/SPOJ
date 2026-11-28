# VECTAR6 — Number of Binary Trees (SPOJ)

<https://www.spoj.com/problems/VECTAR6/>

## Problem

Count binary trees of height N in which every left subtree is at least as tall as its right subtree. Height counts nodes on the longest root-to-leaf path, so a single node has height 1. Print the count modulo 1000000007.

The first line holds T test cases, then T lines each hold one height N. Heights range up to 10000000 and T up to 100000.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 100000 |
| height N | 1 to 10000000 |
| judge limit | 1500 ms, 1536 MB |

The combination of many queries and large heights requires constant-time answers.

Sample input:

```
2
1
2
```

Sample output:

```
1
2
```

## Idea

Each new height multiplies the previous count by one running total, like extending a chain where each link adds to a shared sum.

Let g(h) be the count for height h and P(h) be one plus the sum of g up to h. A tree of height h has a left subtree of height h minus one and any valid right subtree no taller than that. This gives g(h) equal to g(h minus one) times P(h minus one). We build g and P once up to the largest queried height, then answer every query with one table read. Enumerating trees per query would grow superexponentially. The table costs linear time overall.

## Why It Works

1. The empty subtree has height zero and exactly one shape.
2. A tree of height h has root, left height h minus one, and right height r with r at most h minus one.
3. Counting pairs of subtree heights gives g(h) equal to g(h minus one) times P(h minus one).
4. P(h) grows by g(h) each step, so both sequences follow a simple recurrence.
5. Taking the modulus after each multiplication preserves the final remainder.

The main terms:

| term | meaning |
|---|---|
| `treeCounts` | count g for each height, modulo the prime |
| `prefixTotal` | running value P(h), one plus cumulative counts |
| `heightQueries` | all requested heights |
| `maxHeight` | largest requested height |

The recurrence uses only these two sequences and no tree enumeration.

A worked trace from the oracle, showing exact values before the modulus:

```
height 1   g = 1        P = 2
height 2   g = 2        P = 4
height 3   g = 8        P = 12
height 4   g = 96       P = 108
height 5   g = 10368    P = 10476
height 6   g = 108615168    P = 108625644
height 7   g = 11798392572168192
```

Modulo 1000000007 the seventh count becomes 489579448. The sample answers 1 and 2 match the first two rows.

## Code

**Input and scanning.** All heights are read before the table is built.

```nim
const flushBlockBytes = 1 shl 17
const modValue = 1000000007

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

let caseCount = nextInt(inputData, scanPos)
var heightQueries = newSeq[int](caseCount)
var maxHeight = 0
for caseIndex in 0 .. caseCount - 1:
  heightQueries[caseIndex] = nextInt(inputData, scanPos)
  if heightQueries[caseIndex] > maxHeight:
    maxHeight = heightQueries[caseIndex]
```

The largest height sets the table size.
A single pass collects all queries in order.
No negative values appear in this problem.

**Precomputation.** Two recurrence sequences fill the table once.

```nim
var treeCounts = newSeq[int](maxHeight + 1)
if maxHeight >= 1:
  treeCounts[1] = 1
  var prefixTotal = 2
  for height in 2 .. maxHeight:
    treeCounts[height] =
      int(int64(treeCounts[height - 1]) * int64(prefixTotal) mod modValue)
    prefixTotal = (prefixTotal + treeCounts[height]) mod modValue
```

The prefix starts at P(1) equal to two.
The product uses int64 before the modulus.
Each height adds one multiplication and one addition.

**Output.** Buffered answers follow the original query order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  appendOutput($treeCounts[heightQueries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The flush threshold is 131072 bytes.
Queries keep their input order in the output.
The final flush emits the remaining lines.

## Complexity

One linear pass builds all answers, and every query is a constant-time lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over all heights | one input string and query array |
| precomputation | one step per height up to the maximum | one count per height |
| output | one write per block | block buffer |

The table is sized by the largest height, not by T.

The asymptotic bounds:

| measure | Big O |
|---|---|
| preprocessing | O(max N) |
| time per query | O(1) |
| space | O(max N) |

Counting trees directly per query would be exponential, while the shared recurrence makes even 100000 queries cheap.
