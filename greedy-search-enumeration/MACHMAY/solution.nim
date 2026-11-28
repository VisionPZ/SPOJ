const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007

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

proc modularPower(baseValue, exponentValue: int64): int64 =
  var powerResult = 1.int64
  var baseCopy = baseValue mod moduloBase
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1) == 1:
      powerResult = powerResult * baseCopy mod moduloBase
    baseCopy = baseCopy * baseCopy mod moduloBase
    exponentCopy = exponentCopy div 2
  return powerResult

proc berlekampMassey(terms: seq[int64]): seq[int64] =
  var connection = @[1.int64]
  var previous = @[1.int64]
  var order = 0
  var shift = 1
  var lastDiscrepancy = 1.int64
  for index in 0 .. terms.len - 1:
    var discrepancy = terms[index]
    for coefficientIndex in 1 .. order:
      discrepancy = (discrepancy + connection[coefficientIndex] * terms[index - coefficientIndex]) mod moduloBase
    if discrepancy == 0:
      shift += 1
    else:
      var savedConnection = connection
      let factor = discrepancy * modularPower(lastDiscrepancy, moduloBase - 2) mod moduloBase
      let wantedLength = previous.len + shift
      while connection.len < wantedLength:
        connection.add 0
      for previousIndex in 0 .. previous.len - 1:
        connection[previousIndex + shift] = (connection[previousIndex + shift] - factor * previous[previousIndex]) mod moduloBase
      if 2 * order <= index:
        order = index + 1 - order
        previous = savedConnection
        lastDiscrepancy = discrepancy
        shift = 1
      else:
        shift += 1
  connection.setLen(order + 1)
  return connection

proc multiplyPolynomials(leftPoly, rightPoly, recurrence: seq[int64]): seq[int64] =
  let order = recurrence.len
  var product = newSeq[int64](2 * order - 1)
  for leftIndex in 0 .. order - 1:
    if leftPoly[leftIndex] == 0:
      continue
    for rightIndex in 0 .. order - 1:
      if rightPoly[rightIndex] == 0:
        continue
      product[leftIndex + rightIndex] = (product[leftIndex + rightIndex] + leftPoly[leftIndex] * rightPoly[rightIndex]) mod moduloBase
  for degree in countdown(2 * order - 2, order):
    let highValue = product[degree]
    if highValue == 0:
      continue
    for coefficientIndex in 0 .. order - 1:
      product[degree - coefficientIndex - 1] = (product[degree - coefficientIndex - 1] + highValue * recurrence[coefficientIndex]) mod moduloBase
  return product[0 .. order - 1]

proc recurrenceTerm(initialTerms, recurrence: seq[int64], termIndex: int64): int64 =
  let order = recurrence.len
  if termIndex < int64(initialTerms.len):
    return initialTerms[int(termIndex)]
  var resultPoly = newSeq[int64](order)
  resultPoly[0] = 1
  var basePoly = newSeq[int64](order)
  if order == 1:
    basePoly[0] = recurrence[0]
  else:
    basePoly[1] = 1
  var exponentCopy = termIndex
  while exponentCopy > 0:
    if (exponentCopy and 1) == 1:
      resultPoly = multiplyPolynomials(resultPoly, basePoly, recurrence)
    basePoly = multiplyPolynomials(basePoly, basePoly, recurrence)
    exponentCopy = exponentCopy div 2
  var answer = 0.int64
  for termPosition in 0 .. order - 1:
    answer = (answer + resultPoly[termPosition] * initialTerms[termPosition]) mod moduloBase
  return answer

proc robotCount(stepCount, partCount: int64): int64 =
  if partCount == 1:
    return 1
  let width = int(partCount) + 1
  let guessOrder = int((partCount + 1) div 2)
  let remainder = int(stepCount mod partCount)
  let termLimit = (2 * guessOrder + 5) * int(partCount) + remainder
  let workLimit = if stepCount < int64(termLimit): int(stepCount) else: termLimit
  var currentState = newSeq[int64](width * width)
  var nextState = newSeq[int64](width * width)
  currentState[0] = 1
  var totalCounts = newSeq[int64](workLimit + 1)
  totalCounts[0] = 1
  for step in 1 .. workLimit:
    for stateIndex in 0 .. width * width - 1:
      nextState[stateIndex] = 0
    for highIndex in 0 .. int(partCount):
      for middleIndex in 0 .. int(partCount) - highIndex:
        let stateValue = currentState[highIndex * width + middleIndex]
        if stateValue == 0:
          continue
        let lowCount = partCount - int64(highIndex) - int64(middleIndex)
        if lowCount > 0:
          if lowCount >= 2:
            nextState[highIndex * width + middleIndex + 1] = (nextState[highIndex * width + middleIndex + 1] + stateValue * lowCount) mod moduloBase
          else:
            nextState[highIndex] = (nextState[highIndex] + stateValue) mod moduloBase
        if middleIndex > 0:
          if lowCount >= 1:
            nextState[(highIndex + 1) * width + middleIndex - 1] = (nextState[(highIndex + 1) * width + middleIndex - 1] + stateValue * int64(middleIndex)) mod moduloBase
          else:
            nextState[highIndex + 1] = (nextState[highIndex + 1] + stateValue * int64(middleIndex)) mod moduloBase
        if highIndex > 0 and lowCount == 0:
          nextState[width + highIndex - 1] = (nextState[width + highIndex - 1] + stateValue * int64(highIndex)) mod moduloBase
    swap currentState, nextState
    var stepTotal = 0.int64
    for stateIndex in 0 .. width * width - 1:
      stepTotal = (stepTotal + currentState[stateIndex]) mod moduloBase
    totalCounts[step] = stepTotal
  if stepCount <= int64(workLimit):
    return totalCounts[int(stepCount)]
  let sampleCount = 2 * guessOrder + 4
  var samples = newSeq[int64](sampleCount)
  for sampleIndex in 0 .. sampleCount - 1:
    samples[sampleIndex] = totalCounts[remainder + sampleIndex * int(partCount)]
  let connection = berlekampMassey(samples)
  let order = connection.len - 1
  var initialTerms = newSeq[int64](order)
  for termPosition in 0 .. order - 1:
    initialTerms[termPosition] = samples[termPosition]
  var recurrence = newSeq[int64](order)
  for coefficientIndex in 0 .. order - 1:
    recurrence[coefficientIndex] = (moduloBase - connection[coefficientIndex + 1]) mod moduloBase
  return recurrenceTerm(initialTerms, recurrence, int64(stepCount div partCount))

let testCaseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCaseCount - 1:
  let stepCount = int64(nextInt(inputData, scanPos))
  let partCount = int64(nextInt(inputData, scanPos))
  appendOutput($robotCount(stepCount, partCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
