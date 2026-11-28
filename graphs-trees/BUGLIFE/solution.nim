const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc readInputBytes(): string =
  const chunkSize = 1 shl 15
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

proc appendText(text: string) =
  outBuffer.add text
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc findRoot(
    parent: var seq[int],
    parity: var seq[int],
    node: int
): tuple[root: int, par: int] =
  var cur = node
  var accPar = 0
  while parent[cur] >= 0:
    accPar = accPar xor parity[cur]
    cur = parent[cur]
  let rootNode = cur
  cur = node
  var downPar = accPar
  while cur != rootNode:
    let nxt = parent[cur]
    let nextStepPar = parity[cur]
    parent[cur] = rootNode
    parity[cur] = downPar
    downPar = downPar xor nextStepPar
    cur = nxt
  result = (rootNode, accPar)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let scenarioCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](2005)
  var parity = newSeq[int](2005)

  for scenarioIdx in 1 .. scenarioCount:
    let bugCount = nextInt(inputData, scanPos)
    let edgeCount = nextInt(inputData, scanPos)
    for idx in 1 .. bugCount:
      parent[idx] = -1
      parity[idx] = 0
    var suspicious = false
    for edgeIdx in 0 ..< edgeCount:
      let bugU = nextInt(inputData, scanPos)
      let bugV = nextInt(inputData, scanPos)
      if suspicious:
        continue
      let infoU = findRoot(parent, parity, bugU)
      let infoV = findRoot(parent, parity, bugV)
      if infoU.root == infoV.root:
        if infoU.par == infoV.par:
          suspicious = true
      else:
        if parent[infoU.root] > parent[infoV.root]:
          parent[infoV.root] += parent[infoU.root]
          parent[infoU.root] = infoV.root
          parity[infoU.root] = infoU.par xor infoV.par xor 1
        else:
          parent[infoU.root] += parent[infoV.root]
          parent[infoV.root] = infoU.root
          parity[infoV.root] = infoU.par xor infoV.par xor 1

    appendText("Scenario #" & $scenarioIdx & ":\n")
    if suspicious:
      appendText("Suspicious bugs found!\n")
    else:
      appendText("No suspicious bugs found!\n")

  if outBuffer.len > 0:
    stdout.write outBuffer

main()
