const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const missingIndex = 1000000000

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var trieChildren = newSeq[int](alphabetSize)
for childIndex in 0 .. alphabetSize - 1:
  trieChildren[childIndex] = -1
var trieBestIndex = newSeq[int](1)
var trieSpellLength = newSeq[int](1)
trieBestIndex[0] = missingIndex
trieSpellLength[0] = 0
var trieNodeCount = 1

proc addTrieNode() =
  trieChildren.setLen(trieChildren.len + alphabetSize)
  let baseIndex = trieChildren.len - alphabetSize
  for childIndex in 0 .. alphabetSize - 1:
    trieChildren[baseIndex + childIndex] = -1
  trieBestIndex.add missingIndex
  trieSpellLength.add 0
  trieNodeCount += 1

proc insertSpell(spell: string, bookIndex: int) =
  var nodeIndex = 0
  var charIndex = spell.len - 1
  while charIndex >= 0:
    let letterIndex = int(spell[charIndex]) - 65
    let baseIndex = nodeIndex * alphabetSize
    var childIndex = trieChildren[baseIndex + letterIndex]
    if childIndex < 0:
      childIndex = trieNodeCount
      addTrieNode()
      trieChildren[baseIndex + letterIndex] = childIndex
    nodeIndex = childIndex
    charIndex -= 1
  if bookIndex < trieBestIndex[nodeIndex]:
    trieBestIndex[nodeIndex] = bookIndex
    trieSpellLength[nodeIndex] = spell.len

let sourceWord = nextWord(inputData, scanPos)
let spellCount = nextInt(inputData, scanPos)
for spellIndex in 0 .. spellCount - 1:
  let spellWord = nextWord(inputData, scanPos)
  insertSpell(spellWord, spellIndex)

var survivorChars = ""
for sourceChar in sourceWord:
  survivorChars.add sourceChar
  while true:
    var nodeIndex = 0
    var stackCursor = survivorChars.len - 1
    var bestBookIndex = missingIndex
    var deleteLength = 0
    while stackCursor >= 0:
      let letterIndex = int(survivorChars[stackCursor]) - 65
      let baseIndex = nodeIndex * alphabetSize
      let childIndex = trieChildren[baseIndex + letterIndex]
      if childIndex < 0:
        break
      nodeIndex = childIndex
      stackCursor -= 1
      if trieBestIndex[nodeIndex] < bestBookIndex:
        bestBookIndex = trieBestIndex[nodeIndex]
        deleteLength = trieSpellLength[nodeIndex]
    if bestBookIndex >= missingIndex:
      break
    survivorChars.setLen(survivorChars.len - deleteLength)

appendOutput(survivorChars)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
