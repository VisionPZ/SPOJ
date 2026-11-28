# VPL0_B — Basic Grapes Instinct (SPOJ)

<https://www.spoj.com/problems/VPL0_B/>

## Problem

Render a stemplot: split each value into a stem of value div U and a leaf of value mod U, then list leaves in ascending order under each ascending stem. Line up every pipe by padding stems on the left.

Input starts with T. Each case gives N and U, then N values on separate lines. Output a scenario header, the stemplot, and a blank line for each case.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| values per case N | 1 to 10000 |
| stem unit U | 1 to 1000 |
| value si | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

N and U set the sort and padding work.

Sample input:

```
2
17 10
44
46
47
49
63
64
66
68
68
72
72
75
76
81
84
88
106
5 23
1
9
127
23
73
```

Sample output:

```
Scenario #1:
 4 | 4 6 7 9
 6 | 3 4 6 8 8
 7 | 2 2 5 6
 8 | 1 4 8
10 | 6

Scenario #2:
0 | 1 9
1 | 0
3 | 4
5 | 12

```

## Idea

Sort the whole list once, like lining up books by height on one shelf. Equal stems then sit together, and their leaves are already in order.

The algorithm sorts all values, walks consecutive equal stems, and prints one padded line per group. Sorting costs O(N log N) once. Grouping first and sorting every group repeats comparisons and needs extra lists.

Takeaway: one global sort supplies both the stem order and the leaf order.

## Why It Works

1. Dividing a sorted value by U gives a nondecreasing stem sequence.
2. Values with the same stem appear consecutively in that sequence.
3. Their remainders increase with the values, so leaves come out sorted.
4. The widest stem in the case fixes the pad width for every line.
5. Padding on the left aligns all pipes in one column.

| term | meaning |
|---|---|
| `stemUnit` | divisor U that defines a stem |
| `largestStem` | highest stem in the case, used for width |
| `stemWidth` | digit count of `largestStem` |
| `currentStem` | stem shared by one consecutive block of values |

The group walk reads each sorted value once.

A script-generated trace for the second sample case, with U = 23:

```
value  ->  stem | leaf
1      ->     0 | 1
9      ->     0 | 9
23     ->     1 | 0
73     ->     3 | 4
127    ->     5 | 12
stem width 1, so no padding
```

The trace produces the four lines of `Scenario #2`.

## Code

**Input and buffered writer.** The reader loads values and the writer collects output.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips line breaks between values.
Large outputs are flushed in fixed blocks.
The buffer is shared by every case.

**Sort and width.** One sort fixes both orderings, then the widest stem fixes padding.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let valueTotal = nextInt(inputData, scanPos)
  let stemUnit = nextInt(inputData, scanPos)
  var values = newSeq[int](valueTotal)
  for valueIndex in 0 .. valueTotal - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
  values.sort(proc(leftValue, rightValue: int): int = leftValue - rightValue)

  let largestStem = values[valueTotal - 1] div stemUnit
  var stemWidth = 1
  var widthValue = largestStem
  while widthValue >= 10:
    stemWidth += 1
    widthValue = widthValue div 10
```

The last sorted value owns the largest stem.
An explicit comparator supports old Nim compilers.
The width loop uses integer division only.

**Grouped rendering.** Each consecutive stem block becomes one aligned line.

```nim
  appendOutput("Scenario #" & $(caseIndex) & ":\n")
  var position = 0
  while position < valueTotal:
    let currentStem = values[position] div stemUnit
    var digitCount = 1
    var digitValue = currentStem
    while digitValue >= 10:
      digitCount += 1
      digitValue = digitValue div 10
    for padIndex in 0 .. stemWidth - digitCount - 1:
      outputBuffer.add ' '
    appendOutput($(currentStem))
    outputBuffer.add ' '
    outputBuffer.add '|'
    outputBuffer.add ' '
    var firstLeaf = true
    while position < valueTotal and values[position] div stemUnit == currentStem:
      if not firstLeaf:
        outputBuffer.add ' '
      firstLeaf = false
      appendOutput($(values[position] mod stemUnit))
      position += 1
    outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Shorter stems receive spaces on the left.
A flag inserts a space only between leaves.
One blank line closes each scenario.

## Complexity

Sorting dominates, and rendering is a single pass over sorted values.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | value array |
| sort | O(N log N) | sort workspace |
| rendering | O(N) plus pad width | block buffer |
| output | block flushes | block buffer |

The per-case cost grows mainly with N.

| measure | Big O |
|---|---|
| time | O(T * N log N) |
| space | O(N) |

Sorting each stem group separately adds list overhead and more comparisons.

Takeaway: sort once, then stream aligned lines from the ordered values.
