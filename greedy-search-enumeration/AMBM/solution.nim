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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetAmount = int64(nextInt(inputData, scanPos))
  let periodDays = nextInt(inputData, scanPos)
  var dailyPay = newSeq[int64](periodDays)
  var runningPay: int64 = 0
  var totalPay: int64 = 0
  for dayIndex in 0 .. periodDays - 1:
    let basePay = int64(nextInt(inputData, scanPos))
    runningPay = runningPay * 2 + basePay
    dailyPay[dayIndex] = runningPay
    totalPay = totalPay + runningPay
  if totalPay < targetAmount:
    appendOutput("-1")
  else:
    var remaining = targetAmount
    var chosenDays = newSeq[int]()
    var dayIndex = periodDays - 1
    while dayIndex >= 0:
      if dailyPay[dayIndex] <= remaining:
        remaining = remaining - dailyPay[dayIndex]
        chosenDays.add dayIndex + 1
      dayIndex -= 1
    if remaining != 0:
      appendOutput("-1")
    else:
      var outputIndex = chosenDays.len - 1
      while outputIndex >= 0:
        appendOutput($chosenDays[outputIndex])
        if outputIndex > 0:
          appendOutput(" ")
        outputIndex -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
