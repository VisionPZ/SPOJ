const flushBlockBytes = 1 shl 17
const limbBase = 10000
const limbDigits = 4

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

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var modulusDigits = 0
var limbCount = 0
var topMask = limbBase

proc maskTop(number: var seq[int]) =
  number[limbCount - 1] = number[limbCount - 1] mod topMask

proc parseLimited(digits: string): seq[int] =
  result = newSeq[int](limbCount)
  var digitPosition = digits.len - 1
  let firstDigit = if digits.len > modulusDigits: digits.len - modulusDigits else: 0
  var place = 1
  var limbIndex = 0
  while digitPosition >= firstDigit:
    result[limbIndex] = result[limbIndex] + (int(digits[digitPosition]) - 48) * place
    place = place * 10
    if place == limbBase:
      place = 1
      limbIndex = limbIndex + 1
    digitPosition = digitPosition - 1
  maskTop(result)

proc addLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  var carry = 0
  for limbIndex in 0 .. limbCount - 1:
    let total = firstNumber[limbIndex] + secondNumber[limbIndex] + carry
    result[limbIndex] = total mod limbBase
    carry = total div limbBase
  maskTop(result)

proc subtractLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  var borrow = 0
  for limbIndex in 0 .. limbCount - 1:
    var difference = firstNumber[limbIndex] - secondNumber[limbIndex] - borrow
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result[limbIndex] = difference
  maskTop(result)

proc multiplyLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  for outerIndex in 0 .. limbCount - 1:
    if firstNumber[outerIndex] == 0:
      continue
    var carry = 0
    for innerIndex in 0 .. limbCount - outerIndex - 1:
      let total = firstNumber[outerIndex] * secondNumber[innerIndex] +
                  result[outerIndex + innerIndex] + carry
      result[outerIndex + innerIndex] = total mod limbBase
      carry = total div limbBase
  maskTop(result)

proc addSmall(number: seq[int], extraValue: int): seq[int] =
  result = newSeq[int](limbCount)
  for limbIndex in 0 .. limbCount - 1:
    result[limbIndex] = number[limbIndex]
  var extra = extraValue
  var limbIndex = 0
  while extra > 0 and limbIndex < limbCount:
    let total = result[limbIndex] + extra
    result[limbIndex] = total mod limbBase
    extra = total div limbBase
    limbIndex = limbIndex + 1
  maskTop(result)

proc digitSquareSum(number: seq[int]): int =
  var sumOfSquares = 0
  let remainder = modulusDigits mod limbDigits
  for limbIndex in 0 .. limbCount - 1:
    var limbValue = number[limbIndex]
    var digitTotal = limbDigits
    if limbIndex == limbCount - 1 and remainder != 0:
      digitTotal = remainder
    for digitIndex in 0 .. digitTotal - 1:
      let digitValue = limbValue mod 10
      sumOfSquares = sumOfSquares + digitValue * digitValue
      limbValue = limbValue div 10
  return sumOfSquares

let degree = nextInt(inputData, scanPos)
let startDigits = nextDigits(inputData, scanPos)
let answerCount = nextInt(inputData, scanPos)
modulusDigits = nextInt(inputData, scanPos)
limbCount = (modulusDigits + limbDigits - 1) div limbDigits
topMask = limbBase
let remainder = modulusDigits mod limbDigits
if remainder != 0:
  topMask = 1
  for digitIndex in 1 .. remainder:
    topMask = topMask * 10

var coefficients = newSeq[seq[int]](degree + 1)
for coefficientIndex in 0 .. degree:
  coefficients[coefficientIndex] = parseLimited(nextDigits(inputData, scanPos))
let startNumber = parseLimited(startDigits)

var evaluations = newSeq[seq[int]](degree + 1)
for offset in 0 .. degree:
  let evaluationPoint = addSmall(startNumber, offset)
  var accumulator = coefficients[0]
  for coefficientIndex in 1 .. degree:
    accumulator = addLimited(multiplyLimited(accumulator, evaluationPoint),
                             coefficients[coefficientIndex])
  evaluations[offset] = accumulator

var differences = newSeq[seq[int]](degree + 1)
for index in 0 .. degree:
  differences[index] = evaluations[index]
for order in 1 .. degree:
  var index = degree
  while index >= order:
    differences[index] = subtractLimited(differences[index], differences[index - 1])
    index = index - 1

for answerIndex in 0 .. answerCount - 1:
  appendOutput($digitSquareSum(differences[0]))
  outputBuffer.add '\n'
  for order in 0 .. degree - 1:
    differences[order] = addLimited(differences[order], differences[order + 1])

stdout.write outputBuffer
outputBuffer.setLen 0
