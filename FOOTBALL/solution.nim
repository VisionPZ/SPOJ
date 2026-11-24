type BoundaryState = enum
  statePentagonFace, stateHexagonFace, stateHexagonEdge

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  let dataLength = data.len
  while i < dataLength and (data[i] < '0' or data[i] > '9'):
    i += 1
  result = 0
  while i < dataLength and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - firstDigitValue)
    i += 1

var outputBuffer = ""

proc appendResult(blackCount, whiteCount, greenCount: int) =
  outputBuffer.add $blackCount
  outputBuffer.add ' '
  outputBuffer.add $whiteCount
  outputBuffer.add ' '
  outputBuffer.add $greenCount
  outputBuffer.add " \n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let vertexCount = nextInt(inputData, i)
  var greenPieceSum = 0
  var greenPentagonVertices = 0
  var boundaryState = stateHexagonEdge
  for k in 0..<vertexCount:
    let adjoiningGreenPieces = nextInt(inputData, i)
    greenPieceSum += adjoiningGreenPieces
    case boundaryState
    of statePentagonFace:
      if adjoiningGreenPieces == 1:
        boundaryState = statePentagonFace
      else:
        boundaryState = stateHexagonEdge
      inc greenPentagonVertices
    of stateHexagonFace:
      if adjoiningGreenPieces == 1:
        boundaryState = stateHexagonEdge
      else:
        boundaryState = stateHexagonFace
    of stateHexagonEdge:
      if adjoiningGreenPieces == 1:
        boundaryState = stateHexagonFace
      else:
        boundaryState = statePentagonFace
        inc greenPentagonVertices
  let greenPentagons = 2 * greenPieceSum - 3 * vertexCount + 6
  let greenHexagons = (10 * greenPentagons + greenPieceSum - 3 * greenPentagonVertices) div 6
  appendResult(12 - greenPentagons, 20 - greenHexagons, greenPentagons + greenHexagons)

stdout.write outputBuffer
