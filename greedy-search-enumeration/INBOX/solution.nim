const flushBlockBytes = 1 shl 17
const unreachableWeight = 1000000000
const decimalPlaces = 100000

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

proc paddedDigits(value: int): string =
  var digits = $value
  while digits.len < 5:
    digits = "0" & digits
  return digits

while true:
  let boxCount = nextInt(inputData, scanPos)
  if boxCount == 0:
    break
  let groupSize = nextInt(inputData, scanPos)
  var weights = newSeq[int](boxCount)
  var costs = newSeq[int](boxCount)
  var totalWeight = 0
  var totalCost = 0
  for boxIndex in 0 .. boxCount - 1:
    weights[boxIndex] = nextInt(inputData, scanPos)
    costs[boxIndex] = nextInt(inputData, scanPos)
    totalWeight = totalWeight + weights[boxIndex]
    totalCost = totalCost + costs[boxIndex]
  let rowWidth = totalCost + 1
  var minimumWeights = newSeq[int]((groupSize + 1) * rowWidth)
  var maximumWeights = newSeq[int]((groupSize + 1) * rowWidth)
  for index in 0 .. minimumWeights.len - 1:
    minimumWeights[index] = unreachableWeight
    maximumWeights[index] = -1
  minimumWeights[0] = 0
  maximumWeights[0] = 0
  var processedBoxes = 0
  for boxIndex in 0 .. boxCount - 1:
    let boxWeight = weights[boxIndex]
    let boxCost = costs[boxIndex]
    let highestCount = groupSize
    var chosenCount = highestCount
    if chosenCount > processedBoxes + 1:
      chosenCount = processedBoxes + 1
    var countIndex = chosenCount
    while countIndex >= 1:
      let previousRow = (countIndex - 1) * rowWidth
      let currentRow = countIndex * rowWidth
      var costIndex = totalCost - boxCost
      while costIndex >= 0:
        let target = currentRow + costIndex + boxCost
        let previousMinimum = minimumWeights[previousRow + costIndex]
        if previousMinimum != unreachableWeight:
          let candidateMinimum = previousMinimum + boxWeight
          if candidateMinimum < minimumWeights[target]:
            minimumWeights[target] = candidateMinimum
        let previousMaximum = maximumWeights[previousRow + costIndex]
        if previousMaximum >= 0:
          let candidateMaximum = previousMaximum + boxWeight
          if candidateMaximum > maximumWeights[target]:
            maximumWeights[target] = candidateMaximum
        costIndex -= 1
      countIndex -= 1
    processedBoxes += 1
  var bestValue = 1e30
  let answerRow = groupSize * rowWidth
  var costIndex = 1
  while costIndex <= totalCost - 1:
    let smallestWeight = minimumWeights[answerRow + costIndex]
    if smallestWeight != unreachableWeight:
      let largestWeight = maximumWeights[answerRow + costIndex]
      var chosenWeight = smallestWeight
      if 2 * costIndex > totalCost:
        chosenWeight = largestWeight
      let otherCost = totalCost - costIndex
      let candidateValue = float(chosenWeight) / float(costIndex) + float(totalWeight - chosenWeight) / float(otherCost)
      if candidateValue < bestValue:
        bestValue = candidateValue
    costIndex += 1
  let roundedValue = int(bestValue * float(decimalPlaces) + 0.5)
  appendOutput($(roundedValue div decimalPlaces))
  outputBuffer.add '.'
  appendOutput(paddedDigits(roundedValue mod decimalPlaces))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
