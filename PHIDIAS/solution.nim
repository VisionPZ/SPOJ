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

  var desiredWidths = newSeq[int](plateCount)
  var desiredHeights = newSeq[int](plateCount)
  let widthStride = slabHeight + 1
  let heightStride = slabWidth + 1
  var plateFlags = newSeq[bool]((slabWidth + 1) * widthStride)

  for plateIndex in 0 ..< plateCount:
    let plateWidth = nextInt(inputData, scanPos)
    let plateHeight = nextInt(inputData, scanPos)
    desiredWidths[plateIndex] = plateWidth
    desiredHeights[plateIndex] = plateHeight
    plateFlags[plateWidth * widthStride + plateHeight] = true

  var reachableWidth = newSeq[bool](slabWidth + 1)
  var reachableHeight = newSeq[bool](slabHeight + 1)
  reachableWidth[0] = true
  reachableHeight[0] = true
  for sumValue in 0 .. slabWidth:
    if reachableWidth[sumValue]:
      for plateIndex in 0 ..< plateCount:
        let reached = sumValue + desiredWidths[plateIndex]
        if reached <= slabWidth: reachableWidth[reached] = true
  for sumValue in 0 .. slabHeight:
    if reachableHeight[sumValue]:
      for plateIndex in 0 ..< plateCount:
        let reached = sumValue + desiredHeights[plateIndex]
        if reached <= slabHeight: reachableHeight[reached] = true

  var widthCutValues: seq[int] = @[]
  var heightCutValues: seq[int] = @[]
  var widthCutStart = newSeq[int](slabWidth + 2)
  var widthCutCount = newSeq[int](slabWidth + 1)
  var heightCutStart = newSeq[int](slabHeight + 2)
  var heightCutCount = newSeq[int](slabHeight + 1)
  for currentWidth in 1 .. slabWidth:
    widthCutStart[currentWidth] = widthCutValues.len
    for cutWidth in 1 ..< currentWidth:
      if reachableWidth[cutWidth]: widthCutValues.add cutWidth
    widthCutCount[currentWidth] = widthCutValues.len - widthCutStart[currentWidth]
  for currentHeight in 1 .. slabHeight:
    heightCutStart[currentHeight] = heightCutValues.len
    for cutHeight in 1 ..< currentHeight:
      if reachableHeight[cutHeight]: heightCutValues.add cutHeight
    heightCutCount[currentHeight] = heightCutValues.len - heightCutStart[currentHeight]

  var wasteByWidth = newSeq[int32]((slabWidth + 1) * widthStride)
  var wasteByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var usefulWidthByHeight = newSeq[int](slabHeight + 1)

  for currentWidth in 1 .. slabWidth:
    let rowOffset = currentWidth * widthStride
    var usefulHeightForRow = 0
    for currentHeight in 1 .. slabHeight:
      let wholeWaste = currentWidth * currentHeight
      var bestWaste = int32(wholeWaste)
      if plateFlags[rowOffset + currentHeight]:
        bestWaste = 0'i32
      else:
        if usefulWidthByHeight[currentHeight] > 0:
          let verticalStart = widthCutStart[currentWidth]
          for cutIndex in verticalStart ..< verticalStart + widthCutCount[currentWidth]:
            let cutWidth = widthCutValues[cutIndex]
            let leftOffset = currentHeight * heightStride + cutWidth
            let rightOffset = currentHeight * heightStride + (currentWidth - cutWidth)
            let candidateWaste = wasteByHeight[leftOffset] + wasteByHeight[rightOffset]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
            if bestWaste == 0'i32: break
        if bestWaste != 0'i32 and usefulHeightForRow > 0:
          let horizontalStart = heightCutStart[currentHeight]
          for cutIndex in horizontalStart ..< horizontalStart + heightCutCount[currentHeight]:
            let cutHeight = heightCutValues[cutIndex]
            let lowerOffset = rowOffset + cutHeight
            let upperOffset = rowOffset + (currentHeight - cutHeight)
            let candidateWaste = wasteByWidth[lowerOffset] + wasteByWidth[upperOffset]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
            if bestWaste == 0'i32: break
      if bestWaste < int32(wholeWaste):
        usefulWidthByHeight[currentHeight] += 1
        usefulHeightForRow += 1
      wasteByWidth[rowOffset + currentHeight] = bestWaste
    for currentHeight in 1 .. slabHeight:
      wasteByHeight[currentHeight * heightStride + currentWidth] = wasteByWidth[rowOffset + currentHeight]

  let answer = wasteByWidth[slabWidth * widthStride + slabHeight]
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
