# BIT2 — Search Bit Sum (SPOJ)

<https://www.spoj.com/problems/BIT2/>

## Problem

Let F(K) be the total number of set bits in all integers from 1 to K. Given N, find a K with F(K) = N, or report that none exists.

Input starts with the test count T, followed by one target N per case. Output the found K as a decimal integer, or the exact line `Does Not Exist.`

| item | bound |
|---|---|
| target N | 1 to 1000000000000000 |
| test count T | 1 to 100000 |
| judge limit | 1223 ms, 1536 MB |

Sample input:

```
6
282657
377636
472615
567594
662573
1992279
```

Sample output:

```
38050
49299
Does Not Exist.
Does Not Exist.
82953
227394
```

## Idea

Build K one binary digit at a time, like dialing a combination lock from the leftmost wheel. Each wheel position either fits inside the remaining target or it does not.

F(K) is strictly increasing for K >= 1, so a target has at most one answer. Setting bit b adds a known block of set-bit counts, which can be computed from the higher bits already fixed. Each of the 51 bit positions costs constant work. A binary search per case would evaluate F more times and cost more per case. Takeaway: fix high bits first, and each bit decision is one cheap Sum test.

## Why It Works

1. F(K) = F(K - 1) + popcount(K), so F grows whenever K grows.
2. With lower bits still zero, the block from K + 1 to K + 2^b has a fixed high part.
3. Each number in that block contributes popcount(H) plus the set bits of its low part.
4. Summing the low parts gives b * 2^(b - 1) + 1, and the fixed part contributes 2^b * popcount(H).
5. Choosing the block when it fits keeps the built sum at or below N, so the final sum equals N exactly when a K exists.

| term | meaning |
|---|---|
| `targetSum` | the value N for the current case |
| `foundK` | binary digits fixed so far, as an integer |
| `builtSum` | F(foundK) for the digits fixed so far |
| `topBitCount` | number of set bits in the fixed high part |
| `stepSum` | set-bit total added by setting one more bit |

A script builds K for N = 4. At bit 1 the block from 1 to 2 adds 2, so K becomes 2 and the sum is 2. At bit 0 the block from 3 to 3 adds 2, so K becomes 3 and the sum is 4. This matches the sample logic and gives K = 3.

All products stay within 64 bits for bit indexes up to 50. The exact equality test at the end rejects targets that fall between two values of F.

## Code

**Input reader.** The whole stream is loaded and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const highestBitIndex = 50

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The constant `highestBitIndex` bounds the binary search range.
`nextInt` consumes one decimal target per case.
`appendOutput` groups many result lines into block writes.

**Bit construction.** Each bit decision adds one known block of set bits.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetSum = nextInt(inputData, scanPos)
  var foundK = 0'i64
  var builtSum = 0'i64
  var topBitCount = 0'i64
  for bitIndex in countdown(highestBitIndex, 0):
    var stepSum = (1'i64 shl bitIndex) * topBitCount + 1
    if bitIndex > 0:
      stepSum = stepSum + int64(bitIndex) * (1'i64 shl (bitIndex - 1))
    if builtSum + stepSum <= targetSum:
      builtSum = builtSum + stepSum
      foundK = foundK + (1'i64 shl bitIndex)
      topBitCount += 1
  if builtSum == targetSum:
    appendOutput($foundK)
  else:
    appendOutput("Does Not Exist.")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`countdown` visits high bits before low bits.
`stepSum` is the exact cost of setting the current bit.
The equality test rejects targets that F skips over.

## Complexity

Each case visits 51 bit positions and writes one line.

| phase | time | space |
|---|---|---|
| read all input | one pass over the stream | one input string |
| bit construction | 51 constant steps per case | three counters |
| output | block-buffered writes | one output string |

| measure | Big O |
|---|---|
| time | O(T * 51) |
| space | O(L) for input length L |

Binary search with a full F evaluation per probe would repeat the bit summation many times. Takeaway: one pass over the binary digits of K settles each case.
