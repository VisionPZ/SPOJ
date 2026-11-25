const flushBlockBytes = 1 shl 17
const polygonModulus = 1234567

type
  PlanePoint = object
    pointX: int64
    pointY: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc pointBefore(first: PlanePoint, second: PlanePoint): bool =
  if first.pointY != second.pointY:
    return first.pointY < second.pointY
  return first.pointX < second.pointX

proc sortPointsByPosition(points: var seq[PlanePoint]) =
  for index in 1 .. points.len - 1:
    let carried = points[index]
    var prior = index - 1
    while prior >= 0 and pointBefore(carried, points[prior]):
      points[prior + 1] = points[prior]
      prior -= 1
    points[prior + 1] = carried

proc angleBefore(pivot: PlanePoint, first: PlanePoint, second: PlanePoint): bool =
  let firstX = first.pointX - pivot.pointX
  let firstY = first.pointY - pivot.pointY
  let secondX = second.pointX - pivot.pointX
  let secondY = second.pointY - pivot.pointY
  let turn = firstX * secondY - firstY * secondX
  return turn > 0

proc sortPointsByAngle(pivot: PlanePoint, points: var seq[PlanePoint]) =
  for index in 1 .. points.len - 1:
    let carried = points[index]
    var prior = index - 1
    while prior >= 0 and angleBefore(pivot, carried, points[prior]):
      points[prior + 1] = points[prior]
      prior -= 1
    points[prior + 1] = carried

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  var points = newSeq[PlanePoint](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    points[pointIndex].pointX = int64(nextInt(inputData, scanPos))
    points[pointIndex].pointY = int64(nextInt(inputData, scanPos))
  sortPointsByPosition(points)
  var convexCount: int64 = 0
  for pivotIndex in 0 .. pointCount - 1:
    let pivot = points[pivotIndex]
    var upperPoints = newSeq[PlanePoint]()
    for laterIndex in pivotIndex + 1 .. pointCount - 1:
      upperPoints.add points[laterIndex]
    sortPointsByAngle(pivot, upperPoints)
    let upperCount = upperPoints.len
    if upperCount < 2:
      continue
    var chainCounts = newSeq[int](upperCount * upperCount)
    for lastIndex in 0 .. upperCount - 1:
      for nextIndex in 0 .. lastIndex - 1:
        let nextToLast = upperPoints[nextIndex]
        let target = upperPoints[lastIndex]
        let countIndex = nextIndex * upperCount + lastIndex
        chainCounts[countIndex] = (chainCounts[countIndex] + 1) mod polygonModulus
        for earlierIndex in 0 .. nextIndex - 1:
          let earlier = upperPoints[earlierIndex]
          let incomingX = nextToLast.pointX - earlier.pointX
          let incomingY = nextToLast.pointY - earlier.pointY
          let outgoingX = target.pointX - nextToLast.pointX
          let outgoingY = target.pointY - nextToLast.pointY
          let turn = incomingX * outgoingY - incomingY * outgoingX
          if turn > 0:
            let sourceIndex = earlierIndex * upperCount + nextIndex
            chainCounts[countIndex] = (chainCounts[countIndex] + chainCounts[sourceIndex]) mod polygonModulus
    for firstIndex in 0 .. upperCount - 1:
      for secondIndex in firstIndex + 1 .. upperCount - 1:
        convexCount = (convexCount + int64(chainCounts[firstIndex * upperCount + secondIndex])) mod int64(polygonModulus)
  appendOutput($convexCount & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
