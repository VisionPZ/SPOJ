# UNWIRED — Unwired (SPOJ)

<https://www.spoj.com/problems/UNWIRED/>

## Problem

A wire is `n` metres long and must be cut into `k` pieces of one equal length, as long as possible. Each cut made in the middle destroys `m` metres, which are thrown away, and the ends may be trimmed by any amount. The program prints the greatest length each piece can have.

Input starts with `T`, the number of test cases. Each test case is one line with `n`, `k` and `m`. Output holds one integer per test case.

| Item | Bound |
|---|---|
| Test cases `T` | small; tests use up to 100 |
| Wire length `n` | n < 10^9 |
| Pieces `k`, loss `m` | k < 10^9, m < 10^9 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
3
1 1 1
100 2 20
44 3 5
```

```
1
40
11
```

## Idea

Cutting a wire into `k` equal pieces needs exactly `k - 1` cuts, so `m * (k - 1)` metres are lost before the pieces are measured. What is left, `n - m * (k - 1)`, split evenly over `k` pieces gives the answer, rounded down because the ends can be trimmed. Think of a baker with a long loaf and a thick knife: every slice costs crumbs, so the loaf is divided after subtracting the crumbs. This is one subtraction and one division per case, replacing a binary search over all candidate lengths.

## Why It Works

1. Placing `k` pieces end to end in a row needs `k - 1` boundaries between them, and each boundary is one cut that removes `m` metres.
2. After those losses, `k` pieces of length `L` need `k * L + (k - 1) * m` metres, so the largest feasible `L` is the floor of the leftover length divided by `k`.
3. Trimming the ends means leftover wire is allowed, which floor division models exactly.
4. When the losses alone exceed `n`, no positive piece fits; clamping the leftover at 0 gives length 0, which the statement guarantees is always possible.
5. The product `(k - 1) * m` reaches about 10^18, so the arithmetic is done in 64-bit integers to avoid overflow.

| Term | Meaning |
|---|---|
| `wireLength` | `n`, the length in metres |
| `sectionCount` | `k`, the number of equal pieces |
| `cutLoss` | `m`, the metres lost per cut |
| `usableLength` | `n - (k - 1) * m`, clamped at 0 |
| `sectionLength` | the answer for the case |

A traced run of the third sample case:

```
n=44 k=3 m=5
cuts = 2, lost = 10
usable = 44 - 10 = 34
34 div 3 = 11
```

## Code

**Input and hand scanner.** This block loads stdin and reads the integers.

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

One readLine loop collects all input bytes.
The scanner skips whitespace between digits.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block collects the answer lines.

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

**Query loop.** This block applies the closed form to every case.

```nim
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

The three reads stay in 64-bit form so the multiplication cannot overflow.
The clamp handles wires shorter than the total cut loss.
Each case costs one multiply, one subtract and one divide.

## Complexity

The cost splits into input, constant work per case, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Solving | O(1) per case | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(T) for the input buffer |

A binary search over lengths would take about 30 checks per case; the closed form needs one.
