var data = ""
var row = ""
while readLine(stdin, row):
  data.add row
  data.add '\n'
var pos = 0
proc getNum(): int =
  while pos < data.len and data[pos] < '0': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

const limit = 46341
var flags = newSeq[bool](limit + 1)
var primes: seq[int] = @[]
for i in 2..limit:
  if not flags[i]:
    primes.add i
    if i * i <= limit:
      var j = i * i
      while j <= limit:
        flags[j] = true
        j += i

proc isPrime(value: int): bool =
  for prime in primes:
    if prime * prime > value: break
    if value mod prime == 0: return false
  return value > 1

var marks = newSeq[byte](1100000)
var prods = newSeq[int](1100000)
var ob = ""
while true:
  let low = getNum()
  let high = getNum()
  if low + high == 0: break
  let width = high - low + 1
  if width > marks.len:
    marks.setLen width
    prods.setLen width
  for prime in primes:
    if prime == 2: continue
    if prime * prime > high: break
    let step = prime * (prime - 1)
    var value = prime + ((max(prime * prime, low) - prime + step - 1) div step) * step
    while value <= high:
      let index = value - low
      prods[index] = if marks[index] == 0: prime else: prods[index] * prime
      marks[index] += 1
      if (value div prime) mod prime == 0: marks[index] = marks[index] or 128'u8
      value += step
  var found = false
  for index in 0..<width:
    let mark = int(marks[index])
    marks[index] = 0
    if mark < 2 or mark > 127: continue
    let value = low + index
    let rest = value div prods[index]
    var total = mark
    if rest > 1:
      total += 1
      if (value - 1) mod (rest - 1) != 0 or not isPrime(rest): continue
    if total < 3: continue
    ob.add $value
    ob.add '\n'
    if ob.len >= (1 shl 18):
      stdout.write ob
      ob.setLen 0
    found = true
  if not found: ob.add "none\n"
stdout.write ob
