# ORDSUM23 — Sums of 2 and 3 (SPOJ)

<https://www.spoj.com/problems/ORDSUM23/>

## Problem

Write a number N as an ordered sum whose terms are each 2 or 3. Report the number of such sums modulo 1000000007. Order matters, so 2 + 3 and 3 + 2 are different sums.

The input starts with the test count T, followed by T lines each holding one N. Print one count per line in input order.

| item | bound |
|---|---|
| tests T | at most 100000 |
| target N | 1 to 1000000 |
| judge limit | 2000 ms, 1536 MB |

Both counts stay inside these bounds.

Sample input:

```
3
2
3
8
```

Sample output:

```
1
1
4
```

The four sums of 8 are 2+2+2+2, 2+3+3, 3+2+3 and 3+3+2.

## Idea

The last term is either a domino of length 2 or a triomino of length 3, like finishing a tiled row with one of two tile sizes. Removing that last term leaves a smaller ordered sum, so each count is the sum of two earlier counts. Fill one table up to the largest target in a single pass. Each query then costs one lookup instead of an exponential fresh enumeration.

## Why It Works

1. Every nonempty ordered sum ends with the term 2 or the term 3.
2. Deleting a final 2 leaves an ordered sum of N - 2.
3. Deleting a final 3 leaves an ordered sum of N - 3.
4. Thus ways[N] equals ways[N - 2] plus ways[N - 3].
5. The empty sum gives ways[0] = 1, and ways[1] = 0, ways[2] = 1.

| term | meaning |
|---|---|
| `targets` | requested numbers from the input |
| `maxTarget` | largest requested number |
| `ways` | precomputed count for each number |
| `answerModulus` | modulus applied after each addition |

This trace shows the table values used by the sample.

| number | count |
|---|---|
| 0 | 1 |
| 1 | 0 |
| 2 | 1 |
| 3 | 1 |
| 4 | 1 |
| 5 | 2 |
| 6 | 2 |
| 7 | 3 |
| 8 | 4 |

The final row matches the four sums listed in the problem.

## Code

**Input and scanner.** The tests are read first so the table has the right size.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand reader ignores whitespace between numbers.
The largest target sets the table length.
Output uses a single shared buffer.

**Padovan table and lookups.** Each new count needs two earlier values.

```nim
let testCount = nextInt(inputData, scanPos)
var targets = newSeq[int](testCount)
var maxTarget = 0
for testIndex in 0 .. testCount - 1:
  targets[testIndex] = nextInt(inputData, scanPos)
  if targets[testIndex] > maxTarget:
    maxTarget = targets[testIndex]

var ways = newSeq[int64](maxTarget + 1)
ways[0] = 1
if maxTarget >= 2:
  ways[2] = 1
for targetValue in 3 .. maxTarget:
  ways[targetValue] = (ways[targetValue - 2] + ways[targetValue - 3]) mod int64(answerModulus)

for testIndex in 0 .. testCount - 1:
  appendOutput($ways[targets[testIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The recurrence runs once up to the largest target.
Each answer is a direct table read.
The modulus is applied at every step.

## Complexity

The table is built once and shared by all tests.

| phase | time | space |
|---|---|---|
| input read | one pass over T numbers | one input string |
| table build | one step per target value | array of counts |
| output | one line per test | block buffer |

The largest bound on N is one million.

| measure | Big O |
|---|---|
| time | O(maxN + T) |
| space | O(maxN) |

Recursive enumeration without a table repeats subproblems and grows exponentially.
The single forward pass answers all hundred thousand queries at constant cost each.
