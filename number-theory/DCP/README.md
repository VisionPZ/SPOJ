# DCP — Fun With Fibonacci (SPOJ)

<https://www.spoj.com/problems/DCP/>

## Problem

Fibonacci numbers start with F(1) = 0 and F(2) = 1. For each range of indexes, count how many Fibonacci numbers in that range are odd and how many are even.

The first line gives the test count `T`. Each next line gives two indexes `N` and `M`. When `N` exceeds `M`, swap them. The range includes both ends. Print Case x: with x starting at 1, then the odd count and the even count on their own lines.

| item | bound |
|---|---|
| test count `T` | 1 to 50 |
| index `N` | 1 to 1000000000000000000 |
| index `M` | 1 to 1000000000000000000 |
| judge limit | 1000 ms, 1536 MB |

The index range is huge, so no test builds the Fibonacci values themselves.

Sample input:

```
2
2 6
1 5
```

Sample output:

```
Case 1:
Odd = 4
Even = 1
Case 2:
Odd = 3
Even = 2
```

The second case covers F(1) through F(5): 0, 1, 1, 2, 3.

## Idea

A traffic light repeats red, green, green; Fibonacci parity repeats even, odd, odd. The algorithm counts one residue class of indexes inside the range. Each test costs constant time. Generating Fibonacci numbers up to an index near one quintillion is impossible. Use the repeating parity pattern and arithmetic instead.

## Why It Works

1. F(1) is even and F(2) and F(3) are odd.
2. Adding an odd and an even number gives an odd number.
3. The parities therefore repeat every three indexes as even, odd, odd.
4. Even Fibonacci numbers have indexes 1, 4, 7, and so on.
5. Counting those indexes in the range gives the even count, and the rest are odd.

| term | meaning |
|---|---|
| `lowerIndex` | smaller end of the range |
| `upperIndex` | larger end of the range |
| `firstEvenIndex` | first index in the range with an even value |
| `evenCount` | number of even Fibonacci values in the range |

For the range 2 to 6, the first even index is 4. Indexes 4, 7, 10 are spaced by three, so only index 4 lies in the range. The even count is 1. The range holds five values, so the odd count is 4.

All counts fit in `int64`, since the largest range length is one quintillion.

## Code

**Input and scanning.** Each case reads a pair of indexes and orders them.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseTotal:
  var lowerIndex = nextInt(inputData, scanPos)
  var upperIndex = nextInt(inputData, scanPos)
  if lowerIndex > upperIndex:
    let swapValue = lowerIndex
    lowerIndex = upperIndex
    upperIndex = swapValue
```

A reversed pair is swapped before counting.
The case number follows the input order.
No Fibonacci value is stored.

**Counting and output.** The first even index fixes an arithmetic progression.

```nim
  var firstEvenIndex = lowerIndex
  while firstEvenIndex mod 3 != 1:
    firstEvenIndex += 1
  var evenCount: int64 = 0
  if firstEvenIndex <= upperIndex:
    evenCount = int64((upperIndex - firstEvenIndex) div 3 + 1)
  let spanLength = upperIndex - lowerIndex + 1
  let oddCount = int64(spanLength) - evenCount
  appendOutput("Case " & $caseIndex & ":\n")
  appendOutput("Odd = " & $oddCount & "\n")
  appendOutput("Even = " & $evenCount & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop advances at most twice to reach residue one.
Every third index after that is also even.
Odd count is the range length minus the even count.

## Complexity

Each test uses a few integer operations and writes three lines.

| phase | time | space |
|---|---|---|
| input read | one pass over the test list | one input string |
| counting | constant work per test | a few integers |
| output | three lines per test | block output buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond input and output buffers |

Generating Fibonacci values for each range grows with the index and cannot finish for large tests.

Counting the residue class gives the answer for any index with a short calculation.
