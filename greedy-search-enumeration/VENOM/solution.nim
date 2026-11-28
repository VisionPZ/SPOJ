const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc killsHero(health: int64, poison: int64, healAmount: int64, attackIndex: int64): bool =
  let carriedHealth = health + (attackIndex - 1) * healAmount
  let totalDamage = poison * attackIndex * (attackIndex + 1) div 2
  return carriedHealth <= totalDamage

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let health = int64(nextInt(inputData, scanPos))
  let poison = int64(nextInt(inputData, scanPos))
  let healAmount = int64(nextInt(inputData, scanPos))
  var upperAttack = 1'i64
  while not killsHero(health, poison, healAmount, upperAttack):
    upperAttack *= 2
  var lowerAttack = 1'i64
  while lowerAttack < upperAttack:
    let middleAttack = (lowerAttack + upperAttack) div 2
    if killsHero(health, poison, healAmount, middleAttack):
      upperAttack = middleAttack
    else:
      lowerAttack = middleAttack + 1
  appendOutput($(2 * lowerAttack - 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
