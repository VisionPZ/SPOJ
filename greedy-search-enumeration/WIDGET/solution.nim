const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusDays = 7
const inverseValues = [0'u8, 1'u8, 4'u8, 5'u8, 2'u8, 3'u8, 6'u8]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextDayIndex(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let firstChar = data[pos]
  let secondChar = data[pos + 1]
  pos += 3
  case firstChar
  of 'M': return 0
  of 'T':
    if secondChar == 'U': return 1
    return 3
  of 'W': return 2
  of 'F': return 4
  of 'S':
    if secondChar == 'A': return 5
    return 6
  else: return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendDays(residue: int) =
  var dayCount = residue
  if dayCount <= 2:
    dayCount += modulusDays
  appendOutput($dayCount)

while true:
  let typeCount = nextInt(inputData, scanPos)
  let recordCount = nextInt(inputData, scanPos)
  if typeCount == 0 and recordCount == 0:
    break
  let rowWidth = typeCount + 1
  var equations = newSeq[uint8](recordCount * rowWidth)
  for recordIndex in 0 .. recordCount - 1:
    let widgetCount = nextInt(inputData, scanPos)
    let startDay = nextDayIndex(inputData, scanPos)
    let endDay = nextDayIndex(inputData, scanPos)
    let duration = (endDay - startDay + 1 + modulusDays) mod modulusDays
    let rowStart = recordIndex * rowWidth
    equations[rowStart + typeCount] = uint8(duration)
    for widgetIndex in 0 .. widgetCount - 1:
      let widgetType = nextInt(inputData, scanPos) - 1
      let columnIndex = rowStart + widgetType
      equations[columnIndex] = uint8((int(equations[columnIndex]) + 1) mod modulusDays)
  var pivotRow = 0
  var freeColumns = 0
  for columnIndex in 0 .. typeCount - 1:
    var selectedRow = -1
    for rowIndex in pivotRow .. recordCount - 1:
      if equations[rowIndex * rowWidth + columnIndex] != 0'u8:
        selectedRow = rowIndex
        break
    if selectedRow == -1:
      freeColumns += 1
      continue
    if selectedRow != pivotRow:
      for columnScan in columnIndex .. typeCount:
        let pivotValue = equations[pivotRow * rowWidth + columnScan]
        equations[pivotRow * rowWidth + columnScan] = equations[selectedRow * rowWidth + columnScan]
        equations[selectedRow * rowWidth + columnScan] = pivotValue
    let pivotValue = int(equations[pivotRow * rowWidth + columnIndex])
    let scale = int(inverseValues[pivotValue])
    if scale != 1:
      for columnScan in columnIndex .. typeCount:
        let position = pivotRow * rowWidth + columnScan
        equations[position] = uint8((int(equations[position]) * scale) mod modulusDays)
    for rowIndex in 0 .. recordCount - 1:
      if rowIndex == pivotRow:
        continue
      let factor = int(equations[rowIndex * rowWidth + columnIndex])
      if factor == 0:
        continue
      let pivotStart = pivotRow * rowWidth
      let rowStart = rowIndex * rowWidth
      for columnScan in columnIndex .. typeCount:
        let subtraction = (factor * int(equations[pivotStart + columnScan])) mod modulusDays
        equations[rowStart + columnScan] = uint8(
          (int(equations[rowStart + columnScan]) + modulusDays - subtraction) mod modulusDays)
    pivotRow += 1
  var inconsistent = false
  for rowIndex in pivotRow .. recordCount - 1:
    let rowStart = rowIndex * rowWidth
    var zeroCoefficients = true
    for columnIndex in 0 .. typeCount - 1:
      if equations[rowStart + columnIndex] != 0'u8:
        zeroCoefficients = false
        break
    if zeroCoefficients and equations[rowStart + typeCount] != 0'u8:
      inconsistent = true
      break
  if inconsistent:
    appendOutput("Inconsistent data.")
  elif freeColumns > 0:
    appendOutput("Multiple solutions.")
  else:
    for typeIndex in 0 .. typeCount - 1:
      if typeIndex > 0:
        appendOutput(" ")
      appendDays(int(equations[typeIndex * rowWidth + typeCount]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
