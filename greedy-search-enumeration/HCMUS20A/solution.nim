const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let schoolCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and (inputData[scanPos] == ' ' or inputData[scanPos] == '\n' or inputData[scanPos] == '\r'):
  scanPos += 1

var colorSign = newSeq[int](schoolCount + 1)
for schoolIndex in 1 .. schoolCount:
  if inputData[scanPos] == 'B':
    colorSign[schoolIndex] = 1
  else:
    colorSign[schoolIndex] = -1
  scanPos += 1

var happiness = newSeq[int64](schoolCount + 1)
for schoolIndex in 1 .. schoolCount:
  happiness[schoolIndex] = int64(nextInt(inputData, scanPos))

var edgeHead = newSeq[int](schoolCount + 1)
var edgeTarget = newSeq[int](2 * schoolCount + 2)
var edgeNext = newSeq[int](2 * schoolCount + 2)
var edgeCount = 1

proc addEdge(firstSchool: int, secondSchool: int) =
  edgeTarget[edgeCount] = secondSchool
  edgeNext[edgeCount] = edgeHead[firstSchool]
  edgeHead[firstSchool] = edgeCount
  edgeCount += 1

for childSchool in 2 .. schoolCount:
  let parentSchool = nextInt(inputData, scanPos)
  addEdge(parentSchool, childSchool)
  addEdge(childSchool, parentSchool)

var isRemoved = newSeq[bool](schoolCount + 1)
var componentParent = newSeq[int](schoolCount + 1)
var componentSize = newSeq[int](schoolCount + 1)

let balanceOffset = schoolCount + 2
let balanceArraySize = 2 * schoolCount + 5
var bestWeight = newSeq[int64](balanceArraySize)
var bestOwner = newSeq[int](balanceArraySize)
var bestStamp = newSeq[int](balanceArraySize)
var branchWeight = newSeq[int64](balanceArraySize)
var branchStamp = newSeq[int](balanceArraySize)
for index in 0 .. balanceArraySize - 1:
  bestOwner[index] = -1
  bestStamp[index] = -1
  branchStamp[index] = -1
var stampCounter = 0
var branchStampCounter = 0
var bestAnswer: int64 = -(1'i64 shl 60)

var decompositionStack = newSeq[int]()
decompositionStack.add(1)

while decompositionStack.len > 0:
  let startSchool = decompositionStack.pop()
  var componentNodes = newSeq[int]()
  var visitStack = newSeq[int]()
  visitStack.add(startSchool)
  componentParent[startSchool] = 0
  while visitStack.len > 0:
    let currentSchool = visitStack.pop()
    componentNodes.add(currentSchool)
    var edgeIndex = edgeHead[currentSchool]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if neighborSchool != componentParent[currentSchool] and not isRemoved[neighborSchool]:
        componentParent[neighborSchool] = currentSchool
        visitStack.add(neighborSchool)
      edgeIndex = edgeNext[edgeIndex]
  for reverseIndex in countdown(componentNodes.len - 1, 0):
    let currentSchool = componentNodes[reverseIndex]
    var subtreeTotal = 1
    var edgeIndex = edgeHead[currentSchool]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if componentParent[neighborSchool] == currentSchool and not isRemoved[neighborSchool]:
        subtreeTotal += componentSize[neighborSchool]
      edgeIndex = edgeNext[edgeIndex]
    componentSize[currentSchool] = subtreeTotal

  let componentTotal = componentNodes.len
  var centroidSchool = startSchool
  var bestSplit = componentTotal + 1
  for nodeIndex in 0 .. componentTotal - 1:
    let candidate = componentNodes[nodeIndex]
    var largestPart = componentTotal - componentSize[candidate]
    var edgeIndex = edgeHead[candidate]
    while edgeIndex != 0:
      let neighborSchool = edgeTarget[edgeIndex]
      if componentParent[neighborSchool] == candidate and not isRemoved[neighborSchool]:
        if componentSize[neighborSchool] > largestPart:
          largestPart = componentSize[neighborSchool]
      edgeIndex = edgeNext[edgeIndex]
    if largestPart < bestSplit:
      bestSplit = largestPart
      centroidSchool = candidate

  isRemoved[centroidSchool] = true
  stampCounter += 1
  let centroidSign = colorSign[centroidSchool]
  let centroidHappiness = happiness[centroidSchool]
  let centroidBalance = centroidSign + balanceOffset
  bestWeight[centroidBalance] = centroidHappiness
  bestOwner[centroidBalance] = 0
  bestStamp[centroidBalance] = stampCounter
  var touchedBalances = newSeq[int]()
  touchedBalances.add(centroidBalance)

  var centroidEdge = edgeHead[centroidSchool]
  while centroidEdge != 0:
    let branchSchool = edgeTarget[centroidEdge]
    if not isRemoved[branchSchool]:
      let ownerId = branchSchool
      branchStampCounter += 1
      var branchBalances = newSeq[int]()
      var nodeStack = newSeq[int]()
      var balanceStack = newSeq[int]()
      var weightStack = newSeq[int64]()
      nodeStack.add(branchSchool)
      balanceStack.add(centroidSign + colorSign[branchSchool])
      weightStack.add(centroidHappiness + happiness[branchSchool])
      componentParent[branchSchool] = centroidSchool
      while nodeStack.len > 0:
        let currentSchool = nodeStack.pop()
        let currentBalance = balanceStack.pop()
        let currentWeight = weightStack.pop()
        let targetBalance = centroidSign - currentBalance + balanceOffset
        if targetBalance >= 0 and targetBalance < balanceArraySize and bestStamp[targetBalance] == stampCounter:
          let candidateAnswer = currentWeight + bestWeight[targetBalance] - centroidHappiness
          if candidateAnswer > bestAnswer:
            bestAnswer = candidateAnswer
        let storageBalance = currentBalance + balanceOffset
        if storageBalance >= 0 and storageBalance < balanceArraySize:
          if branchStamp[storageBalance] != branchStampCounter:
            branchStamp[storageBalance] = branchStampCounter
            branchBalances.add(storageBalance)
            branchWeight[storageBalance] = currentWeight
          elif currentWeight > branchWeight[storageBalance]:
            branchWeight[storageBalance] = currentWeight
        var edgeIndex = edgeHead[currentSchool]
        while edgeIndex != 0:
          let neighborSchool = edgeTarget[edgeIndex]
          if neighborSchool != componentParent[currentSchool] and not isRemoved[neighborSchool]:
            componentParent[neighborSchool] = currentSchool
            nodeStack.add(neighborSchool)
            balanceStack.add(currentBalance + colorSign[neighborSchool])
            weightStack.add(currentWeight + happiness[neighborSchool])
          edgeIndex = edgeNext[edgeIndex]
      for balanceIndex in 0 .. branchBalances.len - 1:
        let storageBalance = branchBalances[balanceIndex]
        if bestStamp[storageBalance] != stampCounter or branchWeight[storageBalance] > bestWeight[storageBalance]:
          bestStamp[storageBalance] = stampCounter
          bestWeight[storageBalance] = branchWeight[storageBalance]
          bestOwner[storageBalance] = ownerId
          touchedBalances.add(storageBalance)
    centroidEdge = edgeNext[centroidEdge]

  for balanceIndex in 0 .. touchedBalances.len - 1:
    bestStamp[touchedBalances[balanceIndex]] = -1

  centroidEdge = edgeHead[centroidSchool]
  while centroidEdge != 0:
    let neighborSchool = edgeTarget[centroidEdge]
    if not isRemoved[neighborSchool]:
      decompositionStack.add(neighborSchool)
    centroidEdge = edgeNext[centroidEdge]

appendOutput($(bestAnswer))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
