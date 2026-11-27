#include <bits/stdc++.h>
using namespace std;
using i64 = long long;
using i128 = __int128_t;

static const i64 MOD = 2000000778241LL;
static i64 ROOT_G = 0;

i64 modpow(i64 a, i64 e) {
    i64 r = 1;
    while (e) {
        if (e & 1) r = (i128)r * a % MOD;
        a = (i128)a * a % MOD;
        e >>= 1;
    }
    return r;
}

i64 mul(i64 a, i64 b) { return (i128)a * b % MOD; }

void initRoot() {
    i64 phi = MOD - 1;
    vector<i64> factors;
    i64 t = phi;
    for (i64 d = 2; d * d <= t; d += 1) {
        if (t % d == 0) {
            factors.push_back(d);
            while (t % d == 0) t /= d;
        }
    }
    if (t > 1) factors.push_back(t);
    for (i64 g = 2; ; g += 1) {
        bool ok = true;
        for (i64 f : factors) if (modpow(g, phi / f) == 1) { ok = false; break; }
        if (ok) { ROOT_G = g; return; }
    }
}

void ntt(vector<i64>& a, bool invert) {
    int n = (int)a.size();
    for (int i = 1, j = 0; i < n; i += 1) {
        int bit = n >> 1;
        while (j & bit) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) swap(a[i], a[j]);
    }
    for (int len = 2; len <= n; len <<= 1) {
        i64 wlen = modpow(ROOT_G, (MOD - 1) / len);
        if (invert) wlen = modpow(wlen, MOD - 2);
        for (int i = 0; i < n; i += len) {
            i64 w = 1;
            for (int j = 0; j < len / 2; j += 1) {
                i64 u = a[i + j];
                i64 v = mul(a[i + j + len / 2], w);
                i64 x = u + v; if (x >= MOD) x -= MOD;
                i64 y = u - v; if (y < 0) y += MOD;
                a[i + j] = x;
                a[i + j + len / 2] = y;
                w = mul(w, wlen);
            }
        }
    }
    if (invert) {
        i64 invN = modpow(n, MOD - 2);
        for (i64& value : a) value = mul(value, invN);
    }
}

void trim(vector<i64>& p);

vector<i64> multiply(vector<i64> a, vector<i64> b, int limit = -1) {
    if (a.empty() || b.empty()) return {};
    int need = (int)a.size() + (int)b.size() - 1;
    int n = 1;
    while (n < need) n <<= 1;
    a.resize(n); b.resize(n);
    ntt(a, false); ntt(b, false);
    for (int i = 0; i < n; i += 1) a[i] = mul(a[i], b[i]);
    ntt(a, true);
    if (limit > 0 && (int)a.size() > limit) a.resize(limit);
    trim(a);
    return a;
}

void trim(vector<i64>& p) {
    while (!p.empty() && p.back() == 0) p.pop_back();
}

pair<vector<i64>, vector<i64>> divmod(vector<i64> a, const vector<i64>& b) {
    a = a; trim(a);
    vector<i64> q(max(1, (int)a.size() - (int)b.size() + 1), 0);
    while (!a.empty() && a.size() >= b.size()) {
        int k = (int)a.size() - (int)b.size();
        i64 c = mul(a.back(), modpow(b.back(), MOD - 2));
        q[k] = c;
        for (int j = 0; j < (int)b.size(); j += 1) {
            a[k + j] = (a[k + j] - mul(c, b[j])) % MOD;
            if (a[k + j] < 0) a[k + j] += MOD;
        }
        trim(a);
    }
    trim(q);
    return {q, a};
}

vector<i64> polySub(const vector<i64>& a, const vector<i64>& b) {
    vector<i64> res(max(a.size(), b.size()), 0);
    for (int i = 0; i < (int)a.size(); i += 1) res[i] = a[i];
    for (int i = 0; i < (int)b.size(); i += 1) {
        res[i] -= b[i];
        if (res[i] < 0) res[i] += MOD;
    }
    trim(res);
    return res;
}

vector<i64> inverseMod(const vector<i64>& a, const vector<i64>& m) {
    vector<i64> r0 = m, r1 = a;
    vector<i64> s0 = {0}, s1 = {1};
    trim(r1);
    while (!r1.empty()) {
        auto [q, r] = divmod(r0, r1);
        vector<i64> qs = multiply(q, s1);
        vector<i64> sn = polySub(s0, qs);
        s0 = s1; s1 = sn;
        r0 = r1; r1 = r;
    }
    if (r0.size() != 1) return {};
    i64 inv = modpow(r0[0], MOD - 2);
    vector<i64> res(s0.size());
    for (int i = 0; i < (int)s0.size(); i += 1) res[i] = mul(s0[i], inv);
    trim(res);
    return res;
}

static const int inputBlockBytes = 1 << 16;
static string inputData;

static void readInput() {
    char block[inputBlockBytes];
    size_t count = 0;
    while ((count = fread(block, 1, inputBlockBytes, stdin)) > 0) {
        inputData.append(block, count);
    }
}

static size_t scanPos = 0;

static i64 nextInteger() {
    while (scanPos < inputData.size() && (inputData[scanPos] < '0' || inputData[scanPos] > '9') && inputData[scanPos] != '-') scanPos += 1;
    bool negative = false;
    if (scanPos < inputData.size() && inputData[scanPos] == '-') { negative = true; scanPos += 1; }
    i64 value = 0;
    while (scanPos < inputData.size() && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
        value = value * 10 + (inputData[scanPos] - '0');
        scanPos += 1;
    }
    return negative ? -value : value;
}

int main() {
    initRoot();
    readInput();
    int N = (int)nextInteger();
    int samples = N * N;
    vector<i64> y(samples);
    for (int i = 0; i < samples; i += 1) y[i] = nextInteger();
    vector<i64> queries(samples);
    for (int i = 0; i < samples; i += 1) queries[i] = nextInteger();

    vector<vector<i64>> Qm(N + 1);
    for (int m = 1; m <= N; m += 1) {
        vector<i64> den = {1};
        for (int d = 1; d < m; d += 1) {
            if (m % d == 0) den = multiply(den, Qm[d]);
        }
        vector<i64> num(m + 1, 0);
        num[0] = MOD - 1; num[m] = 1;
        auto [phi, rem] = divmod(num, den);
        trim(phi);
        Qm[m] = phi;
        reverse(Qm[m].begin(), Qm[m].end());
    }

    vector<i64> poly = {1};
    for (int m = 1; m <= N; m += 1) poly = multiply(poly, Qm[m]);
    int D = (int)poly.size() - 1;

    vector<i64> ypart(samples);
    for (int i = 0; i < D; i += 1) ypart[i] = y[i] % MOD;
    vector<i64> A = multiply(ypart, poly, D);

    int nttSize = 1;
    while (nttSize < 2 * D + 2) nttSize <<= 1;
    vector<i64> polyNtt(poly.begin(), poly.end());
    polyNtt.resize(nttSize, 0);
    ntt(polyNtt, false);

    vector<vector<i64>> comp(N + 1);
    for (int m = 1; m <= N; m += 1) {
        const vector<i64>& qm = Qm[m];
        int ph = (int)qm.size() - 1;
        vector<i64> num(m + 1, 0);
        num[0] = MOD - 1; num[m] = 1;
        auto [Rm, rem] = divmod(num, qm);
        Rm.resize(m, 0);

        int L = D - ph;
        vector<i64> series(nttSize, 0);
        for (int k = 0; k <= L; k += 1) series[k] = Rm[k % m];
        ntt(series, false);
        for (int i = 0; i < nttSize; i += 1) series[i] = mul(series[i], polyNtt[i]);
        ntt(series, true);
        series.resize(L + 1);
        vector<i64> R = move(series);

        vector<i64> Rfold(m, 0), Afold(m, 0);
        for (int k = 0; k < (int)R.size(); k += 1) {
            Rfold[k % m] += R[k]; if (Rfold[k % m] >= MOD) Rfold[k % m] -= MOD;
        }
        for (int k = 0; k < (int)A.size(); k += 1) {
            Afold[k % m] += A[k]; if (Afold[k % m] >= MOD) Afold[k % m] -= MOD;
        }
        auto [_, Rrem] = divmod(Rfold, qm);
        auto [__, Arem] = divmod(Afold, qm);
        vector<i64> invR = inverseMod(Rrem, qm);
        if (invR.empty()) { cerr << "inverse failed for m=" << m << "\n"; return 1; }
        vector<i64> Am = multiply(Arem, invR);
        auto [___, Amred] = divmod(Am, qm);

        vector<i64> U(m, 0);
        for (int i = 0; i < (int)Amred.size(); i += 1) {
            for (int r = 0; r < m - i && r < m; r += 1) {
                U[i + r] = (U[i + r] + mul(Amred[i], Rm[r % m])) % MOD;
            }
        }
        comp[m] = move(U);
    }

    string output;
    output.reserve(samples * 14);
    for (int qi = 0; qi < samples; qi += 1) {
        i64 x = queries[qi] % MOD;
        i64 total = 0;
        for (int m = 1; m <= N; m += 1) {
            total += comp[m][x % m];
            if (total >= MOD) total -= MOD;
        }
        i64 signedValue = total;
        if (signedValue > MOD / 2) signedValue -= MOD;
        output += to_string(signedValue);
        output += (qi + 1 == samples ? '\n' : ' ');
    }
    fwrite(output.data(), 1, output.size(), stdout);
    return 0;
}
