const flushBlockBytes = 1 shl 16
const firstDigitValue = 48
const firstUpperValue = 65
const dashCharacter = '-'
const morseCodes = [
  ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
  "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
  "..-", "...-", ".--", "-..-", "-.--", "--.."
]

var outputBuffer = ""

proc readToken(inputData: string, scanPos: var int, dataLength: int,
               tokenStart: var int, tokenLength: var int) =
  while scanPos < dataLength and inputData[scanPos] <= ' ':
    scanPos += 1
  tokenStart = scanPos
  while scanPos < dataLength and inputData[scanPos] > ' ':
    scanPos += 1
  tokenLength = scanPos - tokenStart

proc parseCount(inputData: string, tokenStart: int, tokenLength: int): int =
  result = 0
  for offset in 0 ..< tokenLength:
    result = result * 10 + (int(inputData[tokenStart + offset]) - firstDigitValue)

proc addWordToTrie(inputData: string, wordStart: int, wordLength: int,
                   trieDotChild: var seq[int], trieDashChild: var seq[int],
                   trieWordCount: var seq[int]) =
  var nodeIndex = 0
  for letterOffset in 0 ..< wordLength:
    let code = morseCodes[int(inputData[wordStart + letterOffset]) - firstUpperValue]
    for pulseOffset in 0 ..< code.len:
      if code[pulseOffset] == dashCharacter:
        if trieDashChild[nodeIndex] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDashChild[nodeIndex] = trieWordCount.len - 1
        nodeIndex = trieDashChild[nodeIndex]
      else:
        if trieDotChild[nodeIndex] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDotChild[nodeIndex] = trieWordCount.len - 1
        nodeIndex = trieDotChild[nodeIndex]
  trieWordCount[nodeIndex] += 1

proc countDecodings(inputData: string, morseStart: int, morseLength: int,
                    ways: var seq[int], trieDotChild: seq[int],
                    trieDashChild: seq[int], trieWordCount: seq[int]): int =
  for position in 0 .. morseLength:
    ways[position] = 0
  ways[0] = 1
  for startPos in 0 ..< morseLength:
    let waysHere = ways[startPos]
    if waysHere == 0:
      continue
    var nodeIndex = 0
    var endPos = startPos
    while endPos < morseLength:
      var nextNode: int
      if inputData[morseStart + endPos] == dashCharacter:
        nextNode = trieDashChild[nodeIndex]
      else:
        nextNode = trieDotChild[nodeIndex]
      if nextNode == 0:
        break
      nodeIndex = nextNode
      endPos += 1
      let wordCount = trieWordCount[nodeIndex]
      if wordCount != 0:
        ways[endPos] += waysHere * wordCount
  return ways[morseLength]

proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var scanPos = 0
  var tokenStart = 0
  var tokenLength = 0
  readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
  let dataSetCount = parseCount(inputData, tokenStart, tokenLength)
  var ways: seq[int] = @[1]
  for dataIndex in 0 ..< dataSetCount:
    readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
    let morseStart = tokenStart
    let morseLength = tokenLength
    readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
    let wordCount = parseCount(inputData, tokenStart, tokenLength)
    var trieDotChild: seq[int] = @[0]
    var trieDashChild: seq[int] = @[0]
    var trieWordCount: seq[int] = @[0]
    for wordIndex in 0 ..< wordCount:
      readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
      addWordToTrie(inputData, tokenStart, tokenLength, trieDotChild,
                    trieDashChild, trieWordCount)
    if ways.len <= morseLength:
      ways.setLen(morseLength + 1)
    let answer = countDecodings(inputData, morseStart, morseLength, ways,
                                trieDotChild, trieDashChild, trieWordCount)
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()
