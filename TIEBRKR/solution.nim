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

proc nextStatus(data: string, pos: var int): bool =
  while pos < data.len and not (data[pos] >= 'A' and data[pos] <= 'Z'):
    pos += 1
  var isNoWin = false
  if pos < data.len and data[pos] == 'N':
    isNoWin = true
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    pos += 1
  return not isNoWin

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let ticketCount = nextInt(inputData, scanPos)
var winningTickets = newSeq[int](ticketCount)
var winnerCount = 0
for ticketIndex in 0 .. ticketCount - 1:
  let ticketNumber = nextInt(inputData, scanPos)
  let isWinner = nextStatus(inputData, scanPos)
  if isWinner:
    winningTickets[winnerCount] = ticketNumber
    winnerCount += 1
if winnerCount > 1:
  for position in 1 .. winnerCount - 1:
    let valueToInsert = winningTickets[position]
    var insertionPos = position - 1
    while insertionPos >= 0 and winningTickets[insertionPos] > valueToInsert:
      winningTickets[insertionPos + 1] = winningTickets[insertionPos]
      insertionPos -= 1
    winningTickets[insertionPos + 1] = valueToInsert
appendOutput($winnerCount)
outputBuffer.add '\n'
for winnerIndex in 0 .. winnerCount - 1:
  if winnerIndex > 0:
    outputBuffer.add ' '
  appendOutput($winningTickets[winnerIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
