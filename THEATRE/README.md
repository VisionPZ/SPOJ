# THEATRE — Movie Theatre Madness (SPOJ)
<https://www.spoj.com/problems/THEATRE/>

## Problem

Friends occupy one column from back to front. For each friend, find the closest taller friend in front, or use height 1 when nobody blocks the view. Report the product of those heights modulo 1000000007.

Input starts with one integer N. The next line holds N distinct heights, from the last row to the front row.

Output is one line with the product modulo 1000000007.

The input bounds are:

| item | bound |
|---|---|
| friends N | 2 to 100000 |
| each height | 1 to 1000000000 |
| heights | pairwise distinct |
| judge limit | 1000 ms, 1536 MB |

The heights in the input run from back to front, so a blocker sits at a larger index.

Sample input:

```
5
5 2 1 4 3
```

Sample output:

```
16
```

## Idea

Find each blocker by looking for the first taller person ahead, like picking the first suitable card from a stack of candidates.

The algorithm is a monotonic decreasing stack scanned from front to back. Each height is pushed once and popped once, so each item costs constant amortized work.

A forward scan per friend costs quadratic time. The stack keeps only heights that can still block someone behind them. One reverse pass replaces every forward scan.

## Why It Works

1. A blocker of height at index i sits at some index j greater than i with height greater than height i.
2. The nearest such index j is the answer for index i.
3. While scanning right to left, any stack entry shorter than the current height cannot block it or anything further back.
4. Popping those entries leaves the nearest taller height on top of the stack.
5. Multiplying all chosen heights with modular reduction gives the requested value.

The main terms are:

| term | meaning |
|---|---|
| `heights` | input heights ordered from back to front |
| `blockingStack` | positions of still relevant taller friends |
| `stackSize` | number of active positions in the stack |
| `blockerHeight` | height used as the factor for one friend |
| `productValue` | running product modulo 1000000007 |

A short script over the sample gives these factors:

| index | height | closest taller in front | factor |
|---|---|---|---|
| 0 | 5 | none | 1 |
| 1 | 2 | 4 at index 3 | 4 |
| 2 | 1 | 4 at index 3 | 4 |
| 3 | 4 | none | 1 |
| 4 | 3 | none | 1 |

The five factors multiply to 16, which matches the sample output.
The multiplication uses int64 so the product before reduction stays within range.

## Code

**Input and scanning.** The hand reader loads the count and every height.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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

The scanner skips spaces and line breaks.
It builds each value one digit at a time.
The constant holds the required modulus.

**Stack sweep.** Each position pops shorter candidates before taking its factor.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let heightCount = nextInt(inputData, scanPos)
var heights = newSeq[int](heightCount)
for heightIndex in 0 .. heightCount - 1:
  heights[heightIndex] = nextInt(inputData, scanPos)

var blockingStack = newSeq[int](heightCount)
var stackSize = 0
var productValue: int64 = 1
var currentPosition = heightCount - 1
while currentPosition >= 0:
  let currentHeight = heights[currentPosition]
  while stackSize > 0 and heights[blockingStack[stackSize - 1]] <= currentHeight:
    stackSize -= 1
  var blockerHeight = 1
  if stackSize > 0:
    blockerHeight = heights[blockingStack[stackSize - 1]]
  productValue = (productValue * int64(blockerHeight)) mod int64(modulusValue)
  blockingStack[stackSize] = currentPosition
  stackSize += 1
  currentPosition -= 1
```

The stack holds positions in decreasing height order.
A missing blocker contributes the factor 1.
The product is reduced after every multiplication.

**Final write.** The single answer is flushed once.

```nim
appendOutput($productValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The answer is written as one decimal string.
The buffer is flushed at the end.
No per-line writes appear in the program.

## Complexity

The scan visits each height a constant number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over N heights | one input string |
| stack sweep | one push and one pop per height | array of N positions |
| output | one line | block buffer |

The sweep dominates both time and space.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

A forward scan from every seat would cost O(N^2) time.
The decreasing stack keeps one reverse pass enough, and that ends the work.
