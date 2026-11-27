const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc readInputBytes(): string =
  const chunkSize = 1 shl 12
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

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var val = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10 + (int(data[pos]) - firstDigitValue)
    pos += 1
  val

var outBuffer = newStringOfCap(flushBlockBytes + 32)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let squareCount = nextInt(inputData, scanPos)
  var rectCount = 0
  var height = 1
  while height * height <= squareCount:
    rectCount += (squareCount div height) - height + 1
    height += 1
  outBuffer.add $rectCount
  outBuffer.add '\n'
  stdout.write outBuffer

main()
