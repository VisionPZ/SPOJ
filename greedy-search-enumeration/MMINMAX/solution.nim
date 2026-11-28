const flushBlockBytes = 1 shl 17
const largeArea = int64(1000000000000000000)

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

proc doubledTriangleArea(firstX: int64, firstY: int64, secondX: int64, secondY: int64,
                         thirdX: int64, thirdY: int64): int64 =
  let crossProduct = (secondX - firstX) * (thirdY - firstY) -
                     (secondY - firstY) * (thirdX - firstX)
  if crossProduct < 0:
    return -crossProduct
  return crossProduct

let scenarioCount = nextInt(inputData, scanPos)
for scenarioIndex in 0 .. scenarioCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  var vertexXs = newSeq[int64](vertexCount)
  var vertexYs = newSeq[int64](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexXs[vertexIndex] = int64(nextInt(inputData, scanPos))
    vertexYs[vertexIndex] = int64(nextInt(inputData, scanPos))
  var bestMaxAreas = newSeq[int64](vertexCount * vertexCount)
  for stateIndex in 0 .. vertexCount * vertexCount - 1:
    bestMaxAreas[stateIndex] = largeArea
  for leftVertex in 0 .. vertexCount - 2:
    bestMaxAreas[leftVertex * vertexCount + leftVertex + 1] = 0
  for spanLength in 2 .. vertexCount - 1:
    for leftVertex in 0 .. vertexCount - spanLength - 1:
      let rightVertex = leftVertex + spanLength
      var smallestMaximum = largeArea
      for splitVertex in leftVertex + 1 .. rightVertex - 1:
        var candidate = doubledTriangleArea(
          vertexXs[leftVertex], vertexYs[leftVertex],
          vertexXs[splitVertex], vertexYs[splitVertex],
          vertexXs[rightVertex], vertexYs[rightVertex])
        let leftMaximum = bestMaxAreas[leftVertex * vertexCount + splitVertex]
        if leftMaximum > candidate:
          candidate = leftMaximum
        let rightMaximum = bestMaxAreas[splitVertex * vertexCount + rightVertex]
        if rightMaximum > candidate:
          candidate = rightMaximum
        if candidate < smallestMaximum:
          smallestMaximum = candidate
      bestMaxAreas[leftVertex * vertexCount + rightVertex] = smallestMaximum
  let answerDoubled = bestMaxAreas[vertexCount - 1]
  let wholePart = answerDoubled div 2
  if answerDoubled mod 2 == 0:
    appendOutput($wholePart & ".0\n")
  else:
    appendOutput($wholePart & ".5\n")
stdout.write outputBuffer
outputBuffer.setLen 0
