# MAX10 — Maximum of Ten (SPOJ)

<https://www.spoj.com/problems/MAX10/>

## Problem

Ten integers arrive on one line. Print the largest of them in the Indonesian sentence `Bilangan terbesar: X`.

Each value is below 10^10, so 64-bit integers are needed. The output is one line.

| item | bound |
|---|---|
| values | exactly 10 |
| each value | below 10^10 |
| judge limit | 1000 ms, 1536 MB |

A single running maximum answers the question.

Sample input:

```
3 3 2 1 1 7 6 7 1 7
```

Sample output:

```
Bilangan terbesar: 7
```

## Idea

A referee does not need to remember every score, only the best one so far. The scanner hands over the ten numbers one by one, and one variable keeps the largest seen.

Storing the numbers in an array and sorting them would cost more work than a single comparison per value.

Takeaway: a running maximum needs one variable.

## Why It Works

1. The scanner skips spaces and newlines, so the ten values are read in order.
2. Each candidate is compared with the current maximum and replaces it when larger.
3. After ten reads the variable holds the largest value.
4. The fixed prefix and the number form the required line.

For the sample, the candidates 3, 3, 2, 1, 1, 7, 6, 7, 1, 7 raise the maximum to 7, which stays.

Ties are harmless because the comparison keeps the first equal value.

## Code

**Input and scanning.** The hand reader loads the file and parses 64-bit values.

```nim
const flushBlockBytes = 1 shl 17
const expectedCount = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.
`int64` holds values up to 10^10 exactly.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Running maximum.** Ten candidates are compared as they arrive.

```nim
var largestValue: int64 = 0
var valueIndex = 0
while valueIndex < expectedCount:
  let candidate = nextInt(inputData, scanPos)
  if candidate > largestValue:
    largestValue = candidate
  valueIndex += 1

appendOutput("Bilangan terbesar: ")
appendOutput($largestValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The count 10 is a named constant.
The loop stops after exactly ten reads.
The sentence prefix matches the statement.

## Complexity

The program reads ten numbers and compares each once.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| scan | ten comparisons | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(1), ten values |
| space | O(1) |

Sorting the ten values would add needless work.

Takeaway: a max scan is the shortest correct path.
