const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

proc countDecodings(data: string, firstIdx: int, lastIdx: int): int64 =
  let spanLen = lastIdx - firstIdx
  if spanLen <= 0 or data[firstIdx] == '0':
    return 0'i64
  var prevTwo = 1'i64
  var prevOne = 1'i64
  for idx in (firstIdx + 1) ..< lastIdx:
    var currentWays = 0'i64
    if data[idx] != '0':
      currentWays += prevOne
    let pairVal = (int(data[idx - 1]) - firstDigitValue) * 10 + (int(data[idx]) - firstDigitValue)
    if pairVal >= 10 and pairVal <= 26:
      currentWays += prevTwo
    prevTwo = prevOne
    prevOne = currentWays
  prevOne

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  while scanPos < inputData.len:
    while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
      scanPos += 1
    if scanPos >= inputData.len:
      break
    let tokenStart = scanPos
    while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
      scanPos += 1
    let tokenEnd = scanPos
    if tokenEnd - tokenStart == 1 and inputData[tokenStart] == '0':
      break
    appendLine($countDecodings(inputData, tokenStart, tokenEnd))
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
