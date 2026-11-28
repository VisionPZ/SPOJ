# RETRO — Retrovirus (SPOJ)

<https://www.spoj.com/problems/RETRO/>

## Problem

Two RNA strands share a length. A query asks how many positions match between one segment of the first strand and one segment of the second strand. Answer every query in input order.

The input gives `strandLength`, two strings of that length, then `queryCount`, then one triple per query. Each triple holds `X`, `Y`, and `L`: compare `L` characters starting at position `X` in the first strand with `L` characters starting at position `Y` in the second strand. Positions start at one. Print one match count per line.

| item | bound |
|---|---|
| `strandLength` | 1 to 1000 |
| `queryCount` | 1 to 1000000 |
| query region | fits inside both strands |
| judge limit | 500 ms, 1536 MB |

The query count drives the design, since each answer must be produced in constant time.

Sample input:

```
7
AUGCAAG
GGAUGCG
2
1 3 4
6 1 2
```

Sample output:

```
4
1
```

## Idea

Counting a segment repeats work across queries, like recounting the same shelf for every visitor. Build a suffix-match table once: each cell stores matches from its two positions to the ends. A query subtracts the score after its segment from the score at its start. Direct counting costs O(L) per query, while the subtraction costs O(1). Precomputation costs O(N²) once, which pays off for a million queries.

## Why It Works

1. A cell of `similarityTable` counts matches of the two suffixes beginning at those positions.
2. A matching pair contributes one at the current cell and nothing more; a mismatch contributes zero.
3. The suffix score at `(i, j)` equals the current match bit plus the suffix score at `(i + 1, j + 1)`.
4. Matches inside a segment equal the full suffix score minus the suffix score beyond the segment.
5. Both endpoints use zero-based offsets, so `firstStart` is `X - 1` and `secondStart` is `Y - 1`.

| term | meaning |
|---|---|
| `similarityTable` | suffix match counts for every pair of positions |
| `rowWidth` | stride of one row, `strandLength + 1` |
| `fullScore` | suffix score at the segment start |
| `tailScore` | suffix score beyond the segment |
| `matchValue` | one for equal nucleotides, zero otherwise |

A worked trace from the sample follows.

```
first strand   A U G C A A G
second strand  G G A U G C G
query          1 3 4
firstStart     0
secondStart    2
fullScore      similarityTable[0][2] = 4
tailScore      similarityTable[4][6] = 0
answer         4 - 0 = 4
```

The same table gives query two as `similarityTable[5][0] - similarityTable[7][2] = 1 - 0 = 1`.

## Code

**Input and hand scanner.** The reader loads stdin once and parses integers without allocations per token.

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
```

Both strings stay inside `inputData` as byte ranges.
`nextInt` skips newlines between the header and queries.
No per-token strings are created.

**Buffered output.** One buffer collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each answer is appended as text.
A write happens only after the buffer reaches `flushBlockBytes`.
The last flush runs after the query loop.

**Strand offsets and suffix table.** The table is filled from the end backwards.

```nim
let strandLength = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1
let firstStrandStart = scanPos
scanPos += strandLength + 1
let secondStrandStart = scanPos
scanPos += strandLength + 1
let queryCount = nextInt(inputData, scanPos)

let rowWidth = strandLength + 1
var similarityTable = newSeq[int](rowWidth * rowWidth)
var firstIndex = strandLength - 1
while firstIndex >= 0:
  var secondIndex = strandLength - 1
  while secondIndex >= 0:
    var matchValue = 0
    if inputData[firstStrandStart + firstIndex] == inputData[secondStrandStart + secondIndex]:
      matchValue = 1
    similarityTable[firstIndex * rowWidth + secondIndex] =
      matchValue + similarityTable[(firstIndex + 1) * rowWidth + secondIndex + 1]
    secondIndex -= 1
  firstIndex -= 1
```

The last row and column stay zero by allocation.
`matchValue` holds the bit for the current pair.
The table costs one square array of integers.

**Query answers.** Each query reads three integers and writes one difference.

```nim
for queryIndex in 0 .. queryCount - 1:
  let firstStart = nextInt(inputData, scanPos) - 1
  let secondStart = nextInt(inputData, scanPos) - 1
  let regionLength = nextInt(inputData, scanPos)
  let fullScore = similarityTable[firstStart * rowWidth + secondStart]
  let tailScore = similarityTable[(firstStart + regionLength) * rowWidth + secondStart + regionLength]
  appendOutput($(fullScore - tailScore))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`regionLength` advances both positions past the segment.
Two table reads and one subtraction answer each query.
The final flush writes the buffered answers.

## Complexity

Precomputation runs once; queries run a million times.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| suffix table | one step per position pair | square integer array |
| queries | two reads per query | block buffer |
| output | one write per block | block buffer |

| measure | Big O |
|---|---|
| time | O(N² + Q) |
| space | O(N²) |

Scanning `L` characters per query costs O(Q·N), while the suffix table answers each query in O(1). The table costs square space, yet N never exceeds 1000.
