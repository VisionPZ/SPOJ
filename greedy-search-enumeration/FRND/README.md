<https://www.spoj.com/problems/FRND/>

## Problem

Every pair of residents has a friendship value equal to the XOR of their names. Report the sum of those values over all pairs.

Input gives resident count N, then N names, one per line. Output one integer on one line; a single resident outputs that resident's name.

| item | bound |
|---|---|
| residents N | 1 to 1000000 |
| each name | positive, below 1000000 |
| number of bits | 20 |
| judge limit | 1000 ms, 1536 MB |

The XOR result has a 1 in a column only when the two names differ in that column.

Sample input:

```
2
19
10
```

Sample output:

```
25
```

## Idea

Count ones and zeros separately in each bit column, like tallying two teams' goals by position.

The real algorithm is bitwise contribution counting, at O(20N) cost. Testing every pair would take O(N²) time and fail at one million residents. Add each bit's contribution once, then print the total.

## Why It Works

1. Aligning two names and marking differing columns is exactly XOR.
2. For one bit, a pair contributes that bit's place value when one name has 1 and the other has 0.
3. If `onesCount` names have the bit set, exactly `onesCount` times `(N - onesCount)` pairs differ there.
4. Multiplying by the place value gives the bit's total contribution.
5. Summing all 20 bits yields the planet value.
6. With one resident there is no pair, and the judge expects that resident's name.

| term | meaning |
|---|---|
| `setBitCounts` | number of names with each bit set |
| `nameBits` | 20 bits, enough for names below one million |
| `planetValue` | sum of all pairwise XOR values |

A script summed the pairs for names 19 and 10: `19 XOR 10 = 25`. Bits 0, 3, and 4 contribute `1 + 8 + 16`; bits 1 and 2 match in both names and add zero.

Use `int64` for the total: one million names create about 5e11 pairs.

## Code

**Input and scanning.** The whole input is read once, then names come from the hand scanner.

```nim
const flushBlockBytes = 1 shl 17
const nameBits = 20

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

Twenty bits cover every legal name.
The scanner skips whitespace between names.

**Buffered output.** One buffer holds the single answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in blocks.
One final write closes the output.

**Bit tally.** Each name updates 20 counters, then one pass sums the contributions.

```nim
let residentCount = nextInt(inputData, scanPos)
if residentCount == 1:
  let onlyName = nextInt(inputData, scanPos)
  appendOutput($onlyName)
  outputBuffer.add '\n'
else:
  var setBitCounts = newSeq[int64](nameBits)
  var residentIndex = 0
  while residentIndex < residentCount:
    let nameValue = nextInt(inputData, scanPos)
    var bitIndex = 0
    while bitIndex < nameBits:
      if (nameValue and (1 shl bitIndex)) != 0:
        setBitCounts[bitIndex] += 1
      bitIndex += 1
    residentIndex += 1
  var planetValue: int64 = 0
  var bitIndex = 0
  while bitIndex < nameBits:
    let onesCount = setBitCounts[bitIndex]
    planetValue += onesCount * (int64(residentCount) - onesCount) * (int64(1) shl bitIndex)
    bitIndex += 1
  appendOutput($planetValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The single-resident branch matches the judge.
Each set bit increments one counter.
The last loop converts counts into the answer.

## Complexity

Reading and bit tallying dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over N names | one input string |
| bit tally | 20 checks per name | 20 counters |
| summation | 20 products | constant |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(20N) |
| space | O(N) for input text |

Checking all pairs would cost O(N²) time instead.

Tally bits, multiply by differing pairs, and write one number.
