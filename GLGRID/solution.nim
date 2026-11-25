import math

const flushBlockBytes = 1 shl 17
const maximumValue = 1000000000000

proc integerSquareRoot(value: int64): int64 =
  var candidate = int64(sqrt(float(value)))
  while (candidate + 1) * (candidate + 1) <= value:
    candidate += 1
  while candidate * candidate > value:
    candidate -= 1
  return candidate

proc isPerfectSquare(value: int64): bool =
  let root = integerSquareRoot(value)
  return root * root == value

proc pellFundamental(value: int): (int64, int64) =
  let root = integerSquareRoot(int64(value))
  if root * root == int64(value):
    return (int64(0), int64(0))
  var multiplier = 0
  var denominator = 1
  var term = int(root)
  var previousNumerator: int64 = 1
  var numerator: int64 = int64(term)
  var previousDenominator: int64 = 0
  var denominatorValue: int64 = 1
  while numerator * numerator - int64(value) * denominatorValue * denominatorValue != 1:
    multiplier = denominator * term - multiplier
    denominator = (value - multiplier * multiplier) div denominator
    term = (int(root) + multiplier) div denominator
    let oldNumerator = numerator
    numerator = int64(term) * numerator + previousNumerator
    previousNumerator = oldNumerator
    let oldDenominator = denominatorValue
    denominatorValue = int64(term) * denominatorValue + previousDenominator
    previousDenominator = oldDenominator
  return (numerator, denominatorValue)

proc insertionSort(data: var seq[int64]) =
  for sortIndex in 1 .. data.len - 1:
    let sortValue = data[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and data[previousIndex] > sortValue:
      data[previousIndex + 1] = data[previousIndex]
      previousIndex -= 1
    data[previousIndex + 1] = sortValue

proc collectValues(firstCoefficient: int, secondCoefficient: int, thirdCoefficient: int, valueCount: int): seq[int64] =
  var candidates = newSeq[int64]()
  let discriminant = int64(secondCoefficient) * int64(secondCoefficient) - 4 * int64(firstCoefficient) * int64(thirdCoefficient)
  if firstCoefficient == 0:
    if secondCoefficient == 0:
      if isPerfectSquare(int64(thirdCoefficient)):
        for valueIndex in 0 .. valueCount - 1:
          candidates.add int64(valueIndex)
      return candidates
    let startRoot = integerSquareRoot(int64(thirdCoefficient))
    let limitRoot = integerSquareRoot(int64(secondCoefficient) * maximumValue + int64(thirdCoefficient)) + 2
    var rootValue = startRoot
    while rootValue <= limitRoot and candidates.len < valueCount:
      let squareValue = rootValue * rootValue - int64(thirdCoefficient)
      if squareValue mod int64(secondCoefficient) == 0:
        let quotient = squareValue div int64(secondCoefficient)
        if quotient >= 0:
          candidates.add quotient
      rootValue += 1
    return candidates
  if discriminant == 0:
    let thirdRoot = integerSquareRoot(int64(thirdCoefficient))
    if thirdRoot * thirdRoot != int64(thirdCoefficient):
      return candidates
    let firstRoot = integerSquareRoot(int64(firstCoefficient))
    if firstRoot * firstRoot == int64(firstCoefficient) and int64(secondCoefficient) == 2 * firstRoot * thirdRoot:
      for valueIndex in 0 .. valueCount - 1:
        candidates.add int64(valueIndex)
    else:
      candidates.add 0
    return candidates
  let firstRoot = integerSquareRoot(int64(firstCoefficient))
  if firstRoot * firstRoot == int64(firstCoefficient):
    var divisor: int64 = 1
    while divisor * divisor <= discriminant:
      if discriminant mod divisor == 0:
        for signValue in [int64(1), int64(-1)]:
          let firstFactor = signValue * divisor
          let secondFactor = signValue * (discriminant div divisor)
          if (firstFactor + secondFactor) mod 2 == 0:
            let solutionU = (firstFactor + secondFactor) div 2
            let numeratorValue = secondFactor - firstFactor
            if numeratorValue mod (2 * firstRoot) == 0:
              let solutionV = numeratorValue div (2 * firstRoot)
              if solutionV * solutionV >= 0:
                let shift = solutionU - int64(secondCoefficient)
                if shift mod (2 * int64(firstCoefficient)) == 0:
                  let quotient = shift div (2 * int64(firstCoefficient))
                  if quotient >= 0:
                    candidates.add quotient
      divisor += 1
    return candidates
  let fundamental = pellFundamental(firstCoefficient)
  let unitU = fundamental[0]
  let unitV = fundamental[1]
  let searchBound = integerSquareRoot(discriminant * (unitU + 1) div 2) + 1
  let maximumU = 2 * int64(firstCoefficient) * maximumValue + int64(secondCoefficient)
  let growthLimit = int64.high div (unitU + unitV * int64(firstCoefficient) + 1)
  var baseValue: int64 = 0
  while baseValue <= searchBound:
    let difference = baseValue * baseValue - discriminant
    if difference >= 0 and difference mod int64(firstCoefficient) == 0:
      let squareValue = difference div int64(firstCoefficient)
      let baseV = integerSquareRoot(squareValue)
      if baseV * baseV == squareValue:
        for signValue in [int64(1), int64(-1)]:
          var solutionU = baseValue
          var solutionV = signValue * baseV
          while solutionU >= 0 and solutionU <= maximumU:
            let shift = solutionU - int64(secondCoefficient)
            if shift >= 0 and shift mod (2 * int64(firstCoefficient)) == 0 and solutionV mod 2 == 0:
              candidates.add shift div (2 * int64(firstCoefficient))
            let estimatedGrowth = float(solutionU) * float(unitU) + float(solutionV) * float(unitV) * float(firstCoefficient)
            if estimatedGrowth > float(maximumU) or solutionU > growthLimit or solutionV > growthLimit or solutionV < -growthLimit:
              break
            let nextU = solutionU * unitU + solutionV * unitV * int64(firstCoefficient)
            let nextV = solutionU * unitV + solutionV * unitU
            solutionU = nextU
            solutionV = nextV
    baseValue += 1
  return candidates

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstCoefficient = nextInt(inputData, scanPos)
  let secondCoefficient = nextInt(inputData, scanPos)
  let thirdCoefficient = nextInt(inputData, scanPos)
  let valueCount = nextInt(inputData, scanPos)
  var candidates = collectValues(firstCoefficient, secondCoefficient, thirdCoefficient, valueCount)
  insertionSort(candidates)
  var printedCount = 0
  var previousValue: int64 = -1
  for candidateIndex in 0 .. candidates.len - 1:
    if printedCount >= valueCount:
      break
    let candidateValue = candidates[candidateIndex]
    if candidateValue >= 0 and candidateValue != previousValue:
      appendOutput($candidateValue)
      outputBuffer.add '\n'
      previousValue = candidateValue
      printedCount += 1
stdout.write outputBuffer
outputBuffer.setLen 0
