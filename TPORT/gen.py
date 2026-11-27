#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def construct_path(n, k):
    result = [0] * n
    aux = [0] * (n // 2 + 2)

    def fill(write_pos, cur_n, cur_k, base, step):
        while True:
            if cur_k > (cur_n + 1) // 2:
                base += step * (cur_n - 1)
                step = -step
                cur_k = cur_n + 1 - cur_k
            if cur_n == 1:
                result[write_pos] = base
                return
            if cur_k == 1:
                left = 1
                right = cur_n
                pos = write_pos
                while left <= right:
                    result[pos] = base + step * (left - 1)
                    pos += 1
                    left += 1
                    if left <= right:
                        result[pos] = base + step * (right - 1)
                        pos += 1
                        right -= 1
                return
            if cur_n == 2 * cur_k - 1:
                cur = cur_k
                result[write_pos] = base + step * (cur - 1)
                for delta in range(1, cur_n):
                    cur += -delta if delta % 2 == 1 else delta
                    result[write_pos + delta] = base + step * (cur - 1)
                return
            if cur_n == 2 * cur_k:
                cur = cur_k
                result[write_pos] = base + step * (cur - 1)
                for delta in range(1, cur_n):
                    cur += delta if delta % 2 == 1 else -delta
                    result[write_pos + delta] = base + step * (cur - 1)
                return
            if cur_n >= 3 * cur_k - 1:
                pos = write_pos
                for idx in range(cur_k):
                    result[pos] = base + step * (cur_k - idx - 1)
                    pos += 1
                    if idx < cur_k - 1:
                        result[pos] = base + step * (cur_n - cur_k + 1 + idx)
                        pos += 1
                write_pos = pos
                base += step * cur_k
                cur_n, cur_k = cur_n - 2 * cur_k + 1, cur_n - 3 * cur_k + 2
                continue
            side = cur_k - 1
            mid_len = cur_n - 2 * side
            pos = write_pos
            left = 1
            right = mid_len
            last_rel = 1
            while left <= right:
                last_rel = side + left
                result[pos] = base + step * (last_rel - 1)
                pos += 1
                left += 1
                if left <= right:
                    last_rel = side + right
                    result[pos] = base + step * (last_rel - 1)
                    pos += 1
                    right -= 1
            start_right_zero = last_rel + mid_len - cur_n + side - 1
            fill(pos, side, start_right_zero + 1, 0, 1)
            for idx in range(side):
                aux[idx] = result[pos + idx]
            right_base = base + step * (cur_n - side)
            limit = 2 * side - 1
            for idx in range(side):
                offset_val = aux[idx]
                if idx % 2 == 0:
                    result[pos + idx] = right_base + step * offset_val
                    result[pos + limit - idx] = base + step * offset_val
                else:
                    result[pos + idx] = base + step * offset_val
                    result[pos + limit - idx] = right_base + step * offset_val
            return

    fill(0, n, k, 1, 1)
    return result


def verify_jumps(n, k, jumps_text):
    if n == 1:
        assert jumps_text == "\n"
        return
    jumps = [int(token) for token in jumps_text.split()]
    assert len(jumps) == n - 1
    seen_planets = [False] * (n + 1)
    used_teleports = [False] * n
    cur = k
    seen_planets[cur] = True
    for jump in jumps:
        teleport = abs(jump)
        assert 1 <= teleport < n and not used_teleports[teleport]
        used_teleports[teleport] = True
        cur += jump
        assert 1 <= cur <= n and not seen_planets[cur]
        seen_planets[cur] = True


def brute_exists(n, k):
    seen = [False] * (n + 1)
    used = [False] * n
    seen[k] = True

    def dfs(planet, count):
        if count == n:
            return True
        for teleport in range(1, n):
            if not used[teleport]:
                for nxt in (planet - teleport, planet + teleport):
                    if 1 <= nxt <= n and not seen[nxt]:
                        used[teleport] = True
                        seen[nxt] = True
                        if dfs(nxt, count + 1):
                            return True
                        seen[nxt] = False
                        used[teleport] = False
        return False

    return dfs(k, 1)


def oracle(text):
    parts = [int(value) for value in text.split()]
    n, k = parts[0], parts[1]
    if n == 1:
        return "\n"
    planets = construct_path(n, k)
    jumps = [str(planets[idx + 1] - planets[idx]) for idx in range(n - 1)]
    out = " ".join(jumps) + "\n"
    verify_jumps(n, k, out)
    return out


SAMPLE = "6 2\n"
SAMPLE_OUT = "4 -5 3 -1 2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
for small_n in range(1, 11):
    for small_k in range(1, small_n + 1):
        assert brute_exists(small_n, small_k)
        verify_jumps(small_n, small_k, oracle(f"{small_n} {small_k}\n"))
verify_jumps(1, 1, "\n")
assert oracle("2 2\n") == "-1\n"
assert oracle("3 1\n") == "2 -1\n"


def write(name, n, k):
    text = f"{n} {k}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1)
    write("3_wide", 1000000, 412345)
    write("4_random", 999999, 200001)
    write("5_io", 1000000, 499999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
