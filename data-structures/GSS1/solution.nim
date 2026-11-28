const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

type
  SegNode = tuple
    total: int64
    pref: int64
    suff: int64
    best: int64

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
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var isNeg = false
  if pos < data.len and data[pos] == '-':
    isNeg = true
    pos += 1
  var val = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10 + (int(data[pos]) - firstDigitValue)
    pos += 1
  if isNeg: -val else: val

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendInt64Line(val: int64) =
  outBuffer.add $val
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc combineNodes(leftNode: SegNode, rightNode: SegNode): SegNode {.inline.} =
  result.total = leftNode.total + rightNode.total
  let prefCand = leftNode.total + rightNode.pref
  result.pref = if leftNode.pref > prefCand: leftNode.pref else: prefCand
  let suffCand = rightNode.total + leftNode.suff
  result.suff = if rightNode.suff > suffCand: rightNode.suff else: suffCand
  let maxEnds = if leftNode.best > rightNode.best: leftNode.best else: rightNode.best
  let crossVal = leftNode.suff + rightNode.pref
  result.best = if maxEnds > crossVal: maxEnds else: crossVal

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let elemCount = nextInt(inputData, scanPos)
  var treeBase = 1
  while treeBase < elemCount:
    treeBase = treeBase shl 1
  var tree = newSeq[SegNode](treeBase * 2)
  for idx in 0 ..< elemCount:
    let val = int64(nextInt(inputData, scanPos))
    tree[treeBase + idx] = (val, val, val, val)
  for idx in countdown(treeBase - 1, 1):
    tree[idx] = combineNodes(tree[idx shl 1], tree[(idx shl 1) or 1])

  let queryCount = nextInt(inputData, scanPos)
  for qIdx in 0 ..< queryCount:
    var leftPos = nextInt(inputData, scanPos) - 1 + treeBase
    var rightPos = nextInt(inputData, scanPos) - 1 + treeBase
    var hasLeft = false
    var hasRight = false
    var leftAcc: SegNode
    var rightAcc: SegNode
    while leftPos <= rightPos:
      if (leftPos and 1) == 1:
        if not hasLeft:
          leftAcc = tree[leftPos]
          hasLeft = true
        else:
          leftAcc = combineNodes(leftAcc, tree[leftPos])
        leftPos += 1
      if (rightPos and 1) == 0:
        if not hasRight:
          rightAcc = tree[rightPos]
          hasRight = true
        else:
          rightAcc = combineNodes(tree[rightPos], rightAcc)
        rightPos -= 1
      leftPos = leftPos shr 1
      rightPos = rightPos shr 1
    let ansNode =
      if not hasLeft: rightAcc
      elif not hasRight: leftAcc
      else: combineNodes(leftAcc, rightAcc)
    appendInt64Line(ansNode.best)

  if outBuffer.len > 0:
    stdout.write outBuffer

main()
