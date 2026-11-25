const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 1 .. caseCount:
  let slabWidth = nextInt(inputData, scanPos)
  let slabHeight = nextInt(inputData, scanPos)
  let plateCount = nextInt(inputData, scanPos)

  let widthStride = slabHeight + 1
  let heightStride = slabWidth + 1
  var plateFlags = newSeq[bool]((slabWidth + 1) * widthStride)

  for plateIndex in 0 ..< plateCount:
    let plateWidth = nextInt(inputData, scanPos)
    let plateHeight = nextInt(inputData, scanPos)
    plateFlags[plateWidth * widthStride + plateHeight] = true

  var wasteByWidth = newSeq[int32]((slabWidth + 1) * widthStride)
  var wasteByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var reversedByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var reversedColumn = newSeq[int32](slabHeight + 1)

  for currentWidth in 1 .. slabWidth:
    let rowOffset = currentWidth * widthStride
    for reverseHeight in 0 .. slabHeight:
      reversedColumn[reverseHeight] = 0'i32
    for currentHeight in 1 .. slabHeight:
      let wholeWaste = currentWidth * currentHeight
      var bestWaste = int32(wholeWaste)
      if plateFlags[rowOffset + currentHeight]:
        bestWaste = 0'i32
      else:
        let transposedBase = currentHeight * heightStride
        let widthShift = slabWidth - currentWidth
        for cutWidth in 1 .. currentWidth div 2:
          let candidateWaste = wasteByHeight[transposedBase + cutWidth] +
                               reversedByHeight[transposedBase + widthShift + cutWidth]
          if candidateWaste < bestWaste: bestWaste = candidateWaste
        if bestWaste != 0'i32:
          let columnShift = slabHeight - currentHeight
          for cutHeight in 1 .. currentHeight div 2:
            let candidateWaste = wasteByWidth[rowOffset + cutHeight] +
                                 reversedColumn[columnShift + cutHeight]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
      wasteByWidth[rowOffset + currentHeight] = bestWaste
      reversedColumn[slabHeight - currentHeight] = bestWaste
    for currentHeight in 1 .. slabHeight:
      let transposedBase = currentHeight * heightStride
      let storedWaste = wasteByWidth[rowOffset + currentHeight]
      wasteByHeight[transposedBase + currentWidth] = storedWaste
      reversedByHeight[transposedBase + slabWidth - currentWidth] = storedWaste

  let answer = wasteByWidth[slabWidth * widthStride + slabHeight]
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
