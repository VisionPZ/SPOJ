const flushBlockBytes = 1 shl 17
const modulusValue = 65521

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

type
  RecurrenceData = object
    order: int
    startIndex: int
    coefficients: seq[int]
    knownValues: seq[int]

proc recurrenceFor(kind: int): RecurrenceData =
  case kind
  of 1:
    return RecurrenceData(order: 1, startIndex: 2,
                          coefficients: @[1],
                          knownValues: @[1])
  of 2:
    return RecurrenceData(order: 2, startIndex: 4,
                          coefficients: @[3, 65520],
                          knownValues: @[1, 1, 3])
  of 3:
    return RecurrenceData(order: 5, startIndex: 8,
                          coefficients: @[5, 65518, 3, 65516, 1],
                          knownValues: @[1, 1, 3, 16, 75, 336, 1488])
  of 4:
    return RecurrenceData(order: 14, startIndex: 18,
                          coefficients: @[7, 65520, 65496, 31, 65469, 65437, 300, 65437, 65469, 31, 65496, 65520, 7, 65520],
                          knownValues: @[1, 1, 3, 16, 125, 864, 5635, 35840, 29517, 48795, 64376, 52310, 4486, 28336, 8758, 64387, 31184])
  of 5:
    return RecurrenceData(order: 41, startIndex: 46,
                          coefficients: @[8, 5, 65489, 40, 364, 63172, 62845, 2793, 7304, 50170, 14272, 13974, 32712, 27590, 63226, 30516, 31431, 62449, 44809, 2992, 62529, 20712, 3072, 34090, 35005, 2295, 37931, 32809, 51547, 51249, 15351, 58217, 62728, 2676, 2349, 65157, 65481, 32, 65516, 65513, 1],
                          knownValues: @[1, 1, 3, 16, 125, 1296, 12005, 38927, 26915, 65410, 9167, 63054, 58705, 18773, 9079, 38064, 46824, 48121, 50048, 47533, 30210, 24390, 51276, 45393, 357, 44927, 15398, 15923, 31582, 56586, 25233, 41258, 21255, 21563, 16387, 39423, 26418, 10008, 6962, 42377, 50881, 54893, 50452, 23715, 53140])
  else:
    return RecurrenceData(order: 1, startIndex: 2,
                          coefficients: @[1], knownValues: @[1])

proc multiplyPolynomials(leftPoly, rightPoly, coefficients: seq[int]): seq[int] =
  let degree = coefficients.len
  var product = newSeq[int](2 * degree - 1)
  for leftIndex in 0 .. degree - 1:
    for rightIndex in 0 .. degree - 1:
      let targetIndex = leftIndex + rightIndex
      let addend = leftPoly[leftIndex] * rightPoly[rightIndex]
      product[targetIndex] = (product[targetIndex] + addend) mod modulusValue
  var currentDegree = 2 * degree - 2
  while currentDegree >= degree:
    let leading = product[currentDegree]
    if leading != 0:
      for coefficientIndex in 0 .. degree - 1:
        let targetIndex = currentDegree - 1 - coefficientIndex
        let addend = leading * coefficients[coefficientIndex]
        product[targetIndex] = (product[targetIndex] + addend) mod modulusValue
    currentDegree -= 1
  result = newSeq[int](degree)
  for index in 0 .. degree - 1:
    result[index] = product[index]

proc evaluateRecurrence(data: RecurrenceData, nodeCount: int64): int =
  if nodeCount < int64(data.startIndex):
    return data.knownValues[int(nodeCount) - 1]
  let baseIndex = data.startIndex - data.order
  let shiftCount = nodeCount - int64(baseIndex)
  var powerPoly = newSeq[int](data.order)
  powerPoly[0] = 1
  var stepPoly = newSeq[int](data.order)
  if data.order == 1:
    stepPoly[0] = data.coefficients[0]
  else:
    stepPoly[1] = 1
  var remaining = shiftCount
  while remaining > 0:
    if (remaining and 1) == 1:
      powerPoly = multiplyPolynomials(powerPoly, stepPoly, data.coefficients)
    stepPoly = multiplyPolynomials(stepPoly, stepPoly, data.coefficients)
    remaining = remaining div 2
  var answer = 0
  for polyIndex in 0 .. data.order - 1:
    let knownIndex = baseIndex - 1 + polyIndex
    answer = (answer + powerPoly[polyIndex] * data.knownValues[knownIndex]) mod modulusValue
  return answer

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let reach = nextInt(inputData, scanPos)
  let nodeCount = int64(nextInt(inputData, scanPos))
  let data = recurrenceFor(reach)
  let answer = evaluateRecurrence(data, nodeCount)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
