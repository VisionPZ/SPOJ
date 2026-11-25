const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc armLength(armIndex: int, size: int): int =
  if armIndex <= 2:
    return size - 1
  return size - 3 - 2 * ((armIndex - 3) div 2)

proc pointOnArm(armIndex: int, row: int, col: int, size: int): bool =
  if armIndex < 0 or armIndex >= size:
    return false
  if armIndex == 0:
    return col == 0 and row <= size - 1
  let group = (armIndex - 1) div 4
  let kind = (armIndex - 1) mod 4
  let length = armLength(armIndex, size)
  if kind == 0:
    return row == size - 1 - 2 * group and col >= 2 * group + 1 and col <= 2 * group + length
  if kind == 1:
    return col == size - 1 - 2 * group and row >= size - 1 - 2 * group - length and row <= size - 2 * group - 1
  if kind == 2:
    return row == 2 * group and col >= size - 1 - 2 * group - length and col <= size - 2 * group - 1
  return col == 2 * group + 2 and row >= 2 * group + 1 and row <= 2 * group + length

proc spiralCharacter(size: int, row: int, col: int): char =
  if pointOnArm(0, row, col, size):
    return '*'
  if col >= 2 and col mod 2 == 0:
    if pointOnArm(2 * col, row, col, size):
      return '*'
  if (size - 1 - col) mod 2 == 0:
    let distance = size - 1 - col
    if pointOnArm(2 * distance + 2, row, col, size):
      return '*'
    if pointOnArm(2 * distance + 3, row, col, size):
      return '*'
  if row mod 2 == 0:
    if pointOnArm(2 * row + 3, row, col, size):
      return '*'
    if row >= 2:
      if pointOnArm(2 * row + 4, row, col, size):
        return '*'
  if (size - 1 - row) mod 2 == 0:
    let distance = size - 1 - row
    if pointOnArm(2 * distance + 1, row, col, size):
      return '*'
  return '.'

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let oneBasedRow = nextInt(inputData, scanPos)
  let oneBasedCol = nextInt(inputData, scanPos)
  appendOutput($spiralCharacter(size, oneBasedRow - 1, oneBasedCol - 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
