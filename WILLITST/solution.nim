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

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var val = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10'i64 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  val

var outBuffer = newStringOfCap(flushBlockBytes + 16)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let startValue = nextInt64(inputData, scanPos)
  if (startValue and (startValue - 1'i64)) == 0'i64:
    outBuffer.add "TAK\n"
  else:
    outBuffer.add "NIE\n"
  stdout.write outBuffer

main()
