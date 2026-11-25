# TREENUM2 — The art of tree numbers (SPOJ)

<https://www.spoj.com/problems/TREENUM2/>

## Problem

A tree number is a sum of distinct powers of 3, so its ternary digits are only 0 or 1. The i-th tree number comes from reading the binary digits of i in base 3; report the sum from index L through index R modulo 2^32.

The first line gives the test count T. Each later line gives L and R. Print one sum per line.

| item | bound |
|---|---|
| test count T | 1 to 100000 |
| indices L and R | 1 to 10^18 |
| output modulus | 2^32 |
| judge limit | 1000 ms, 1536 MB |

Indices reach 10^18, so a per-index loop cannot work; the answer must come from about 60 bit positions.

Sample input:

```
5
1 3
3 3
4 5
6 7
2 5
```

Sample output:

```
8
4
19
25
26
```

## Idea

Read the i-th tree number as a binary pattern recast in base 3, like turning a row of light switches into place values. A prefix sum over indices 0 to n - 1 is built one set bit at a time; each set bit fixes one switch and leaves the lower switches free.

The algorithm is a bit-by-bit prefix DP and costs about 64 steps per prefix. Each step adds a block of numbers sharing a prefix, plus the sum of their free lower digits. A naïve loop would add up to 10^18 tree numbers per query.

Two prefix sums answer each query by subtraction, so each test case stays short.

## Why It Works

1. The binary digits of i become ternary digits, so bit j contributes 3^j when set.
2. For a set bit j of the prefix limit, numbers with lower bits free have a fixed higher part.
3. There are 2^j such numbers, and each carries the value `builtValue`.
4. Their free digits sum to 2^(j-1)(3^j - 1)/2, precomputed in `lowerContributions`.
5. Subtracting the prefix at L from the prefix at R + 1 leaves exactly indices L through R.

| term | meaning |
|---|---|
| `powersOfThree` | 3^j modulo 2^32 for each bit position |
| `lowerContributions` | sum of all free ternary digits below bit j |
| `prefixSum` | sum of tree numbers with index below a limit |
| `builtValue` | ternary value of the set bits processed so far |
| `rangeSum` | answer for one query, masked to 32 bits |

The lower-digit sum is the total of all subsets of the powers below bit j.

A script-generated trace on small prefixes:

```
prefixSum(1)=0
prefixSum(3)=4
prefixSum(4)=8
prefixSum(6)=27
F(1,3)=prefixSum(4)-prefixSum(1)=8
F(4,5)=prefixSum(6)-prefixSum(4)=19
```

The last row matches the third sample answer 19.

## Code

**Input and digit tables.** The reader loads all tokens, then two tables are prepared once.

```nim
const flushBlockBytes = 1 shl 17
const modulusMask = 4294967295'u64
const wideModulusMask = 8589934591'u64
const highestBit = 63

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

The wide mask keeps the division by 2 exact.
The scanner reads indices as large as 10^18.
Both tables have one entry per bit position.

```nim
var powersOfThree = newSeq[uint64](highestBit + 1)
var lowerContributions = newSeq[uint64](highestBit + 1)
var runningPower = 1'u64
var widePower = 1'u64
for bitIndex in 0 .. highestBit:
  powersOfThree[bitIndex] = runningPower
  if bitIndex > 0:
    let oddPart = ((widePower - 1'u64) and wideModulusMask) div 2'u64
    lowerContributions[bitIndex] = (oddPart * (1'u64 shl (bitIndex - 1))) and modulusMask
  runningPower = (runningPower * 3'u64) and modulusMask
  widePower = (widePower * 3'u64) and wideModulusMask
```

Bit zero contributes no lower digits.
The wide power holds 3^j modulo 2^33.
Both tables use uint64 to avoid signed overflow.

**Prefix and answer.** Each prefix walks the set bits of its limit from high to low.

```nim
proc prefixSum(limitValue: uint64): uint64 =
  var accumulated = 0'u64
  var builtValue = 0'u64
  for bitIndex in countdown(highestBit, 0):
    let bitSelector = 1'u64 shl bitIndex
    if (limitValue and bitSelector) != 0'u64:
      accumulated = (accumulated + builtValue * bitSelector + lowerContributions[bitIndex]) and modulusMask
      builtValue = (builtValue + powersOfThree[bitIndex]) and modulusMask
  return accumulated

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let leftBound = uint64(nextInt(inputData, scanPos))
  let rightBound = uint64(nextInt(inputData, scanPos))
  let beforeLeft = prefixSum(leftBound)
  let beforeRight = prefixSum(rightBound + 1'u64)
  let rangeSum = (beforeRight - beforeLeft) and modulusMask
  appendOutput($rangeSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The subtraction wraps modulo 2^32.
Two prefixes answer each query.
Output leaves through the shared block buffer.

## Complexity

The tables are built once, then each query uses two short prefix walks.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table build | 64 constant steps | two 64-entry tables |
| queries | two 64-step walks each | block buffer |

The table build is negligible beside the query loop.

| measure | Big O |
|---|---|
| time | O(T * 64) |
| space | O(64) beyond input and output |

Adding tree numbers one index at a time would take up to 10^18 steps per query; this method stays under a hundred.
