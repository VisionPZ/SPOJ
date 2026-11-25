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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let attackCount = nextInt(inputData, scanPos)
  let anomalyCount = nextInt(inputData, scanPos)
  var hasLowerAnomaly = newSeq[bool](attackCount + 1)
  var higherAnomalyCount = newSeq[int](attackCount + 1)
  for pairIndex in 0 .. anomalyCount - 1:
    let weakerAttack = nextInt(inputData, scanPos)
    let strongerAttack = nextInt(inputData, scanPos)
    hasLowerAnomaly[strongerAttack] = true
    higherAnomalyCount[weakerAttack] += 1
  var winningAttack = 0
  for attack in 1 .. attackCount:
    if not hasLowerAnomaly[attack] and higherAnomalyCount[attack] == attackCount - attack:
      winningAttack = attack
      break
  if winningAttack != 0:
    appendOutput("2 " & $winningAttack)
  else:
    appendOutput("1")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
