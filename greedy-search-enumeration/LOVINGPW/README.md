# LOVINGPW — Loving Power (SPOJ)

<https://www.spoj.com/problems/LOVINGPW/>

## Problem

Count pairs of numbers between zero and N whose bitwise XOR is a power of two. The answer is reported modulo 1000000007. A power of two is written 2^z, with z at least zero.

Input starts with the test count, followed by one bound N per line. Output one count per line, in order. Only pairs with the smaller value first are counted.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 100 |
| bound N | 0 to 1,000,000,000,000,000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The large bound rules out enumerating pairs.

Sample input:

```
3
1
2
3
```

Sample output:

```
1
2
4
```

## Idea

Split the number range at its highest power of two, like cutting a rope into a known long piece and a short remainder.

A pair inside a complete half contributes a fixed count. A pair across the cut must use equal lower values. Pairs inside the upper half repeat the same problem on a smaller bound. The algorithm is a bitwise recurrence. Each bit level costs constant time. Enumerating every pair would cost O(N^2) time.

A few bit levels replace a huge pair scan.

## Why It Works

1. Let p be the highest power of two not above N, and let k be its bit index.
2. Pairs inside the lower half of size p contribute k times 2^(k-1).
3. A cross pair works only when its two entries differ in bit k alone.
4. The cross count is N minus p, plus one.
5. Pairs inside the upper half are the same problem on N minus p.
6. The loop repeats the split until the bound reaches zero.

The code uses these names:

| term | meaning |
|---|---|
| `powerOfTwo` | powers of two taken modulo the modulus |
| `upperBound` | bound left in the current split |
| `highestBit` | bit index of the highest power of two |
| `pairCount` | accumulated answer modulo the modulus |
| `modulusValue` | the given modulus |

Each term maps to one part of the split.

The bound five traces as follows:

```
N=5: highest bit 2, add 2 * 2^1 = 4, remainder 1, add 2 -> 6
N=1: highest bit 0, add 0, remainder 0, add 1 -> 7
answer 7
```

The two splits give the same count as direct checking.

The highest bit stays below 50, so the power table holds 61 entries.

## Code

**Input and scanning.** The reader loads all tokens and builds the power table.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips separators before each number.
`powerOfTwo` holds values modulo `modulusValue`.
Integer parsing uses no sign in this problem.

**Output buffer.** Results are held until a large block is ready.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var powerOfTwo = newSeq[int64](61)
powerOfTwo[0] = 1
for bitIndex in 1 .. 60:
  powerOfTwo[bitIndex] = (powerOfTwo[bitIndex - 1] * 2) mod modulusValue
```

`appendOutput` flushes once the buffer reaches the block size.
A final write emits any remaining bytes.
No number triggers a write on its own.

**Bit recurrence.** Each split removes one highest power of two.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  var upperBound = nextInt(inputData, scanPos)
  var pairCount: int64 = 0
  while upperBound > 0:
    var highestBit = 0
    var highestPower = 1
    while highestPower * 2 <= upperBound:
      highestPower = highestPower * 2
      highestBit = highestBit + 1
    if highestBit >= 1:
      pairCount = (pairCount + int64(highestBit) * powerOfTwo[highestBit - 1]) mod modulusValue
    upperBound = upperBound - highestPower
    pairCount = (pairCount + int64(upperBound) + 1) mod modulusValue
  appendOutput($pairCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`highestPower` and `highestBit` locate the current cut.
Both added terms use the modulus before any growth.
Large bounds take fewer than 50 loop rounds.

## Complexity

Each case removes one set bit per round, so work follows the bit length of N.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| power table | one pass over 60 bits | 61 integers |
| bit recurrence | one pass over set bits | block buffer |
| output | one line per case | block buffer |

The phase table shows constant work per bit level.

| measure | Big O |
|---|---|
| time | O(log N) per case |
| space | O(1) beyond input and output |

Checking every pair costs O(N^2) time per case.
The bitwise recurrence finishes in a few dozen rounds.
