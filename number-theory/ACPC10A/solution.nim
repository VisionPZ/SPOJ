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

proc nextInt64(data: string, pos: var int, outVal: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var isNeg = false
  if data[pos] == '-':
    isNeg = true
    pos += 1
    while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
      pos += 1
  var val: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10'i64 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  outVal = if isNeg: -val else: val
  true

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendLine(text: string) =
  outBuffer.add text
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  var firstTerm: int64 = 0
  var secondTerm: int64 = 0
  var thirdTerm: int64 = 0
  while nextInt64(inputData, scanPos, firstTerm) and
        nextInt64(inputData, scanPos, secondTerm) and
        nextInt64(inputData, scanPos, thirdTerm):
    if firstTerm == 0 and secondTerm == 0 and thirdTerm == 0:
      break
    let diffFirst = secondTerm - firstTerm
    let diffSecond = thirdTerm - secondTerm
    if diffFirst == diffSecond:
      appendLine("AP " & $(thirdTerm + diffSecond))
    else:
      appendLine("GP " & $((thirdTerm * secondTerm) div firstTerm))
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
