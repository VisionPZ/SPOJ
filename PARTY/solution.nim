const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxBudget = 500

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let budget = nextInt(inputData, i)
  let partyCount = nextInt(inputData, i)
  if budget == 0 and partyCount == 0:
    break
  var bestFun = newSeq[int](budget + 1)
  for j in 0..<partyCount:
    let fee = nextInt(inputData, i)
    let fun = nextInt(inputData, i)
    for k in countdown(budget, fee):
      let candidate = bestFun[k - fee] + fun
      if candidate > bestFun[k]:
        bestFun[k] = candidate
  var topFun = 0
  for k in 0..budget:
    if bestFun[k] > topFun:
      topFun = bestFun[k]
  var cheapest = budget
  for k in 0..budget:
    if bestFun[k] == topFun and k < cheapest:
      cheapest = k
  appendOutput($cheapest)
  outputBuffer.add ' '
  appendOutput($topFun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
