const flushBlockBytes = 1 shl 17

proc precedence(symbol: char): int =
  if symbol == '+' or symbol == '-': 1
  elif symbol == '*' or symbol == '/': 2
  elif symbol == '^': 3
  else: 0

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ': scanPos = scanPos + 1
  if scanPos > tokenStart: inputData[tokenStart .. scanPos - 1]
  else: ""

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
var caseCount = 0
for digit in nextToken(inputData, scanPos):
  caseCount = caseCount * 10 + int(digit) - 48

var outputBuffer: string
var operatorStack: array[4096, char]

for _ in 1 .. caseCount:
  var expression = nextToken(inputData, scanPos)
  var stackHeight = 0
  for symbol in expression:
    if symbol == '(':
      operatorStack[stackHeight] = symbol
      stackHeight = stackHeight + 1
    elif symbol == ')':
      while stackHeight > 0 and operatorStack[stackHeight - 1] != '(':
        outputBuffer.add operatorStack[stackHeight - 1]
        stackHeight = stackHeight - 1
      stackHeight = stackHeight - 1
    elif symbol == '+' or symbol == '-' or symbol == '*' or symbol == '/' or symbol == '^':
      while stackHeight > 0 and (precedence(operatorStack[stackHeight - 1]) > precedence(symbol) or (precedence(operatorStack[stackHeight - 1]) == precedence(symbol) and symbol != '^')):
        outputBuffer.add operatorStack[stackHeight - 1]
        stackHeight = stackHeight - 1
      operatorStack[stackHeight] = symbol
      stackHeight = stackHeight + 1
    elif symbol >= 'a' and symbol <= 'z':
      outputBuffer.add symbol
  while stackHeight > 0:
    stackHeight = stackHeight - 1
    outputBuffer.add operatorStack[stackHeight]
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
