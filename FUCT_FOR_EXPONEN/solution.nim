import math
import tables

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const bigBaseBits = 30
const bigBase = 1 shl bigBaseBits
const bigMask = bigBase - 1
const decimalBase = 1000000000
const scaleMillion = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc bigMul(leftNumber: seq[int], rightNumber: seq[int]): seq[int] =
  var productGroups = newSeq[int](leftNumber.len + rightNumber.len)
  for leftIndex in 0..<leftNumber.len:
    var carry = 0
    var writeIndex = leftIndex
    for rightIndex in 0..<rightNumber.len:
      let cell = productGroups[writeIndex] + leftNumber[leftIndex] * rightNumber[rightIndex] + carry
      productGroups[writeIndex] = cell and bigMask
      carry = cell shr bigBaseBits
      writeIndex += 1
    while carry > 0:
      let cell = productGroups[writeIndex] + carry
      productGroups[writeIndex] = cell and bigMask
      carry = cell shr bigBaseBits
      writeIndex += 1
  return productGroups

proc bigPowGroups(baseValue: int, exponentValue: int): seq[int] =
  if baseValue == 0:
    if exponentValue == 0:
      return @[1]
    return @[0]
  var baseGroups: seq[int] = @[]
  var rest = baseValue
  while rest > 0:
    baseGroups.add rest mod bigBase
    rest = rest div bigBase
  var powerResult: seq[int] = @[1]
  var remainingPower = exponentValue
  while remainingPower > 0:
    if remainingPower mod 2 == 1:
      powerResult = bigMul(powerResult, baseGroups)
    remainingPower = remainingPower div 2
    if remainingPower > 0:
      baseGroups = bigMul(baseGroups, baseGroups)
  return powerResult

proc decimalTextOf(number: seq[int]): string =
  var work = number
  var decimalGroups: seq[int] = @[]
  while true:
    var topIndex = work.len - 1
    while topIndex > 0 and work[topIndex] == 0:
      topIndex -= 1
    if topIndex == 0 and work[0] == 0:
      break
    var carry = 0
    var readIndex = topIndex
    while readIndex >= 0:
      let cell = (carry shl bigBaseBits) + work[readIndex]
      work[readIndex] = cell div decimalBase
      carry = cell mod decimalBase
      readIndex -= 1
    decimalGroups.add carry
  if decimalGroups.len == 0:
    decimalGroups.add 0
  var text = ""
  var groupIndex = decimalGroups.len - 1
  text.add $(decimalGroups[groupIndex])
  groupIndex -= 1
  while groupIndex >= 0:
    var part = $(decimalGroups[groupIndex])
    while part.len < 9:
      part = "0" & part
    text.add part
    groupIndex -= 1
  return text

proc appendFixedSix(value: float) =
  var signText = ""
  var magnitude = value
  if value < 0:
    signText = "-"
    magnitude = -value
  if magnitude >= 1000000000000000.0:
    appendOutput(signText & "inf")
    return
  let scaled = int(magnitude * 1000000.0 + 0.5)
  appendOutput(signText)
  appendOutput($(scaled div scaleMillion))
  appendOutput(".")
  var fractionText = $(scaled mod scaleMillion)
  while fractionText.len < 6:
    fractionText = "0" & fractionText
  appendOutput(fractionText)

var answerCache = initTable[(int, int), string]()

let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let baseNumber = nextSignedInt(inputData, scanPos)
  let exponentNumber = nextSignedInt(inputData, scanPos)
  if exponentNumber >= 0:
    let cacheKey = (abs(baseNumber), exponentNumber)
    var digitsText = ""
    if answerCache.hasKey(cacheKey):
      digitsText = answerCache[cacheKey]
    else:
      digitsText = decimalTextOf(bigPowGroups(abs(baseNumber), exponentNumber))
      answerCache[cacheKey] = digitsText
    if baseNumber < 0 and exponentNumber mod 2 == 1:
      appendOutput("-")
    appendOutput(digitsText)
    appendOutput("\n")
  else:
    appendFixedSix(pow(float(baseNumber), float(exponentNumber)))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
