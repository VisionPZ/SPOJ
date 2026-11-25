# MOZSAS — Shahadat and Sequence (SPOJ)

<https://www.spoj.com/problems/MOZSAS/>

## Problem

A sequence is built from given numbers x1..xn: odd positions hold `2 × x`, even positions hold `2 × x + 1`. For each query, decide whether the sum of the sequence from position l to position r is even or odd.

Input gives n, then the n values of x, then Q, then Q lines with l and r. Output gives one word per query.

| Item | Bound |
|---|---|
| Sequence length | 2 ≤ n ≤ 100000 |
| Each x | 1 ≤ x ≤ 30 |
| Query count | 1 ≤ Q ≤ 100000 |
| Query range | 1 ≤ l ≤ r ≤ n |
| Judge limit | 1000 ms, 1536 MB |

One division pair per query is enough.

The sample case:

```
5
3 2 1 2 2
3
1 3
2 5
2 3
```

```
Odd
Even
Odd
```

## Idea

Throw away the numbers and count positions. Every `2 × x` term is even, so it cannot change the parity of a sum; only the `2 × x + 1` terms, which sit at even positions, flip it. So a query is Odd exactly when the window `[l, r]` holds an odd number of even positions. Think of a row of light switches where only some flips matter: you only need to know how many of those special switches were touched. The count of even positions up to r is `r div 2`, so the window count is `r div 2 - (l - 1) div 2`, done in two divisions. Adding the window term by term costs up to 100000 additions per query.

## Why It Works

1. `2 × x` is always even and `2 × x + 1` is always odd, for every x in 1..30. The value of x never matters.
2. The parity of a sum equals the parity of the number of odd addends in it.
3. The odd addends sit exactly at even indices 2, 4, 6, and so on.
4. There are `r div 2` even indices at or below r, and `(l - 1) div 2` even indices below l. Subtracting leaves the count inside the window.
5. That count is even means the sum is Even; odd means Odd.

| Term | Meaning |
|---|---|
| `elementCount` | n, the sequence length |
| `queryCount` | Q, the number of queries |
| `leftIndex` | l, the first position of a query |
| `rightIndex` | r, the last position of a query |
| `evenIndexCount` | how many even positions lie in `[l, r]` |

The parity test on that count is the whole answer.

A script-traced example from `gen.py`:

```
x values 3 2 1 2 2
array    6 5 2 5 4
query 2 5 sum 5+2+5+4=16 -> Even
```

The trace matches the second sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

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
```

One readLine loop collects all input bytes.
The scanner skips newlines and spaces without special handling.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block collects answer words.

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

**Query loop.** This block answers every query with two divisions.

```nim
let elementCount = nextInt(inputData, scanPos)
for skipIndex in 0..<elementCount:
  discard nextInt(inputData, scanPos)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0..<queryCount:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  let evenIndexCount = rightIndex div 2 - (leftIndex - 1) div 2
  if evenIndexCount mod 2 == 0:
    appendOutput("Even\n")
  else:
    appendOutput("Odd\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The x values are read and dropped, because they carry no parity information.
`rightIndex div 2` counts even positions up to r, and `(leftIndex - 1) div 2` counts them below l.
Each answer costs two divisions and one buffer append.

## Complexity

The cost splits into input, two divisions per query, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Queries | O(1) per query | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(N + Q) |
| Space | O(N) for the input buffer |

Summing each window directly costs O(Q × N), up to 10^10 additions; the position count stays at about 2×10^5 steps.
