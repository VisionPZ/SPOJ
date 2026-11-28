{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

let cityCount = nextNumber(inputData, scanPos)
let roadCount = nextNumber(inputData, scanPos)
var parent: seq[int] = @[]
parent.setLen(cityCount)
var subtreeSize: seq[int] = @[]
subtreeSize.setLen(cityCount)
for city in 0..<cityCount:
  parent[city] = city
  subtreeSize[city] = 1

var componentCount = cityCount
for roadIndex in 0..<roadCount:
  let firstCity = nextNumber(inputData, scanPos)
  let secondCity = nextNumber(inputData, scanPos)
  var firstRoot = findRoot(parent, firstCity)
  var secondRoot = findRoot(parent, secondCity)
  if firstRoot != secondRoot:
    if subtreeSize[firstRoot] < subtreeSize[secondRoot]:
      swap(firstRoot, secondRoot)
    parent[secondRoot] = firstRoot
    subtreeSize[firstRoot] += subtreeSize[secondRoot]
    componentCount -= 1

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($(componentCount - 1))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
