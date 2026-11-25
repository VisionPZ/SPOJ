# VZLA2019I — Italian Dinner (SPOJ)
<https://www.spoj.com/problems/VZLA2019I/>

## Problem

Pick exactly one option from each of six courses. The number of different dinners equals the product of the six option counts.

Input is one line with six integers `C1` to `C6`, each between 1 and 50, separated by single spaces. Output is one line holding the product of those six integers.

| item | bound |
|---|---|
| each option count Ci | 1 to 50 |
| number of courses | 6 |
| maximum product | 50^6 = 15625000000 |
| judge limit | 1000 ms, 1536 MB |

Signed 32-bit integers stop at 2147483647, so the product needs 64-bit storage.

Sample input:

```
1 1 1 2 1 1
```

Sample output:

```
2
```

## Idea

Choosing one item from each course multiplies the options, like assembling outfits from shirts, trousers and shoes. The algorithm reads six integers and multiplies them in one pass. Each course costs one multiplication and one 64-bit update. Listing every dinner would create over 15 billion entries, so multiplication wins. Takeaway: multiply the counts, never enumerate the dinners.

## Why It Works

1. Every course choice is independent of the other five courses.
2. The product of the six counts counts all combined choices.
3. The largest possible product is 50^6, which is 15625000000.
4. A 64-bit accumulator holds that product without overflow.
5. The scanner reads all input once and ignores line breaks.

| term | meaning |
|---|---|
| `courseCount` | fixed number of courses, which is 6 |
| `optionCount` | options offered for the current course |
| `dinnerCount` | running product of all option counts |

The accumulator starts at one, so multiplying six values needs no special first case.

For the sample counts 1, 1, 1, 2, 1, 1 the running products are 1, 1, 1, 2, 2, 2. The final product is 2, matching the sample output.

## Code

**Input and scanning.** The hand reader loads the single input line and parses digits.

```nim
const flushBlockBytes = 1 shl 17
const courseCount = 6

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

`inputData` holds the whole line, and `scanPos` walks it once.
`nextInt` skips spaces and builds each value from digits.

**Product and output.** Six multiplications build the answer in 64-bit math.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var dinnerCount: int64 = 1
for courseIndex in 0 .. courseCount - 1:
  let optionCount = nextInt(inputData, scanPos)
  dinnerCount = dinnerCount * int64(optionCount)
appendOutput($dinnerCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`dinnerCount` uses `int64` to hold the maximum product.
`appendOutput` buffers the single answer line.
One final write flushes the buffer after the loop.

## Complexity

The program reads six numbers and writes one result.

| phase | time | space |
|---|---|---|
| input read | one pass over six integers | one input string |
| multiplication | six 64-bit products | one accumulator |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) |

Enumerating every dinner would take O(50^6) time instead of constant time. Takeaway: constant-time multiplication solves the whole problem.
