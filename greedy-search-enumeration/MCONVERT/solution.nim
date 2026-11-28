const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbDigits = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyAdd(target: var seq[int64], multiplier: int, addend: int) =
  var carry: int64 = int64(addend)
  var limbIndex = 0
  while limbIndex < target.len:
    let product = int64(target[limbIndex]) * int64(multiplier) + carry
    target[limbIndex] = product mod limbBase
    carry = product div limbBase
    limbIndex += 1
  while carry > 0:
    target.add(carry mod limbBase)
    carry = carry div limbBase

proc addBig(target: var seq[int64], source: seq[int64]) =
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < source.len:
    if limbIndex >= target.len:
      target.add 0
    let limbTotal = int64(target[limbIndex]) + source[limbIndex] + carry
    target[limbIndex] = limbTotal mod limbBase
    carry = limbTotal div limbBase
    limbIndex += 1
  while carry > 0:
    if limbIndex >= target.len:
      target.add 0
    let limbTotal = int64(target[limbIndex]) + carry
    target[limbIndex] = limbTotal mod limbBase
    carry = limbTotal div limbBase
    limbIndex += 1

proc bigToString(digits: seq[int64]): string =
  var text = ""
  var limbIndex = digits.len
  while limbIndex > 0:
    limbIndex -= 1
    let limbValue = digits[limbIndex]
    if limbIndex == digits.len - 1:
      text.add $limbValue
    else:
      var padded = $limbValue
      while padded.len < limbDigits:
        padded = "0" & padded
      text.add padded
  return text

var digitMap = newSeq[int](256)
for codeValue in 0 .. 255:
  digitMap[codeValue] = -1

var lineStart = 0
var datasetCount = 0
var digitCount = 0
var inDataset = false
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var trimStart = lineStart
  var trimEnd = lineEnd
  while trimStart < trimEnd and inputData[trimStart] <= ' ':
    trimStart += 1
  while trimEnd > trimStart and inputData[trimEnd - 1] <= ' ':
    trimEnd -= 1
  if trimStart < trimEnd:
    if not inDataset:
      for codeValue in 0 .. 255:
        digitMap[codeValue] = -1
      digitCount = 0
      var charIndex = trimStart
      while charIndex < trimEnd:
        digitMap[int(inputData[charIndex])] = digitCount
        digitCount += 1
        charIndex += 1
      inDataset = true
      if datasetCount > 0:
        outputBuffer.add '\n'
      datasetCount += 1
    else:
      var numberDigits = newSeq[int]()
      var maxDigit = 0
      var charIndex = trimStart
      while charIndex < trimEnd:
        let digitValue = digitMap[int(inputData[charIndex])]
        numberDigits.add digitValue
        if digitValue > maxDigit:
          maxDigit = digitValue
        charIndex += 1
      var totalAnswer: seq[int64] = @[0'i64]
      var base = maxDigit + 1
      if base < 2:
        base = 2
      while base <= digitCount:
        var numberValue: seq[int64] = @[0'i64]
        for digitValue in numberDigits:
          multiplyAdd(numberValue, base, digitValue)
        addBig(totalAnswer, numberValue)
        base += 1
      appendOutput(bigToString(totalAnswer))
      outputBuffer.add '\n'
  else:
    inDataset = false
  lineStart = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
