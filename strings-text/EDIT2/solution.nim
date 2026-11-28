const flushBlockBytes = 1 shl 18
const unreachableCost = 1000000000

proc lessLex(leftSeq, rightSeq: seq[int]): bool =
  let commonLength = min(leftSeq.len, rightSeq.len)
  for i in 0 ..< commonLength:
    if leftSeq[i] < rightSeq[i]:
      return true
    if leftSeq[i] > rightSeq[i]:
      return false
  return leftSeq.len < rightSeq.len

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add(text)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc buildProgram(targetText: string, costTable, dcountTable: seq[seq[int]], startPos, endPos: int): string =
  var reversedKeys = newSeq[char]()
  var i = startPos
  var j = endPos
  while i < j:
    let appendKeepsCount = costTable[i][j] == costTable[i][j - 1] + 1
    let appendKeepsDCount = dcountTable[i][j] == dcountTable[i][j - 1]
    if appendKeepsCount and appendKeepsDCount:
      reversedKeys.add(targetText[j - 1])
      j -= 1
    else:
      reversedKeys.add('d')
      j = i + (j - i) div 2
  var programText = newString(reversedKeys.len)
  for i in 0 ..< reversedKeys.len:
    programText[i] = reversedKeys[reversedKeys.len - 1 - i]
  return programText

proc solveCase(targetText: string, outputBuffer: var string) =
  let textLength = targetText.len
  var costTable = newSeq[seq[int]](textLength + 1)
  var dcountTable = newSeq[seq[int]](textLength + 1)
  var lcpTable = newSeq[seq[int]](textLength + 1)
  for i in 0 .. textLength:
    costTable[i] = newSeq[int](textLength + 1)
    dcountTable[i] = newSeq[int](textLength + 1)
    lcpTable[i] = newSeq[int](textLength + 1)
  var i = textLength - 1
  while i >= 0:
    var j = textLength - 1
    while j >= 0:
      if targetText[i] == targetText[j]:
        lcpTable[i][j] = lcpTable[i + 1][j + 1] + 1
      j -= 1
    i -= 1
  for segmentLength in 1 .. textLength:
    for k in 0 .. (textLength - segmentLength):
      let j = k + segmentLength
      var bestCost = costTable[k][j - 1] + 1
      var bestDCount = dcountTable[k][j - 1]
      if segmentLength mod 2 == 0:
        let halfLength = segmentLength div 2
        if lcpTable[k][k + halfLength] >= halfLength:
          let doubleCost = costTable[k][k + halfLength] + 1
          let doubleDCount = dcountTable[k][k + halfLength] + 1
          if doubleCost < bestCost or (doubleCost == bestCost and doubleDCount < bestDCount):
            bestCost = doubleCost
            bestDCount = doubleDCount
      costTable[k][j] = bestCost
      dcountTable[k][j] = bestDCount
  var dpCost = newSeq[int](textLength + 1)
  var dpLines = newSeq[int](textLength + 1)
  var dpPrevious = newSeq[int](textLength + 1)
  var dpCostSeqs = newSeq[seq[int]](textLength + 1)
  for i in 0 .. textLength:
    dpCost[i] = unreachableCost
  dpCost[0] = 0
  for j in 1 .. textLength:
    for k in 0 ..< j:
      let lineCost = costTable[k][j]
      let candidateCost = dpCost[k] + lineCost + 1
      let candidateLines = dpLines[k] + 1
      var candidateSeq = newSeq[int](dpCostSeqs[k].len + 1)
      for i in 0 ..< dpCostSeqs[k].len:
        candidateSeq[i] = dpCostSeqs[k][i]
      candidateSeq[candidateSeq.len - 1] = lineCost
      var isBetter = false
      if candidateCost < dpCost[j]:
        isBetter = true
      elif candidateCost == dpCost[j]:
        if candidateLines < dpLines[j]:
          isBetter = true
        elif candidateLines == dpLines[j]:
          if lessLex(candidateSeq, dpCostSeqs[j]):
            isBetter = true
      if isBetter:
        dpCost[j] = candidateCost
        dpLines[j] = candidateLines
        dpPrevious[j] = k
        dpCostSeqs[j] = candidateSeq
  let totalKeystrokes = dpCost[textLength] + 1
  var boundaryList = newSeq[int]()
  var l = textLength
  while l > 0:
    boundaryList.add(l)
    l = dpPrevious[l]
  boundaryList.add(0)
  var forwardBoundaries = newSeq[int]()
  for i in 0 ..< boundaryList.len:
    forwardBoundaries.add(boundaryList[boundaryList.len - 1 - i])
  appendOutput(outputBuffer, $totalKeystrokes)
  appendOutput(outputBuffer, "\n")
  for j in 0 ..< (forwardBoundaries.len - 1):
    let programText = buildProgram(targetText, costTable, dcountTable, forwardBoundaries[j], forwardBoundaries[j + 1])
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
  var i = 0
  var j = 0
  while i < inputData.len and j < 10:
    var k = i
    while k < inputData.len and inputData[k] != '\n':
      k += 1
    var targetText = inputData[i ..< k]
    if targetText.len > 0 and targetText[targetText.len - 1] == '\r':
      targetText.setLen(targetText.len - 1)
    i = k + 1
    j += 1
    solveCase(targetText, outputBuffer)
  if outputBuffer.len > 0:
    stdout.write(outputBuffer)

main()
