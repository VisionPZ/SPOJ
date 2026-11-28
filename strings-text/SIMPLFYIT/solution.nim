const powerOffset = 10
const powerSpan = 21
const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

proc readSigned(data: string, pos: var int): int =
  var sign = 1
  if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
    if data[pos] == '-':
      sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc parseMonomial(token: string): tuple[coefficient, powerA, powerB: int] =
  var pos = 0
  let coefficient = readSigned(token, pos)
  if pos < token.len and token[pos] == 'a':
    pos += 1
  let powerA = readSigned(token, pos)
  if pos < token.len and token[pos] == 'b':
    pos += 1
  let powerB = readSigned(token, pos)
  return (coefficient, powerA, powerB)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendExpression(coeffs: array[powerSpan, array[powerSpan, int]]) =
  var firstTerm = true
  for powerIndexA in 0..<powerSpan:
    for powerIndexB in 0..<powerSpan:
      let coefficient = coeffs[powerIndexA][powerIndexB]
      if coefficient == 0:
        continue
      if coefficient < 0:
        appendOutput("-")
      elif not firstTerm:
        appendOutput("+")
      let magnitude = abs(coefficient)
      let powerA = powerIndexA - powerOffset
      let powerB = powerIndexB - powerOffset
      if magnitude != 1 or (powerA == 0 and powerB == 0):
        appendOutput($magnitude)
      if powerA > 0:
        appendOutput("a")
        if powerA != 1:
          appendOutput($powerA)
      elif powerA < 0:
        appendOutput("a" & $powerA)
      if powerB > 0:
        appendOutput("b")
        if powerB != 1:
          appendOutput($powerB)
      elif powerB < 0:
        appendOutput("b" & $powerB)
      firstTerm = false
  if firstTerm:
    appendOutput("0")
  appendOutput("\n")

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let testCount = nextInt(inputData, scanPos)
for _ in 0..<testCount:
  var coeffs: array[powerSpan, array[powerSpan, int]]
  let commandCount = nextInt(inputData, scanPos)
  for _ in 0..<commandCount:
    let commandType = nextInt(inputData, scanPos)
    if commandType == 3:
      appendExpression(coeffs)
    else:
      let monomial = parseMonomial(nextToken(inputData, scanPos))
      let powerA = monomial.powerA
      let powerB = monomial.powerB
      if powerA >= -powerOffset and powerA <= powerOffset and
         powerB >= -powerOffset and powerB <= powerOffset:
        let indexA = powerA + powerOffset
        let indexB = powerB + powerOffset
        var delta = monomial.coefficient
        if commandType == 2:
          delta = -delta
        coeffs[indexA][indexB] += delta

stdout.write outputBuffer
outputBuffer.setLen 0
