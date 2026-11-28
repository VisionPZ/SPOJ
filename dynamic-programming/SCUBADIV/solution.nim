const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const nitrogenStride = 80
const maxOxygen = 21
const maxCells = (maxOxygen + 1) * nitrogenStride
const impossibleWeight = 1 shl 29

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var bestWeight: array[maxCells, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let oxygenDemand = nextInt(inputData, scanPos)
  let nitrogenDemand = nextInt(inputData, scanPos)
  let cylinderCount = nextInt(inputData, scanPos)
  for cellIndex in 0..<(oxygenDemand + 1) * nitrogenStride:
    bestWeight[cellIndex] = impossibleWeight
  bestWeight[0] = 0
  for cylinderIndex in 0..<cylinderCount:
    let cylinderOxygen = nextInt(inputData, scanPos)
    let cylinderNitrogen = nextInt(inputData, scanPos)
    let cylinderWeight = nextInt(inputData, scanPos)
    var oxygenIndex = oxygenDemand
    while oxygenIndex >= 0:
      var nitrogenIndex = nitrogenDemand
      while nitrogenIndex >= 0:
        let currentIndex = oxygenIndex * nitrogenStride + nitrogenIndex
        let currentWeight = bestWeight[currentIndex]
        if currentWeight < impossibleWeight:
          var newOxygen = oxygenIndex + cylinderOxygen
          if newOxygen > oxygenDemand:
            newOxygen = oxygenDemand
          var newNitrogen = nitrogenIndex + cylinderNitrogen
          if newNitrogen > nitrogenDemand:
            newNitrogen = nitrogenDemand
          let candidateWeight = currentWeight + cylinderWeight
          let targetIndex = newOxygen * nitrogenStride + newNitrogen
          if candidateWeight < bestWeight[targetIndex]:
            bestWeight[targetIndex] = candidateWeight
        nitrogenIndex -= 1
      oxygenIndex -= 1
  appendOutput($(bestWeight[oxygenDemand * nitrogenStride + nitrogenDemand]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
