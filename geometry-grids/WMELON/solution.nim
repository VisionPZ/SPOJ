const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCoordinate = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc solveCase(plantCount: int, fruitGoal: int, xValues: seq[int],
               yValues: seq[int], fruitCounts: seq[int]): int =
  var xSeen = newSeq[bool](maxCoordinate + 1)
  var ySeen = newSeq[bool](maxCoordinate + 1)
  for j in 0..<plantCount:
    xSeen[xValues[j]] = true
    ySeen[yValues[j]] = true
  var xCoords: seq[int] = @[]
  var yCoords: seq[int] = @[]
  var xSlot = newSeq[int](maxCoordinate + 1)
  var ySlot = newSeq[int](maxCoordinate + 1)
  for k in 1..maxCoordinate:
    if xSeen[k]:
      xSlot[k] = xCoords.len
      xCoords.add k
    if ySeen[k]:
      ySlot[k] = yCoords.len
      yCoords.add k
  let xCount = xCoords.len
  let yCount = yCoords.len
  var field = newSeq[int](xCount * yCount)
  for j in 0..<plantCount:
    field[xSlot[xValues[j]] * yCount + ySlot[yValues[j]]] += fruitCounts[j]
  for k in 0..<yCount:
    var rowTotal = 0
    for j in 0..<xCount:
      rowTotal += field[j * yCount + k]
    if rowTotal >= fruitGoal: return 0
  for j in 0..<xCount:
    var colTotal = 0
    for k in 0..<yCount:
      colTotal += field[j * yCount + k]
    if colTotal >= fruitGoal: return 0
  var best = maxCoordinate * maxCoordinate
  var strip = newSeq[int](yCount)
  for leftX in 0..<xCount:
    for k in 0..<yCount:
      strip[k] = 0
    for rightX in leftX..<xCount:
      let width = xCoords[rightX] - xCoords[leftX]
      if width >= best: break
      let rowBase = rightX * yCount
      var stripTotal = 0
      for k in 0..<yCount:
        strip[k] += field[rowBase + k]
        stripTotal += strip[k]
      if stripTotal < fruitGoal: continue
      var bottom = 0
      var collected = 0
      for top in 0..<yCount:
        collected += strip[top]
        while collected - strip[bottom] >= fruitGoal:
          collected -= strip[bottom]
          bottom += 1
        if collected >= fruitGoal:
          let area = width * (yCoords[top] - yCoords[bottom])
          if area < best:
            best = area
            if best == 0: return 0
  return best

let caseCount = nextInt(inputData, i)
for caseIndex in 0..<caseCount:
  let plantCount = nextInt(inputData, i)
  let fruitGoal = nextInt(inputData, i)
  var xValues = newSeq[int](plantCount)
  var yValues = newSeq[int](plantCount)
  var fruitCounts = newSeq[int](plantCount)
  for j in 0..<plantCount:
    xValues[j] = nextInt(inputData, i)
    yValues[j] = nextInt(inputData, i)
    fruitCounts[j] = nextInt(inputData, i)
  appendOutput($(solveCase(plantCount, fruitGoal, xValues, yValues, fruitCounts)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
