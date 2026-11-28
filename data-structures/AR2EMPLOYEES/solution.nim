const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  let lineText = data[startPos .. pos - 1]
  if pos < data.len:
    pos += 1
  return lineText

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

let headerLine = nextLine(inputData, scanPos)
var headerScanPos = 0
let employeeCount = nextInt(headerLine, headerScanPos)
for employeeIndex in 0 .. employeeCount - 1:
  let employeeId = nextLine(inputData, scanPos)
  let employeeName = nextLine(inputData, scanPos)
  let employeeGender = nextLine(inputData, scanPos)
  let salaryLine = nextLine(inputData, scanPos)
  var salaryScanPos = 0
  let employeeSalary = nextInt(salaryLine, salaryScanPos)
  appendOutput(employeeId & " : " & employeeName & " : " &
               employeeGender & " : " & $employeeSalary)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
