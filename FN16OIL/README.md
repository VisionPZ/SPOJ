# FN16OIL — Oil (SPOJ)

<https://www.spoj.com/problems/FN16OIL/>

## Problem

Horizontal oil deposits lie at different depths. A single straight well starts at the surface and can hit any deposit it crosses, endpoints included. Find the largest total width one well can reach.

Input holds test cases until end of file. Each case starts with the deposit count, then one line per deposit with two x endpoints and a depth y. The endpoints may appear in either order. Output the best total width on its own line per case.

| item | bound |
|---|---|
| deposits per case | 1 to 2000 |
| endpoint coordinates | -1000000 to 1000000 |
| depth | 1 to 1000000 |
| judge limit | 90000 ms, 1536 MB |

The deposit count drives the design, since candidate wells must be checked efficiently.

The exact sample input is:

    5
    100 180 20
    30 60 30
    70 110 40
    10 40 50
    0 80 70
    3
    50 60 10
    -42 -42 20
    25 0 10

The exact sample output is:

    200
    25

## Idea

Rotate a well like a flashlight beam around a hinge: an optimal well can always touch some deposit endpoint. Through that endpoint, every deposit allows a range of slopes, which is one interval on a number line. Sweep those intervals to find the slope hitting the most total width.

The takeaway is to replace a 2D search with many one-dimensional interval sweeps.

## Why It Works

1. Sliding and rotating an optimal well until it touches an endpoint keeps every hit.
2. A well through point (ax, ay) has x = ax + slope(y - ay) at depth y.
3. That value lies in a deposit exactly when the slope lies in one interval.
4. Interval endpoints are ratios, compared exactly by cross multiplication.
5. Sorting starts before ends at equal ratios counts shared endpoints, as the statement allows.

| term | meaning |
|---|---|
| `anchorX` | x coordinate of the endpoint used as hinge |
| `depthGap` | deposit depth minus anchor depth |
| `OilEvent` | one interval boundary with its signed weight |
| `alwaysHit` | width of same-depth deposits containing the hinge |
| `bestTotal` | largest width found over all hinges |

The table shows that every event carries a rational slope and a weight.

A script trace of the sample follows:

    hinge (100,20) on the widest deposit
    interval for depth 30 deposit: [30-100, 60-100]/10 = [-7, -4]
    interval for depth 40 deposit: [70-100, 110-100]/20 = [-1.5, 0.5]
    sweep finds a slope that also reaches the depth 50 and 70 deposits
    total width 80+30+40+50 = 200

The trace explains the first sample answer of 200.

## Code

**Input and scanning.** The reader parses signed coordinates for every case.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false
```

The scanner handles a leading minus for negative x values.
The empty scan returns zero, which ends the case loop via the probe.
Deposits are normalized so the left endpoint is never larger.

**Buffered output.** One string collects the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 131072 bytes.
A final flush writes any remaining bytes.
Each test case adds one line.

**Slope ordering.** Events are compared as exact fractions.

```nim
type OilEvent = object
  numerator: int64
  denominator: int64
  eventKind: int
  weight: int64

proc compareEvents(first: OilEvent, second: OilEvent): int =
  let leftProduct = first.numerator * second.denominator
  let rightProduct = second.numerator * first.denominator
  if leftProduct < rightProduct:
    return -1
  elif leftProduct > rightProduct:
    return 1
  elif first.eventKind < second.eventKind:
    return -1
  elif first.eventKind > second.eventKind:
    return 1
  return 0
```

Denominators stay positive after normalizing the depth gap.
Cross products stay below 4e12 and fit in 64 bits.
Start events sort before end events at the same slope.

**Interval sweep.** Each endpoint produces one slope sweep.

```nim
while hasMoreData(inputData, scanPos):
  let depositCount = nextInt(inputData, scanPos)
  var leftEnds = newSeq[int](depositCount)
  var rightEnds = newSeq[int](depositCount)
  var depths = newSeq[int](depositCount)
  for depositIndex in 0 .. depositCount - 1:
    let firstEnd = nextInt(inputData, scanPos)
    let secondEnd = nextInt(inputData, scanPos)
    if firstEnd <= secondEnd:
      leftEnds[depositIndex] = firstEnd
      rightEnds[depositIndex] = secondEnd
    else:
      leftEnds[depositIndex] = secondEnd
      rightEnds[depositIndex] = firstEnd
    depths[depositIndex] = nextInt(inputData, scanPos)
  var bestTotal: int64 = 0
  var events = newSeq[OilEvent](2 * depositCount)
  for anchorIndex in 0 .. depositCount - 1:
    for anchorSide in 0 .. 1:
      var anchorX = leftEnds[anchorIndex]
      if anchorSide == 1:
        anchorX = rightEnds[anchorIndex]
      let anchorY = depths[anchorIndex]
      events.setLen(2 * depositCount)
      var alwaysHit: int64 = 0
      var eventCount = 0
      for depositIndex in 0 .. depositCount - 1:
        let depthGap = depths[depositIndex] - anchorY
        let depositWidth = int64(rightEnds[depositIndex] - leftEnds[depositIndex])
        if depthGap == 0:
          if leftEnds[depositIndex] <= anchorX and anchorX <= rightEnds[depositIndex]:
            alwaysHit += depositWidth
          continue
        var lowerNumerator = 0
        var upperNumerator = 0
        var denominator = depthGap
        if depthGap > 0:
          lowerNumerator = leftEnds[depositIndex] - anchorX
          upperNumerator = rightEnds[depositIndex] - anchorX
        else:
          lowerNumerator = anchorX - rightEnds[depositIndex]
          upperNumerator = anchorX - leftEnds[depositIndex]
          denominator = -depthGap
        events[eventCount] = OilEvent(numerator: int64(lowerNumerator),
                                      denominator: int64(denominator),
                                      eventKind: 0, weight: depositWidth)
        eventCount += 1
        events[eventCount] = OilEvent(numerator: int64(upperNumerator),
                                      denominator: int64(denominator),
                                      eventKind: 1, weight: -depositWidth)
        eventCount += 1
      events.setLen(eventCount)
      events.sort(compareEvents)
      var currentTotal = alwaysHit
      if currentTotal > bestTotal:
        bestTotal = currentTotal
      for eventIndex in 0 .. eventCount - 1:
        currentTotal += events[eventIndex].weight
        if currentTotal > bestTotal:
          bestTotal = currentTotal
  appendOutput($bestTotal)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both endpoints of every deposit serve as hinges.
Deposits at the anchor depth contribute only if they contain that x.
The sweep adds widths on entry and removes them on exit.
The best running total across all sweeps is the answer.

## Complexity

There are two endpoints per deposit, and each endpoint sweeps all deposits.

| phase | time | space |
|---|---|---|
| input read | one pass over all triples | one input string |
| endpoint sweeps | 2n sweeps of n intervals | three deposit arrays |
| sorting | 2n sorts of 2n events | one event array |
| output | one write per full block | block buffer |

The sorting step dominates the run.

| measure | Big O |
|---|---|
| time | O(n^2 log n) per case |
| space | O(n) |

Trying wells on a dense grid would miss narrow optimal bands and cost more.
The takeaway is that exact rational sweeps replace an imprecise 2D search.
