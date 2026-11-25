import strutils
import math
import algorithm

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type GainPair = object
  wallLength: float64
  extraDoubleArea: int64

proc comparePairs(left: GainPair, right: GainPair): int =
  if left.wallLength < right.wallLength:
    return -1
  if left.wallLength > right.wallLength:
    return 1
  if left.extraDoubleArea > right.extraDoubleArea:
    return -1
  if left.extraDoubleArea < right.extraDoubleArea:
    return 1
  return 0

proc prunePairs(candidates: var seq[GainPair]) =
  candidates.sort(comparePairs)
  var kept = newSeq[GainPair](0)
  var bestSoFar: int64 = -1
  for candidate in candidates:
    if candidate.extraDoubleArea > bestSoFar:
      kept.add candidate
      bestSoFar = candidate.extraDoubleArea
  candidates = kept

var vertexX = newSeq[int](0)
var vertexY = newSeq[int](0)
var prefixArea = newSeq[int64](0)

proc crossAt(firstIndex: int, secondIndex: int): int64 =
  return int64(vertexX[firstIndex]) * int64(vertexY[secondIndex]) -
    int64(vertexY[firstIndex]) * int64(vertexX[secondIndex])

proc wallDistance(firstIndex: int, secondIndex: int): float64 =
  let deltaX = float64(vertexX[firstIndex] - vertexX[secondIndex])
  let deltaY = float64(vertexY[firstIndex] - vertexY[secondIndex])
  return sqrt(deltaX * deltaX + deltaY * deltaY)

proc closingGain(startIndex: int, endIndex: int): int64 =
  return -(prefixArea[endIndex] - prefixArea[startIndex] +
    crossAt(endIndex, startIndex))

var caseNumber = 0
while true:
  let vertexCount = nextInt(inputData, scanPos)
  let budget = nextInt(inputData, scanPos)
  if vertexCount == 0 and budget == 0:
    break
  caseNumber += 1
  vertexX = newSeq[int](vertexCount)
  vertexY = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexX[vertexIndex] = nextInt(inputData, scanPos)
    vertexY[vertexIndex] = nextInt(inputData, scanPos)
  let doubledCount = vertexCount * 2
  vertexX.setLen(doubledCount + 1)
  vertexY.setLen(doubledCount + 1)
  for vertexIndex in vertexCount .. doubledCount:
    vertexX[vertexIndex] = vertexX[vertexIndex - vertexCount]
    vertexY[vertexIndex] = vertexY[vertexIndex - vertexCount]
  prefixArea = newSeq[int64](doubledCount + 1)
  for vertexIndex in 0 .. doubledCount - 1:
    prefixArea[vertexIndex + 1] = prefixArea[vertexIndex] +
      crossAt(vertexIndex, vertexIndex + 1)
  let tableWidth = doubledCount + 1
  var frontierTable = newSeq[seq[GainPair]](doubledCount * tableWidth)
  for startIndex in 0 .. doubledCount - 1:
    frontierTable[startIndex * tableWidth + startIndex + 1] = @[GainPair(
      wallLength: 0'f64, extraDoubleArea: 0'i64)]
  for span in 2 .. vertexCount:
    for startIndex in 0 .. doubledCount - span:
      let endIndex = startIndex + span
      var candidates = newSeq[GainPair](0)
      let directGain = closingGain(startIndex, endIndex)
      if directGain > 0'i64:
        candidates.add GainPair(wallLength: wallDistance(startIndex, endIndex),
                                extraDoubleArea: directGain)
      for middleIndex in startIndex + 1 .. endIndex - 1:
        let leftFrontier = frontierTable[startIndex * tableWidth + middleIndex]
        let rightFrontier = frontierTable[middleIndex * tableWidth + endIndex]
        for leftPair in leftFrontier:
          for rightPair in rightFrontier:
            candidates.add GainPair(
              wallLength: leftPair.wallLength + rightPair.wallLength,
              extraDoubleArea: leftPair.extraDoubleArea + rightPair.extraDoubleArea)
      prunePairs(candidates)
      frontierTable[startIndex * tableWidth + endIndex] = candidates
  var bestExtraArea = 0'i64
  for startIndex in 0 .. vertexCount - 1:
    let fullFrontier = frontierTable[startIndex * tableWidth + startIndex + vertexCount]
    for candidate in fullFrontier:
      if candidate.wallLength <= float64(budget) + 1e-9 and
          candidate.extraDoubleArea > bestExtraArea:
        bestExtraArea = candidate.extraDoubleArea
  let finalArea = float64(prefixArea[vertexCount] + bestExtraArea) / 2'f64
  appendOutput("Case " & $caseNumber & ": " & formatFloat(finalArea, ffDecimal, 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
