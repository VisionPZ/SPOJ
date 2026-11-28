const flushBlockBytes = 1 shl 17
const maxArrayValue = 1000000
const modulusValue: int64 = 1000000007

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

let countNumbers = nextInt(inputData, scanPos)
var frequencies = newSeq[int](maxArrayValue + 1)
var maxValue = 0
for numberIndex in 0 .. countNumbers - 1:
  let value = nextInt(inputData, scanPos)
  frequencies[value] = frequencies[value] + 1
  if value > maxValue:
    maxValue = value

var powersOfTwo = newSeq[int64](countNumbers + 1)
powersOfTwo[0] = 1
for powerIndex in 1 .. countNumbers:
  powersOfTwo[powerIndex] = (powersOfTwo[powerIndex - 1] * 2) mod modulusValue

var answer: int64 = 0
for baseValue in 1 .. maxValue:
  let multiplicity = frequencies[baseValue]
  if multiplicity == 0:
    continue
  let sameValueWays = (powersOfTwo[multiplicity] - 1 - int64(multiplicity) +
                       2 * modulusValue) mod modulusValue
  answer = (answer + sameValueWays) mod modulusValue
  var ratio = 2
  while baseValue <= maxValue div ratio:
    if baseValue mod ratio == 0 and frequencies[baseValue div ratio] > 0:
      ratio += 1
      continue
    var currentValue = baseValue
    var suffixProducts: int64 = 0
    var chainTotal: int64 = 0
    while currentValue <= maxValue and frequencies[currentValue] > 0:
      let currentFrequency = int64(frequencies[currentValue])
      chainTotal = (chainTotal + currentFrequency * suffixProducts) mod modulusValue
      suffixProducts = currentFrequency * (suffixProducts + 1) mod modulusValue
      if currentValue > maxValue div ratio:
        break
      currentValue = currentValue * ratio
    answer = (answer + chainTotal) mod modulusValue
    ratio += 1

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
