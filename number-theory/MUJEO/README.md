# MUJEO — Even Odd (SPOJ)

<https://www.spoj.com/problems/MUJEO/>

## Problem

Numbers sit in a row with even values on odd positions and odd values on even positions. Each value keeps its order inside its own parity. Report the sum of the values between two positions.

The input starts with the test count. Each test gives two positions. Print one sum per line.

| item | bound |
|---|---|
| tests T | 1 to 10 |
| positions a, b | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Huge positions rule out building the row.

Sample input:

```
2
1 4
1 1000000000
```

Sample output:

```
10
500000000500000000
```

## Idea

Treat the row as ordinary counting with a small swap at each position. Picture correcting a tally by adding one for odd labels and subtracting one for even labels. The ordinary sum up to n is n times n plus one, halved. Add the number of odd positions and subtract the number of even positions. A range sum is then one prefix minus another, with no row built at all.

## Why It Works

1. Position i normally holds i before the parity swap.
2. Odd positions gain one, and even positions lose one.
3. Up to n there are (n plus one) divided by two odd positions and n divided by two even positions.
4. Subtracting the prefix before a gives the sum over the requested range.

| term | meaning |
|---|---|
| `prefixTotal` | corrected ordinary sum from position one up to a bound |
| `pairCount` | complete odd-even pairs inside a bound |
| `rangeTotal` | sum over the two requested positions |

The two prefixes differ by exactly the requested range.

Script-generated trace for the first six positions:

```
position | value | corrected ordinary sum
1 | 2 | 2
2 | 1 | 3
3 | 4 | 7
4 | 3 | 10
5 | 6 | 16
6 | 5 | 21
```

The row from one to four sums to 10, matching the first sample.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

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

All numbers are parsed before any output is produced.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Prefix formula and output.** One closed form serves every bound.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc prefixTotal(limitIndex: int64): int64 =
  if limitIndex <= 0:
    return 0
  let pairCount = limitIndex div 2
  let pairTotal = 2 * pairCount * pairCount + pairCount
  if limitIndex mod 2 == 0:
    return pairTotal
  return pairTotal + limitIndex + 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var leftIndex = int64(nextInt(inputData, scanPos))
  var rightIndex = int64(nextInt(inputData, scanPos))
  if leftIndex > rightIndex:
    let swapValue = leftIndex
    leftIndex = rightIndex
    rightIndex = swapValue
  let rangeTotal = prefixTotal(rightIndex) - prefixTotal(leftIndex - 1)
  appendOutput($rangeTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Complete pairs contribute a quadratic term.
An odd upper bound contributes one extra value.
Each test costs two formula evaluations and one buffered line.

## Complexity

One formula answers each test without visiting any position.

| phase | time | space |
|---|---|---|
| input read | one pass over 2t positions | one input string |
| prefix formula | constant work per test | no table |
| output | one line per test | block buffer |

No array grows with the position bound.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(1) apart from input and output buffers |

Walking every position up to b would take O(b) per test and overflow the time limit.
