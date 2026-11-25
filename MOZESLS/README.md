# MOZESLS — Sharmeen Loves Substring [EASY] (SPOJ)

<https://www.spoj.com/problems/MOZESLS/>

## Problem

A lowercase string hides copies of the pattern `sms`.
Each query gives a window from position L to position R.
Count distinct triples of positions inside that window.
The first position holds `s`, the second holds `m`, the third holds `s`.
Order matters, positions must increase, and chosen positions need not touch.
The string `skmjssm` has two copies, using positions 1, 3, 5 and 1, 3, 6.

| Item | Bound |
|---|---|
| String length | 1 ≤ N ≤ 100 |
| Queries | 1 ≤ Q ≤ 50 |
| Window | 1 ≤ L ≤ R ≤ N |
| Judge limit | 1000 ms, 1536 MB |

The small bounds still reward a reusable prefix method.

The sample case:

```
sasmasamsas
3
1 6
3 9
8 11
```

```
2
4
0
```

## Idea

Count each middle letter once, then multiply by the `s` letters around it.
Think of theatre seats: every `m` is a seat with `s` guests on both sides.
Prefix arrays report those guest counts in constant time.
A triple loop checks every three positions and costs cubic work per query.

## Why It Works

1. Every copy of `sms` has one middle `m` and two surrounding `s` letters.
2. For an `m` at position p, earlier `s` letters equal prefixS[p − 1] − prefixS[L − 1].
3. Later `s` letters equal prefixS[R] − prefixS[p], and prefixS[p] equals prefixS[p − 1].
4. Expanding the product leaves four prefix sums, each read in constant time.
5. An int64 holds every answer under these bounds.

| Term | Meaning |
|---|---|
| `prefixS` | count of `s` letters up to a position |
| `prefixBefore` | sum of earlier-`s` counts over all `m` letters |
| `prefixSquares` | sum of squared earlier-`s` counts over all `m` letters |
| `prefixMiddles` | count of `m` letters up to a position |
| `answer` | number of `sms` copies in one window |

The terms turn a triple loop into four array lookups.

A script-traced example from `gen.py`:

```
window skmjssm
brute 2
scan 2
```

Both the triple loop and the scan find two copies.

## Code

**Input and hand scanners.** This block loads stdin and reads one integer or word.

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
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token
```

One readLine loop collects the whole input.
The scanner tracks its index and skips whitespace.
Both helpers cost one pass over their tokens.

**Buffered output.** This block collects finished answer lines.

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

**Prefix tables and query answers.** This block builds four tables and answers every query.

```nim
let sourceText = nextToken(inputData, scanPos)
let textLength = sourceText.len
var prefixS: seq[int64]
prefixS.setLen(textLength + 1)
var prefixBefore: seq[int64]
prefixBefore.setLen(textLength + 1)
var prefixSquares: seq[int64]
prefixSquares.setLen(textLength + 1)
var prefixMiddles: seq[int64]
prefixMiddles.setLen(textLength + 1)
for index in 1..textLength:
  let character = sourceText[index - 1]
  prefixS[index] = prefixS[index - 1]
  prefixBefore[index] = prefixBefore[index - 1]
  prefixSquares[index] = prefixSquares[index - 1]
  prefixMiddles[index] = prefixMiddles[index - 1]
  if character == 's':
    prefixS[index] += 1
  elif character == 'm':
    let earlierS = prefixS[index - 1]
    prefixBefore[index] += earlierS
    prefixSquares[index] += earlierS * earlierS
    prefixMiddles[index] += 1

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0..<queryCount:
  let left = nextInt(inputData, scanPos)
  let right = nextInt(inputData, scanPos)
  let beforeWindow = prefixS[left - 1]
  let upToRight = prefixS[right]
  let middleTotal = prefixMiddles[right] - prefixMiddles[left - 1]
  let beforeSum = prefixBefore[right] - prefixBefore[left - 1]
  let squareSum = prefixSquares[right] - prefixSquares[left - 1]
  let answer = upToRight * beforeSum - squareSum - beforeWindow * upToRight * middleTotal + beforeWindow * beforeSum
  appendOutput($(answer) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The build loop runs once over N characters.
Each query uses constant work and avoids the cubic triple loop.
The final write flushes the buffer at end of input.

## Complexity

The cost splits into input, one prefix build, and one pass per query.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Prefix build | O(N) character visits | four arrays of N + 1 int64 |
| Queries | O(1) work each | output buffer |
| Output | one write per 128 KiB block | block buffer |

Each phase stays within the small bounds.

| Measure | Big O |
|---|---|
| Time | O(N + Q) |
| Space | O(N) |

A triple loop costs O(N³Q) in the worst case, so prefix sums replace it.
