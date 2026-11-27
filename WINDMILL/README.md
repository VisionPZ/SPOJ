# WINDMILL — The Tall Windmills (SPOJ)

<https://www.spoj.com/problems/WINDMILL/>

## Problem

Place n windmills in a row, one furlong apart, and pick integer heights in yards. Every pair k furlongs apart must differ by at least n − k yards, and the tallest height must be as small as possible.

Input starts with t, the number of cases, at most 100. Each following line holds one integer n. For each case, print one line with n heights in row order, separated by single spaces.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases t | at most 100 |
| Windmills n | 1 to 100 |
| Required gap | n − k yards for distance k |
| Judge limit | 500 ms, 1536 MB |
| Source limit | 50 000 B |

The largest peak is 4902, so int arithmetic stays small. That peak bound drives the choice of a direct formula.

The sample case:

```
3
1
2
3
```

```
1
1 2
2 4 1
```

The sample fixes the printed order for n = 2 and n = 3.

## Idea

Write each answer as two ascending runs with one common step, like two staircases sharing the same riser height. The second run slides down to ground level, so the whole row stays short.

The algorithm is a closed-form two-block construction. For even n, each run holds n/2 heights and advances by n − 1. The program writes one height with a handful of arithmetic operations, so cost per item is O(1). Trying every height combination explores an exponential set of rows, and the formula skips that search.

For odd n, the row uses a short descending lead, one peak, and a copy of the lead shifted down. Cases n = 1, 2, 3 use the sample order directly. The formula always gives a valid row with the smallest possible peak, so no search runs at all.

## Why It Works

Two shape rules and two bounds prove the construction.

1. Inside a run with step n − 1, two windmills d places apart differ by d(n − 1). That is at least n − d for every d from 1 to n − 1.
2. For even n = 2m, run one starts at m + 1 and ends at 2m² − 2m + 2. Run two starts at 1 and repeats the step. Matching positions differ by m, which clears every cross pair.
3. For odd n = 2m + 1, the lead starts at m + 1 and drops by n until the peak. The peak is the smallest value that clears every earlier windmill. The tail repeats the lead shifted down by m.
4. Cases n = 1, 2, 3 keep the printed order from the statement. Their peaks still match the general values.

The main terms:

| Term | Meaning |
|---|---|
| step | n − 1, the gap between neighbors inside an even run |
| `halfCount` | n div 2, the length of each even run |
| `tailLength` | (n − 3) div 2, the descending lead length for odd n |
| peak | 2m² − 2m + 2 for even n, 2m² + 3 for odd n |

Each term is computed once per case, so the row is written in one pass.

A script trace for n = 6, with halfCount = 3:

```
index:    0   1   2   3   4   5
height:   4   9  14   1   6  11
peak = 14
distance 1: |9-4|=5, |14-9|=5, |1-14|=13, |6-1|=5, |11-6|=5
distance 3: |1-4|=3, |6-9|=3, |11-14|=3
```

Every printed gap meets its bound, and 14 is the smallest possible peak.

## Code

**Constants, input, and scanner.** The whole stream is read before any number is parsed.

```nim
const digitBase = 48
const flushBlockBytes = 1 shl 17
const maxWindmills = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - digitBase
    pos += 1
  return value
```

`flushBlockBytes` sets a 128 KiB output block. `nextInt` walks the single buffer by index, so no token object is built. The scanner costs one pass over the digits.

**Output buffer.** Text is appended, then written in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`outputBuffer` keeps one allocation. `setLen 0` reuses it after each write. The size check runs once per appended number, not per byte.

**Driver.** One fixed array holds the row, and the peak formula fills it.

```nim
var heights: array[maxWindmills + 1, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let windmillCount = nextInt(inputData, scanPos)
  let halfCount = windmillCount div 2
  if windmillCount == 1:
    heights[0] = 1
  elif windmillCount == 2:
    heights[0] = 1
    heights[1] = 2
  elif windmillCount == 3:
    heights[0] = 2
    heights[1] = 4
    heights[2] = 1
  elif (windmillCount mod 2) == 0:
    for i in 0..<halfCount:
      heights[i] = i * (windmillCount - 1) + halfCount + 1
    for i in 0..<halfCount:
      heights[halfCount + i] = i * (windmillCount - 1) + 1
  else:
    let tailLength = (windmillCount - 3) div 2
    heights[0] = halfCount + 1
    for i in 0..<tailLength:
      heights[1 + i] = (tailLength - i) * windmillCount + 2
    heights[halfCount] = (windmillCount * windmillCount - 2 * windmillCount + 7) div 2
    for i in 0..<halfCount:
      heights[halfCount + 1 + i] = heights[i] - halfCount
  for i in 0..<windmillCount:
    appendOutput($heights[i])
    if i == windmillCount - 1:
      outputBuffer.add '\n'
    else:
      outputBuffer.add ' '
stdout.write outputBuffer
outputBuffer.setLen 0
```

`heights` is indexed from zero, so `halfCount` splits the row at index three for n = 6. `tailLength` is zero for n = 3, which the case order handles earlier. The final write flushes the tail. One case costs O(n).

## Complexity

Each case fills one array and writes one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input lines, then one digit pass | input bytes |
| Row fill | O(n) arithmetic writes | 101 ints |
| Output | one write per 128 KiB block | 128 KiB |
| Total for t = 100 | O(t·n), at most 10 000 height writes | 101 ints plus one block |

The row fill matches the output size, so no phase dominates.

| Measure | Big O |
|---|---|
| Time | O(t·n) |
| Space | O(n) for the row plus the fixed output block |

A search over all height choices grows exponentially with n. The closed form writes each height once, so the largest legal input finishes far inside the limit.
