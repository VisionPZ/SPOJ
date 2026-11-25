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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc turnClass(dotProduct: int64): int =
  if dotProduct > 0: return 0
  if dotProduct == 0: return 1
  return 2

proc compareTurns(crossFirst: int64, dotFirst: int64, crossSecond: int64, dotSecond: int64): int =
  let classFirst = turnClass(dotFirst)
  let classSecond = turnClass(dotSecond)
  if classFirst != classSecond:
    if classFirst < classSecond: return -1
    return 1
  if classFirst == 1: return 0
  let scaledFirst = crossFirst * crossFirst * (dotSecond * dotSecond)
  let scaledSecond = crossSecond * crossSecond * (dotFirst * dotFirst)
  if classFirst == 0:
    if scaledFirst < scaledSecond: return -1
    if scaledFirst > scaledSecond: return 1
    return 0
  if scaledFirst > scaledSecond: return -1
  if scaledFirst < scaledSecond: return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let heroX = int64(nextInt(inputData, scanPos))
  let heroY = int64(nextInt(inputData, scanPos))
  let heroFaceX = int64(nextInt(inputData, scanPos))
  let heroFaceY = int64(nextInt(inputData, scanPos))
  let heroineX = int64(nextInt(inputData, scanPos))
  let heroineY = int64(nextInt(inputData, scanPos))
  let heroineFaceX = int64(nextInt(inputData, scanPos))
  let heroineFaceY = int64(nextInt(inputData, scanPos))
  let heroDirX = heroFaceX - heroX
  let heroDirY = heroFaceY - heroY
  let heroTargetX = heroineX - heroX
  let heroTargetY = heroineY - heroY
  let heroineDirX = heroineFaceX - heroineX
  let heroineDirY = heroineFaceY - heroineY
  let heroineTargetX = heroX - heroineX
  let heroineTargetY = heroY - heroineY
  let crossHero = heroDirX * heroTargetY - heroDirY * heroTargetX
  let dotHero = heroDirX * heroTargetX + heroDirY * heroTargetY
  let crossHeroine = heroineDirX * heroineTargetY - heroineDirY * heroineTargetX
  let dotHeroine = heroineDirX * heroineTargetX + heroineDirY * heroineTargetY
  let verdict = compareTurns(crossHero, dotHero, crossHeroine, dotHeroine)
  if verdict < 0:
    appendOutput("Hero\n")
  elif verdict > 0:
    appendOutput("Heroine\n")
  else:
    appendOutput("0\n")
stdout.write outputBuffer
outputBuffer.setLen 0
