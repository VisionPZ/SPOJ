# EMPODIA — Empodia (SPOJ)

<https://www.spoj.com/problems/EMPODIA/>

## Problem

A biosequence is a permutation of `0..M-1` that starts with `0`, ends with `M-1`, and never puts `E` directly before `E+1`. Find every shortest segment whose first value is the smallest, last value is the largest, and values fill one unbroken range. Such a segment is an empodio. Write `value[i]` for the 0-based value at position `i`.

Input: `t`, then `t` cases. Each case gives `M`, then `M` values, one per line. Output: `H`, then `H` lines `A B` in start order. Both `A` and `B` are 1-based positions.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 20 |
| Length `M` | 1 to 60000, except one case from 1000000 to 1100000 |
| Values | each of `0..M-1` once, no adjacent `E`, `E+1` in that order |
| Judge limits | 40 s, 1536 MB |

The single large case drives the design; a quadratic scan cannot finish it.

The sample input:

```
1
8
0
3
5
4
6
2
1
7
```

The sample output:

```
1
2 5
```

## Idea

Give each position a hook label, `value[i] - i`. The two ends of a framed segment share one hook. Sweep left to right and keep two stacks: one for positions that can still be a minimum, one for values that can block a maximum. Think of two clerks crossing names off two lists while you walk past the seats.

This is a synchronized monotonic-stack sweep. Each position enters each stack once and leaves once, so the work per item stays constant. A nested framed interval always starts later, so the newest accepted start also screens nesting.

Testing every start and end pair costs `O(M^2)`. At `M = 1100000` that count reaches trillions. One pass settles each end as it arrives.

A single pass, two stacks, and one table of hook labels solve the whole case.

## Why It Works

Four facts prove the sweep.

1. A segment `[i, j]` is framed when `value[i] - i = value[j] - j`, with no smaller or larger value between. Equal hooks make the value range match the position range.
2. The increasing stack holds precisely the positions whose value is the minimum from that position up to the current end. A position leaves when a smaller value arrives.
3. The decreasing stack top is the rightmost earlier position whose value exceeds the current value. That position is the only possible blocker for the current maximum.
4. A framed interval inside another starts later. Rejecting starts at or before the newest accepted start removes every nested interval.

The terms used by the sweep:

| Term | Meaning |
|---|---|
| `value[i] - i` | hook label shared by both ends of a framed segment |
| `minStack` | positions that can still be the minimum for the current end |
| `maxStack` | positions whose values exceed the current value |
| `rightmostStart` | left edge of the newest empodio; later starts must pass it |

The table turns each check into one comparison against a stack top.

A script trace of the sample follows. The sweep prints `right`, `value`, `key`, both stacks, and the decision before pushing the end.

```
right=0 value=0 key= 0 mn=[]               mx=[]           candidate=None no matching earlier start
right=1 value=3 key= 2 mn=[0]              mx=[]           candidate=None no matching earlier start
right=2 value=5 key= 3 mn=[0, 1]           mx=[]           candidate=None no matching earlier start
right=3 value=4 key= 1 mn=[0, 1]           mx=[2]          candidate=None no matching earlier start
right=4 value=6 key= 2 mn=[0, 1, 3]        mx=[]           candidate=   1 empodio (2, 5)
right=5 value=2 key=-3 mn=[0]              mx=[4]          candidate=None no matching earlier start
right=6 value=1 key=-5 mn=[0]              mx=[4, 5]       candidate=None no matching earlier start
right=7 value=7 key= 0 mn=[0, 6]           mx=[]           candidate=   0 start 0 hides an older empodio
answer H = 1 [(1, 4)]
```

At `right=4` the hook is `2`, and position `1` carries the same hook. Both stacks clear it, so the answer is `(2, 5)`. At `right=7` the hook is `0`, but position `0` hides the earlier empodio, so the sweep rejects it.

## Code

**Constants and scanner.** The scanner walks one input buffer by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The loop skips separators, including blank lines. Digits become values through `firstDigitValue`, with no token objects. The scan uses one `var int` position, so it survives every call.

**Bulk input and output.** Both streams use one buffer each.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All lines enter `inputData` before any parsing. The output buffer flushes at `flushBlockBytes` and reuses its allocation. A case never writes per line.

**Case setup.** One parse pass reads the count and the values.

```nim
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for position in 0 ..< elementCount:
    values[position] = nextInt(inputData, scanPos)
```

`caseIndex` runs from zero to `caseCount - 1`. The inner loop reads exactly `elementCount` values, so newlines cannot desync it. Arrays are sized once for the case.

**Workspace.** Stacks, hook buckets, and answer arrays are flat sequences.

```nim
  var minStack = newSeq[int](elementCount)
  var maxStack = newSeq[int](elementCount)
  var keyStackLink = newSeq[int](elementCount)
  var keyTop = newSeq[int](2 * elementCount + 1)
  var foundStarts = newSeq[int](elementCount)
  var foundEnds = newSeq[int](elementCount)
  var minStackTop = -1
  var maxStackTop = -1
  var foundCount = 0
  var rightmostStart = -1
```

The hook offset adds `elementCount`, so every hook index stays non-negative. `keyTop` stores a position plus one; zero means empty. `keyStackLink` removes a leaving position from its hook bucket in one step.

**The sweep.** Each end is tested, then pushed onto both stacks.

```nim
  for rightPos in 0 ..< elementCount:
    let currentValue = values[rightPos]
    while maxStackTop >= 0 and values[maxStack[maxStackTop]] < currentValue:
      maxStackTop -= 1
    while minStackTop >= 0 and values[minStack[minStackTop]] > currentValue:
      let poppedPos = minStack[minStackTop]
      let poppedKeyOffset = values[poppedPos] - poppedPos + elementCount
      keyTop[poppedKeyOffset] = keyStackLink[poppedPos]
      minStackTop -= 1

    let currentKeyOffset = currentValue - rightPos + elementCount
    let candidateStart = keyTop[currentKeyOffset] - 1
    if candidateStart >= 0:
      let clearOfGreater = maxStackTop < 0 or candidateStart > maxStack[maxStackTop]
      if candidateStart > rightmostStart and clearOfGreater:
        foundStarts[foundCount] = candidateStart
        foundEnds[foundCount] = rightPos
        foundCount += 1
        rightmostStart = candidateStart

    keyStackLink[rightPos] = keyTop[currentKeyOffset]
    keyTop[currentKeyOffset] = rightPos + 1
    minStackTop += 1
    minStack[minStackTop] = rightPos
    maxStackTop += 1
    maxStack[maxStackTop] = rightPos
```

The two `while` loops run once per position over the whole case. `candidateStart` is the largest matching hook still in the minimum stack. The `clearOfGreater` test rejects a larger earlier value. The final lines insert the current position once.

**Emission.** The count comes first, then one line per pair.

```nim
  appendOutput($foundCount)
  outputBuffer.add '\n'
  for pairIndex in 0 ..< foundCount:
    outputBuffer.add $(foundStarts[pairIndex] + 1)
    outputBuffer.add ' '
    outputBuffer.add $(foundEnds[pairIndex] + 1)
    outputBuffer.add '\n'
```

`pairIndex` covers exactly the accepted pairs. Each position gains one, because the output uses 1-based indices. The loop appends to the buffer and never writes directly to the stream.

**Final flush.** The tail leaves the buffer at exit.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

This write also handles a case whose answer count is zero. The buffer is reset once, after the last case.

## Complexity

The work splits into input, one sweep per case, and buffered output.

| Phase | Time | Space |
|---|---|---|
| Input read | one line pass, then one digit pass | input bytes |
| Sweep per case | one push and one pop per position | hook table and two stacks, about `6M` ints |
| Output | one write per 256 KiB block | block buffer |

The large case needs about `2.2M` stack moves and a bounded output buffer.

The asymptotic bounds follow from the single sweep.

| Measure | Big O |
|---|---|
| Time | `O(M)` per case, `O(total values)` overall |
| Space | `O(M)` per case |

Checking every start and end pair costs `O(M^2)`, which cannot finish a million-element case.
