import tables

const flushBlockBytes = 1 shl 17
const maleGender = 1
const femaleGender = 2
const noGender = 0

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

proc isLowerLetter(character: char): bool =
  return character >= 'a' and character <= 'z'

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isLowerLetter(data[pos]):
    pos += 1
  var word = ""
  while pos < data.len and isLowerLetter(data[pos]):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc extractedParent(word: string, suffixLength: var int): string =
  if word.len >= 2 and word[word.len - 2] == 'j' and word[word.len - 1] == 'k':
    suffixLength = 2
    return word[0 .. word.len - 3]
  if word.len >= 3 and word[word.len - 3] == 'g' and word[word.len - 2] == 'v' and word[word.len - 1] == 'w':
    suffixLength = 3
    return word[0 .. word.len - 4]
  suffixLength = 0
  return ""

var childLinks: seq[seq[int]]
var visitColors: seq[int]

proc hasParentCycle(node: int): bool =
  visitColors[node] = 1
  for childNode in childLinks[node]:
    if visitColors[childNode] == 1:
      return true
    if visitColors[childNode] == 0 and hasParentCycle(childNode):
      return true
  visitColors[node] = 2
  return false

var allNames = initTable[string, int]()
var allNameCount = 0
var unionParent: seq[int]

proc getNameId(name: string): int =
  if not allNames.hasKey(name):
    allNames[name] = allNameCount
    unionParent[allNameCount] = allNameCount
    allNameCount += 1
  return allNames[name]

proc findRoot(node: int): int =
  var current = node
  while unionParent[current] != current:
    current = unionParent[current]
  return current

proc uniteNames(firstNode: int, secondNode: int) =
  let firstRoot = findRoot(firstNode)
  let secondRoot = findRoot(secondNode)
  if firstRoot != secondRoot:
    unionParent[secondRoot] = firstRoot

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var ownNames = newSeq[string](personCount)
  var firstParents = newSeq[string](personCount)
  var secondParents = newSeq[string](personCount)
  var genders = newSeq[int](personCount)
  var nameToIndex = initTable[string, int]()
  var isValid = true
  for personIndex in 0 .. personCount - 1:
    ownNames[personIndex] = nextWord(inputData, scanPos)
    let firstWord = nextWord(inputData, scanPos)
    let secondWord = nextWord(inputData, scanPos)
    var firstSuffixLength = 0
    var secondSuffixLength = 0
    firstParents[personIndex] = extractedParent(firstWord, firstSuffixLength)
    secondParents[personIndex] = extractedParent(secondWord, secondSuffixLength)
    if firstSuffixLength == 0 or secondSuffixLength == 0 or firstSuffixLength != secondSuffixLength:
      isValid = false
    if firstParents[personIndex].len == 0 or secondParents[personIndex].len == 0:
      isValid = false
    if firstParents[personIndex] == secondParents[personIndex]:
      isValid = false
    if firstSuffixLength == 2:
      genders[personIndex] = maleGender
    else:
      genders[personIndex] = femaleGender
    nameToIndex[ownNames[personIndex]] = personIndex
  var partnerOf = initTable[string, string]()
  if isValid:
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      if partnerOf.hasKey(firstParent) and partnerOf[firstParent] != secondParent:
        isValid = false
        break
      if partnerOf.hasKey(secondParent) and partnerOf[secondParent] != firstParent:
        isValid = false
        break
      partnerOf[firstParent] = secondParent
      partnerOf[secondParent] = firstParent
      var firstGender = noGender
      var secondGender = noGender
      if nameToIndex.hasKey(firstParent):
        firstGender = genders[nameToIndex[firstParent]]
      if nameToIndex.hasKey(secondParent):
        secondGender = genders[nameToIndex[secondParent]]
      if firstGender == maleGender and secondGender == maleGender:
        isValid = false
        break
  if isValid:
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      var firstKey = ""
      var secondKey = ""
      if nameToIndex.hasKey(firstParent):
        let parentIndex = nameToIndex[firstParent]
        var leftParent = firstParents[parentIndex]
        var rightParent = secondParents[parentIndex]
        if leftParent > rightParent:
          swap leftParent, rightParent
        firstKey = leftParent & "|" & rightParent
      if nameToIndex.hasKey(secondParent):
        let parentIndex = nameToIndex[secondParent]
        var leftParent = firstParents[parentIndex]
        var rightParent = secondParents[parentIndex]
        if leftParent > rightParent:
          swap leftParent, rightParent
        secondKey = leftParent & "|" & rightParent
      if firstKey != "" and firstKey == secondKey:
        isValid = false
        break
  if isValid:
    childLinks = newSeq[seq[int]](personCount)
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      if nameToIndex.hasKey(firstParent):
        childLinks[nameToIndex[firstParent]].add personIndex
      if nameToIndex.hasKey(secondParent):
        childLinks[nameToIndex[secondParent]].add personIndex
    visitColors = newSeq[int](personCount)
    for personIndex in 0 .. personCount - 1:
      if visitColors[personIndex] == 0 and hasParentCycle(personIndex):
        isValid = false
        break
  if isValid:
    allNames = initTable[string, int]()
    allNameCount = 0
    unionParent = newSeq[int](3 * personCount + 2)
    for personIndex in 0 .. personCount - 1:
      let childId = getNameId(ownNames[personIndex])
      let firstId = getNameId(firstParents[personIndex])
      let secondId = getNameId(secondParents[personIndex])
      uniteNames(childId, firstId)
      uniteNames(childId, secondId)
    let baseRoot = findRoot(getNameId(ownNames[0]))
    for personIndex in 1 .. personCount - 1:
      if findRoot(getNameId(ownNames[personIndex])) != baseRoot:
        isValid = false
        break
  if isValid:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
