# ULTREVEN — Ultra-even (SPOJ)

<https://www.spoj.com/problems/ULTREVEN/>

## Problem

An array is ultra even when every consecutive block has an even sum. Decide whether the given array has that property.

The input starts with the array length. The array values follow, separated by spaces or line breaks. Print YES or NO.

| item | bound |
|---|---|
| array length n | 1 to 100000 |
| array value | not stated beyond integer |
| judge limit | 1000 ms, 1536 MB |

A single odd value already breaks the property.

Sample input:

```
4
1 4 5 2
```

Sample output:

```
NO
```

## Idea

Look at blocks of length one, like checking every single card before checking any pile. Such a block has the value itself as its sum. An ultra even array therefore needs every value even, and that condition also suffices. One pass over the array replaces checking all blocks, which would be quadratic.

## Why It Works

1. A block of one element is a consecutive block.
2. Its sum is that element, so every element must be even.
3. A sum of even values is always even.
4. Hence all-even values are both necessary and sufficient.

| term | meaning |
|---|---|
| `allEven` | flag that stays true while every value read is even |
| `currentNumber` | one value taken from the input buffer |

One parity test per value settles the whole array.

Script-generated trace for the two sample arrays:

```
values 1 4 5 2 -> odd value found -> NO
values 2 4 6   -> all values even -> YES
```

The first sample contains 1 and 5, so it prints NO.

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

All values are parsed before any output is written.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Parity pass and output.** One flag records the whole array's verdict.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var allEven = true
for numberIndex in 0 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  if currentNumber mod 2 != 0:
    allEven = false
if allEven:
  appendOutput("YES")
else:
  appendOutput("NO")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits each value exactly once.
One odd value clears the flag for good.
The verdict is written once from the block buffer.

## Complexity

One linear pass replaces a quadratic scan over all blocks.

| phase | time | space |
|---|---|---|
| input read | one pass over n values | one input string |
| parity pass | one test per value | one flag |
| output | one line | block buffer |

No block table is built and no array of values is stored.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(1) apart from input bytes |

Testing every block would cost O(n squared) and still reach the same verdict.
