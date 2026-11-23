const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxBudget = 500

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let budget = nextInt(inputData, scanPos)
  let partyCount = nextInt(inputData, scanPos)
  if budget == 0 and partyCount == 0:
    break
  var bestFun = newSeq[int](budget + 1)
  for partyIndex in 0..<partyCount:
    let fee = nextInt(inputData, scanPos)
    let fun = nextInt(inputData, scanPos)
    for spent in countdown(budget, fee):
      let candidate = bestFun[spent - fee] + fun
      if candidate > bestFun[spent]:
        bestFun[spent] = candidate
  var topFun = 0
  for spent in 0..budget:
    if bestFun[spent] > topFun:
      topFun = bestFun[spent]
  var cheapest = budget
  for spent in 0..budget:
    if bestFun[spent] == topFun and spent < cheapest:
      cheapest = spent
  appendOutput($cheapest)
  outputBuffer.add ' '
  appendOutput($topFun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
