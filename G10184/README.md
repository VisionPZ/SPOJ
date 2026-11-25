# G10184 — Arroz con Pollo Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10184/>

Judge status: submissions return "Missing testcases", so the problem has no
test data and cannot be accepted. The solution below passes the local harness,
including the statement sample.

## Problem

A rice-and-chicken meal feeds four people with 0.5 kg of rice and 0.25 kg of chicken. Each input line gives the number of diners, the price per kg of rice, and the price per kg of chicken; `0 0 0` ends the input. For each line print the rice amount, the chicken amount, and the total cost, separated by spaces. A value that is not a whole number prints with exactly two decimal places; a whole number prints plain.

| Item | Bound |
|---|---|
| Values | positive integers per line |
| Output | three amounts per line |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
12 1200 6000
200 1000 4000
60 1500 5000
0 0 0
```

```
1.50 0.75 6300
25 12.50 75000
7.50 3.75 30000
```

## Idea

Do all the arithmetic in exact integer hundredths, like counting money in cents, and only format at the end. Rice is diners/8 kg, chicken is diners/16 kg, and cost is diners × (2·ricePrice + chickenPrice) / 16. One multiply and one divmod give each amount in cents, so no float ever touches the answer. Float arithmetic would drift on large prices and force careful rounding rules.

## Why It Works

1. Scaling by 100 turns each fraction into an integer division with a remainder.
2. Rounding half up happens exactly when `remainder * 2 >= denominator`.
3. A cent total divisible by 100 is a whole number, so it prints without a decimal point.
4. The cost formula combines both ingredients over the common denominator 16, matching 0.5 and 0.25 kg per four people.

| Term | Meaning |
|---|---|
| `dinerCount` | people at the table |
| `ricePrice` | price per kilogram of rice |
| `chickenPrice` | price per kilogram of chicken |
| `formatAmount` | turns numerator/denominator into the printed form |
| `scaledValue` | the amount in hundredths |
| `costNumerator` | diners × (2·ricePrice + chickenPrice) |

Rice uses denominator 8 and chicken denominator 16 because 0.5/4 and 0.25/4 per person equal those fractions.

A script-traced example from `gen.py`:

```
diners 12, rice 1200/kg, chicken 6000/kg
rice 12/8 = 150 cents -> 1.50
chicken 12/16 = 75 cents -> 0.75
cost 12*(2*1200+6000)/16 = 6300 -> 6300
```

The trace reproduces the first sample line byte for byte.

## Code

**Amount formatter.** This block converts a fraction into the required text.

```python
def formatAmount(numerator, denominator):
    scaledValue, remainder = divmod(numerator * hundredScale, denominator)
    if remainder * 2 >= denominator:
        scaledValue += 1
    if scaledValue % hundredScale == 0:
        return str(scaledValue // hundredScale)
    return "%d.%02d" % (scaledValue // hundredScale, scaledValue % hundredScale)
```

The divmod keeps the value exact in hundredths.
The remainder test rounds halves up.
Whole amounts lose the decimal part entirely.

**Case loop.** This block reads triples and emits one line each.

```python
    riceText = formatAmount(dinerCount, riceDenominator)
    chickenText = formatAmount(dinerCount, chickenDenominator)
    costNumerator = dinerCount * (2 * ricePrice + chickenPrice)
    costText = formatAmount(costNumerator, costDenominator)
    answerLines.append(riceText + " " + chickenText + " " + costText)
```

Three calls format the three amounts.
The cost numerator folds both prices into one exact fraction.
The `0 0 0` line breaks the loop before this block runs.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Per case | 3 divmods, a few multiplies | one answer line |
| Output | one write | joined buffer |

| Measure | Big O |
|---|---|
| Time | O(cases) |
| Space | O(N) for the input buffer |

Float math with manual rounding is the usual naive route and drifts on big values.
