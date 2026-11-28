import algorithm

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type SpendingRecord = object
  friendName: string
  totalExpense: int64

proc compareByName(leftRecord: SpendingRecord, rightRecord: SpendingRecord): int =
  cmp(leftRecord.friendName, rightRecord.friendName)

proc compareByExpense(leftRecord: SpendingRecord, rightRecord: SpendingRecord): int =
  if leftRecord.totalExpense > rightRecord.totalExpense:
    return -1
  if leftRecord.totalExpense < rightRecord.totalExpense:
    return 1
  return 0

while hasMoreData(inputData, scanPos):
  let giftCount = nextInt(inputData, scanPos)
  let unfriendLimit = nextInt(inputData, scanPos)
  var spendingRecords = newSeq[SpendingRecord](giftCount)
  for recordIndex in 0 .. giftCount - 1:
    spendingRecords[recordIndex].friendName = nextToken(inputData, scanPos)
    spendingRecords[recordIndex].totalExpense = int64(nextInt(inputData, scanPos))
  spendingRecords.sort(compareByName)
  var friendTotals = newSeq[SpendingRecord]()
  for record in spendingRecords:
    if friendTotals.len > 0 and friendTotals[friendTotals.len - 1].friendName == record.friendName:
      friendTotals[friendTotals.len - 1].totalExpense += record.totalExpense
    else:
      friendTotals.add record
  friendTotals.sort(compareByExpense)
  let takeCount = min(unfriendLimit, friendTotals.len)
  var sparedMoney: int64 = 0
  for recordIndex in 0 .. takeCount - 1:
    sparedMoney += friendTotals[recordIndex].totalExpense
  appendOutput($sparedMoney)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
