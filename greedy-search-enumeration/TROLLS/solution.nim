type
  RingState = array[11, uint16]
  BigDigits = seq[uint32]

const bigBase = 1000000000'u64
const firstDigitValue = 48

proc mulSmall(digits: var BigDigits, factor: uint64) =
  var carry = 0'u64
  for idx in 0 ..< digits.len:
    let prod = uint64(digits[idx]) * factor + carry
    digits[idx] = uint32(prod mod bigBase)
    carry = prod div bigBase
  if carry > 0'u64:
    digits.add uint32(carry)

proc divSmall(digits: var BigDigits, divisor: uint64) =
  var rem = 0'u64
  for idx in countdown(digits.len - 1, 0):
    let cur = rem * bigBase + uint64(digits[idx])
    digits[idx] = uint32(cur div divisor)
    rem = cur mod divisor
  while digits.len > 1 and digits[^1] == 0'u32:
    digits.setLen(digits.len - 1)

proc bigToStr(digits: BigDigits): string =
  var res = $digits[^1]
  for idx in countdown(digits.len - 2, 0):
    var part = digits[idx]
    var buf: array[9, char]
    for pos in countdown(8, 0):
      buf[pos] = char(int(part mod 10'u32) + firstDigitValue)
      part = part div 10'u32
    for pos in 0 .. 8:
      res.add buf[pos]
  res

proc solveProgram1(): string =
  var digits: BigDigits = @[1'u32]
  for step in 1'u64 .. 50'u64:
    digits.mulSmall(301'u64 - step)
    digits.divSmall(step)
  bigToStr(digits)

proc stepRing(state: var RingState) {.inline.} =
  let nxt = uint16((uint32(state[10]) + uint32(state[0]) div 3'u32) mod 1001'u32)
  for idx in 0 .. 9:
    state[idx] = state[idx + 1]
  state[10] = nxt

proc solveProgram2(): int =
  var initial: RingState
  for idx in 0 .. 10:
    initial[idx] = uint16(idx)
  var tortoise = initial
  var hare = initial
  stepRing(tortoise)
  stepRing(hare)
  stepRing(hare)
  while tortoise != hare:
    stepRing(tortoise)
    stepRing(hare)
    stepRing(hare)
  var tailLen = 0
  tortoise = initial
  while tortoise != hare:
    stepRing(tortoise)
    stepRing(hare)
    tailLen += 1
  var cycleLen = 1
  hare = tortoise
  stepRing(hare)
  while tortoise != hare:
    stepRing(hare)
    cycleLen += 1
  tailLen + cycleLen

proc solveProgram3(): int =
  const modBase = 13
  var total = 0
  var fact = 1
  for term in 1 .. 1001:
    fact = (fact * term) mod modBase
    if fact == 0:
      break
    total += fact
  total

proc solveProgram4(): string =
  var digits: BigDigits = @[1'u32]
  for power in 1 .. 100:
    digits.mulSmall(2'u64)
  for power in 1 .. 10:
    digits.mulSmall(3'u64)
  for power in 1 .. 6:
    digits.mulSmall(5'u64)
  bigToStr(digits)

proc main() =
  var outText = solveProgram1() & "\n"
  outText.add $solveProgram2() & "\n"
  outText.add $solveProgram3() & "\n"
  outText.add solveProgram4() & "\n"
  stdout.write outText

main()
