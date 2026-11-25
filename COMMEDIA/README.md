# COMMEDIA — Commedia dell Arte (SPOJ)

<https://www.spoj.com/problems/COMMEDIA/>

## Problem

A cube of M by M by M slots holds numbered tiles with one slot empty. Decide whether sliding tiles into the empty slot can restore the original ordering.

Input: one integer for the puzzle count, then one side length M and M cubed tile values per puzzle. Zero marks the empty slot.

Output: `Puzzle can be solved.` or `Puzzle is unsolvable.` on its own line for each puzzle.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Puzzles per file | not fixed |
| Cube side M | 1 to 100 |
| Slots per puzzle | up to 1000000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

A naive search of arrangements is impossible, so the answer comes from a parity invariant.

The sample input and output:

```
2
2
1 2 3 4
5 7 6 0
2
2 1 3 5
4 6 0 7
```

```
Puzzle is unsolvable.
Puzzle can be solved.
```

## Idea

Treat the empty slot as the largest tile, like swapping a blank card into a sorted deck. Every slide then swaps two entries, which flips the permutation (ordering) parity.

The program counts inversions (out-of-order pairs) with a Fenwick tree (an array that sums prefixes fast). It adds the parity of the empty slot's coordinate sum and compares with the solved arrangement.

Counting inversions costs O(N log N) for N slots. Pairwise comparison would cost O(N²) and fail on the largest cube.

One parity sum decides every puzzle.

## Why It Works

Each slide changes two things at once.

1. The empty slot swaps with one tile, which flips the permutation parity.
2. The same slide changes exactly one coordinate by one, which flips the coordinate-sum parity.
3. Their sum therefore stays unchanged by every legal move.
4. In the solved arrangement the permutation is the identity and the empty slot sits at `(M-1, M-1, M-1)`.

The test and the index layout are as follows:

| Term | Meaning |
| --- | --- |
| inversion parity | parity of out-of-order tile pairs |
| `blankCoordinateParity` | parity of the empty slot's coordinate sum |
| `solvedCoordinateParity` | `3 × (M - 1)` reduced modulo 2 |
| linear index | `x + M × y + M² × z` |
| test | `inversion parity + blank parity ≡ solved parity (mod 2)` |

The linear index is read with one division and two remainders.

A script checks the two sample puzzles:

| Puzzle | Tiles with blank as largest | Inversions | Blank parity | Solved parity | Result |
| --- | --- | --- | --- | --- | --- |
| 1 | `1 2 3 4 5 7 6 8` | 1 | 1 | 1 | unsolvable |
| 2 | `2 1 3 5 4 6 8 7` | 3 | 0 | 1 | solvable |

Puzzle 1 gives `1 + 1 = 0 (mod 2)` against 1. Puzzle 2 gives `3 + 0 = 1 (mod 2)` against 1.

## Code

**Constants and scanner.** All tile numbers are non-negative, so the scanner needs no sign branch.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const solvableMessage = "Puzzle can be solved."
const unsolvableMessage = "Puzzle is unsolvable."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The read loop keeps the whole stream in one string. Parsing one number visits each digit once. The two messages are constants, so no line is built per puzzle.

**Fenwick tree.** Adding a value and summing a prefix both walk a short chain of indexes.

```nim
var fenwickTree: seq[int]

proc addValue(j: int, delta: int) =
  var k = j
  while k < fenwickTree.len:
    fenwickTree[k] += delta
    k += k and -k

proc prefixSum(j: int): int =
  var total = 0
  var k = j
  while k > 0:
    total += fenwickTree[k]
    k -= k and -k
  return total
```

`addValue` climbs by the lowest set bit of the index. `prefixSum` descends by the same bit. Each call costs O(log N).

**Parity pass.** The blank becomes the largest value and lands last in the solved order.

```nim
proc permutationParity(slotCount: int, blankValue: int, k: var int): int =
  fenwickTree = newSeq[int](slotCount + 1)
  var parity = 0
  for j in 0..<slotCount:
    let tileValue = nextInt(inputData, i)
    if tileValue == 0:
      k = j
    let sequenceValue = if tileValue == 0: blankValue else: tileValue
    parity = (parity + (j - prefixSum(sequenceValue))) and 1
    addValue(sequenceValue, 1)
  return parity
```

At slot j, the count of earlier larger values is `j - prefixSum(value)`. Only parity matters, so the tree stores counts and the accumulator keeps one bit. The empty marker uses the largest value.

**Driver.** The program converts the empty index to coordinates and applies the test.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let sideLength = nextInt(inputData, i)
  let slotCount = sideLength * sideLength * sideLength
  var k = 0
  let parity = permutationParity(slotCount, slotCount, k)
  let coordinateX = k mod sideLength
  let coordinateY = (k div sideLength) mod sideLength
  let coordinateZ = k div (sideLength * sideLength)
  let blankCoordinateParity = (coordinateX + coordinateY + coordinateZ) and 1
  let solvedCoordinateParity = (3 * (sideLength - 1)) and 1
  if ((parity + blankCoordinateParity) and 1) == solvedCoordinateParity:
    appendOutput(solvableMessage)
  else:
    appendOutput(unsolvableMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The tree is rebuilt per puzzle because the slot count can change. The three coordinates come from one division and two remainders. Output is written in blocks, not one call per puzzle.

## Complexity

Inversion counting dominates each puzzle, and the coordinate test costs constant work.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Fenwick build | O(N) per puzzle | O(N) |
| Inversion count | O(N log N) per puzzle | O(N) |
| Parity test | O(1) per puzzle | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per puzzle | O(N log N) | O(N) |

At the largest cube, N reaches one million slots.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(N log N) per puzzle |
| Space | O(N) per puzzle |

Counting inversions by pairwise comparison would cost O(N²) and fail at that size.
