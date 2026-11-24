const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const heightOffset = 256
const noResidue = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value

proc gcdValues(aValue, bValue: int): int =
  var larger = aValue
  var smaller = bValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc inverseModulo(aValue, modulus: int): int =
  if modulus == 1:
    return 0
  var oldCoeff = 1
  var coeff = 0
  var oldValue = aValue
  var value = modulus
  while value != 0:
    let quotient = oldValue div value
    let nextValue = oldValue - quotient * value
    oldValue = value
    value = nextValue
    let nextCoeff = oldCoeff - quotient * coeff
    oldCoeff = coeff
    coeff = nextCoeff
  var answerValue = oldCoeff mod modulus
  if answerValue < 0:
    answerValue += modulus
  return answerValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0..<testCount:
  let liftCount = nextInt(inputData, scanPos)
  let platformCount = liftCount + 2
  var periods = newSeq[int](platformCount)
  var positions = newSeq[seq[int]](platformCount)
  var firstResidue = newSeq[seq[int]](platformCount)
  var secondResidue = newSeq[seq[int]](platformCount)
  for platformIndex in 0..<platformCount:
    var lowPos = 0
    var highPos = 0
    var initPos = 0
    var direction = 1
    if platformIndex > 0 and platformIndex <= liftCount:
      lowPos = 2 * nextInt(inputData, scanPos)
      highPos = 2 * nextInt(inputData, scanPos)
      initPos = 2 * nextInt(inputData, scanPos)
      direction = nextInt(inputData, scanPos)
    let period = if highPos > lowPos: 2 * (highPos - lowPos) else: 1
    periods[platformIndex] = period
    var positionSeq = newSeq[int](period)
    var firstSeq = newSeq[int](513)
    var secondSeq = newSeq[int](513)
    for slot in 0..512:
      firstSeq[slot] = noResidue
      secondSeq[slot] = noResidue
    var height = initPos
    var stepDir = direction
    for i in 0..<period:
      positionSeq[i] = height
      let slot = height + heightOffset
      if firstSeq[slot] == noResidue:
        firstSeq[slot] = i
      else:
        secondSeq[slot] = i
      if stepDir == 1:
        if height < highPos:
          height += 1
        else:
          height -= 1
          stepDir = -1
      else:
        if height > lowPos:
          height -= 1
        else:
          height += 1
          stepDir = 1
    positions[platformIndex] = positionSeq
    firstResidue[platformIndex] = firstSeq
    secondResidue[platformIndex] = secondSeq

  var currentTime = 2
  var possible = true
  for platformIndex in 0..<platformCount - 1:
    let firstPeriod = periods[platformIndex]
    let secondPeriod = periods[platformIndex + 1]
    let common = gcdValues(firstPeriod, secondPeriod)
    let cycleLength = (firstPeriod div common) * secondPeriod
    let reducedSecond = secondPeriod div common
    let inverseValue = inverseModulo(firstPeriod div common, reducedSecond)
    var bestTime = high(int)
    for i in 0..<firstPeriod:
      let sharedHeight = positions[platformIndex][i]
      let slot = sharedHeight + heightOffset
      for j in [firstResidue[platformIndex + 1][slot], secondResidue[platformIndex + 1][slot]]:
        if j != noResidue and (i - j) mod common == 0:
          var remainderValue = ((j - i) div common) mod reducedSecond
          if remainderValue < 0:
            remainderValue += reducedSecond
          let stepCount = (remainderValue * inverseValue) mod reducedSecond
          var baseTime = (i + firstPeriod * stepCount) mod cycleLength
          if baseTime < currentTime:
            let skip = (currentTime - baseTime + cycleLength - 1) div cycleLength
            baseTime += skip * cycleLength
          if baseTime < bestTime:
            bestTime = baseTime
    if bestTime == high(int):
      possible = false
      break
    currentTime = bestTime + (if platformIndex < liftCount: 4 else: 2)
  if possible:
    appendOutput($(currentTime div 2))
  else:
    appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
