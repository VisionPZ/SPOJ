import sys

firstDigitValue = 48
riceDenominator = 8
chickenDenominator = 16
costDenominator = 16
hundredScale = 100


def nextNumber(data, position):
    length = len(data)
    while position < length and not (firstDigitValue <= data[position] <= firstDigitValue + 9):
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return value, position, found


def formatAmount(numerator, denominator):
    scaledValue, remainder = divmod(numerator * hundredScale, denominator)
    if remainder * 2 >= denominator:
        scaledValue += 1
    if scaledValue % hundredScale == 0:
        return str(scaledValue // hundredScale)
    return "%d.%02d" % (scaledValue // hundredScale, scaledValue % hundredScale)


inputData = sys.stdin.buffer.read()
scanPos = 0
answerLines = []
while True:
    dinerCount, scanPos, found = nextNumber(inputData, scanPos)
    if not found:
        break
    ricePrice, scanPos, _ = nextNumber(inputData, scanPos)
    chickenPrice, scanPos, _ = nextNumber(inputData, scanPos)
    if dinerCount == 0 and ricePrice == 0 and chickenPrice == 0:
        break
    riceText = formatAmount(dinerCount, riceDenominator)
    chickenText = formatAmount(dinerCount, chickenDenominator)
    costNumerator = dinerCount * (2 * ricePrice + chickenPrice)
    costText = formatAmount(costNumerator, costDenominator)
    answerLines.append(riceText + " " + chickenText + " " + costText)

outputBuffer = "\n".join(answerLines)
if answerLines:
    outputBuffer += "\n"
sys.stdout.write(outputBuffer)
