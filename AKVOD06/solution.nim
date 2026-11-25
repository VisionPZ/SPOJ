const flushBlockBytes = 1 shl 17
const maxMoney = 1000

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

var grundyValues = newSeq[seq[int]](maxMoney + 1)
for moneyValue in 0 .. maxMoney:
  grundyValues[moneyValue] = newSeq[int](moneyValue + 1)
for moneyValue in 1 .. maxMoney:
  var seenValues: array[maxMoney + 4, bool]
  for valueIndex in 0 .. maxMoney + 3:
    seenValues[valueIndex] = false
  var currentMex = 0
  for capValue in 1 .. moneyValue:
    let remainingMoney = moneyValue - capValue
    let previousValue = grundyValues[remainingMoney][min(capValue, remainingMoney)]
    seenValues[previousValue] = true
    while seenValues[currentMex]:
      currentMex += 1
    grundyValues[moneyValue][capValue] = currentMex

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let boxCount = nextInt(inputData, scanPos)
  let initialCap = nextInt(inputData, scanPos)
  var nimTotal = 0
  for boxIndex in 0 .. boxCount - 1:
    let moneyInside = nextInt(inputData, scanPos)
    let useCap = min(initialCap, moneyInside)
    nimTotal = nimTotal xor grundyValues[moneyInside][useCap]
  if nimTotal != 0:
    appendOutput("Cartman\n")
  else:
    appendOutput("Butters\n")
stdout.write outputBuffer
outputBuffer.setLen 0
