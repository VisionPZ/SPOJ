import algorithm
import math
import strutils

const flushBlockBytes = 1 shl 17
const unreachableDistance = 1e100

type
  GeometryLine = object
    aCoeff: int64
    bCoeff: int64
    offset: int64
  GeometryPoint = object
    xNumerator: int64
    yNumerator: int64
    denominator: int64
  IntersectionRecord = object
    pointValue: GeometryPoint
    firstLine: int
    secondLine: int

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

proc compareLines(leftLine: GeometryLine, rightLine: GeometryLine): int =
  if leftLine.aCoeff != rightLine.aCoeff:
    if leftLine.aCoeff < rightLine.aCoeff:
      return -1
    return 1
  if leftLine.bCoeff != rightLine.bCoeff:
    if leftLine.bCoeff < rightLine.bCoeff:
      return -1
    return 1
  if leftLine.offset != rightLine.offset:
    if leftLine.offset < rightLine.offset:
      return -1
    return 1
  return 0

proc comparePoints(leftPoint: GeometryPoint, rightPoint: GeometryPoint): int =
  let leftCompare = leftPoint.xNumerator * rightPoint.denominator
  let rightCompare = rightPoint.xNumerator * leftPoint.denominator
  if leftCompare != rightCompare:
    if leftCompare < rightCompare:
      return -1
    return 1
  let leftVertical = leftPoint.yNumerator * rightPoint.denominator
  let rightVertical = rightPoint.yNumerator * leftPoint.denominator
  if leftVertical != rightVertical:
    if leftVertical < rightVertical:
      return -1
    return 1
  return 0

proc normalizedPoint(xNumerator: int64, yNumerator: int64, denominatorValue: int64): GeometryPoint =
  var nx = xNumerator
  var ny = yNumerator
  var den = denominatorValue
  if den < 0:
    nx = -nx
    ny = -ny
    den = -den
  var divisor = gcd(gcd(abs(nx), abs(ny)), den)
  if divisor == 0:
    divisor = 1
  return GeometryPoint(xNumerator: nx div divisor, yNumerator: ny div divisor, denominator: den div divisor)

proc collectLines(electrodes: seq[array[4, int]], startX: int64, startY: int64, targetX: int64, targetY: int64): seq[GeometryLine] =
  var candidates = newSeq[GeometryLine]()
  for electrode in electrodes:
    var directionX = int64(electrode[2] - electrode[0])
    var directionY = int64(electrode[3] - electrode[1])
    if directionX == 0 and directionY == 0:
      continue
    let commonDivisor = gcd(abs(directionX), abs(directionY))
    directionX = directionX div commonDivisor
    directionY = directionY div commonDivisor
    if directionX < 0 or (directionX == 0 and directionY < 0):
      directionX = -directionX
      directionY = -directionY
    let firstOffset = directionX * int64(electrode[0]) + directionY * int64(electrode[1])
    let secondOffset = directionX * int64(electrode[2]) + directionY * int64(electrode[3])
    let lowerOffset = min(firstOffset, secondOffset)
    let upperOffset = max(firstOffset, secondOffset)
    var trialOffsets = [lowerOffset, upperOffset, directionX * startX + directionY * startY, directionX * targetX + directionY * targetY]
    for trialIndex in 0 .. 3:
      let trialOffset = trialOffsets[trialIndex]
      if trialOffset >= lowerOffset and trialOffset <= upperOffset:
        candidates.add GeometryLine(aCoeff: directionX, bCoeff: directionY, offset: trialOffset)
  candidates.sort(compareLines)
  var uniqueLines = newSeq[GeometryLine]()
  for candidate in candidates:
    if uniqueLines.len == 0 or compareLines(uniqueLines[uniqueLines.len - 1], candidate) != 0:
      uniqueLines.add candidate
  return uniqueLines

var heapDistances = newSeq[float]()
var heapNodes = newSeq[int]()

proc heapPush(distanceValue: float, nodeIndex: int) =
  heapDistances.add distanceValue
  heapNodes.add nodeIndex
  var childIndex = heapNodes.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapDistances[parentIndex] <= heapDistances[childIndex]:
      break
    swap heapDistances[parentIndex], heapDistances[childIndex]
    swap heapNodes[parentIndex], heapNodes[childIndex]
    childIndex = parentIndex

proc heapPop(): (float, int) =
  let resultDistance = heapDistances[0]
  let resultNode = heapNodes[0]
  let lastIndex = heapNodes.len - 1
  heapDistances[0] = heapDistances[lastIndex]
  heapNodes[0] = heapNodes[lastIndex]
  heapDistances.setLen lastIndex
  heapNodes.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftChild = 2 * parentIndex + 1
    if leftChild >= heapNodes.len:
      break
    let rightChild = leftChild + 1
    var smallestChild = leftChild
    if rightChild < heapNodes.len and heapDistances[rightChild] < heapDistances[leftChild]:
      smallestChild = rightChild
    if heapDistances[parentIndex] <= heapDistances[smallestChild]:
      break
    swap heapDistances[parentIndex], heapDistances[smallestChild]
    swap heapNodes[parentIndex], heapNodes[smallestChild]
    parentIndex = smallestChild
  return (resultDistance, resultNode)

proc shortestDistance(lines: seq[GeometryLine], startPoint: GeometryPoint, targetPoint: GeometryPoint): float =
  var records = newSeq[IntersectionRecord]()
  for firstIndex in 0 .. lines.len - 1:
    for secondIndex in firstIndex + 1 .. lines.len - 1:
      let firstLine = lines[firstIndex]
      let secondLine = lines[secondIndex]
      let determinant = firstLine.aCoeff * secondLine.bCoeff - secondLine.aCoeff * firstLine.bCoeff
      if determinant == 0:
        continue
      let xTop = firstLine.offset * secondLine.bCoeff - secondLine.offset * firstLine.bCoeff
      let yTop = firstLine.aCoeff * secondLine.offset - secondLine.aCoeff * firstLine.offset
      let crossing = normalizedPoint(xTop, yTop, determinant)
      records.add IntersectionRecord(pointValue: crossing, firstLine: firstIndex, secondLine: secondIndex)
  records.add IntersectionRecord(pointValue: startPoint, firstLine: -1, secondLine: -1)
  records.add IntersectionRecord(pointValue: targetPoint, firstLine: -1, secondLine: -1)
  records.sort(proc(leftRecord: IntersectionRecord, rightRecord: IntersectionRecord): int = comparePoints(leftRecord.pointValue, rightRecord.pointValue))
  var nodePoints = newSeq[GeometryPoint]()
  for record in records:
    if nodePoints.len == 0 or comparePoints(nodePoints[nodePoints.len - 1], record.pointValue) != 0:
      nodePoints.add record.pointValue
  var startNode = -1
  var targetNode = -1
  for nodeIndex in 0 .. nodePoints.len - 1:
    if comparePoints(nodePoints[nodeIndex], startPoint) == 0:
      startNode = nodeIndex
    if comparePoints(nodePoints[nodeIndex], targetPoint) == 0:
      targetNode = nodeIndex
  if startNode < 0 or targetNode < 0:
    return unreachableDistance
  var nodesOnLine = newSeq[seq[int]]()
  for lineIndex in 0 .. lines.len - 1:
    nodesOnLine.add newSeq[int]()
  for nodeIndex in 0 .. nodePoints.len - 1:
    let pointValue = nodePoints[nodeIndex]
    for lineIndex in 0 .. lines.len - 1:
      let lineValue = lines[lineIndex]
      if lineValue.aCoeff * pointValue.xNumerator + lineValue.bCoeff * pointValue.yNumerator == lineValue.offset * pointValue.denominator:
        nodesOnLine[lineIndex].add nodeIndex
  var adjacency = newSeq[seq[(int, float)]]()
  for nodeIndex in 0 .. nodePoints.len - 1:
    adjacency.add newSeq[(int, float)]()
  for lineIndex in 0 .. lines.len - 1:
    let lineValue = lines[lineIndex]
    var onLine = nodesOnLine[lineIndex]
    onLine.sort(proc(leftNode: int, rightNode: int): int =
      let leftPoint = nodePoints[leftNode]
      let rightPoint = nodePoints[rightNode]
      let leftParameter = -lineValue.bCoeff * leftPoint.xNumerator + lineValue.aCoeff * leftPoint.yNumerator
      let rightParameter = -lineValue.bCoeff * rightPoint.xNumerator + lineValue.aCoeff * rightPoint.yNumerator
      let leftCompare = leftParameter * rightPoint.denominator
      let rightCompare = rightParameter * leftPoint.denominator
      if leftCompare < rightCompare:
        return -1
      if leftCompare > rightCompare:
        return 1
      return 0)
    for positionIndex in 0 .. onLine.len - 2:
      let firstNode = onLine[positionIndex]
      let secondNode = onLine[positionIndex + 1]
      let firstPoint = nodePoints[firstNode]
      let secondPoint = nodePoints[secondNode]
      let firstX = float(firstPoint.xNumerator) / float(firstPoint.denominator)
      let firstY = float(firstPoint.yNumerator) / float(firstPoint.denominator)
      let secondX = float(secondPoint.xNumerator) / float(secondPoint.denominator)
      let secondY = float(secondPoint.yNumerator) / float(secondPoint.denominator)
      let segmentLength = sqrt((secondX - firstX) * (secondX - firstX) + (secondY - firstY) * (secondY - firstY))
      adjacency[firstNode].add (secondNode, segmentLength)
      adjacency[secondNode].add (firstNode, segmentLength)
  var distances = newSeq[float](nodePoints.len)
  for nodeIndex in 0 .. nodePoints.len - 1:
    distances[nodeIndex] = unreachableDistance
  distances[startNode] = 0.0
  heapDistances.setLen 0
  heapNodes.setLen 0
  heapPush(0.0, startNode)
  while heapNodes.len > 0:
    let poppedEntry = heapPop()
    let currentDistance = poppedEntry[0]
    let currentNode = poppedEntry[1]
    if currentDistance > distances[currentNode] + 1e-9:
      continue
    if currentNode == targetNode:
      break
    for edgeEntry in adjacency[currentNode]:
      let nextNode = edgeEntry[0]
      let segmentLength = edgeEntry[1]
      let candidateDistance = currentDistance + segmentLength
      if candidateDistance < distances[nextNode] - 1e-9:
        distances[nextNode] = candidateDistance
        heapPush(candidateDistance, nextNode)
  return distances[targetNode]

var caseNumber = 1
while true:
  let electrodeCount = nextInt(inputData, scanPos)
  if electrodeCount == 0:
    break
  let startX = int64(nextInt(inputData, scanPos))
  let startY = int64(nextInt(inputData, scanPos))
  let targetX = int64(nextInt(inputData, scanPos))
  let targetY = int64(nextInt(inputData, scanPos))
  var electrodes = newSeq[array[4, int]]()
  for electrodeIndex in 0 .. electrodeCount - 1:
    var electrode: array[4, int]
    for coordinateIndex in 0 .. 3:
      electrode[coordinateIndex] = nextInt(inputData, scanPos)
    electrodes.add electrode
  let startPoint = normalizedPoint(startX, startY, 1)
  let targetPoint = normalizedPoint(targetX, targetY, 1)
  var resultText = "Impossible"
  if comparePoints(startPoint, targetPoint) == 0:
    resultText = "0.00000"
  else:
    let lines = collectLines(electrodes, startX, startY, targetX, targetY)
    if lines.len > 0:
      let bestDistance = shortestDistance(lines, startPoint, targetPoint)
      if bestDistance < unreachableDistance / 2:
        resultText = formatFloat(bestDistance, ffDecimal, 5)
  appendOutput("Case " & $caseNumber & ": " & resultText)
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
