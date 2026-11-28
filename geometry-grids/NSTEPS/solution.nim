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

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var val = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10 + (int(data[pos]) - firstDigitValue)
    pos += 1
  val

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
  let caseCount = nextInt(inputData, scanPos)
  for caseIdx in 0 ..< caseCount:
    let xCoord = nextInt(inputData, scanPos)
    let yCoord = nextInt(inputData, scanPos)
    if xCoord == yCoord or xCoord == yCoord + 2:
      let sumVal = xCoord + yCoord
      let stepVal = if (xCoord and 1) == 0: sumVal else: sumVal - 1
      appendLine($stepVal)
    else:
      appendLine("No Number")
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
