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

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let serverCount = nextInt(inputData, scanPos)
let wireCount = nextInt(inputData, scanPos)
var parentServers = newSeq[int](serverCount)
for serverIndex in 0 .. serverCount - 1:
  parentServers[serverIndex] = serverIndex
var componentCount = serverCount
for wireIndex in 0 .. wireCount - 1:
  let firstServer = nextInt(inputData, scanPos)
  let secondServer = nextInt(inputData, scanPos)
  let firstRoot = findRoot(parentServers, firstServer)
  let secondRoot = findRoot(parentServers, secondServer)
  if firstRoot != secondRoot:
    parentServers[firstRoot] = secondRoot
    componentCount -= 1
appendOutput($componentCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
