# BITPLAY — PLAYING WITH BITS (SPOJ)
<https://www.spoj.com/problems/BITPLAY/>

## Problem

For each even limit N and budget K, find the largest odd number below N whose binary form uses at most K ones. Print minus one when no such number exists.

Input starts with T. Each of the next T lines holds an even integer N and an integer K. Output T lines, one answer per case.

| quantity | bound |
|---|---|
| test cases T | 1 to 10000 |
| even limit N | 2 to 1000000000 |
| budget K | 0 to 30 |
| judge limit | 1000 ms, 1536 MB |

Every answer needs at most thirty-one bit checks, so the case count sets the running time.

Sample input:

```
2
10 2
6 1
```

Sample output:

```
9
1
```

For 10, the binary form 1001 has two ones. For 6, the number 1 is the only odd choice with one one.

## Idea

Editing the answer is like changing a price tag: keep the high digits, lower one digit, then spend the remaining ones on the largest low digits.

Since N is even, the first changed bit must be a one in N. Take the lowest position where that change still leaves enough ones for the odd last bit. Clear that bit and all bits below it, then set the last bit and fill the highest spare positions.

Each case scans at most thirty-one bits. Walking down by two from N could take hundreds of millions of steps, so the bit jump avoids that work.

Choose the first legal difference, then spend the leftover ones from the top down.

## Why It Works

1. N has a zero in bit zero because N is even.
2. Any smaller number first differs from N at a bit where N holds a one.
3. The lowest such difference leaves the most high bits unchanged, so it gives the largest value.
4. Bits above that position keep the same ones in the answer.
5. The last bit must be one, so the budget must leave one place after the higher bits.
6. Each spare one goes to the highest free lower bit, which maximises the value.

| term | meaning |
|---|---|
| `evenLimit` | the even upper bound N for one case |
| `onesBudget` | largest allowed count of set bits K |
| `chosenPosition` | lowest bit where N can be lowered |
| `higherOnes` | set bits above the chosen position |
| `lowerBits` | value written into the free positions |
| `blockSize` | power of two that clears the chosen bit and below |

The chosen position fixes the high part, and `lowerBits` fixes the rest.

For N equals 10, written as 1010, bit one is the first legal change. Bit three stays set, so one of the two ones is spent. The answer keeps 1000 and adds bit zero, giving 1001, which is 9.

For N equals 6, written as 110, bit one already needs both ones. The next choice is bit two, which clears every lower bit and leaves 1.

A budget of zero has no answer, because every positive odd number has at least one set bit. Higher ones are counted with a small loop, and all values stay inside the machine integer range.

## Code

**Input and helpers.** The reader loads input, parses integers, and counts set bits.

```nim
const flushBlockBytes = 1 shl 17
const maximumBitPosition = 30

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

proc countSetBits(value: int): int =
  var bitCount = 0
  var remaining = value
  while remaining > 0:
    bitCount = bitCount + (remaining and 1)
    remaining = remaining shr 1
  return bitCount
```

The scanner ignores spaces and line breaks.
`appendOutput` flushes after a whole block of bytes.
`countSetBits` shifts until the value reaches zero.

**Bit choice.** Each case picks the first legal difference and builds the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let evenLimit = nextInt(inputData, scanPos)
  let onesBudget = nextInt(inputData, scanPos)
  if onesBudget < 1:
    appendOutput("-1")
  else:
    var chosenPosition = -1
    var higherOnes = 0
    for bitPosition in 0 .. maximumBitPosition:
      if (evenLimit and (1 shl bitPosition)) != 0:
        let prefixOnes = countSetBits(evenLimit shr (bitPosition + 1))
        if prefixOnes <= onesBudget - 1:
          chosenPosition = bitPosition
          higherOnes = prefixOnes
          break
    if chosenPosition < 0:
      appendOutput("-1")
    else:
      var lowerBits = 1
      var spareOnes = onesBudget - 1 - higherOnes
      var bitPosition = chosenPosition - 1
      while bitPosition >= 1 and spareOnes > 0:
        lowerBits = lowerBits or (1 shl bitPosition)
        spareOnes = spareOnes - 1
        bitPosition = bitPosition - 1
      let blockSize = 1 shl (chosenPosition + 1)
      let answer = evenLimit - (evenLimit mod blockSize) + lowerBits
      appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan stops at the lowest legal bit.
Spare ones fill the highest free positions.
The modulo clears the lower block before adding the new bits.

## Complexity

Bit work is fixed by the input range, not by N itself.

| phase | time | space |
|---|---|---|
| input read | one pass over the input text | one input string |
| bit choice | up to thirty-one checks per case | a few integers |
| output | one line per case | block buffer |

The number of cases drives the total time.

| measure | Big O |
|---|---|
| per case | O(log N) |
| total | O(T log N) |
| space | O(1) beyond the input |

Counting down by two from N would take O(N) steps in the worst case.

The bit scan gives each answer with a fixed small amount of work.
