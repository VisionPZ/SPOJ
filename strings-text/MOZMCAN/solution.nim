const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let text = nextToken(inputData, scanPos)
  let target = int64(nextInt(inputData, scanPos))
  var insideS = 0
  var insideM = 0
  var smPairs = 0
  var msPairs = 0
  var total: int64 = 0
  var right = 0
  var bestLength = 0
  var bestStart = 0
  var bestEnd = 0
  for left in 0 ..< text.len:
    while right < text.len:
      let incoming = text[right]
      var growth = 0
      if incoming == 's':
        growth = smPairs
      if total + int64(growth) <= target:
        if incoming == 's':
          total += int64(smPairs)
          msPairs += insideM
          insideS += 1
        elif incoming == 'm':
          smPairs += insideS
          insideM += 1
        right += 1
      else:
        break
    if right > left and total == target:
      let length = right - left
      if length > bestLength:
        bestLength = length
        bestStart = left
        bestEnd = right - 1
    if right > left:
      let leaving = text[left]
      if leaving == 's':
        total -= int64(msPairs)
        smPairs -= insideM
        insideS -= 1
      elif leaving == 'm':
        msPairs -= insideS
        insideM -= 1
    else:
      right = left + 1
  if bestLength == 0:
    appendOutput "-1\n"
  else:
    appendOutput($(bestStart + 1) & " " & $(bestEnd + 1) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
