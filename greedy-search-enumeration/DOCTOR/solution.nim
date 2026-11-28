const flushBlockBytes = 1 shl 17
const wordCount = 5
const bitsPerWord = 64

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

type DiseaseSet = array[wordCount, int64]

proc isSubset(candidate: DiseaseSet, target: DiseaseSet): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (candidate[wordIndex] and not target[wordIndex]) != 0:
      return false
  return true

proc identical(firstSet: DiseaseSet, secondSet: DiseaseSet): bool =
  for wordIndex in 0 .. wordCount - 1:
    if firstSet[wordIndex] != secondSet[wordIndex]:
      return false
  return true

proc coveredBySubsets(materialSets: seq[DiseaseSet], materialIndex: int): bool =
  var covered: DiseaseSet
  for wordIndex in 0 .. wordCount - 1:
    covered[wordIndex] = 0
  for otherIndex in 0 .. materialSets.len - 1:
    if otherIndex == materialIndex or identical(materialSets[otherIndex], materialSets[materialIndex]):
      continue
    if isSubset(materialSets[otherIndex], materialSets[materialIndex]):
      for wordIndex in 0 .. wordCount - 1:
        covered[wordIndex] = covered[wordIndex] or materialSets[otherIndex][wordIndex]
  for wordIndex in 0 .. wordCount - 1:
    if (materialSets[materialIndex][wordIndex] and not covered[wordIndex]) != 0:
      return false
  return true

while true:
  let diseaseCount = nextInt(inputData, scanPos)
  let materialCount = nextInt(inputData, scanPos)
  if diseaseCount == 0 and materialCount == 0:
    break
  var materialSets = newSeq[DiseaseSet](materialCount)
  for materialIndex in 0 .. materialCount - 1:
    for wordIndex in 0 .. wordCount - 1:
      materialSets[materialIndex][wordIndex] = 0
    let detectedCount = nextInt(inputData, scanPos)
    for detectedIndex in 0 .. detectedCount - 1:
      let diseaseIndex = nextInt(inputData, scanPos) - 1
      let wordIndex = diseaseIndex div bitsPerWord
      let bitIndex = diseaseIndex mod bitsPerWord
      materialSets[materialIndex][wordIndex] = materialSets[materialIndex][wordIndex] or
        (int64(1) shl bitIndex)

  var irreducibleCount = 0
  for materialIndex in 0 .. materialCount - 1:
    var earlierTwin = false
    for otherIndex in 0 .. materialIndex - 1:
      if identical(materialSets[otherIndex], materialSets[materialIndex]):
        earlierTwin = true
        break
    if not earlierTwin and not coveredBySubsets(materialSets, materialIndex):
      irreducibleCount += 1
  appendOutput($(materialCount - irreducibleCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
