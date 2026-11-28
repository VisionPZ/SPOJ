# BAT3 — BATMAN3 (SPOJ)

<https://www.spoj.com/problems/BAT3/>

## Problem

A climber moves forward over peaks and only takes strictly downhill jumps. At one fixed peak, a small bat allows a single jump of any height to a later peak.

Each case gives the peak count, the zero-based bat peak, and the peak heights. Print the largest number of peaks visited.

| item | bound |
|---|---|
| peaks per case | 1 to 1000 |
| bat peak index | 0 to peak count minus 1 |
| peak heights | integers |
| judge limit | 1000 ms, 1536 MB |

The bat jump is optional and works only at the given peak.

Sample input:

```
1
6 4
6 3 5 2 4 5
```

Sample output:

```
4
```

## Idea

Think of a slide with one elevator: you descend freely, and the elevator lifts you once at a marked stop.

The algorithm runs two longest decreasing subsequence passes. One pass gives the best route ending at each peak. The other gives the best route starting at each peak. Combining the bat peak with a later start costs O(n^2) per case.

Searching all jump sequences grows far faster than two quadratic passes.

Two passes capture every route with at most one uphill jump.

## Why It Works

1. An ordinary route is a strictly decreasing subsequence in peak order.
2. The length ending at a peak comes from a higher earlier peak.
3. The length starting at a peak comes from a lower later peak.
4. A bat route must reach the bat peak, then jump to any later peak.
5. The jumped peak is counted once by the starting length.
6. The better of the plain route and each bat route is the answer.

| term | meaning |
|---|---|
| `downhillEnding` | longest strictly decreasing run ending at a peak |
| `downhillStarting` | longest strictly decreasing run starting at a peak |
| `robinIndex` | the peak where the bat is available |
| `batRoute` | peaks reached by ending at the bat peak and jumping |

Strict height comparison keeps equal peaks apart.

A script trace uses heights `6 3 5 2 4 5` with bat peak 4:

```
ending lengths   1 2 2 3 3 1
starting lengths 2 1 2 1 1 1
plain best       3
bat route        3 + 1 = 4
answer           4
```

The trace matches the sample output 4.

## Code

**Input and scanning.** The reader loads each case and its peak heights.

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

The scanner reads positive integers from one buffer.
It skips whitespace and line breaks.
No negative height appears in the statement.

**Two subsequence passes.** Both passes then combine for the bat route.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let peakCount = nextInt(inputData, scanPos)
  let robinIndex = nextInt(inputData, scanPos)
  var peakHeights = newSeq[int](peakCount)
  for peakIndex in 0 .. peakCount - 1:
    peakHeights[peakIndex] = nextInt(inputData, scanPos)
  var downhillEnding = newSeq[int](peakCount)
  for peakIndex in 0 .. peakCount - 1:
    downhillEnding[peakIndex] = 1
    for earlierPeak in 0 .. peakIndex - 1:
      if peakHeights[earlierPeak] > peakHeights[peakIndex]:
        if downhillEnding[earlierPeak] + 1 > downhillEnding[peakIndex]:
          downhillEnding[peakIndex] = downhillEnding[earlierPeak] + 1
  var downhillStarting = newSeq[int](peakCount)
  var reverseIndex = peakCount - 1
  while reverseIndex >= 0:
    downhillStarting[reverseIndex] = 1
    for laterPeak in reverseIndex + 1 .. peakCount - 1:
      if peakHeights[laterPeak] < peakHeights[reverseIndex]:
        if downhillStarting[laterPeak] + 1 > downhillStarting[reverseIndex]:
          downhillStarting[reverseIndex] = downhillStarting[laterPeak] + 1
    reverseIndex -= 1
  var bestStrength = 0
  for peakIndex in 0 .. peakCount - 1:
    if downhillEnding[peakIndex] > bestStrength:
      bestStrength = downhillEnding[peakIndex]
  for landingPeak in robinIndex + 1 .. peakCount - 1:
    let batRoute = downhillEnding[robinIndex] + downhillStarting[landingPeak]
    if batRoute > bestStrength:
      bestStrength = batRoute
  appendOutput($bestStrength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first pass scans peaks forward.
The second pass scans peaks backward.
The final loop tests every legal bat landing.

## Complexity

Each pass compares each peak with every other peak.

| phase | time | space |
|---|---|---|
| input read | one pass over heights | one input string |
| subsequence passes | two n by n comparisons | two n-element arrays |
| bat routes | one pass over later peaks | constant extra space |

Both arrays are rebuilt for every test case.

| measure | Big O |
|---|---|
| time per case | O(n^2) |
| space per case | O(n) |

Enumerating jump paths would grow exponentially with the peak count.

Two subsequence passes give the quadratic answer.
