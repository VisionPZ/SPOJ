# KURUK14 — Genie Sequence (SPOJ)

<https://www.spoj.com/problems/KURUK14/>

## Problem

Given a bag of numbers, decide whether they can be ordered so each entry states how many entries stand before it or after it.

Input starts with T, followed by T cases. Each case gives N and then N integers. Output is one line per case with YES or NO.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| sequence length N | 2 to 1000 |
| each value | 1 to 1000 |
| judge limit | 100 ms, 1536 MB |

The short time limit favors one linear pass over each sequence.

Sample input:

```
1
4
1 3 3 2
```

Sample output:

```
YES
```

The order 3, 1, 2, 3 satisfies every entry in the sequence.

## Idea

Treat mirrored ticket numbers as sharing the same two seats.

A position can hold its own index or the mirrored index. Two mirrored values claim the same two positions, so their combined count must be exactly two. An odd length has one unpaired middle position, which needs exactly one copy of its index. The program counts values once and checks each mirrored pair. A brute force that tries every ordering grows factorially and cannot meet the limit.

## Why It Works

1. At position i there are i entries before it and N minus one minus i after it.
2. A value placed at position i must equal i or its mirror N minus one minus i.
3. Values k and N minus one minus k can only occupy the same two positions.
4. Those two positions require exactly two entries, so the two counts sum to two.
5. When N is odd, the middle position is its own mirror and needs one entry.

| term | meaning |
|---|---|
| `frequencies` | how often each value appears in the case |
| `leftValue` | lower value of the mirrored pair under test |
| `rightValue` | upper value of the mirrored pair under test |
| `possible` | current answer before later checks reject it |

Each mirrored pair is tested once, so the work stays linear.

A script traces the sample case:

```
N = 4
pair (0,3): count[0]=0 count[3]=2 total=2
pair (1,2): count[1]=1 count[2]=1 total=2
answer YES
```

Both pairs pass, which matches the printed YES.

## Code

**Input and scanner.** The reader loads stdin once and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const frequencyLimit = 1000

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

The scanner skips line breaks and spaces between tokens.
The frequency table is sized for the stated value limit.

**Buffered output.** One string holds answers until a block is full.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each YES or NO line enters the same buffer.
A final write handles any remaining bytes.

**Pair checks.** Counts are gathered, then mirrored pairs are tested.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequenceLength = nextInt(inputData, scanPos)
  var frequencies = newSeq[int](frequencyLimit + 1)
  var hasOversizedValue = false
  for elementIndex in 0 .. sequenceLength - 1:
    let elementValue = nextInt(inputData, scanPos)
    if elementValue >= 0 and elementValue <= frequencyLimit:
      frequencies[elementValue] += 1
    else:
      hasOversizedValue = true
  var possible = not hasOversizedValue
  var leftValue = 0
  var rightValue = sequenceLength - 1
  while possible and leftValue < rightValue:
    if frequencies[leftValue] + frequencies[rightValue] != 2:
      possible = false
    leftValue += 1
    rightValue -= 1
  if possible and (sequenceLength mod 2) == 1:
    if frequencies[(sequenceLength - 1) div 2] != 1:
      possible = false
  if possible:
    appendOutput "YES\n"
  else:
    appendOutput "NO\n"
stdout.write outputBuffer
outputBuffer.setLen 0
```

An oversized value cannot occupy any position and fails the case.
The loop stops early once a pair fails.
The middle index is checked only for odd lengths.

## Complexity

Each case is counted once and then scanned once over half its length.

| phase | time | space |
|---|---|---|
| input read | one pass over T cases | one input string |
| counting | one pass over N values | one count array |
| pair checks | N divided by two comparisons | constant |
| output | one line per case | block buffer |

No ordering of the values is ever constructed.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(1001) |

Trying every arrangement costs factorial time and cannot pass.
The mirrored-pair count is the takeaway.
