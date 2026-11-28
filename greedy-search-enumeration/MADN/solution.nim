const flushBlockBytes = 1 shl 17
const vowelCapacity = 21
const consonantCapacity = 5
const vowelOrder = "AUEOI"
const consonantOrder = "JSBKTCLDMVNWFXGPYHQZR"

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

proc sortChars(values: var seq[char]) =
  for index in 1 ..< values.len:
    let currentValue = values[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and values[previousIndex] > currentValue:
      values[previousIndex + 1] = values[previousIndex]
      previousIndex -= 1
    values[previousIndex + 1] = currentValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let nameLength = nextInt(inputData, scanPos)
  let vowelSlots = (nameLength + 1) div 2
  let consonantSlots = nameLength div 2
  var vowelChars: seq[char] = @[]
  var consonantChars: seq[char] = @[]
  var remainingVowels = vowelSlots
  for vowelChar in vowelOrder:
    if remainingVowels <= 0: break
    let taken = min(remainingVowels, vowelCapacity)
    for copyIndex in 0 ..< taken:
      vowelChars.add vowelChar
    remainingVowels -= taken
  var remainingConsonants = consonantSlots
  for consonantChar in consonantOrder:
    if remainingConsonants <= 0: break
    let taken = min(remainingConsonants, consonantCapacity)
    for copyIndex in 0 ..< taken:
      consonantChars.add consonantChar
    remainingConsonants -= taken
  sortChars(vowelChars)
  sortChars(consonantChars)
  var luckyName = ""
  for position in 0 ..< nameLength:
    if (position mod 2) == 0:
      luckyName.add vowelChars[position div 2]
    else:
      luckyName.add consonantChars[position div 2]
  appendOutput("Case " & $caseNumber & ": " & luckyName)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
