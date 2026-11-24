{.push checks: off.}
{.passC: "-O3".}

import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const slopeScale = int64(1) shl 40

type
  HLine = object
    x1: int
    x2: int
    y: int
  VLine = object
    x: int
    y1: int
    y2: int
  Altar = object
    x1: int
    y1: int
    x2: int
    y2: int
    direction: int
    id: int

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextDir(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'E' and data[pos] != 'W' and
        data[pos] != 'S' and data[pos] != 'N':
    pos += 1
  let foundDir = data[pos]
  pos += 1
  return foundDir

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let templeCount = nextInt(inputData, scanPos)
  var hlines: seq[HLine] = @[]
  var vlines: seq[VLine] = @[]
  var altars: seq[Altar] = @[]

  for j in 0..<templeCount:
    var westX = nextInt(inputData, scanPos)
    var northY = nextInt(inputData, scanPos)
    var eastX = nextInt(inputData, scanPos)
    var southY = nextInt(inputData, scanPos)
    let door = nextDir(inputData, scanPos)
    westX *= 4
    northY *= 4
    eastX *= 4
    southY *= 4
    let spanX = eastX - westX
    let spanY = northY - southY
    var facing = 0
    case door
    of 'E':
      facing = 0
      hlines.add(HLine(x1: westX, x2: eastX, y: southY))
      hlines.add(HLine(x1: westX, x2: eastX, y: northY))
      vlines.add(VLine(x: westX, y1: southY, y2: northY))
      vlines.add(VLine(x: eastX, y1: southY, y2: southY + spanY div 4))
      vlines.add(VLine(x: eastX, y1: northY - spanY div 4, y2: northY))
    of 'N':
      facing = 1
      vlines.add(VLine(x: westX, y1: southY, y2: northY))
      vlines.add(VLine(x: eastX, y1: southY, y2: northY))
      hlines.add(HLine(x1: westX, x2: eastX, y: southY))
      hlines.add(HLine(x1: westX, x2: westX + spanX div 4, y: northY))
      hlines.add(HLine(x1: eastX - spanX div 4, x2: eastX, y: northY))
    of 'W':
      facing = 2
      hlines.add(HLine(x1: westX, x2: eastX, y: southY))
      hlines.add(HLine(x1: westX, x2: eastX, y: northY))
      vlines.add(VLine(x: eastX, y1: southY, y2: northY))
      vlines.add(VLine(x: westX, y1: southY, y2: southY + spanY div 4))
      vlines.add(VLine(x: westX, y1: northY - spanY div 4, y2: northY))
    else:
      facing = 3
      vlines.add(VLine(x: westX, y1: southY, y2: northY))
      vlines.add(VLine(x: eastX, y1: southY, y2: northY))
      hlines.add(HLine(x1: westX, x2: eastX, y: northY))
      hlines.add(HLine(x1: westX, x2: westX + spanX div 4, y: southY))
      hlines.add(HLine(x1: eastX - spanX div 4, x2: eastX, y: southY))
    altars.add(Altar(x1: westX, y1: southY, x2: eastX, y2: northY,
                     direction: facing, id: j + 1))

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
