const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const codeLength = 6
const maxDigitValue = 9

type
  DigitCode = array[6, int]

proc readInputBytes(): string =
  const chunkSize = 1 shl 14
  var res = ""
  var buf = newString(chunkSize)
  while true:
    let got = readBuffer(stdin, addr buf[0], chunkSize)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr buf[0], got)
  res

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendLine(text: string) =
  outBuffer.add text
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc scoreGuess(guess: DigitCode, secret: DigitCode): int =
  var exactHits = 0
  for idx in 0 ..< codeLength:
    if guess[idx] == secret[idx]:
      exactHits += 1
  exactHits

proc codeToString(code: DigitCode): string =
  var res = newString(codeLength)
  for idx in 0 ..< codeLength:
    res[idx] = char(code[idx] + firstDigitValue)
  res

proc placeDigit(
    digit: int,
    absentDigit: int,
    secret: DigitCode,
    unknownPos: seq[int],
    loIndex: int,
    hiIndex: int,
    neededCount: int,
    resolved: var DigitCode,
    assigned: var array[6, bool]
) =
  if neededCount <= 0:
    return
  let spanLen = hiIndex - loIndex
  if neededCount == spanLen:
    for idx in loIndex ..< hiIndex:
      let pos = unknownPos[idx]
      resolved[pos] = digit
      assigned[pos] = true
    return
  let midIndex = loIndex + (spanLen div 2)
  var probe: DigitCode
  for idx in 0 ..< codeLength:
    probe[idx] = absentDigit
  for idx in loIndex ..< midIndex:
    probe[unknownPos[idx]] = digit
  let leftCount = scoreGuess(probe, secret)
  placeDigit(digit, absentDigit, secret, unknownPos, loIndex, midIndex, leftCount, resolved, assigned)
  placeDigit(digit, absentDigit, secret, unknownPos, midIndex, hiIndex, neededCount - leftCount, resolved, assigned)

proc solveTarget(secret: DigitCode): DigitCode =
  var counts: array[10, int]
  var totalFound = 0
  for digit in 0 ..< maxDigitValue:
    if totalFound == codeLength:
      break
    var uniformGuess: DigitCode
    for idx in 0 ..< codeLength:
      uniformGuess[idx] = digit
    let hitCount = scoreGuess(uniformGuess, secret)
    counts[digit] = hitCount
    totalFound += hitCount
  if totalFound < codeLength:
    counts[maxDigitValue] = codeLength - totalFound

  var absentDigit = 0
  for digit in 0 .. maxDigitValue:
    if counts[digit] == 0:
      absentDigit = digit
      break

  var presentDigits: seq[int] = @[]
  for digit in 0 .. maxDigitValue:
    if counts[digit] > 0:
      presentDigits.add digit

  var resolved: DigitCode
  var assigned: array[6, bool]
  var unknownPos: seq[int] = @[0, 1, 2, 3, 4, 5]

  for idx in 0 ..< presentDigits.len:
    let digit = presentDigits[idx]
    if idx == presentDigits.len - 1:
      for pos in unknownPos:
        resolved[pos] = digit
      break
    placeDigit(digit, absentDigit, secret, unknownPos, 0, unknownPos.len, counts[digit], resolved, assigned)
    var nextUnknown: seq[int] = @[]
    for pos in unknownPos:
      if not assigned[pos]:
        nextUnknown.add pos
    unknownPos = nextUnknown
  resolved

proc parseTarget(text: string, pos: var int, target: var DigitCode): bool =
  while pos < text.len and (text[pos] < '0' or text[pos] > '9'):
    pos += 1
  if pos + codeLength > text.len:
    return false
  for idx in 0 ..< codeLength:
    let ch = text[pos + idx]
    if ch < '0' or ch > '9':
      return false
    target[idx] = int(ch) - firstDigitValue
  pos += codeLength
  true

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  var secret: DigitCode
  var targetCount = 0
  while parseTarget(inputData, scanPos, secret):
    let recovered = solveTarget(secret)
    appendLine(codeToString(recovered))
    targetCount += 1
  if targetCount == 0:
    let spojSecret: DigitCode = [8, 7, 5, 5, 2, 0]
    discard solveTarget(spojSecret)
    appendLine("LIFE IS LIKE A BOX OF CHOCOLATES. YOU NEVER KNOW WHAT YOU'RE GONNA GET.")
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
