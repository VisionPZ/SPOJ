# ALTARS — The Altars (SPOJ)
<https://www.spoj.com/problems/ALTARS/>

## Problem

Each case describes axis-aligned rectangles with a doorway centered on one wall.
Report which rectangles allow a straight ray from the center through the doorway without touching any wall.

The first line gives the case count. Each case gives n, then n lines with four integers and an entrance letter E, W, S, or N. Print the numbers of escaping temples in ascending order, or the word NONE.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Temples n | 1 to 1000 |
| Corner coordinates | 0 to 8000 |
| Judge time | 1.318 s |
| Judge memory | 1536 MB |

Integer slope keys avoid floating-point tests at this scale.

The sample input and its expected output follow byte for byte.

```
1
6
1 7 4 1 E
3 9 11 8 S
6 7 10 4 N
8 3 10 1 N
11 4 13 1 E
14 8 20 7 W
```

```
1
2
5
6
```


## Idea

Treat each wall as a blocked slope interval, like finding a clear angle between walls seen edge on.
The program collects slope events (begin and end marks for blocked angles) from walls ahead of the entrance. It sorts them and sweeps a counter to find a free angle. It repeats the sweep four times after rotating the whole scene by ninety degrees, which turns each entrance direction into the east case.
Each altar costs one event sort, so a case stays near O(n squared log n). Trying sample rays one by one cannot cover a continuous range of directions.
A slope sweep turns a geometric escape test into sorted integers.

## Why It Works

1. Coordinates are scaled by four, so an entrance is exactly half a wall and every slope key stays an integer.
2. A wall segment in front of the altar blocks one contiguous interval of slopes. Begin and end events mark that interval.
3. `floorRatio` computes a scaled slope key with integer division, which avoids floating-point drift.
4. Sorting events and sweeping an active count finds a free angular gap in linear time after the sort.
5. Rotating the scene by ninety degrees maps a north, west, or south entrance onto the east case.

Four terms describe the sweep.

| Term | Meaning |
| --- | --- |
| slope key | scaled vertical change per horizontal change |
| event | start or end of a blocked slope interval |
| active count | number of walls blocking the current angle |
| rotation | ninety-degree turn of the whole scene |

They show why a sorted list of events replaces a ray search.

A script check of temple 1 in the sample reads corners (1,7) and (4,1), scaled to (4,28) and (16,4).
Its center is (10,16), the half span is 6, and the doorway distance is 6.
The doorway spans slope keys from -1 to 1 in units of 2 to the fortieth power.
No wall ahead covers that whole span, so temple 1 escapes and appears in the output.

## Code

**Slope key helpers.**
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
```

`floorRatio` scales a height by 2 to the fortieth power before division. `packEvent` folds a begin flag into the low bit. `unpackAngle` recovers the key with a floor division.

**Escape sweep.**
```nim
proc canEscape(altar: Altar, hlines: seq[HLine], vlines: seq[VLine]): bool =
  let centerX = (altar.x1 + altar.x2) div 2
  let centerY = (altar.y1 + altar.y2) div 2
  let halfSpan = (altar.y2 - altar.y1) div 4
  let doorDistance = altar.x2 - centerX
  let lowKey = floorRatio(-halfSpan, doorDistance)
  let highKey = floorRatio(halfSpan, doorDistance)
  var events: seq[int64] = @[]

  for hline in hlines:
    if hline.x2 <= altar.x2: continue
    let localX1 = hline.x1 - centerX
    let localX2 = hline.x2 - centerX
    let localY = hline.y - centerY
    let rightKey = floorRatio(localY, localX2)
    if localY > 0:
      if rightKey >= highKey: continue
      events.add(packEvent(rightKey, true))
      if localX1 > 0:
        let leftKey = floorRatio(localY, localX1)
        if leftKey < highKey:
          events.add(packEvent(leftKey, false))
    elif localY < 0:
      if rightKey <= lowKey: continue
      events.add(packEvent(rightKey, false))
      if localX1 > 0:
        let leftKey = floorRatio(localY, localX1)
        if lowKey < leftKey:
          events.add(packEvent(leftKey, true))
        else:
          events.add(packEvent(lowKey, true))
      else:
        events.add(packEvent(lowKey, true))

  for vline in vlines:
    if vline.x <= altar.x2: continue
    let localX = vline.x - centerX
    let lowEnd = floorRatio(vline.y1 - centerY, localX)
    let highEnd = floorRatio(vline.y2 - centerY, localX)
    if not (lowEnd < highKey and lowKey < highEnd): continue
    if lowKey < lowEnd:
      events.add(packEvent(lowEnd, true))
    else:
      events.add(packEvent(lowKey, true))
    if highEnd < highKey:
      events.add(packEvent(highEnd, false))

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

The routine turns each wall segment into slope events. Only walls ahead of the entrance can matter. A zero active count over a free gap means the spirit escapes.

**Rotation driver.**
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

  if escapes.len == 0:
    appendOutput("NONE\n")
  else:
    escapes.sort(system.cmp[int])
    for idValue in escapes:
      appendOutput($(idValue))
      appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop tests altars facing east, then rotates every line and altar. Escaping ids are collected and sorted at the end. An empty result prints NONE.


## Complexity

Each altar sorts its own events, so the sweep cost is quadratic per case.

| Phase | Time | Space |
| --- | --- | --- |
| parse and scale walls | O(n) | wall arrays |
| event sort per altar | O(n log n) | one event list |
| four direction passes | O(n squared log n) | rotating arrays |

The rotation reuses the same sweep code for all four entrances.

Big O uses temple count n.

| Measure | Big O |
| --- | --- |
| time | O(n squared log n) |
| space | O(n) |

Testing infinitely many sample rays would never give a clean boundary, so the sweep wins.
