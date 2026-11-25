# ADACHES2 — Ada and Palaces (SPOJ)

<https://www.spoj.com/problems/ADACHES2/>

## Problem

Place N palaces on an N×N board so that no two attack each other, and count the placements modulo 1000000007. A palace attacks along rows, columns, and all eight neighbouring squares.

Input begins with T, the number of cases. Each following line holds one board size N, from 1 to 10000000.

Output holds one number per case: the count of valid placements modulo 1000000007.

| item | bound |
|---|---|
| test cases T | 1 to 100000 |
| board size N | 1 to 10000000 |
| modulus | 1000000007 |
| judge limit | 2000 ms, 1536 MB |

These bounds cover every value read by the program.

Sample input:

```
8
1
2
3
7
10
1000
10000
9999999
```

Eight board sizes appear in the sample.

Sample output:

```
1
0
0
646
479306
711794305
450342414
838796194
```

Each output line belongs to the matching input line.

## Idea

Treat a placement as a permutation, like assigning one seat per row and one seat per column. The tower rule forces distinct rows and columns; the king rule forbids neighbouring rows from using neighbouring columns.

The count of these permutations follows a four-term recurrence with coefficients that depend on N. The program scans N once, keeps the last four values, and stores each answer it passes. Preprocessing costs one step per board size up to the largest query. A brute-force search over placements would grow far faster than that.

Compute the sequence once in increasing order, then answer every case by indexing the stored values.

## Why It Works

1. A tower attacks the whole row and column, so each row and column holds one palace.
2. A placement therefore corresponds to a permutation of column indexes.
3. Kings add one restriction: rows i and i+1 cannot use columns j and j+1.
4. Counting permutations without those adjacencies gives the sequence 1, 0, 0, 2, 14, 90, 646.
5. That sequence satisfies `a(n) = (n+1)a(n-1) - (n-2)a(n-2) - (n-5)a(n-3) + (n-3)a(n-4)`.
6. The identity holds over integers, so reducing each step modulo the prime modulus preserves it.

| term | meaning |
|---|---|
| `answerBySize` | stored count for each board size |
| `requestedSizes` | board sizes from the input cases |
| `previousOne` | value of a(n-1) at the current step |
| `nextValue` | value computed for the current board size |

The four rolling variables replace a full table during the scan.

The generator checked the first values by enumerating every permutation. It also checked the recurrence against an inclusion-exclusion count.

For N = 5, using a(1)=1, a(2)=0, a(3)=0, and a(4)=2:

| quantity | value |
|---|---|
| (n+1)a(n-1) | 6 times 2 = 12 |
| -(n-2)a(n-2) | minus 3 times 0 = 0 |
| -(n-5)a(n-3) | minus 0 times 0 = 0 |
| +(n-3)a(n-4) | plus 2 times 1 = 2 |
| total | 12 + 0 + 0 + 2 = 14 |

The total matches the brute-force count for five palaces.

Every coefficient stays below 1e8, so a 64-bit product cannot overflow. Negative intermediate sums are corrected with one modulus addition.

## Code

**Input and scanning.** The reader stores each requested board size while tracking the largest one.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007

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

The hand scanner accepts spaces and line breaks without special cases.

All values are non-negative, so no minus branch is needed.

**Output helper.** Answers accumulate in one string and flush in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A flush happens only after 131072 bytes accumulate.

The driver adds one newline after every answer.

**Sequence scan.** Four rolling values generate every answer up to the largest query.

```nim
let testCount = nextInt(inputData, scanPos)
var requestedSizes = newSeq[int](testCount)
var largestSize = 0
for caseIndex in 0 .. testCount - 1:
  let boardSize = nextInt(inputData, scanPos)
  requestedSizes[caseIndex] = boardSize
  if boardSize > largestSize:
    largestSize = boardSize

var answerBySize = newSeq[int32](largestSize + 1)
if largestSize >= 1:
  answerBySize[1] = 1
if largestSize >= 4:
  answerBySize[4] = 2
  var previousOne: int64 = 2
  var previousTwo: int64 = 0
  var previousThree: int64 = 0
  var previousFour: int64 = 1
  for boardSize in 5 .. largestSize:
    var nextValue = int64(boardSize + 1) * previousOne - int64(boardSize - 2) * previousTwo - int64(boardSize - 5) * previousThree + int64(boardSize - 3) * previousFour
    nextValue = nextValue mod int64(answerModulus)
    if nextValue < 0:
      nextValue += int64(answerModulus)
    answerBySize[boardSize] = int32(nextValue)
    previousFour = previousThree
    previousThree = previousTwo
    previousTwo = previousOne
    previousOne = nextValue
```

The first four values seed the recurrence directly.

Each iteration stores a 32-bit residue and shifts the four rolling values.

64-bit arithmetic keeps the products and their sum exact.

**Case driver.** Every case prints its stored answer.

```nim
for caseIndex in 0 .. testCount - 1:
  appendOutput($answerBySize[requestedSizes[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Indexing makes each answer a single memory read.

The final flush writes the remaining buffered text.

## Complexity

Reading all cases first lets one scan serve the whole input.

| phase | time | space |
|---|---|---|
| input read | one pass over T sizes | array of T sizes |
| sequence scan | one step per size up to max N | array of max N residues |
| output | one write per answer | output buffer |

Every phase has a single dominant cost shown in the table.

| measure | Big O |
|---|---|
| time | O(T + max N) |
| space | O(T + max N) |

The largest observed size controls the scan length.

Enumerating every placement would take factorial time instead of one linear scan.

A single pass over the sequence serves all cases and keeps memory predictable.
