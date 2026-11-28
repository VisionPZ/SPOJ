# PERMUT2 — Ambiguous Permutations (SPOJ)

<https://www.spoj.com/problems/PERMUT2/>

## Problem

Decide whether each permutation of `1` to `n` equals its own inverse. Write `P(k)` for the value at position `k`. Write `P(P(k))` for applying the permutation twice. The permutation is ambiguous when `P(P(k)) = k` at every position. Write `P⁻¹(v)` for the position holding value `v`.

Input holds several cases. Each case gives `n` on one line, then the `n` permutation values on the next line. A line containing `0` ends the input and produces no output. Output one line per case: `ambiguous` or `not ambiguous`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Length `n` | 1 ≤ n ≤ 100 000 |
| Values | each integer from 1 to n appears once |
| Terminator | a line containing `0` |
| Case count | unbounded, ends at the terminator |
| Judge limit | 10 s, 1536 MB |

The length bound fixes the array size; the case count fixes the input pass.

The sample case:

```
4
1 4 3 2
5
2 3 4 5 1
1
1
0
```

```
ambiguous
not ambiguous
ambiguous
```

The sample has three cases, and the trailing `0` ends the run.

## Idea

Applying the permutation twice must return to the starting position. Picture arrows between numbered seats: each seat points to one seat, and the arrangement is ambiguous when two arrows bring you home.

The program reads every number into one buffer and stores each value in `permValues`. It then tests that `permValues[permValues[position]]` returns `position` at every position. This is the involution check. Each position costs one array lookup, so one case costs O(n).

A naive method searches the whole list once for each value to find its position. That costs O(n²) per case, so it loses as `n` grows.

One array and one pass are enough.

## Why It Works

Four facts carry the check.

1. Every value in the permutation lies between 1 and `n`, so `permValues[position]` is always a valid index.
2. The inverse of value `v` is the position holding `v`; that position is found directly from the stored array.
3. A permutation equals its inverse exactly when `P(P(k)) = k` at every position, so the double lookup decides the case.
4. The first mismatch ends the loop, so the program never builds a second array.

The main terms:

| Term | Meaning |
|---|---|
| `P(k)` | the value at position `k`, stored as `permValues[position]` |
| `P⁻¹(v)` | the position that holds value `v` |
| `P(P(k))` | the value at `P(k)`, read as `permValues[permValues[position]]` |
| `P(P(k)) = k` | the exact test for an ambiguous permutation |

Every term maps to one array slot, so the check needs no search.

A script traces both sample permutations:

```
worked example: n = 4, permutation 1 4 3 2
  k=1: P(k)=1 inverse(k)=1 P(P(k))=1
  k=2: P(k)=4 inverse(k)=4 P(P(k))=2
  k=3: P(k)=3 inverse(k)=3 P(P(k))=3
  k=4: P(k)=2 inverse(k)=2 P(P(k))=4
answer: ambiguous
worked example: n = 5, permutation 2 3 4 5 1
  k=1: P(k)=2 P(P(k))=3
answer: not ambiguous
```

The first case passes all four positions. The second case fails at position one, matching the sample output.

## Code

**Constants and scanner.** These lines set the fixed sizes and read one integer at a time.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumPermutationLength = 100000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`firstDigitValue` turns a digit byte into its value. `maximumPermutationLength` bounds the array above. `nextInt` skips separators, so no token objects are built. The scan cost is one pass over the input bytes.

**Input buffer and output writer.** One loop gathers all input, and one procedure emits full blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`readLine` appends every line into `inputData`, so blank lines cannot desync the reader. `appendOutput` flushes at `flushBlockBytes` and reuses the buffer with `setLen 0`. One write per 256 KiB keeps the output path cheap.

**Driver and involution check.** This loop reads a case, tests it, and flushes the tail.

```nim
var permValues = newSeq[int](maximumPermutationLength + 1)

while true:
  let lengthCount = nextInt(inputData, scanPos)
  if lengthCount == 0: break
  for position in 1 .. lengthCount:
    permValues[position] = nextInt(inputData, scanPos)
  var isAmbiguous = true
  for position in 1 .. lengthCount:
    if permValues[permValues[position]] != position:
      isAmbiguous = false
      break
  if isAmbiguous:
    appendOutput("ambiguous\n")
  else:
    appendOutput("not ambiguous\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`permValues` is sized once for the largest legal `n`, so no case allocates an array. The loop runs `1 .. lengthCount` and stops at the first mismatch. The final `stdout.write` covers the tail and does no work on an empty buffer.

## Complexity

The cost follows the number of values read, not the number of cases.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass per line, then one digit pass per token | input bytes |
| Involution check | one array lookup per position | one array of n + 1 integers |
| Output write | one write per 256 KiB block | one block buffer |

The input pass and the check both grow with the values in the file.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(total input length) |
| Space | O(n) for the permutation array, plus O(1) for the buffers |

Searching the list once per value costs O(n²) per case, so the single scan is the cheaper choice.
