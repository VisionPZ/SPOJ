import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const fullTurn = 2.0 * PI
const timeCeiling = 1.0e12
const rootCeiling = 1.0e6
const gridScale = 10
const maxRootPeriod = 159200

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  elif pos < data.len and data[pos] == '+':
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float(int(data[pos]) - firstDigitValue)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fractionScale = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value += fractionScale * float(int(data[pos]) - firstDigitValue)
      fractionScale = fractionScale * 0.1
      pos += 1
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentSign = 1
    if pos < data.len and data[pos] == '-':
      exponentSign = -1
      pos += 1
    elif pos < data.len and data[pos] == '+':
      pos += 1
    var exponent = 0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponent = exponent * 10 + int(data[pos]) - firstDigitValue
      pos += 1
    value = value * pow(10.0, float(exponentSign * exponent))
  return signValue * value

proc pointDistance(timeValue, centerX, centerY: float): float =
  let horizontalError = sin(sqrt(timeValue)) - centerX
  let verticalError = cos(timeValue) - centerY
  return sqrt(horizontalError * horizontalError + verticalError * verticalError)

proc findGridIndex(centerX, centerY, radius: float): int =
  var bestIndex = -1
  let clampedX = max(-1.0, min(1.0, centerX))
  let clampedY = max(-1.0, min(1.0, centerY))
  let lowBase = max(-1.0, clampedX - radius)
  let highBase = min(1.0, clampedX + radius)
  let arcLow = arcsin(lowBase)
  let arcHigh = arcsin(highBase)
  let primaryPhase = arccos(clampedY)
  var phaseTable: array[2, float]
  phaseTable[0] = primaryPhase
  phaseTable[1] = fullTurn - primaryPhase
  for branchKind in 0 .. 1:
    for periodIndex in 0 .. maxRootPeriod:
      var bandLow: float
      var bandHigh: float
      if branchKind == 0:
        bandLow = arcLow + fullTurn * float(periodIndex)
        bandHigh = arcHigh + fullTurn * float(periodIndex)
      else:
        bandLow = PI - arcHigh + fullTurn * float(periodIndex)
        bandHigh = PI - arcLow + fullTurn * float(periodIndex)
      if bandLow < 0.0: bandLow = 0.0
      if bandLow > rootCeiling: break
      let timeLow = bandLow * bandLow
      var timeHigh = bandHigh * bandHigh
      if timeHigh > timeCeiling: timeHigh = timeCeiling
      if bestIndex >= 0 and timeLow > float(bestIndex) / float(gridScale): break
      for phaseIndex in 0 .. 1:
        let targetPhase = phaseTable[phaseIndex]
        var waveIndex = ceil((timeLow - targetPhase) / fullTurn - 1.0e-12)
        while true:
          let targetTime = targetPhase + fullTurn * waveIndex
          if targetTime > timeHigh + 1.0e-9: break
          if bestIndex >= 0 and targetTime > float(bestIndex) / float(gridScale): break
          let approxIndex = int(floor(targetTime * float(gridScale)))
          for offset in -1 .. 2:
            let candidateIndex = approxIndex + offset
            if candidateIndex < 0: continue
            if float(candidateIndex) > timeCeiling * float(gridScale): continue
            if bestIndex >= 0 and candidateIndex >= bestIndex: continue
            let candidateTime = float(candidateIndex) / float(gridScale)
            if pointDistance(candidateTime, clampedX, clampedY) <= radius:
              bestIndex = candidateIndex
          waveIndex += 1
  return bestIndex

let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0 ..< caseCount:
  let centerX = nextFloat(inputData, scanPos)
  let centerY = nextFloat(inputData, scanPos)
  let radius = nextFloat(inputData, scanPos)
  let bestIndex = findGridIndex(centerX, centerY, radius)
  if bestIndex < 0:
    outputBuffer.add "FAIL\n"
  else:
    outputBuffer.add $(bestIndex div gridScale)
    outputBuffer.add "."
    outputBuffer.add $(bestIndex mod gridScale)
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
