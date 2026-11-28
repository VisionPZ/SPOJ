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

proc readToken(inputData: string, i: var int, dataLength: int,
               j: var int, tokenLength: var int) =
  while i < dataLength and inputData[i] <= ' ':
    i += 1
  j = i
  while i < dataLength and inputData[i] > ' ':
    i += 1
  tokenLength = i - j

proc parseCount(inputData: string, i: int, tokenLength: int): int =
  result = 0
  for j in 0 ..< tokenLength:
    result = result * 10 + (int(inputData[i + j]) - firstDigitValue)

proc addWordToTrie(inputData: string, i: int, wordLength: int,
                   trieDotChild: var seq[int], trieDashChild: var seq[int],
                   trieWordCount: var seq[int]) =
  var j = 0
  for k in 0 ..< wordLength:
    let code = morseCodes[int(inputData[i + k]) - firstUpperValue]
    for l in 0 ..< code.len:
      if code[l] == dashCharacter:
        if trieDashChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDashChild[j] = trieWordCount.len - 1
        j = trieDashChild[j]
      else:
        if trieDotChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDotChild[j] = trieWordCount.len - 1
        j = trieDotChild[j]
  trieWordCount[j] += 1

proc countDecodings(inputData: string, i: int, morseLength: int,
                    ways: var seq[int], trieDotChild: seq[int],
                    trieDashChild: seq[int], trieWordCount: seq[int]): int =
  for j in 0 .. morseLength:
    ways[j] = 0
  ways[0] = 1
  for j in 0 ..< morseLength:
    let waysHere = ways[j]
    if waysHere == 0:
      continue
    var l = 0
    var k = j
    while k < morseLength:
      var nextNode: int
      if inputData[i + k] == dashCharacter:
        nextNode = trieDashChild[l]
      else:
        nextNode = trieDotChild[l]
      if nextNode == 0:
        break
      l = nextNode
      k += 1
      let wordCount = trieWordCount[l]
      if wordCount != 0:
        ways[k] += waysHere * wordCount
  return ways[morseLength]

proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var i = 0
  var j = 0
  var tokenLength = 0
  readToken(inputData, i, dataLength, j, tokenLength)
  let dataSetCount = parseCount(inputData, j, tokenLength)
  var ways: seq[int] = @[1]
  for k in 0 ..< dataSetCount:
    readToken(inputData, i, dataLength, j, tokenLength)
    let l = j
    let morseLength = tokenLength
    readToken(inputData, i, dataLength, j, tokenLength)
    let wordCount = parseCount(inputData, j, tokenLength)
    var trieDotChild: seq[int] = @[0]
    var trieDashChild: seq[int] = @[0]
    var trieWordCount: seq[int] = @[0]
    for k in 0 ..< wordCount:
      readToken(inputData, i, dataLength, j, tokenLength)
      addWordToTrie(inputData, j, tokenLength, trieDotChild,
                    trieDashChild, trieWordCount)
    if ways.len <= morseLength:
      ways.setLen(morseLength + 1)
    let answer = countDecodings(inputData, l, morseLength, ways,
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
