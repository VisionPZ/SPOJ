const flushBlockBytes = 1 shl 17
const smallWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const decadeWords = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

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

proc spellScore(value: int): string =
  if value < 20:
    return smallWords[value]
  let decade = value div 10
  let unit = value mod 10
  if unit == 0:
    return decadeWords[decade]
  return decadeWords[decade] & "-" & smallWords[unit]

proc hasMoreScore(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  return probe < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreScore(inputData, scanPos):
  let score = nextInt(inputData, scanPos)
  appendOutput(spellScore(score))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
