# BROKEN — Broken Keyboard (SPOJ)

<https://www.spoj.com/problems/BROKEN/>

## Problem

Find the longest text run that uses at most m distinct characters. Spaces count as characters, and a zero line ends input.

Each case has a line with m, then one line with the typed text. The keyboard has m working keys, each mapped to one character.

A run needs no layout switch, so it contains at most m different characters. Print the maximum run length per case.

| item | bound |
|---|---|
| working keys m | 1 to 128 |
| text length | up to 1000000 characters |
| cases | until the 0 line |
| judge limit | 4358 ms, 1536 MB |

The text length makes a linear scan necessary.

Sample input:

```
5
This can't be solved by brute force.
1
Mississippi
0
```

Sample output:

```
7
2
```

## Idea

Slide a frame along the text like a moving picture window: grow it on the right, then shrink it on the left until only m characters remain inside. The algorithm is a two-pointer sliding window with a frequency count per character. Each character enters once and leaves once, so cost is O(L) per case.

Trying every start and end pair costs O(L^2) and fails on a million characters. One running distinct count keeps the window legal at all times.

## Why It Works

1. A window is legal when its distinct character count is at most m.
2. Adding the right character changes the count only when its frequency was zero.
3. Removing the left character lowers the count only when its frequency reaches zero.
4. The left edge advances until the window becomes legal again.
5. Every legal window ending at a right edge is measured before that edge moves.
6. The maximum measured length is the answer.

The state kept during the scan:

| term | meaning |
|---|---|
| `occurrences` | frequency of each byte value in the window |
| `distinctCount` | number of byte values with positive frequency |
| `leftEdge` | first position still inside the window |
| `longestRun` | largest legal length seen so far |

Each value between 0 and 255 gets one slot.

A trace of the second sample, with m = 1:

```
right char   window   distinct   best
M            M        1          1
i            Mi       2          1
s            s        1          1
s            ss       1          2
i            ssi      2          2
p            p        1          2
p            pp       1          2
best run     ss or pp            2
```

The trace matches the sample answer of two.

The carriage return from a line ending is removed before scanning.

## Code

**Input and output plumbing.** Lines are stored once, and the count is read by hand.

```nim
const flushBlockBytes = 1 shl 17
const characterKinds = 256

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputLines.add inputLine
  inputData.add inputLine
  inputData.add '\n'

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

A full line preserves spaces. The zero line stops the loop. The output buffer flushes in blocks.

**Sliding window scan.** Both edges move forward over the text.

```nim
var linePos = 0
while linePos + 1 < inputLines.len:
  var headerPos = 0
  let maxDistinct = nextInt(inputLines[linePos], headerPos)
  linePos += 1
  if maxDistinct == 0:
    break
  var typedText = inputLines[linePos]
  linePos += 1
  if typedText.len > 0 and typedText[typedText.len - 1] == '\r':
    typedText.setLen typedText.len - 1
  var occurrences = newSeq[int](characterKinds)
  var distinctCount = 0
  var leftEdge = 0
  var longestRun = 0
  for rightEdge in 0 .. typedText.len - 1:
    let incomingKind = int(typedText[rightEdge])
    if occurrences[incomingKind] == 0:
      distinctCount += 1
    occurrences[incomingKind] += 1
    while distinctCount > maxDistinct:
      let outgoingKind = int(typedText[leftEdge])
      occurrences[outgoingKind] -= 1
      if occurrences[outgoingKind] == 0:
        distinctCount -= 1
      leftEdge += 1
    let runLength = rightEdge - leftEdge + 1
    if runLength > longestRun:
      longestRun = runLength
  appendOutput($longestRun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The right edge visits each character once. The left edge only moves forward. One answer line is written per case.

## Complexity

Each case scans the text once.

| phase | time | space |
|---|---|---|
| input read | one pass over input lines | input string and lines |
| window scan | one add and at most one remove per character | 256 counters |
| output | one line per case | block buffer |

Every character leaves the window at most once.

| measure | Big O |
|---|---|
| time | O(L) per case, where L is text length |
| space | O(256) |

Checking all start and end pairs costs O(L^2), which cannot handle a million characters. The sliding window keeps the scan linear.
