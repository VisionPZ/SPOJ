# SDF4D — Praktikum 4 SDF D (SPOJ)

<https://www.spoj.com/problems/SDF4D/>

## Problem

Boruto writes N integers, each tagged as a binary `b` literal or a decimal `d` literal. Himawari sorts the values by numeric value, then prints every value in the form that occurs more often.

Input starts with N, an odd count. The next N lines each hold a form character and one literal. Output has N lines, one sorted value per line, written in the winning form.

| item | bound |
|---|---|
| values N | odd, at least 1 |
| literal type | binary or decimal, non-negative |
| value range | 32-bit integer |
| judge limit | 1000 ms, 1536 MB |

N is odd, so one form always wins and no tie needs handling.

Sample input:

```
3
b 111
d 2
d 15
```

Sample output:

```
2
7
15
```

Two decimal forms beat one binary form, so the sorted values print in decimal.

## Idea

Treat every literal as a number first, like sorting coins by weight before choosing which label to show on each coin. Convert both forms to an integer, sort once, then format by majority.

The algorithm uses base conversion and one comparison sort. Conversion costs one pass over each literal, and sorting costs O(N log N) comparisons. Sorting the literal strings instead would order them lexicographically and give the wrong sequence. Convert first, decide the output form second, and print once.

## Why It Works

1. A binary literal with digits 111 equals decimal 7, so both forms map to one integer.
2. Sorting the integers gives the required ascending order regardless of input form.
3. The majority tag decides the shared output form because N is odd.
4. An integer written back in base 2 has no leading zeros.

| term | meaning |
|---|---|
| `sortedValues` | integer values in ascending order |
| `binaryForms` | count of `b` tagged literals |
| `decimalForms` | count of `d` tagged literals |
| `printBinary` | true when binary forms outnumber decimal forms |

The counts decide one format for the whole answer, not per value.

The sample trace from the generator is:

```
b 111 -> 7
d 2   -> 2
d 15  -> 15
sorted -> 2, 7, 15
majority -> decimal (2 vs 1)
```

The trace matches the sample output line for line.

## Code

**Input and scanner.** The reader loads stdin once, then extracts the count, tags, and literals.

```nim
import algorithm

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

Each literal is scanned as digits, so spacing and line breaks do not matter.
The scanner skips the letter tag on the way to the digits.
This stage costs one pass over the input string.

**Conversion helpers.** Tags, base conversion, and the sort comparator are kept together.

```nim
proc nextForm(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'b' and data[pos] != 'd':
    pos += 1
  let foundForm = data[pos]
  pos += 1
  return foundForm

proc nextLong(data: string, pos: var int, inputForm: char): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let numberBase = if inputForm == 'b': 2 else: 10
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * int64(numberBase) + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc toBinaryString(value: int64): string =
  if value == 0:
    return "0"
  var reversedDigits = ""
  var remaining = value
  while remaining > 0:
    reversedDigits.add chr(int(remaining mod 2) + 48)
    remaining = remaining div 2
  var forwardDigits = ""
  var digitIndex = reversedDigits.len - 1
  while digitIndex >= 0:
    forwardDigits.add reversedDigits[digitIndex]
    digitIndex -= 1
  return forwardDigits

proc compareValues(leftValue, rightValue: int64): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0
```

`nextLong` handles both bases because it skips the tag first.
`toBinaryString` returns `0` for zero, avoiding an empty line.
The comparator gives an ascending numeric order.

**Sort and output.** The program counts tags, sorts once, then writes the chosen form.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var sortedValues = newSeq[int64](numberCount)
var binaryForms = 0
var decimalForms = 0
for itemIndex in 0 .. numberCount - 1:
  let inputForm = nextForm(inputData, scanPos)
  sortedValues[itemIndex] = nextLong(inputData, scanPos, inputForm)
  if inputForm == 'b':
    binaryForms += 1
  else:
    decimalForms += 1
sortedValues.sort(compareValues)
let printBinary = binaryForms > decimalForms
for valueIndex in 0 .. numberCount - 1:
  if printBinary:
    appendOutput(toBinaryString(sortedValues[valueIndex]))
  else:
    appendOutput($sortedValues[valueIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes by block, not by line.
One call to `sort` fixes the order for all N values.
The final write clears the buffer once.

## Complexity

The work splits into conversion, sorting, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| conversion | one pass per literal | N integers |
| sort | O(N log N) comparisons | sort scratch space |
| output | one line per value | block buffer |

Conversion and output are linear; sorting dominates for large N.

| measure | Big O |
|---|---|
| time | O(N log N) plus literal length |
| space | O(N) |

Sorting literal strings lexicographically would take similar time but give wrong order. Convert first, sort numerically, then print in the majority form.
