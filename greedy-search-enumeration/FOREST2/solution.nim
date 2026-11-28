import math

const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000
const fullTurn = 2.0 * PI
const angleEpsilon = 1e-12

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type TreeInfo = object
  centerDistance: float
  rayAngle: float
  halfAngle: float
  nearestDistance: float

type AngularInterval = tuple[firstAngle, lastAngle: float]

proc intervalCovers(intervals: seq[AngularInterval], firstAngle, lastAngle: float): bool =
  for interval in intervals:
    if interval.firstAngle <= firstAngle + angleEpsilon and
       interval.lastAngle >= lastAngle - angleEpsilon:
      return true
  return false

proc insertInterval(intervals: var seq[AngularInterval], firstAngle, lastAngle: float) =
  var merged = newSeq[AngularInterval](intervals.len + 1)
  var mergedCount = 0
  var currentFirst = firstAngle
  var currentLast = lastAngle
  var placed = false
  for existing in intervals:
    if existing.lastAngle < currentFirst - angleEpsilon:
      merged[mergedCount] = existing
      mergedCount += 1
    elif currentLast < existing.firstAngle - angleEpsilon:
      if not placed:
        merged[mergedCount] = (currentFirst, currentLast)
        mergedCount += 1
        placed = true
      merged[mergedCount] = existing
      mergedCount += 1
    else:
      if existing.firstAngle < currentFirst:
        currentFirst = existing.firstAngle
      if existing.lastAngle > currentLast:
        currentLast = existing.lastAngle
  if not placed:
    merged[mergedCount] = (currentFirst, currentLast)
    mergedCount += 1
  merged.setLen(mergedCount)
  intervals = merged

while true:
  let treeCount = nextInt(inputData, scanPos)
  if treeCount == 0:
    break
  var trees = newSeq[TreeInfo](treeCount)
  for treeIndex in 0 .. treeCount - 1:
    let centerX = float(nextInt(inputData, scanPos))
    let centerY = float(nextInt(inputData, scanPos))
    let radius = float(nextInt(inputData, scanPos))
    let distanceSquared = centerX * centerX + centerY * centerY
    let centerDistance = sqrt(distanceSquared)
    var rayAngle = arctan2(centerY, centerX)
    if rayAngle < 0.0:
      rayAngle += fullTurn
    let halfAngle = arcsin(radius / centerDistance)
    trees[treeIndex].centerDistance = centerDistance
    trees[treeIndex].rayAngle = rayAngle
    trees[treeIndex].halfAngle = halfAngle
    trees[treeIndex].nearestDistance = centerDistance - radius

  var sortIndex = 1
  while sortIndex < treeCount:
    let currentTree = trees[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and trees[previousIndex].centerDistance > currentTree.centerDistance:
      trees[previousIndex + 1] = trees[previousIndex]
      previousIndex -= 1
    trees[previousIndex + 1] = currentTree
    sortIndex += 1

  var coveredAngles: seq[AngularInterval] = @[]
  var bestDistance = 0.0
  for treeIndex in 0 .. treeCount - 1:
    let currentTree = trees[treeIndex]
    var firstAngle = currentTree.rayAngle - currentTree.halfAngle
    if firstAngle < 0.0:
      firstAngle += fullTurn
    let lastAngle = firstAngle + 2.0 * currentTree.halfAngle
    var visible = false
    if lastAngle <= fullTurn:
      visible = not intervalCovers(coveredAngles, firstAngle, lastAngle)
    else:
      visible = (not intervalCovers(coveredAngles, firstAngle, fullTurn)) or
                (not intervalCovers(coveredAngles, 0.0, lastAngle - fullTurn))
    if visible and currentTree.nearestDistance > bestDistance:
      bestDistance = currentTree.nearestDistance
    if lastAngle <= fullTurn:
      insertInterval(coveredAngles, firstAngle, lastAngle)
    else:
      insertInterval(coveredAngles, firstAngle, fullTurn)
      insertInterval(coveredAngles, 0.0, lastAngle - fullTurn)

  let scaledDistance = int64(bestDistance * float(decimalPlaces) + 0.5)
  var fractionDigits = $(scaledDistance mod decimalPlaces)
  while fractionDigits.len < 3:
    fractionDigits = "0" & fractionDigits
  appendOutput($(scaledDistance div decimalPlaces) & "." & fractionDigits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
