import math

const flushBlockBytes = 1 shl 17
const feasibilityMargin = 1.0e-9
const stopMargin = 1.0e-7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatPayoff(value: float): string =
  var rounded: int64
  if value >= 0:
    rounded = int64(floor(value * 1000.0 + 0.5))
  else:
    rounded = -int64(floor(-value * 1000.0 + 0.5))
  let negative = rounded < 0
  var magnitude = rounded
  if negative:
    magnitude = -magnitude
  let wholePart = magnitude div 1000
  let fractionPart = magnitude mod 1000
  result = ""
  if negative:
    result.add '-'
  result.add $wholePart
  result.add '.'
  result.add chr(48 + fractionPart div 100)
  result.add chr(48 + (fractionPart div 10) mod 10)
  result.add chr(48 + fractionPart mod 10)

proc solveThreeByThree(coefficients: array[3, array[3, float]],
                       rightSides: array[3, float]): seq[float] =
  var matrixValues = coefficients
  var values = rightSides
  for columnIndex in 0 .. 2:
    var pivotRow = columnIndex
    for rowIndex in columnIndex + 1 .. 2:
      if abs(matrixValues[rowIndex][columnIndex]) > abs(matrixValues[pivotRow][columnIndex]):
        pivotRow = rowIndex
    if abs(matrixValues[pivotRow][columnIndex]) < feasibilityMargin:
      return @[]
    if pivotRow != columnIndex:
      swap(matrixValues[pivotRow], matrixValues[columnIndex])
      swap(values[pivotRow], values[columnIndex])
    let divisor = matrixValues[columnIndex][columnIndex]
    for cellIndex in 0 .. 2:
      matrixValues[columnIndex][cellIndex] = matrixValues[columnIndex][cellIndex] / divisor
    values[columnIndex] = values[columnIndex] / divisor
    for rowIndex in 0 .. 2:
      if rowIndex == columnIndex:
        continue
      let factor = matrixValues[rowIndex][columnIndex]
      if abs(factor) < feasibilityMargin:
        continue
      for cellIndex in 0 .. 2:
        matrixValues[rowIndex][cellIndex] = matrixValues[rowIndex][cellIndex] - factor * matrixValues[columnIndex][cellIndex]
      values[rowIndex] = values[rowIndex] - factor * values[columnIndex]
  return @[values[0], values[1], values[2]]

proc guardedPayoff(matrix: seq[seq[int]], rowCount: int,
                   probabilities: seq[float], columns: seq[int]): float =
  var minimum = 1.0e30
  for columnIndex in columns:
    var expected = 0.0
    for rowIndex in 0 .. rowCount - 1:
      expected = expected + probabilities[rowIndex] * float(matrix[rowIndex][columnIndex])
    if expected < minimum:
      minimum = expected
  return minimum

proc solveActive(matrix: seq[seq[int]], rowCount: int,
                 columns: seq[int]): (float, seq[float]) =
  var bestValue = -1.0e30
  var bestProbabilities = newSeq[float](rowCount)
  for fixedRow in 0 .. rowCount - 1:
    var probabilities = newSeq[float](rowCount)
    probabilities[fixedRow] = 1.0
    let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
    if candidate > bestValue:
      bestValue = candidate
      bestProbabilities = probabilities
  for firstRow in 0 .. rowCount - 1:
    for secondRow in firstRow + 1 .. rowCount - 1:
      for firstPosition in 0 .. columns.len - 1:
        for secondPosition in firstPosition + 1 .. columns.len - 1:
          let firstColumn = columns[firstPosition]
          let secondColumn = columns[secondPosition]
          let slopeDifference = float(matrix[firstRow][firstColumn] - matrix[secondRow][firstColumn]) -
                                float(matrix[firstRow][secondColumn] - matrix[secondRow][secondColumn])
          if abs(slopeDifference) < feasibilityMargin:
            continue
          let crossing = float(matrix[secondRow][secondColumn] - matrix[secondRow][firstColumn]) / slopeDifference
          if crossing < -feasibilityMargin or crossing > 1.0 + feasibilityMargin:
            continue
          var shareFirst = crossing
          if shareFirst < 0:
            shareFirst = 0
          if shareFirst > 1:
            shareFirst = 1
          var probabilities = newSeq[float](rowCount)
          probabilities[firstRow] = shareFirst
          probabilities[secondRow] = 1.0 - shareFirst
          let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
          if candidate > bestValue:
            bestValue = candidate
            bestProbabilities = probabilities
  if rowCount == 3:
    for firstPosition in 0 .. columns.len - 1:
      for secondPosition in firstPosition + 1 .. columns.len - 1:
        for thirdPosition in secondPosition + 1 .. columns.len - 1:
          let firstColumn = columns[firstPosition]
          let secondColumn = columns[secondPosition]
          let thirdColumn = columns[thirdPosition]
          var coefficients: array[3, array[3, float]]
          coefficients[0] = [float(matrix[0][firstColumn] - matrix[0][secondColumn]),
                             float(matrix[1][firstColumn] - matrix[1][secondColumn]),
                             float(matrix[2][firstColumn] - matrix[2][secondColumn])]
          coefficients[1] = [float(matrix[0][firstColumn] - matrix[0][thirdColumn]),
                             float(matrix[1][firstColumn] - matrix[1][thirdColumn]),
                             float(matrix[2][firstColumn] - matrix[2][thirdColumn])]
          coefficients[2] = [1.0, 1.0, 1.0]
          let rightSides = [0.0, 0.0, 1.0]
          let probabilities = solveThreeByThree(coefficients, rightSides)
          if probabilities.len == 0:
            continue
          var feasible = true
          for rowIndex in 0 .. 2:
            if probabilities[rowIndex] < -feasibilityMargin:
              feasible = false
          if not feasible:
            continue
          let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
          if candidate > bestValue:
            bestValue = candidate
            bestProbabilities = probabilities
  return (bestValue, bestProbabilities)

proc gameValue(matrix: seq[seq[int]], rowCount: int, columnCount: int): float =
  if rowCount == 1:
    var minimum = 1.0e30
    for columnIndex in 0 .. columnCount - 1:
      let candidate = float(matrix[0][columnIndex])
      if candidate < minimum:
        minimum = candidate
    return minimum
  var columns = @[0]
  for iteration in 0 .. columnCount + 1:
    let solution = solveActive(matrix, rowCount, columns)
    let probabilities = solution[1]
    var minimumValue = 1.0e30
    var violatingColumn = 0
    for columnIndex in 0 .. columnCount - 1:
      var expected = 0.0
      for rowIndex in 0 .. rowCount - 1:
        expected = expected + probabilities[rowIndex] * float(matrix[rowIndex][columnIndex])
      if expected < minimumValue:
        minimumValue = expected
        violatingColumn = columnIndex
    if minimumValue >= solution[0] - stopMargin:
      return solution[0]
    if violatingColumn in columns:
      return solution[0]
    columns.add violatingColumn
  return solveActive(matrix, rowCount, columns)[0]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var matrix = newSeq[seq[int]](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    matrix[rowIndex] = newSeq[int](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      matrix[rowIndex][columnIndex] = nextInt(inputData, scanPos)
  let payoff = gameValue(matrix, rowCount, columnCount)
  appendOutput(formatPayoff(payoff) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
