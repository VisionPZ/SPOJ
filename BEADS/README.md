## Problem

Read a count, then that many necklaces. Each necklace is a string of lowercase bead sizes. Print the 1-based bead where a cut gives the smallest string read around the circle; use the lowest position on ties.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| necklaces | positive count N, no upper bound in the spec |
| beads per necklace | at most 10 000 |
| bead letters | a through z |
| judge limit | 500 ms, 1536 MB |

A rebuild of every rotation is too slow at 10 000 beads.

## Idea

Find the smallest rotation with Booth's two-pointer scan (Duval's algorithm) on the doubled necklace. Two candidate starts move forward together, and matching beads let one step skip a whole equal run. The larger next bead loses, so that pointer jumps past the run and no rotation string is built.

Cost per bead: constant amortized work, since each bead is compared at most twice.

## Why It Works

The doubled string holds every rotation as a window of n beads. When two starts match for a run of beads, no start inside that run can win. The pointer with the larger next bead moves, because that rotation is larger.

These terms drive one step of the scan.

| term | meaning |
|---|---|
| `doubled[i + matchCount]` | next bead of the left candidate |
| `doubled[j + matchCount]` | next bead of the right candidate |
| `i = i + matchCount + 1` | skip the left run after a loss |
| `min(i, j)` | winning start, counted from zero |

Each step removes at least one bead from the race, so the scan stays linear.

This trace uses the necklace aaabaaa from the sample.

| start | rotation |
|---|---|
| 1 | aaabaaa |
| 2 | aabaaaa |
| 3 | abaaaaa |
| 4 | baaaaaa |
| 5 | aaaaaab |
| 6 | aaaaaba |
| 7 | aaaabaa |

Start 5 gives the smallest rotation, so the answer is 5.

The pointer trace reaches the same start.

| step | left | right | equal beads | compared | next move |
|---|---|---|---|---|---|
| 0 | 0 | 1 | 2 | a vs b | right jumps to 4 |
| 1 | 0 | 4 | 3 | b vs a | left becomes 5 |
| 2 | 5 | 4 | 5 | b vs a | left jumps to 11 |

The left start passes the bead count, so the loop ends and the right start wins.

## Code

**Input and scan position.**

```nim
var inputData = ""
var inputLine = ""
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')
var i = 0
```

The read loop runs to EOF, so one pass loads all input. `i` begins at zero and survives every reader call. Cost: one pass over the input bytes.

**Byte readers.**

```nim
proc skipToLowercase() =
  while i < inputData.len and (inputData[i] < 'a' or inputData[i] > 'z'):
    inc i

proc readCaseCount(): int =
  var value = 0
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  return value
```

Both scanners stop at the first byte outside their class. `skipToLowercase` skips digits and spacing before a necklace. Cost: one pass over the bytes each call skips.

**Necklace reader.**

```nim
proc readNecklace(): string =
  skipToLowercase()
  var j = i
  while i < inputData.len and inputData[i] >= 'a' and inputData[i] <= 'z':
    inc i
  return inputData[j .. i - 1]
```

The slice ends at `i - 1`, the last bead byte. Reading by byte keeps stray spacing out of the necklace. Cost: one slice of n bytes per case.

**Smallest rotation.**

```nim
proc worstDisjoinStart(beads: string): int =
  let beadCount = beads.len
  if beadCount < 2:
    return 0
  let doubled = beads & beads
  var i = 0
  var j = 1
  while i < beadCount and j < beadCount:
    var matchCount = 0
    while matchCount < beadCount and doubled[i + matchCount] == doubled[j + matchCount]:
      inc matchCount
    if matchCount >= beadCount:
      break
    if doubled[i + matchCount] > doubled[j + matchCount]:
      i = i + matchCount + 1
      if i == j:
        inc i
    else:
      j = j + matchCount + 1
      if i == j:
        inc j
  return min(i, j)
```

The outer loop stops when either start reaches `beadCount`. The inner loop counts equal beads, so one step skips a whole run. `doubled` holds every rotation, so no rotation string is built. Cost: O(n) comparisons per necklace.

**Output buffer.**

```nim
var outputBuffer = ""
const flushBlockBytes = 1 shl 18

proc flushOutput() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)
```

`flushBlockBytes` is 256 KiB. `setLen(0)` reuses the buffer storage instead of allocating a new string. Cost: one write per 256 KiB of output.

**Driver.**

```nim
let caseCount = readCaseCount()
for i in 0 ..< caseCount:
  let beads = readNecklace()
  outputBuffer.add($(worstDisjoinStart(beads) + 1))
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
stdout.write(outputBuffer)
```

`i` runs once per necklace. Adding 1 converts the zero-based start into the printed bead number. The final write covers the tail. Cost: one answer per necklace.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| one necklace | O(n) comparisons on the doubled string | 2n bytes |
| output | one write per 256 KiB block | 256 KiB |
| total over N cases | O(total beads plus input plus output) | longest necklace plus one block |

Space tracks the longest necklace, not the count of rotations.

Big O terms:

| measure | form |
|---|---|
| time | O(N) for N total beads |
| space | O(m) for the longest necklace m |

No table of rotations is stored.

Building all m rotations and sorting them costs O(m^2 log m) time and O(m^2) space. One pass over the doubled string stays linear.
