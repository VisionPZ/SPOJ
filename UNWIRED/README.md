# UNWIRED — Unwired (SPOJ)

<https://www.spoj.com/problems/UNWIRED/>

## Problem

A wire of given length must be cut into equal sections, and every cut removes some extra wire. Report the longest possible section length for each case.

The input starts with the test count. Each case gives wire length, section count, and loss per cut. Print one length per case.

| item | bound |
|---|---|
| tests T | not stated |
| wire length n | below 1000000000 |
| section count k | below 1000000000 |
| cut loss m | below 1000000000 |
| judge limit | 1000 ms, 1536 MB |

A case can still make k sections of length zero.

Sample input:

```
3
1 1 1
100 2 20
44 3 5
```

Sample output:

```
1
40
11
```

## Idea

Budget the wire like cutting ribbon with a thick blade: reserve the waste before sharing the rest. k sections need k minus one cuts, so the waste is k minus one times m. Divide what remains by k. If the waste already exceeds the wire, the answer is zero.

## Why It Works

1. Making k sections needs exactly k minus one cuts.
2. Each cut throws away m metres, so total waste is k minus one times m.
3. The k sections share the wire left after waste.
4. Equal sections of maximum length come from integer division of that remainder by k.

| term | meaning |
|---|---|
| `wireLength` | starting length n |
| `sectionCount` | required sections k |
| `cutLoss` | metres lost per cut m |
| `usableLength` | wire left after all cuts |

The division uses int64 because waste can reach one quintillion.

Script-generated trace for the three sample cases:

```
wire | sections | loss | waste | left | answer
1 | 1 | 1 | 0 | 1 | 1
100 | 2 | 20 | 20 | 80 | 40
44 | 3 | 5 | 10 | 34 | 11
```

All three rows match the sample output.

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

All cases are parsed before any output.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Waste budget and output.** One division gives each answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let wireLength = int64(nextInt(inputData, scanPos))
  let sectionCount = int64(nextInt(inputData, scanPos))
  let cutLoss = int64(nextInt(inputData, scanPos))
  var usableLength = wireLength - (sectionCount - 1) * cutLoss
  if usableLength < 0:
    usableLength = 0
  let sectionLength = usableLength div sectionCount
  appendOutput($sectionLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Waste is subtracted before division.
A negative remainder is clamped to zero.
Each case costs a few int64 operations and one buffered line.

## Complexity

Each case is answered by one formula.

| phase | time | space |
|---|---|---|
| input read | one pass over 3t numbers | one input string |
| length formula | constant work per case | no table |
| output | one line per case | block buffer |

The work does not depend on the wire length.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(1) apart from buffers |

Trying every length would cost O(n) per case and cannot finish for large wires.
