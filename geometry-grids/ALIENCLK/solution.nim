import strutils

const flushBlockBytes = 1 shl 17
const minutesPerHour = 80
const hoursPerDay = 16
const unitsPerDegree = 32
const unitsPerTurn = 360 * unitsPerDegree
const minuteUnitsPerMinute = 360 * unitsPerDegree div minutesPerHour
const hourUnitsPerMinute = 360 * unitsPerDegree div (hoursPerDay * minutesPerHour)

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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let clockHour = nextInt(inputData, scanPos)
  let clockMinute = nextInt(inputData, scanPos)
  let normalizedHour = clockHour mod hoursPerDay
  let minuteUnits = clockMinute * minuteUnitsPerMinute
  let hourUnits = (normalizedHour * minutesPerHour + clockMinute) * hourUnitsPerMinute
  var separationUnits = hourUnits - minuteUnits
  if separationUnits < 0:
    separationUnits = -separationUnits
  separationUnits = separationUnits mod unitsPerTurn
  if separationUnits > unitsPerTurn div 2:
    separationUnits = unitsPerTurn - separationUnits
  let angleDegrees = float(separationUnits) / float(unitsPerDegree)
  appendOutput(formatFloat(angleDegrees, ffDecimal, 1))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
