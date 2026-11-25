import math
import strutils

const flushBlockBytes = 1 shl 17
const decimalPlaces = 6

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-' and data[pos] != '.':
    pos += 1
  var tokenStart = pos
  while pos < data.len and ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-' or data[pos] == '.'):
    pos += 1
  if pos == tokenStart:
    return 0.0
  return parseFloat(data[tokenStart .. pos - 1])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let enteredNumber = nextNumber(inputData, scanPos)
if enteredNumber < 0:
  appendOutput("Accept positive number only!")
else:
  let formattedInput = formatFloat(enteredNumber, ffDecimal, decimalPlaces)
  let formattedRoot = formatFloat(sqrt(enteredNumber), ffDecimal, decimalPlaces)
  appendOutput("Square root of " & formattedInput & " is " & formattedRoot)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
