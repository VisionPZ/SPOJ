const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxQueryLimit = 1000000

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

proc appendIntLine(val: int) =
  outBuffer.add $val
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc main() =
  var phi = newSeq[int32](maxQueryLimit + 1)
  for idx in 1 .. maxQueryLimit:
    phi[idx] = int32(idx)
  for prime in 2 .. maxQueryLimit:
    if phi[prime] == int32(prime):
      var mult = prime
      while mult <= maxQueryLimit:
        phi[mult] -= phi[mult] div int32(prime)
        mult += prime

  let inputData = readInputBytes()
  var scanPos = 0
  let caseCount = nextInt(inputData, scanPos)
  for caseIdx in 0 ..< caseCount:
    let targetVal = nextInt(inputData, scanPos)
    appendIntLine(int(phi[targetVal]))
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
