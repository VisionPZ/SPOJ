## Problem

Read several test cases, each holding up to 1000 temples. Each temple gives its north-west corner, its south-east corner, and one of E, W, S, N for its door. An evil spirit travels in a straight line from the altar at the rectangle center, out through the door. Print the ascending numbers of temples the spirit can leave, or print NONE when no temple qualifies.

| Quantity | Bound |
| --- | --- |
| Test cases | not stated |
| Temples per case | 1 to 1000 |
| Corner coordinates | 0 to 8000 |
| Time limit | 1318 ms |
| Memory limit | 1536 MB |

The temple count drives the design, since each temple needs its own escape test.

## Idea

Scale coordinates by four and rotate the scene until each temple faces east. The door admits a wedge of slopes, and each wall east of the altar blocks one angular interval. A scaled integer key preserves slope order, so a sweep finds a free slope in O(n log n) per temple, beating direction-by-direction tests.

## Why It Works

The door spans the middle half of its wall. The two extreme rays from the altar then have slopes h / (2w) and -h / (2w). Here w is the width and h the height. Scaling by four keeps the altar and both door ends at whole coordinates. A wall segment seen from the altar covers the slopes of its two ends, clipped to that wedge. Rotating the scene by a quarter turn maps north to east and advances the facing code. Each temple faces east in exactly one pass.

The slope of a wall end is its height minus the altar height, divided by its east distance from the altar. The program stores floor(height * 2^40 / distance) as an integer key. Distinct slopes differ by at least one key unit, because every distance is at most 32000. A begin event opens a blocked interval, and an end event closes it. A gap with no active interval lets the spirit through.

The script in `gen.py` computes the blocked slopes for temple 1 of the sample. Its wedge is (-1, 1).

| Temple blocking temple 1 | Low slope | High slope |
| --- | --- | --- |
| 2 | -6/11 = -0.5455 | -2/15 = -0.1333 |
| 4 | -6/17 = -0.3529 | 0 |
| 3 | 0 | 6/7 = 0.8571 |
| 5 | 6/35 = 0.1714 | 8/23 = 0.3478 |
| 6 | 8/17 = 0.4706 | 1 |

The first interval starts at -0.5455, which leaves (-1, -0.5455) free and profanes temple 1.

## Code

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The loops stop at the end of the one input buffer. Skipping non-digits absorbs the blank line between cases. The cost is one pass over the input bytes.

```nim
proc floorRatio(height, distance: int): int64 =
  let numerator = int64(height) * slopeScale
  let denominator = int64(distance)
  let quotient = numerator div denominator
  if numerator < 0 and numerator mod denominator != 0:
    return quotient - 1
  return quotient

proc packEvent(angleKey: int64, isBegin: bool): int64 =
  if isBegin: return angleKey * 2 + 1
  return angleKey * 2

proc unpackAngle(packed: int64): int64 =
  let quotient = packed div 2
  if packed < 0 and packed mod 2 != 0: return quotient - 1
  return quotient

proc quickSort(data: var openArray[int64], lowIndex, highIndex: int) =
  var leftIndex = lowIndex
  var rightIndex = highIndex
  let pivot = data[(leftIndex + rightIndex) div 2]
  while leftIndex <= rightIndex:
    while data[leftIndex] < pivot: leftIndex += 1
    while data[rightIndex] > pivot: rightIndex -= 1
    if leftIndex <= rightIndex:
      swap data[leftIndex], data[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex: quickSort(data, lowIndex, rightIndex)
  if leftIndex < highIndex: quickSort(data, leftIndex, highIndex)
```

The packed key sets the event type in its low bit. Floor division keeps the key ordered for negative slopes. The in-place sort avoids a fresh temporary buffer per temple.

```nim
  if events.len == 0: return true
  if events.len > 1: quickSort(events, 0, events.len - 1)
  var activeCount = 0
  var lastKey = lowKey
  for packed in events:
    let currentKey = unpackAngle(packed)
    if activeCount == 0 and lastKey < currentKey: return true
    lastKey = currentKey
    if (packed and 1) == 1: activeCount += 1
    else: activeCount -= 1
  return activeCount == 0 and lastKey < highKey
```

The loop visits one sorted event per wall end. End events precede begin events at equal angles, so a single touch never reads as a gap. Sorting and sweeping cost O(k log k) for k events.

```nim
  var escapes: seq[int] = @[]
  for k in 0..<4:
    for altar in altars:
      if altar.direction != 0: continue
      if canEscape(altar, hlines, vlines): escapes.add altar.id

    var nextHlines: seq[HLine] = @[]
    var nextVlines: seq[VLine] = @[]
    for hline in hlines:
      nextVlines.add(VLine(x: -hline.y, y1: hline.x1, y2: hline.x2))
    for vline in vlines:
      nextHlines.add(HLine(x1: -vline.y2, x2: -vline.y1, y: vline.x))
    hlines = nextHlines
    vlines = nextVlines

    for l in 0..<altars.len:
      let altar = altars[l]
      altars[l] = Altar(x1: -altar.y2, y1: altar.x1,
                        x2: -altar.y1, y2: altar.x2,
                        direction: (altar.direction + 1) mod 4,
                        id: altar.id)
```

The outer loop runs four quarter turns. The facing code advances with the walls, so each temple is tested once in its east-facing frame. Each turn rebuilds the wall lists in O(n).

## Complexity

Reading and scanning take time linear in the input size. Building walls costs O(n) per case, and testing one temple sorts up to O(n) events. The total is O(n^2 log n) time and O(n) space for walls and events. A naive version samples many directions and tests each against every wall, which costs more for the same n.
