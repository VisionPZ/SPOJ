const flushBlockBytes = 1 shl 17
const probabilityEpsilon = 1e-12

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

proc multiplyMatrices(left, right: seq[float], size: int): seq[float] =
  result = newSeq[float](size * size)
  for row in 0 .. size - 1:
    let rowBase = row * size
    for middle in 0 .. size - 1:
      let leftValue = left[rowBase + middle]
      if leftValue == 0.0:
        continue
      let middleBase = middle * size
      for column in 0 .. size - 1:
        result[rowBase + column] = result[rowBase + column] + leftValue * right[middleBase + column]

proc multiplyRowsMatrix(rows, matrix: seq[float], rowCount, size: int): seq[float] =
  result = newSeq[float](rowCount * size)
  for row in 0 .. rowCount - 1:
    let rowBase = row * size
    for source in 0 .. size - 1:
      let sourceValue = rows[rowBase + source]
      if sourceValue == 0.0:
        continue
      let sourceBase = source * size
      for target in 0 .. size - 1:
        result[rowBase + target] = result[rowBase + target] + sourceValue * matrix[sourceBase + target]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let positionCount = nextInt(inputData, scanPos)
  let pathCount = nextInt(inputData, scanPos)
  var neighborWeights = newSeq[seq[float]](positionCount)
  for position in 0 .. positionCount - 1:
    neighborWeights[position] = newSeq[float](positionCount)
  for pathIndex in 0 .. pathCount - 1:
    let firstPosition = nextInt(inputData, scanPos)
    let secondPosition = nextInt(inputData, scanPos)
    let joy = float(nextInt(inputData, scanPos))
    let snow = float(nextInt(inputData, scanPos))
    let weight = joy / snow
    neighborWeights[firstPosition][secondPosition] = weight
    neighborWeights[secondPosition][firstPosition] = weight

  let queryCount = nextInt(inputData, scanPos)
  var queryTimes = newSeq[int](queryCount)
  var queryStarts = newSeq[seq[int]](queryCount)
  var largestTime = 0
  for queryIndex in 0 .. queryCount - 1:
    queryTimes[queryIndex] = nextInt(inputData, scanPos)
    let startingCount = nextInt(inputData, scanPos)
    if queryTimes[queryIndex] > largestTime:
      largestTime = queryTimes[queryIndex]
    queryStarts[queryIndex] = newSeq[int](startingCount)
    for startIndex in 0 .. startingCount - 1:
      queryStarts[queryIndex][startIndex] = nextInt(inputData, scanPos)

  var transition = newSeq[float](positionCount * positionCount)
  for position in 0 .. positionCount - 1:
    var totalWeight = 0.0
    for neighbor in 0 .. positionCount - 1:
      totalWeight = totalWeight + neighborWeights[position][neighbor]
    if totalWeight > 0.0:
      for neighbor in 0 .. positionCount - 1:
        transition[position * positionCount + neighbor] = neighborWeights[position][neighbor] / totalWeight

  var bitCount = 0
  while (1 shl bitCount) <= largestTime:
    bitCount += 1
  var powers = newSeq[seq[float]](bitCount)
  if bitCount > 0:
    powers[0] = transition
    for bitIndex in 1 .. bitCount - 1:
      powers[bitIndex] = multiplyMatrices(powers[bitIndex - 1], powers[bitIndex - 1], positionCount)

  appendOutput("Scenario #" & $(caseIndex + 1) & ":")
  outputBuffer.add "\n\n"
  for queryIndex in 0 .. queryCount - 1:
    let starts = queryStarts[queryIndex]
    var rows = newSeq[float](starts.len * positionCount)
    for startIndex in 0 .. starts.len - 1:
      let startPosition = starts[startIndex]
      if startPosition >= 0 and startPosition < positionCount:
        rows[startIndex * positionCount + startPosition] = 1.0
    var elapsed = queryTimes[queryIndex]
    var bitIndex = 0
    while elapsed > 0:
      if (elapsed and 1) == 1:
        rows = multiplyRowsMatrix(rows, powers[bitIndex], starts.len, positionCount)
      elapsed = elapsed shr 1
      bitIndex += 1
    for startIndex in 0 .. starts.len - 1:
      let rowBase = startIndex * positionCount
      var bestPosition = -1
      var bestProbability = 0.0
      for position in 0 .. positionCount - 1:
        let probability = rows[rowBase + position]
        if probability > bestProbability + probabilityEpsilon:
          bestProbability = probability
          bestPosition = position
      if startIndex > 0:
        appendOutput(" ")
      appendOutput($bestPosition)
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
