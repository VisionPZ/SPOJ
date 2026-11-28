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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let patternLength = nextInt(inputData, scanPos)
let textChars = nextWord(inputData, scanPos)
let charCount = textChars.len

var oddRadius = newSeq[int](charCount)
var oddLeft = 0
var oddRight = -1
for centerIndex in 0 .. charCount - 1:
  var radius = 1
  if centerIndex <= oddRight:
    let mirrorIndex = oddLeft + oddRight - centerIndex
    let available = oddRight - centerIndex + 1
    radius = oddRadius[mirrorIndex]
    if radius > available:
      radius = available
  while centerIndex - radius >= 0 and centerIndex + radius < charCount and textChars[centerIndex - radius] == textChars[centerIndex + radius]:
    radius += 1
  oddRadius[centerIndex] = radius
  if centerIndex + radius - 1 > oddRight:
    oddLeft = centerIndex - radius + 1
    oddRight = centerIndex + radius - 1

var evenRadius = newSeq[int](charCount)
var evenLeft = 0
var evenRight = -1
for centerIndex in 0 .. charCount - 1:
  var radius = 0
  if centerIndex <= evenRight:
    let mirrorIndex = evenLeft + evenRight - centerIndex + 1
    let available = evenRight - centerIndex + 1
    radius = evenRadius[mirrorIndex]
    if radius > available:
      radius = available
  while centerIndex - radius - 1 >= 0 and centerIndex + radius < charCount and textChars[centerIndex - radius - 1] == textChars[centerIndex + radius]:
    radius += 1
  evenRadius[centerIndex] = radius
  if centerIndex + radius - 1 > evenRight:
    evenLeft = centerIndex - radius
    evenRight = centerIndex + radius - 1

var palindromeCount = 0
if (patternLength and 1) == 1:
  let needed = patternLength div 2 + 1
  for centerIndex in 0 .. charCount - 1:
    if oddRadius[centerIndex] >= needed:
      palindromeCount += 1
else:
  let needed = patternLength div 2
  for centerIndex in 0 .. charCount - 1:
    if evenRadius[centerIndex] >= needed:
      palindromeCount += 1

appendOutput($palindromeCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
