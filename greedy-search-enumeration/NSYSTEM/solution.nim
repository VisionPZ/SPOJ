const flushBlockBytes = 1 shl 17

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc mcxiValue(token: string): int =
  var total = 0
  var index = 0
  while index < token.len:
    var multiplier = 1
    if token[index] >= '2' and token[index] <= '9':
      multiplier = int(token[index]) - 48
      index += 1
    case token[index]
    of 'm': total += multiplier * 1000
    of 'c': total += multiplier * 100
    of 'x': total += multiplier * 10
    of 'i': total += multiplier
    else: discard
    index += 1
  return total

proc appendMcxi(value: int) =
  var text = ""
  var placeIndex = 0
  while placeIndex < 4:
    var place = 1000
    case placeIndex
    of 1: place = 100
    of 2: place = 10
    of 3: place = 1
    else: discard
    var digit = (value div place) mod 10
    if digit > 1:
      text.add chr(48 + digit)
    if digit > 0:
      case placeIndex
      of 0: text.add 'm'
      of 1: text.add 'c'
      of 2: text.add 'x'
      of 3: text.add 'i'
      else: discard
    placeIndex += 1
  appendOutput(text)

let specificationCount = nextInt(inputData, scanPos)
for specificationIndex in 0 .. specificationCount - 1:
  let firstNumber = mcxiValue(nextToken(inputData, scanPos))
  let secondNumber = mcxiValue(nextToken(inputData, scanPos))
  appendMcxi(firstNumber + secondNumber)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
