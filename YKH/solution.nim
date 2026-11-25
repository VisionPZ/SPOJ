import strutils

const flushBlockBytes = 1 shl 17
const answerDecimals = 6

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

proc comesBefore(firstA: int, firstB: int, secondA: int, secondB: int): bool =
  return float64(firstA) * float64(secondB) < float64(secondA) * float64(firstB)

proc sortClients(values: var seq[int]) =
  for outerIndex in 1 .. values.len div 2 - 1:
    var cursor = outerIndex
    while cursor > 0:
      let previous = cursor - 1
      let firstA = values[previous * 2]
      let firstB = values[previous * 2 + 1]
      let secondA = values[cursor * 2]
      let secondB = values[cursor * 2 + 1]
      if comesBefore(secondA, secondB, firstA, firstB):
        let heldA = values[cursor * 2]
        let heldB = values[cursor * 2 + 1]
        values[cursor * 2] = firstA
        values[cursor * 2 + 1] = firstB
        values[previous * 2] = heldA
        values[previous * 2 + 1] = heldB
        cursor = previous
      else:
        break

proc formatAnswer(value: float64): string =
  if value == 0.0:
    return "0"
  result = formatFloat(value, ffDecimal, answerDecimals)
  while result.len > 0 and result[result.len - 1] == '0':
    result.setLen(result.len - 1)
  if result.len > 0 and result[result.len - 1] == '.':
    result.setLen(result.len - 1)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bribe = nextInt(inputData, scanPos)
  let clientCount = nextInt(inputData, scanPos)
  var clients = newSeq[int](clientCount * 2)
  for clientIndex in 0 .. clientCount - 1:
    clients[clientIndex * 2] = nextInt(inputData, scanPos)
    clients[clientIndex * 2 + 1] = nextInt(inputData, scanPos)
  sortClients(clients)
  var prefixA = newSeq[float64](clientCount + 1)
  var prefixB = newSeq[float64](clientCount + 1)
  for clientIndex in 0 .. clientCount - 1:
    prefixA[clientIndex + 1] = prefixA[clientIndex] + float64(clients[clientIndex * 2])
    prefixB[clientIndex + 1] = prefixB[clientIndex] + float64(clients[clientIndex * 2 + 1])
  var bestProfit = newSeq[float64](clientCount + 1)
  for prefixLength in 1 .. clientCount:
    var bestHere = bestProfit[prefixLength - 1]
    for blockStart in 0 .. prefixLength - 1:
      let amountSum = prefixA[prefixLength] - prefixA[blockStart]
      let rateSum = prefixB[prefixLength] - prefixB[blockStart]
      let blockRevenue = amountSum * amountSum / (4.0 * rateSum)
      let candidate = bestProfit[blockStart] + blockRevenue - float64(bribe)
      if candidate > bestHere:
        bestHere = candidate
    bestProfit[prefixLength] = bestHere
  if bestProfit[clientCount] < 0.0:
    bestProfit[clientCount] = 0.0
  appendOutput(formatAnswer(bestProfit[clientCount]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
