import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
var lineCount = 0
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
  lineCount += 1

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextLine(data: string, pos: var int): string =
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  result = data[pos ..< lineEnd]
  pos = lineEnd + 1

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc isOperatorToken(token: string): bool =
  return token == "+" or token == "-" or token == "*" or token == "/"

proc parseNumber(token: string, value: var float): bool =
  if token.len == 0:
    return false
  var charIndex = 0
  if token[0] == '+' or token[0] == '-':
    charIndex = 1
  var digitsBeforeDot = 0
  var digitsAfterDot = 0
  var exponentDigits = 0
  var dotSeen = false
  var exponentSeen = false
  var exponentSignSeen = false
  while charIndex < token.len:
    let currentChar = token[charIndex]
    if currentChar >= '0' and currentChar <= '9':
      if exponentSeen:
        exponentDigits += 1
      elif dotSeen:
        digitsAfterDot += 1
      else:
        digitsBeforeDot += 1
    elif currentChar == '.' and not dotSeen and not exponentSeen:
      dotSeen = true
    elif (currentChar == 'e' or currentChar == 'E') and not exponentSeen and
         digitsBeforeDot + digitsAfterDot > 0:
      exponentSeen = true
    elif (currentChar == '+' or currentChar == '-') and exponentSeen and
         not exponentSignSeen and exponentDigits == 0:
      exponentSignSeen = true
    else:
      return false
    charIndex += 1
  if digitsBeforeDot + digitsAfterDot == 0:
    return false
  if exponentSeen and exponentDigits == 0:
    return false
  if not dotSeen and not exponentSeen and token.len <= 16:
    var tokenPos = 0
    let integerValue = nextInt(token, tokenPos)
    value = float(integerValue)
    if token[0] == '-':
      value = -value
    return true
  try:
    value = parseFloat(token)
  except ValueError:
    return false
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var valueStack: seq[float]
var linePos = 0
var lineIndex = 0
while lineIndex < lineCount:
  let expressionText = nextLine(inputData, linePos)
  valueStack.setLen 0
  var expressionValid = true
  scanPos = 0
  var hasToken = false
  while true:
    let currentToken = nextToken(expressionText, scanPos)
    if currentToken.len == 0:
      break
    hasToken = true
    if isOperatorToken(currentToken):
      if valueStack.len < 2:
        expressionValid = false
        break
      let rightOperand = valueStack[valueStack.len - 1]
      let leftOperand = valueStack[valueStack.len - 2]
      valueStack.setLen(valueStack.len - 1)
      if currentToken == "+":
        valueStack[valueStack.len - 1] = leftOperand + rightOperand
      elif currentToken == "-":
        valueStack[valueStack.len - 1] = leftOperand - rightOperand
      elif currentToken == "*":
        valueStack[valueStack.len - 1] = leftOperand * rightOperand
      else:
        if rightOperand == 0.0:
          expressionValid = false
          break
        valueStack[valueStack.len - 1] = leftOperand / rightOperand
    else:
      var parsedValue = 0.0
      if not parseNumber(currentToken, parsedValue):
        expressionValid = false
        break
      valueStack.add parsedValue
  if expressionValid and hasToken and valueStack.len == 1:
    appendOutput(formatFloat(valueStack[0], ffDecimal, 4))
  else:
    appendOutput("ERROR")
  outputBuffer.add '\n'
  lineIndex += 1
stdout.write outputBuffer
