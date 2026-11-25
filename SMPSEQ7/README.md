# SMPSEQ7 — Fun with Sequences, Act 5 (SPOJ)

<https://www.spoj.com/problems/SMPSEQ7/>

## Problem

Cut a row of numbers once so the left part always falls and the right part always rises. Answer whether such a cut exists.

Input: a length `n`, then `n` integers. Output: the word `Yes` or `No` on one line.

| Item | Bound |
|---|---|
| Sequence length `n` | 2 to 100 |
| Values | -100 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The samples, verbatim:

```
5
-1 2 -1 1 -1
```

```
No
```

```
6
3 1 -2 -2 -1 3
```

```
Yes
```

```
6
2 2 1 0 1 2
```

```
No
```

## Idea

Think of cutting a rope once so the left half slopes down and the right half slopes up. The prefix-and-suffix scan finds the longest possible halves.

The scan walks down from the first value and up from the last value. Each step costs one comparison between neighbours. Trying every cut and checking both halves would cost more comparisons.

The two walks meet when a valid cut exists.

## Why It Works

1. `prefixLength` is the longest strictly decreasing start of the sequence.
2. `suffixLength` is the longest strictly increasing end of the sequence.
3. A cut after position `k` needs `k <= prefixLength` and `n-k <= suffixLength`.
4. Clamping `splitIndex` to at least 1 handles a sequence that rises all the way to its end.

| Term | Meaning |
|---|---|
| `values` | the input sequence |
| `prefixLength` | length of the decreasing start |
| `suffixLength` | length of the increasing end |
| `splitIndex` | the first position of the increasing half |

The two lengths decide the cut without trying it.

A traced run of the second sample, produced by the generator:

```
values: [3, 1, -2, -2, -1, 3]
decreasing prefix length 3
increasing suffix length 3
candidate split 3
answer Yes
```

The trace confirms that the cut after the third value works.

## Code

**Constants and input read.** One string holds every input line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The digit offset is the byte of `0`. The block size bounds the output buffer.

**Digit scanner.** Each call advances the shared scan position past one signed integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

The minus sign is part of the token, not a separator. The `var` parameter keeps the position between calls.

**Output buffer.** Appends collect bytes and write one block at a time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write.

**Two walks and answer.** The walks stop at the first broken neighbour.

```nim
let sequenceLength = nextInt(inputData, scanPos)
var values = newSeq[int](sequenceLength)
var positionIndex = 0
while positionIndex < sequenceLength:
  values[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1

var prefixLength = 1
while prefixLength < sequenceLength and values[prefixLength] < values[prefixLength - 1]:
  prefixLength += 1
var suffixLength = 1
while suffixLength < sequenceLength and values[sequenceLength - suffixLength - 1] < values[sequenceLength - suffixLength]:
  suffixLength += 1

var splitIndex = sequenceLength - suffixLength
if splitIndex < 1:
  splitIndex = 1
if splitIndex <= prefixLength:
  appendOutput("Yes")
else:
  appendOutput("No")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each walk visits a value at most once. Strict inequalities reject equal neighbours. The final write covers the answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines | input bytes |
| Digit scan | one pass over `n+1` integers | constant |
| Two walks | one comparison per neighbour | one sequence |
| Output | one write per block | one buffer |

Each neighbour is examined at most once in each walk.

| Measure | Big O |
|---|---|
| Time | O(input bytes + n) |
| Space | O(n) plus one output block |

Checking every cut and both halves would cost O(n squared) comparisons instead.
