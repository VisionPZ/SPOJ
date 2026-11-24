{.passC: "-O3".}
{.optimization: speed.}
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
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

proc sortValues(values: var seq[int]) =
  for i in 1..<values.len:
    let key = values[i]
    var j = i - 1
    while j >= 0 and values[j] > key:
      values[j + 1] = values[j]
      j -= 1
    values[j + 1] = key

proc buildVertices(lengths: seq[int], startVertical: bool): seq[int] =
  var points: seq[int] = @[]
  var x = 0
  var y = 0
  points.add x
  points.add y
  for i in 0..<lengths.len:
    let step = lengths[i]
    let vertical = ((i mod 2) == 0) == startVertical
    if vertical:
      y += step
    else:
      x += step
    points.add x
    points.add y
  return points

proc signedArea(points: seq[int]): int64 =
  var areaSum: int64 = 0
  let count = points.len div 2
  for i in 0..<count:
    let nextIndex = (i + 1) mod count
    let x1 = int64(points[2 * i])
    let y1 = int64(points[2 * i + 1])
    let x2 = int64(points[2 * nextIndex])
    let y2 = int64(points[2 * nextIndex + 1])
    areaSum += x1 * y2 - x2 * y1
  return areaSum

proc indexOf(sortedValues: seq[int], target: int): int =
  var low = 0
  var high = sortedValues.len - 1
  while low <= high:
    let mid = (low + high) div 2
    if sortedValues[mid] < target:
      low = mid + 1
    elif sortedValues[mid] > target:
      high = mid - 1
    else:
      return mid
  return -1

proc floodFill(inside: var seq[bool], vWall: seq[bool], hWall: seq[bool],
               width: int, height: int) =
  var queue: seq[int] = @[]
  queue.add 0
  inside[0] = true
  var head = 0
  while head < queue.len:
    let cell = queue[head]
    head += 1
    let i = cell div height
    let j = cell mod height
    if i + 1 < width and vWall[(i + 1) * height + j] == false:
      let next = cell + height
      if not inside[next]:
        inside[next] = true
        queue.add next
    if i > 0 and vWall[i * height + j] == false:
      let next = cell - height
      if not inside[next]:
        inside[next] = true
        queue.add next
    if j + 1 < height and hWall[i * height + (j + 1)] == false:
      let next = cell + 1
      if not inside[next]:
        inside[next] = true
        queue.add next
    if j > 0 and hWall[i * height + j] == false:
      let next = cell - 1
      if not inside[next]:
        inside[next] = true
        queue.add next

proc collectSegments(points: seq[int], lengths: seq[int], startVertical: bool,
                     vSegX: var seq[int], vSegLow: var seq[int], vSegHigh: var seq[int],
                     hSegY: var seq[int], hSegLow: var seq[int], hSegHigh: var seq[int]) =
  var xs: seq[int] = @[]
  var ys: seq[int] = @[]
  for i in 0..<(points.len div 2):
    xs.add points[2 * i]
    ys.add points[2 * i + 1]
  sortValues(xs)
  sortValues(ys)
  var uniqueXs: seq[int] = @[]
  for value in xs:
    if uniqueXs.len == 0 or uniqueXs[uniqueXs.len - 1] != value:
      uniqueXs.add value
  var uniqueYs: seq[int] = @[]
  for value in ys:
    if uniqueYs.len == 0 or uniqueYs[uniqueYs.len - 1] != value:
      uniqueYs.add value
  var xCoords: seq[int] = @[]
  xCoords.add uniqueXs[0] - 1
  for value in uniqueXs:
    xCoords.add value
  xCoords.add uniqueXs[uniqueXs.len - 1] + 1
  var yCoords: seq[int] = @[]
  yCoords.add uniqueYs[0] - 1
  for value in uniqueYs:
    yCoords.add value
  yCoords.add uniqueYs[uniqueYs.len - 1] + 1
  let width = xCoords.len
  let height = yCoords.len
  var vWall = newSeq[bool](width * height)
  var hWall = newSeq[bool](width * height)
  var x = 0
  var y = 0
  for i in 0..<lengths.len:
    let step = lengths[i]
    let vertical = ((i mod 2) == 0) == startVertical
    let oldX = x
    let oldY = y
    if vertical:
      y += step
    else:
      x += step
    if vertical:
      let ix = indexOf(xCoords, x)
      let lo = min(oldY, y)
      let hi = max(oldY, y)
      for j in 0..<height - 1:
        if yCoords[j] >= lo and yCoords[j + 1] <= hi:
          vWall[ix * height + j] = true
    else:
      let jy = indexOf(yCoords, y)
      let lo = min(oldX, x)
      let hi = max(oldX, x)
      for k in 0..<width - 1:
        if xCoords[k] >= lo and xCoords[k + 1] <= hi:
          hWall[k * height + jy] = true
  var reached = newSeq[bool](width * height)
  floodFill(reached, vWall, hWall, width, height)
  for ix in 1..<width - 1:
    var runStart = -1
    for j in 0..<height - 1:
      let present = (not reached[(ix - 1) * height + j]) or (not reached[ix * height + j])
      if present:
        if runStart == -1:
          runStart = j
      else:
        if runStart != -1:
          vSegX.add xCoords[ix]
          vSegLow.add yCoords[runStart]
          vSegHigh.add yCoords[j]
          runStart = -1
    if runStart != -1:
      vSegX.add xCoords[ix]
      vSegLow.add yCoords[runStart]
      vSegHigh.add yCoords[height - 1]
  for jy in 1..<height - 1:
    var runStart = -1
    for i in 0..<width - 1:
      let present = (not reached[i * height + (jy - 1)]) or (not reached[i * height + jy])
      if present:
        if runStart == -1:
          runStart = i
      else:
        if runStart != -1:
          hSegY.add yCoords[jy]
          hSegLow.add xCoords[runStart]
          hSegHigh.add xCoords[i]
          runStart = -1
    if runStart != -1:
      hSegY.add yCoords[jy]
      hSegLow.add xCoords[runStart]
      hSegHigh.add xCoords[width - 1]

proc minCoverCount(coverSize: seq[seq[int]], universe: seq[seq[int]],
                   spans: seq[int], universeCount: int): int =
  if universeCount == 0:
    return 0
  let setCount = coverSize.len
  var greedyChosen: seq[int] = @[]
  var remaining = newSeq[bool](universeCount)
  for i in 0..<universeCount:
    remaining[i] = true
  var remainingCount = universeCount
  while remainingCount > 0:
    var bestSet = -1
    var bestGain = 0
    for j in 0..<setCount:
      var gain = 0
      for item in coverSize[j]:
        if remaining[item]:
          gain += 1
      if gain > bestGain:
        bestGain = gain
        bestSet = j
    if bestSet < 0:
      return 999999
    greedyChosen.add bestSet
    for item in coverSize[bestSet]:
      if remaining[item]:
        remaining[item] = false
        remainingCount -= 1
  var best = greedyChosen.len
  var order = newSeq[int](universeCount)
  for i in 0..<universeCount:
    order[i] = i
  for i in 1..<universeCount:
    let key = order[i]
    var k = i - 1
    while k >= 0 and spans[key] < spans[order[k]]:
      order[k + 1] = order[k]
      k -= 1
    order[k + 1] = key
  var bestGlobal = best

  proc packingBound(uncovered: seq[bool]): int =
    var avail = newSeq[bool](universeCount)
    for i in 0..<universeCount:
      avail[i] = uncovered[i]
    var count = 0
    for item in order:
      if avail[item]:
        count += 1
        for setIndex in universe[item]:
          for other in coverSize[setIndex]:
            avail[other] = false
    return count

  proc search(uncovered: seq[bool], depth: int) =
    if depth + packingBound(uncovered) >= bestGlobal:
      return
    var pivot = -1
    var pivotSize = 999999
    for i in 0..<universeCount:
      if uncovered[i] and universe[i].len < pivotSize:
        pivotSize = universe[i].len
        pivot = i
    if pivot < 0:
      if depth < bestGlobal:
        bestGlobal = depth
      return
    var candidates = newSeq[int]()
    for setIndex in universe[pivot]:
      candidates.add setIndex
    for i in 1..<candidates.len:
      let key = candidates[i]
      var gainKey = 0
      var gainPrev = 0
      for item in coverSize[key]:
        if uncovered[item]: gainKey += 1
      for item in coverSize[candidates[i - 1]]:
        if uncovered[item]: gainPrev += 1
      if gainKey > gainPrev:
        var k = i - 1
        while k >= 0:
          var gk = 0
          var gp = 0
          for item in coverSize[key]:
            if uncovered[item]: gk += 1
          for item in coverSize[candidates[k]]:
            if uncovered[item]: gp += 1
          if gk <= gp: break
          candidates[k + 1] = candidates[k]
          k -= 1
        candidates[k + 1] = key
    for setIndex in candidates:
      var nextUncovered = newSeq[bool](universeCount)
      for i in 0..<universeCount:
        nextUncovered[i] = uncovered[i]
      for item in coverSize[setIndex]:
        nextUncovered[item] = false
      if depth + 1 < bestGlobal:
        search(nextUncovered, depth + 1)

  var initial = newSeq[bool](universeCount)
  for i in 0..<universeCount:
    initial[i] = true
  search(initial, 0)
  return bestGlobal

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextSigned(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let sectionCount = nextSigned(inputData, scanPos)
  var lengths: seq[int] = @[]
  for i in 0..<sectionCount:
    lengths.add nextSigned(inputData, scanPos)
  let startVertical = signedArea(buildVertices(lengths, true)) < 0
  let vertices = buildVertices(lengths, startVertical)
  var vSegX: seq[int] = @[]
  var vSegLow: seq[int] = @[]
  var vSegHigh: seq[int] = @[]
  var hSegY: seq[int] = @[]
  var hSegLow: seq[int] = @[]
  var hSegHigh: seq[int] = @[]
  collectSegments(vertices, lengths, startVertical, vSegX, vSegLow, vSegHigh, hSegY, hSegLow, hSegHigh)
  let vCount = vSegX.len
  let hCount = hSegY.len
  var coverByH: seq[seq[int]] = @[]
  var coverByV: seq[seq[int]] = @[]
  for i in 0..<vCount:
    coverByH.add @[]
  for j in 0..<hCount:
    coverByV.add @[]
  for i in 0..<vCount:
    for j in 0..<hCount:
      if hSegLow[j] <= vSegX[i] and vSegX[i] <= hSegHigh[j] and
         vSegLow[i] <= hSegY[j] and hSegY[j] <= vSegHigh[i]:
        coverByH[i].add j
        coverByV[j].add i
  var vSpans: seq[int] = @[]
  var hSpans: seq[int] = @[]
  for i in 0..<vCount:
    vSpans.add vSegHigh[i] - vSegLow[i]
  for j in 0..<hCount:
    hSpans.add hSegHigh[j] - hSegLow[j]
  let firstPart = minCoverCount(coverByV, coverByH, vSpans, vCount)
  let secondPart = minCoverCount(coverByH, coverByV, hSpans, hCount)
  appendOutput($(firstPart + secondPart))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
