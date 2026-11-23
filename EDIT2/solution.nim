const flushBlockBytes = 1 shl 18
const unreachableCost = 1000000000

proc lessLex(leftSeq, rightSeq: seq[int]): bool =
  let commonLength = min(leftSeq.len, rightSeq.len)
  for index in 0 ..< commonLength:
    if leftSeq[index] < rightSeq[index]:
      return true
    if leftSeq[index] > rightSeq[index]:
      return false
  return leftSeq.len < rightSeq.len

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add(text)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc buildProgram(targetText: string, costTable, dcountTable: seq[seq[int]], startPos, endPos: int): string =
  var reversedKeys = newSeq[char]()
  var leftEdge = startPos
  var rightEdge = endPos
  while leftEdge < rightEdge:
    let appendKeepsCount = costTable[leftEdge][rightEdge] == costTable[leftEdge][rightEdge - 1] + 1
    let appendKeepsDCount = dcountTable[leftEdge][rightEdge] == dcountTable[leftEdge][rightEdge - 1]
    if appendKeepsCount and appendKeepsDCount:
      reversedKeys.add(targetText[rightEdge - 1])
      rightEdge -= 1
    else:
      reversedKeys.add('d')
      rightEdge = leftEdge + (rightEdge - leftEdge) div 2
  var programText = newString(reversedKeys.len)
  for index in 0 ..< reversedKeys.len:
    programText[index] = reversedKeys[reversedKeys.len - 1 - index]
  return programText

proc solveCase(targetText: string, outputBuffer: var string) =
  let textLength = targetText.len
  var costTable = newSeq[seq[int]](textLength + 1)
  var dcountTable = newSeq[seq[int]](textLength + 1)
  var lcpTable = newSeq[seq[int]](textLength + 1)
  for rowIndex in 0 .. textLength:
    costTable[rowIndex] = newSeq[int](textLength + 1)
    dcountTable[rowIndex] = newSeq[int](textLength + 1)
    lcpTable[rowIndex] = newSeq[int](textLength + 1)
  var leftPos = textLength - 1
  while leftPos >= 0:
    var rightPos = textLength - 1
    while rightPos >= 0:
      if targetText[leftPos] == targetText[rightPos]:
        lcpTable[leftPos][rightPos] = lcpTable[leftPos + 1][rightPos + 1] + 1
      rightPos -= 1
    leftPos -= 1
  for segmentLength in 1 .. textLength:
    for startPos in 0 .. (textLength - segmentLength):
      let endPosition = startPos + segmentLength
      var bestCost = costTable[startPos][endPosition - 1] + 1
      var bestDCount = dcountTable[startPos][endPosition - 1]
      if segmentLength mod 2 == 0:
        let halfLength = segmentLength div 2
        if lcpTable[startPos][startPos + halfLength] >= halfLength:
          let doubleCost = costTable[startPos][startPos + halfLength] + 1
          let doubleDCount = dcountTable[startPos][startPos + halfLength] + 1
          if doubleCost < bestCost or (doubleCost == bestCost and doubleDCount < bestDCount):
            bestCost = doubleCost
            bestDCount = doubleDCount
      costTable[startPos][endPosition] = bestCost
      dcountTable[startPos][endPosition] = bestDCount
  var dpCost = newSeq[int](textLength + 1)
  var dpLines = newSeq[int](textLength + 1)
  var dpPrevious = newSeq[int](textLength + 1)
  var dpCostSeqs = newSeq[seq[int]](textLength + 1)
  for index in 0 .. textLength:
    dpCost[index] = unreachableCost
  dpCost[0] = 0
  for endPosition in 1 .. textLength:
    for splitPos in 0 ..< endPosition:
      let lineCost = costTable[splitPos][endPosition]
      let candidateCost = dpCost[splitPos] + lineCost + 1
      let candidateLines = dpLines[splitPos] + 1
      var candidateSeq = newSeq[int](dpCostSeqs[splitPos].len + 1)
      for index in 0 ..< dpCostSeqs[splitPos].len:
        candidateSeq[index] = dpCostSeqs[splitPos][index]
      candidateSeq[candidateSeq.len - 1] = lineCost
      var isBetter = false
      if candidateCost < dpCost[endPosition]:
        isBetter = true
      elif candidateCost == dpCost[endPosition]:
        if candidateLines < dpLines[endPosition]:
          isBetter = true
        elif candidateLines == dpLines[endPosition]:
          if lessLex(candidateSeq, dpCostSeqs[endPosition]):
            isBetter = true
      if isBetter:
        dpCost[endPosition] = candidateCost
        dpLines[endPosition] = candidateLines
        dpPrevious[endPosition] = splitPos
        dpCostSeqs[endPosition] = candidateSeq
  let totalKeystrokes = dpCost[textLength] + 1
  var boundaryList = newSeq[int]()
  var boundaryPos = textLength
  while boundaryPos > 0:
    boundaryList.add(boundaryPos)
    boundaryPos = dpPrevious[boundaryPos]
  boundaryList.add(0)
  var forwardBoundaries = newSeq[int]()
  for index in 0 ..< boundaryList.len:
    forwardBoundaries.add(boundaryList[boundaryList.len - 1 - index])
  appendOutput(outputBuffer, $totalKeystrokes)
  appendOutput(outputBuffer, "\n")
  for boundaryIndex in 0 ..< (forwardBoundaries.len - 1):
    let programText = buildProgram(targetText, costTable, dcountTable, forwardBoundaries[boundaryIndex], forwardBoundaries[boundaryIndex + 1])
    appendOutput(outputBuffer, programText)
    appendOutput(outputBuffer, "\n")
  appendOutput(outputBuffer, "\n")

proc main() =
  var inputData = ""
  var inputLine = ""
  while stdin.readLine(inputLine):
    inputData.add(inputLine)
    inputData.add('\n')
  var outputBuffer = ""
  var scanPos = 0
  var caseIndex = 0
  while scanPos < inputData.len and caseIndex < 10:
    var lineEnd = scanPos
    while lineEnd < inputData.len and inputData[lineEnd] != '\n':
      lineEnd += 1
    var targetText = inputData[scanPos ..< lineEnd]
    if targetText.len > 0 and targetText[targetText.len - 1] == '\r':
      targetText.setLen(targetText.len - 1)
    scanPos = lineEnd + 1
    caseIndex += 1
    solveCase(targetText, outputBuffer)
  if outputBuffer.len > 0:
    stdout.write(outputBuffer)

main()
