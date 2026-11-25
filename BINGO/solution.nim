const flushBlockBytes = 1 shl 18
const uppercaseShift = 32
const slotTableSize = 4096
const hashSeed = 5381
const hashBase = 33
const hashMask = 0x7fffffff

var slotGeneration: array[slotTableSize, int]
var slotWordIndex: array[slotTableSize, int]
var wordPool: seq[string]
var normalizedWord = ""
var activeGeneration = 1
var totalDistinctWords = 0
var completedGameCount = 0
var outputBuffer = ""

proc isAsciiLetter(character: char): bool =
  result = (character >= 'a' and character <= 'z') or
           (character >= 'A' and character <= 'Z')

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isAsciiLetter(data[pos]):
    pos += 1
  if pos >= data.len:
    return ""
  let wordStart = pos
  while pos < data.len and isAsciiLetter(data[pos]):
    pos += 1
  return data[wordStart ..< pos]

proc normalizeWord(rawWord: string) =
  normalizedWord.setLen 0
  for letter in rawWord:
    if letter >= 'A' and letter <= 'Z':
      normalizedWord.add chr(int(letter) + uppercaseShift)
    else:
      normalizedWord.add letter

proc wordHashKey(word: string): int =
  result = hashSeed
  for letter in word:
    result = (result * hashBase + int(letter)) and hashMask

proc noteDistinctWord(word: string) =
  var slotIndex = wordHashKey(word) mod slotTableSize
  while slotGeneration[slotIndex] == activeGeneration:
    if wordPool[slotWordIndex[slotIndex]] == word:
      return
    slotIndex = (slotIndex + 1) mod slotTableSize
  slotGeneration[slotIndex] = activeGeneration
  slotWordIndex[slotIndex] = wordPool.len
  wordPool.add word

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var largerValue = firstValue
  var smallerValue = secondValue
  while smallerValue > 0:
    let remainderValue = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainderValue
  return largerValue

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
while true:
  let rawWord = nextWord(inputData, scanPos)
  if rawWord.len == 0:
    break
  normalizeWord(rawWord)
  if normalizedWord == "bullshit":
    totalDistinctWords += wordPool.len
    completedGameCount += 1
    wordPool.setLen 0
    activeGeneration += 1
  else:
    noteDistinctWord(normalizedWord)

let commonDivisor = greatestCommonDivisor(totalDistinctWords, completedGameCount)
appendOutput($(totalDistinctWords div commonDivisor))
appendOutput(" / ")
appendOutput($(completedGameCount div commonDivisor))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
