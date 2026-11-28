# CANTON — Count on Cantor (SPOJ)

<https://www.spoj.com/problems/CANTON/>

## Problem

Each case gives a position in Cantor's diagonal listing of positive fractions. Print the fraction at that position in the exact line form shown below.

Input: one integer `t`, then `t` lines each holding one position. Output: one line per case with `TERM`, the position, `IS`, and the fraction.

| Item | Bound |
|---|---|
| Test cases `t` | at most 20 |
| Position | 1 to 10^7 |
| Diagonals needed | 4472 |
| Judge limits | 5 s, 1536 MB |

The position bound fixes the search range, and the small case count keeps output short.

The sample input:

```
3
3
14
7
```

Three positions follow the case count.

The sample output:

```
TERM 3 IS 2/1
TERM 14 IS 2/4
TERM 7 IS 1/4
```

Each line repeats its position and names the matching fraction.

## Idea

Picture the fractions as cards in diagonal rows on a table. Row k holds k cards, so you count whole rows until the running total passes your position, then read the card at the leftover slot.

The program runs a binary search over the triangular row totals in `diagonalForTerm`, then applies a parity rule to orient the row. Each case costs about 13 comparisons, since the largest position needs only 4472 rows.

Walking rows from the start costs up to 4472 additions per case. Building the whole listing up to 10^7 terms costs millions of steps.

A short search plus one parity test replaces that long walk for every case.

## Why It Works

Four facts prove the rule.

1. Row k holds exactly k fractions, so the total through row k is k times (k + 1) divided by 2.
2. The answer row is the first row whose total reaches the position, so that row is unique.
3. Even rows run numerators upward; odd rows run numerators downward.
4. The leftover slot fixes both numbers once the row direction is known.

The formulas below use names from the program:

| Term | Meaning |
|---|---|
| `diagonalIndex` | the row that contains the wanted position |
| `previousTerms` | fractions in all rows before `diagonalIndex` |
| `positionInDiagonal` | zero-based slot inside that row |
| `1 + positionInDiagonal` | numerator when `diagonalIndex` is even |
| `diagonalIndex - positionInDiagonal` | denominator when `diagonalIndex` is even |

The parity branch swaps those last two expressions on odd rows. The search finds the row, and the branch turns one slot into two numbers.

Here is the traced path for position 14 from the generator:

```
position: 14
row 1 total 1
row 2 total 3
row 3 total 6
row 4 total 10
row 5 total 15
first total at least 14: row 5
previousTerms: 10
positionInDiagonal: 14 - 10 - 1 = 3
row 5 is odd, so numerator = 5 - 3 = 2 and denominator = 1 + 3 = 4
TERM 14 IS 2/4
```

The trace ends at the second line of the sample output.

## Code

**Constants.** The scanner base, the flush threshold, and the search ceiling.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const searchUpperBound = 10000
```

`firstDigitValue` converts a digit byte into its value. `flushBlockBytes` caps memory at 256 KiB. The ceiling 10000 exceeds the 4472 rows the spec needs.

**Token scan.** One digit pass over the shared input buffer.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`pos` is a var parameter, so the cursor survives between calls. The first loop skips newlines and blank lines. The second loop costs one step per digit and builds no token object.

**Row search.** Binary search for the first row whose total reaches the position.

```nim
proc diagonalForTerm(termIndex: int): int =
  var low = 1
  var high = searchUpperBound
  while low < high:
    let middle = (low + high) div 2
    if (middle * (middle + 1)) div 2 >= termIndex:
      high = middle
    else:
      low = middle + 1
  return low
```

The bound is `searchUpperBound`, well past the 4472 rows the spec needs. The comparison counts fractions through `middle` with a triangular number. One case costs at most 14 iterations.

**Driver.** Read once, answer every case, and flush in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let termIndex = nextInt(inputData, scanPos)
  let diagonalIndex = diagonalForTerm(termIndex)
  let previousTerms = ((diagonalIndex - 1) * diagonalIndex) div 2
  let positionInDiagonal = termIndex - previousTerms - 1
  var numerator = 0
  var denominator = 0
  if diagonalIndex mod 2 == 0:
    numerator = 1 + positionInDiagonal
    denominator = diagonalIndex - positionInDiagonal
  else:
    numerator = diagonalIndex - positionInDiagonal
    denominator = 1 + positionInDiagonal
  outputBuffer.add "TERM "
  outputBuffer.add $termIndex
  outputBuffer.add " IS "
  outputBuffer.add $numerator
  outputBuffer.add "/"
  outputBuffer.add $denominator
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs `caseCount` times, and the input caps that count at 20. `positionInDiagonal` is zero-based, which explains the extra subtraction. The final write covers the tail after the last block flush.

## Complexity

Costs split into three phases.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| Row search | at most 14 comparisons per case | three integers |
| Output | one write per 256 KiB block | block buffer |

The search dominates the arithmetic, while the output buffer stays small.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(t log M), with M the largest position |
| Space | O(input bytes plus block size) |

Walking rows from the start costs O(sqrt M) per case, and building the full listing costs O(M) time and space. The binary search keeps both costs far below those bounds.
