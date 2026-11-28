const flushBlockBytes = 1 shl 17
const wordBits = 64
const maxParts = 60
const maxTotalWeight = 60000
const wordCount = 940

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc shiftInto(destination: var seq[uint64], source: seq[uint64], wordShift: int, bitShift: int, lastWord: int) =
  if bitShift == 0:
    for wordIndex in countdown(lastWord, wordShift):
      destination[wordIndex] = destination[wordIndex] or source[wordIndex - wordShift]
  else:
    if lastWord > wordShift:
      for wordIndex in countdown(lastWord, wordShift + 1):
        let lowerWord = source[wordIndex - wordShift - 1]
        let upperWord = source[wordIndex - wordShift]
        destination[wordIndex] = destination[wordIndex] or ((upperWord shl bitShift) or (lowerWord shr (wordBits - bitShift)))
    destination[wordShift] = destination[wordShift] or (source[0] shl bitShift)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let partCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  if partCount == 0 and queryCount == 0:
    break
  var reachable = newSeq[seq[uint64]](maxParts + 1)
  for pieceCount in 0 .. maxParts:
    reachable[pieceCount] = newSeq[uint64](wordCount)
  reachable[0][0] = 1'u64
  var activeParts = 0
  var currentLimit = 0
  for partIndex in 0 ..< partCount:
    let partWeight = nextInt(inputData, scanPos)
    let wordShift = partWeight div wordBits
    let bitShift = partWeight mod wordBits
    let lastWord = min(wordCount - 1, (currentLimit + partWeight) div wordBits)
    let nextParts = activeParts + 1
    if nextParts > 0:
      for pieceCount in countdown(nextParts, 1):
        shiftInto(reachable[pieceCount], reachable[pieceCount - 1], wordShift, bitShift, lastWord)
    activeParts = nextParts
    currentLimit = min(maxTotalWeight, currentLimit + partWeight)
  for queryIndex in 0 ..< queryCount:
    let targetWeight = nextInt(inputData, scanPos)
    if targetWeight < 0 or targetWeight > maxTotalWeight:
      appendOutput("That's impossible!\n")
    else:
      let targetWord = targetWeight div wordBits
      let targetMask = 1'u64 shl (targetWeight mod wordBits)
      var hasPieceCount = false
      for pieceCount in 1 .. activeParts:
        if (reachable[pieceCount][targetWord] and targetMask) != 0'u64:
          if hasPieceCount:
            appendOutput(" ")
          appendOutput($pieceCount)
          hasPieceCount = true
      if not hasPieceCount:
        appendOutput("That's impossible!")
      appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
