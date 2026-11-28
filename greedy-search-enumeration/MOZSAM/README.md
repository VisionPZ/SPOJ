# MOZSAM — Sharmeen And Multiplication (SPOJ)

<https://www.spoj.com/problems/MOZSAM/>

## Problem

Sharmeen hears n integers and may skip any of them. She multiplies the kept integers, starting from a product of 1. Skipping every integer is allowed and gives 1. Print the largest product reachable from any subset.

The first input value is n with 0 ≤ n ≤ 9. It is followed by n integers, each between −10 and 10. Print the maximum product followed by a newline.

| Item | Bound |
|---|---|
| Count n | 0 ≤ n ≤ 9 |
| Heard value x | −10 ≤ x ≤ 10 |
| Judge limit | 1000 ms, 1536 MB |

The small count allows exact reasoning about signs.

The sample case:

```
5
-3 2 -2 1 -3
```

```
18
```

## Idea

Zeros and ones never raise a maximum product. Multiply every value above one. Pair negative values by largest magnitude first; an odd leftover negative is skipped. Think of pairing socks: two left socks form a pair, and the odd one stays in the drawer. Each value is visited once, and sorting the negatives costs O(n log n). Total time is O(n log n + L).

## Why It Works

1. Multiplying by 1 changes nothing, and multiplying by 0 cannot improve a positive product.
2. Two negatives multiply to a positive, so negative pairs help the product.
3. With an odd count of negatives, dropping the one nearest zero keeps the largest pair product.
4. Sorting ascending puts the most negative values first, so adjacent pairs have the largest magnitudes.

| Term | Meaning |
|---|---|
| `positiveProduct` | product of values greater than one |
| `negativeValues` | all heard negative values |
| `negativeProduct` | product of the chosen negative pairs |
| `pairIndex` | index walking the sorted negatives |

Greedy pairing replaces a search over every subset.

A script-traced example from `gen.py`:

```
numbers -3 2 -2 1 -3
best subset -3 -3 2 gives 18
```

The traced subset product equals the sample answer.

## Code

**Input and scanners.** This block loads stdin and reads unsigned and signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value * sign
```

One readLine loop stores the whole input.
The signed scanner handles the minus branch.
Both scanners cost one pass over their tokens.

**Buffered output.** This block collects answer bytes before writing.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.
Each append runs in constant time.

**Greedy selection and final flush.** This block filters, sorts, pairs, and writes the maximum.

```nim
let numberCount = nextInt(inputData, scanPos)
var positiveProduct: int64 = 1
var negativeValues: seq[int] = @[]
for itemIndex in 0..<numberCount:
  let heardValue = nextSignedInt(inputData, scanPos)
  if heardValue > 1:
    positiveProduct = positiveProduct * int64(heardValue)
  elif heardValue < 0:
    negativeValues.add heardValue

for sortIndex in 1..<negativeValues.len:
  let currentValue = negativeValues[sortIndex]
  var cursor = sortIndex - 1
  while cursor >= 0 and negativeValues[cursor] > currentValue:
    negativeValues[cursor + 1] = negativeValues[cursor]
    cursor -= 1
  negativeValues[cursor + 1] = currentValue

var negativeProduct: int64 = 1
var pairIndex = 0
while pairIndex + 1 < negativeValues.len:
  negativeProduct = negativeProduct * int64(negativeValues[pairIndex]) * int64(negativeValues[pairIndex + 1])
  pairIndex += 2

appendOutput($(positiveProduct * negativeProduct) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort handles at most nine values.
An odd last negative stays unpaired.
The empty-subset product stays available as 1.

## Complexity

The cost splits into reading values, sorting negatives, pairing them, and writing one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Filter and sort | O(n log n) | negative values |
| Pairing | O(n) | constant |
| Output | one write per 128 KiB block | block buffer |

The tiny bound keeps every phase cheap.

| Measure | Big O |
|---|---|
| Time | O(n log n + L) for L input bytes |
| Space | O(n + L) |

Trying all 2ⁿ subsets costs O(2ⁿ) work.
Greedy pairing replaces that enumeration.
