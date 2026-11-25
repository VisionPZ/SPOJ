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
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  var suffixMinimum = newSeq[int](elementCount + 1)
  suffixMinimum[elementCount] = 2147483647
  var reverseIndex = elementCount - 1
  while reverseIndex >= 0:
    if values[reverseIndex] < suffixMinimum[reverseIndex + 1]:
      suffixMinimum[reverseIndex] = values[reverseIndex]
    else:
      suffixMinimum[reverseIndex] = suffixMinimum[reverseIndex + 1]
    reverseIndex -= 1
  var beautiful = true
  for leftIndex in 0 .. elementCount - 3:
    if values[leftIndex] > suffixMinimum[leftIndex + 2]:
      beautiful = false
  if beautiful:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
