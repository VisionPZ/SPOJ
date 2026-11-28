const flushBlockBytes = 1 shl 17
const rateScale = 8192'i64

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc rateNumerator(rateText: string): int64 =
  var fraction = 0'i64
  var denominator = 1'i64
  var index = 0
  while index < rateText.len and rateText[index] != '.':
    index += 1
  if index < rateText.len:
    index += 1
  while index < rateText.len:
    fraction = fraction * 10 + int64(int(rateText[index]) - 48)
    denominator = denominator * 10
    index += 1
  return fraction * rateScale div denominator

proc yearlyInterest(balance: int64, numerator: int64): int64 =
  return balance * numerator div rateScale

proc finalAmount(initialFund: int64, years: int, isCompound: bool,
                 numerator: int64, charge: int64): int64 =
  var balance = initialFund
  var savedInterest = 0'i64
  for yearIndex in 0 .. years - 1:
    var interest = yearlyInterest(balance, numerator)
    if isCompound:
      balance += interest
    else:
      savedInterest += interest
    balance -= charge
  if isCompound:
    return balance
  return balance + savedInterest

let datasetCount = nextInt(inputData, scanPos)
for datasetIndex in 0 .. datasetCount - 1:
  let initialFund = int64(nextInt(inputData, scanPos))
  let years = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var bestAmount = 0'i64
  for operationIndex in 0 .. operationCount - 1:
    let kind = nextInt(inputData, scanPos)
    let numerator = rateNumerator(nextToken(inputData, scanPos))
    let charge = int64(nextInt(inputData, scanPos))
    let amount = finalAmount(initialFund, years, kind == 1, numerator, charge)
    if amount > bestAmount:
      bestAmount = amount
  appendOutput($bestAmount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
