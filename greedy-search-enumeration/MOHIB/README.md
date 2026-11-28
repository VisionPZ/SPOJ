# MOHIB — Mohib and series (SPOJ)

<https://www.spoj.com/problems/MOHIB/>

## Problem

A sequence of distinct positive integers has average A + 1. Appending x changes the average to A; report the largest value that sequence can contain.

The first line gives the test count T. Each following line gives x and A. Print one largest value per line.

| item | bound |
|---|---|
| test count T | at most 5000 |
| appended value x | 1 to 49999 |
| target average A | x + 1 to 50000 |
| judge limit | 100 ms, 1536 MB |

The gap A - x fixes the sequence length, so no search over lengths is needed.

Sample input:

```
1
1 2
```

Sample output:

```
3
```

## Idea

Treat the averages as group bills: knowing both totals reveals how many friends paid, like counting seats from two headcounts. Algebra fixes the length at A - x, then the smallest possible companions leave the largest remaining value.

The method is direct arithmetic per test case. It uses one subtraction, two products, and one division. Enumerating sequences would examine exponentially many distinct sets. Each test case costs constant time and needs no stored table.

## Why It Works

1. With k terms, the original sum equals k(A + 1).
2. After appending x, the sum equals (k + 1)A.
3. Equating the two sums gives k + x = A, hence k = A - x.
4. The other k - 1 distinct positive integers sum to at least 1 + 2 + ... + (k - 1).
5. Removing that minimum leaves the largest possible final term.

| term | meaning |
|---|---|
| `appendedValue` | the integer x added after the sequence |
| `targetAverage` | the average A after appending |
| `sequenceLength` | k = A - x terms before appending |
| `totalSum` | k(A + 1), the sum before appending |
| `smallestOthers` | (k - 1)k / 2, the minimum sum of companions |

The minimum companion sum is that of the k - 1 smallest positive integers.

A script-generated trace for three cases:

```
x=1 A=2  k=1 totalSum=3  smallestOthers=0 answer=3
x=2 A=4  k=2 totalSum=10 smallestOthers=1 answer=9
x=1 A=5  k=4 totalSum=24 smallestOthers=6 answer=18
```

The first trace row reproduces the sample answer 3.

## Code

**Input and scanning.** One read fills the buffer and the hand scanner extracts each pair.

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

The scanner skips separators and stops after each digit run.
The loop bound follows the first token.
Parsing costs one pass over the input text.

**Answer and output.** Each case applies the derived length and accumulates one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let appendedValue = nextInt(inputData, scanPos)
  let targetAverage = nextInt(inputData, scanPos)
  let sequenceLength = targetAverage - appendedValue
  let totalSum = int64(sequenceLength) * int64(targetAverage + 1)
  let smallestOthers = int64(sequenceLength - 1) * int64(sequenceLength) div 2
  appendOutput($(totalSum - smallestOthers))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Products use int64 because the largest sum reaches about 2.5 * 10^9.
`appendOutput` flushes by block, not per line.
One final write empties the remaining buffer.

## Complexity

Each test case performs a fixed number of arithmetic operations.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| arithmetic | constant work per case | no extra storage |
| output | one buffered append per case | block buffer |

The phases scale linearly with the number of test cases.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond input and output |

Searching all distinct sets would be exponential in the sequence length; this formula finishes each case in constant time.
