const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc nextType(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'X' and data[pos] != 'F':
    pos += 1
  result = data[pos]
  pos += 1

proc norm(value: int64): int64 =
  let reduced = value mod answerModulus
  if reduced < 0:
    return reduced + answerModulus
  return reduced

proc inverse(value: int64): int64 =
  var baseVal = norm(value)
  var exponentVal = answerModulus - 2
  result = 1'i64
  while exponentVal > 0:
    if exponentVal mod 2 == 1:
      result = result * baseVal mod answerModulus
    baseVal = baseVal * baseVal mod answerModulus
    exponentVal = exponentVal div 2

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let homePosition = nextInt(inputData, scanPos)
  let objectCount = nextInt(inputData, scanPos)
  if homePosition == 0 and objectCount == 0:
    break
  let objectTotal = int(objectCount)
  var objectPos = newSeq[int64](objectTotal + 1)
  var objectProb = newSeq[int64](objectTotal)
  var objectIsWar = newSeq[bool](objectTotal)
  for objectIndex in 0 .. objectTotal - 1:
    let objectType = nextType(inputData, scanPos)
    let place = nextInt(inputData, scanPos)
    let numerator = nextInt(inputData, scanPos)
    let denominator = nextInt(inputData, scanPos)
    objectIsWar[objectIndex] = objectType == 'X'
    objectPos[objectIndex + 1] = place
    objectProb[objectIndex] = numerator * inverse(denominator) mod answerModulus
  var cost = newSeq[int64](objectTotal + 1)
  var weight = newSeq[int64](objectTotal + 1)
  cost[objectTotal] = norm(homePosition - objectPos[objectTotal])
  weight[objectTotal] = 0
  for index in countdown(objectTotal - 1, 0):
    let segmentLength = norm(objectPos[index + 1] - objectPos[index])
    let chance = objectProb[index]
    if objectIsWar[index]:
      cost[index] = norm(segmentLength + chance * cost[index + 1])
      weight[index] = norm(chance * weight[index + 1] + 1 - chance)
    else:
      let denominatorValue = norm(1 - weight[index + 1] * chance)
      let inverseDenominator = inverse(denominatorValue)
      let alpha = cost[index + 1] * inverseDenominator mod answerModulus
      let failureWeight = norm(1 - chance) * weight[index + 1] mod answerModulus
      let beta = failureWeight * inverseDenominator mod answerModulus
      let deal = norm(chance * beta + 1 - chance)
      cost[index] = norm(segmentLength + cost[index + 1] + weight[index + 1] * chance mod answerModulus * alpha)
      weight[index] = norm(weight[index + 1] * deal)
  let closing = inverse(norm(1 - weight[0]))
  appendOutput($(cost[0] * closing mod answerModulus))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
