const flushBlockBytes = 1 shl 17
const countMask = 4294967295'i64

type Query = object
  kind: int
  leftIndex: int
  rightIndex: int
  parameter: int
  order: int

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

let itemCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var values = newSeq[int](itemCount)
var totalSum = 0
for itemIndex in 0 .. itemCount - 1:
  values[itemIndex] = nextInt(inputData, scanPos)
  totalSum += values[itemIndex]
var queriesByLeft = newSeq[seq[Query]](itemCount)
for queryIndex in 0 .. queryCount - 1:
  var query: Query
  query.kind = nextInt(inputData, scanPos)
  query.leftIndex = nextInt(inputData, scanPos) - 1
  query.rightIndex = nextInt(inputData, scanPos) - 1
  query.parameter = nextInt(inputData, scanPos)
  query.order = queryIndex
  queriesByLeft[query.leftIndex].add query
var answers = newSeq[int](queryCount)
var counts = newSeq[int64](totalSum + 1)
var reachable = newSeq[bool](totalSum + 1)

for leftIndex in 0 .. itemCount - 1:
  for sumIndex in 0 .. totalSum:
    counts[sumIndex] = 0'i64
    reachable[sumIndex] = false
  counts[0] = 1'i64
  reachable[0] = true
  var currentSum = 0
  for rightIndex in leftIndex .. itemCount - 1:
    let addedValue = values[rightIndex]
    var sumIndex = currentSum
    while sumIndex >= 0:
      let previousCount = counts[sumIndex]
      if previousCount != 0'i64:
        counts[sumIndex + addedValue] = (counts[sumIndex + addedValue] + previousCount) and countMask
      if reachable[sumIndex]:
        reachable[sumIndex + addedValue] = true
      sumIndex -= 1
    currentSum += addedValue
    for query in queriesByLeft[leftIndex]:
      if query.rightIndex != rightIndex:
        continue
      if query.kind == 1:
        if query.parameter > currentSum:
          answers[query.order] = 0
        else:
          var result = counts[query.parameter]
          if query.parameter == 0:
            result = (result - 1'i64) and countMask
          answers[query.order] = int(result)
      else:
        var missing = 0
        var found = false
        for value in 1 .. currentSum:
          if not reachable[value]:
            missing += 1
            if missing == query.parameter:
              answers[query.order] = value
              found = true
              break
        if not found:
          answers[query.order] = currentSum + (query.parameter - missing)

for answer in answers:
  appendOutput($(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
