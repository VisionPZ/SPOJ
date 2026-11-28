import math
import strutils

const flushBlockBytes = 1 shl 17
const rootPrecision = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc normalizeRoot(rootValue: float): float =
  if rootValue == 0.0:
    return 0.0
  return rootValue

let coefficientA = int64(nextInt(inputData, scanPos))
let coefficientB = int64(nextInt(inputData, scanPos))
let coefficientC = int64(nextInt(inputData, scanPos))
let discriminant = coefficientB * coefficientB - 4 * coefficientA * coefficientC
if discriminant < 0:
  appendOutput("0")
  outputBuffer.add '\n'
elif discriminant == 0:
  let rootValue = normalizeRoot(-float64(coefficientB) / (2.0 * float64(coefficientA)))
  appendOutput("1")
  outputBuffer.add '\n'
  appendOutput(formatFloat(rootValue, ffDecimal, rootPrecision))
  outputBuffer.add '\n'
else:
  let rootSqrt = sqrt(float64(discriminant))
  var firstRoot = (-float64(coefficientB) - rootSqrt) / (2.0 * float64(coefficientA))
  var secondRoot = (-float64(coefficientB) + rootSqrt) / (2.0 * float64(coefficientA))
  firstRoot = normalizeRoot(firstRoot)
  secondRoot = normalizeRoot(secondRoot)
  if firstRoot > secondRoot:
    swap(firstRoot, secondRoot)
  appendOutput("2")
  outputBuffer.add '\n'
  appendOutput(formatFloat(firstRoot, ffDecimal, rootPrecision))
  outputBuffer.add ' '
  appendOutput(formatFloat(secondRoot, ffDecimal, rootPrecision))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
