const flushBlockBytes = 1 shl 17
const modValue = 1000000007
const maxScore = 49

var combTable: array[0 .. maxScore, array[0 .. maxScore, int]]
for totalScore in 0 .. maxScore:
  combTable[totalScore][0] = 1
  combTable[totalScore][totalScore] = 1
  for chosen in 1 .. totalScore - 1:
    combTable[totalScore][chosen] =
      (combTable[totalScore - 1][chosen - 1] + combTable[totalScore - 1][chosen]) mod modValue

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstScore = nextInt(inputData, scanPos)
  let secondScore = nextInt(inputData, scanPos)
  var answer = 0
  if firstScore == 25 and secondScore < 24:
    answer = combTable[24 + secondScore][secondScore]
  elif secondScore == 25 and firstScore < 24:
    answer = combTable[24 + firstScore][firstScore]
  elif firstScore >= 24 and secondScore >= 24 and
      (firstScore - secondScore == 2 or secondScore - firstScore == 2):
    var loserScore = firstScore
    if secondScore < firstScore:
      loserScore = secondScore
    var powerBase: int64 = 2
    var exponent = loserScore - 24
    var power: int64 = 1
    while exponent > 0:
      if (exponent and 1) == 1:
        power = power * powerBase mod modValue
      powerBase = powerBase * powerBase mod modValue
      exponent = exponent shr 1
    answer = int(int64(combTable[48][24]) * power mod modValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
