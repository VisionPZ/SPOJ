import algorithm

const flushBlockBytes = 1 shl 17
const rootShiftBits = 17
const rootMultiplier = 1 shl rootShiftBits
const impossibleAnswer = -1

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

proc findRoot(parentSeq: var seq[int], atom: int): int =
  var current = atom
  while parentSeq[current] != current:
    parentSeq[current] = parentSeq[parentSeq[current]]
    current = parentSeq[current]
  return current

proc unionAtoms(parentSeq: var seq[int], sizeSeq: var seq[int], leftAtom: int, rightAtom: int) =
  var leftRoot = findRoot(parentSeq, leftAtom)
  var rightRoot = findRoot(parentSeq, rightAtom)
  if leftRoot == rightRoot:
    return
  if sizeSeq[leftRoot] < sizeSeq[rightRoot]:
    let swapRoot = leftRoot
    leftRoot = rightRoot
    rightRoot = swapRoot
  parentSeq[rightRoot] = leftRoot
  sizeSeq[leftRoot] = sizeSeq[leftRoot] + sizeSeq[rightRoot]

proc compareEncoded(leftValue: int, rightValue: int): int =
  return leftValue - rightValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let atomCount = nextInt(inputData, scanPos)
  let bondCount = nextInt(inputData, scanPos)
  var parentSeq = newSeq[int](atomCount)
  var sizeSeq = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    parentSeq[atomIndex] = atomIndex
    sizeSeq[atomIndex] = 1
  for bondIndex in 0 .. bondCount - 1:
    let leftAtom = nextInt(inputData, scanPos) - 1
    let rightAtom = nextInt(inputData, scanPos) - 1
    unionAtoms(parentSeq, sizeSeq, leftAtom, rightAtom)
  var atomicMasses = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    atomicMasses[atomIndex] = nextInt(inputData, scanPos)
  var componentSeen = newSeq[bool](atomCount)
  var componentCount = 0
  for atomIndex in 0 .. atomCount - 1:
    let rootIndex = findRoot(parentSeq, atomIndex)
    if not componentSeen[rootIndex]:
      componentSeen[rootIndex] = true
      componentCount += 1
  if componentCount == 1:
    appendOutput("0\n")
    continue
  var encodedMasses = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    let rootIndex = findRoot(parentSeq, atomIndex)
    encodedMasses[atomIndex] = atomicMasses[atomIndex] * rootMultiplier + rootIndex
  encodedMasses.sort(compareEncoded)
  var componentChosen = newSeq[bool](atomCount)
  var extraSlotsNeeded = componentCount - 2
  var totalEnergy: int64 = 0
  for atomIndex in 0 .. atomCount - 1:
    let encoded = encodedMasses[atomIndex]
    let mass = encoded div rootMultiplier
    let rootIndex = encoded mod rootMultiplier
    if not componentChosen[rootIndex]:
      componentChosen[rootIndex] = true
      totalEnergy = totalEnergy + int64(mass)
    elif extraSlotsNeeded > 0:
      totalEnergy = totalEnergy + int64(mass)
      extraSlotsNeeded -= 1
  if extraSlotsNeeded > 0:
    appendOutput($impossibleAnswer)
    outputBuffer.add '\n'
  else:
    appendOutput($totalEnergy)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
