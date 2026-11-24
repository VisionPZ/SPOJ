const firstDigitValue = 48
const rentPerUnit = 3
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextSymbol(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

{.push checks: off.}
let caseCount = nextInt(inputData, i)
var heights: seq[int]
var barStack: seq[int]

for j in 0..<caseCount:
  let rowCount = nextInt(inputData, i)
  let colCount = nextInt(inputData, i)
  heights.setLen colCount
  for l in 0..<colCount:
    heights[l] = 0
  barStack.setLen 0
  var bestArea = 0
  for k in 0..<rowCount:
    barStack.setLen 0
    for l in 0..<colCount:
      let symbol = nextSymbol(inputData, i)
      if symbol == 'F':
        heights[l] += 1
      else:
        heights[l] = 0
    for l in 0..colCount:
      let curHeight = if l == colCount: 0 else: heights[l]
      while barStack.len > 0 and heights[barStack[barStack.len - 1]] > curHeight:
        let barHeight = heights[barStack[barStack.len - 1]]
        barStack.setLen(barStack.len - 1)
        let leftLess = if barStack.len > 0: barStack[barStack.len - 1] else: -1
        let width = l - leftLess - 1
        let area = barHeight * width
        if area > bestArea:
          bestArea = area
      if l < colCount:
        barStack.add l
  appendOutput($(bestArea * rentPerUnit))
  outputBuffer.add '\n'

{.pop.}
stdout.write outputBuffer
outputBuffer.setLen 0
