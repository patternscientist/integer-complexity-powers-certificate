#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

using ull = unsigned long long;

static const ull INF = std::numeric_limits<ull>::max() / 4;

struct Node {
    char kind = 'M';
    ull constant = 0;
    std::unique_ptr<Node> child;
    std::vector<std::unique_ptr<Node>> children;
    int degree = 0;
    ull min_value = 0;
    ull max_coeff = 0;
    ull term_count = 0;
};

struct Pair {
    ull base_complexity = 0;
    int degree = 0;
    std::unique_ptr<Node> tree;
};

struct Case {
    int m;
    int b;
    ull n;
    ull bound;
};

struct Survivor {
    bool found = false;
    ull pair_index = 0;
    ull e = 0;
    std::vector<ull> k;
    ull complexity = 0;
    std::string polynomial;
};

static ull cap_mul(ull a, ull b) {
    if (a == 0 || b == 0) return 0;
    if (a > INF / b) return INF;
    return a * b;
}

static ull cap_add(ull a, ull b) {
    if (a > INF - b) return INF;
    return a + b;
}

static ull pow_u64(ull base, int exp) {
    ull out = 1;
    for (int i = 0; i < exp; ++i) out *= base;
    return out;
}

static std::vector<ull> pow3_table() {
    std::vector<ull> p(80, 1);
    for (size_t i = 1; i < p.size(); ++i) {
        if (p[i - 1] > INF / 3) p[i] = INF;
        else p[i] = p[i - 1] * 3;
    }
    return p;
}

static const std::vector<ull> POW3 = pow3_table();

static ull max_for_budget(const Node* node, ull budget) {
    ull out = cap_mul(node->max_coeff, node->term_count);
    if (budget < POW3.size()) out = cap_mul(out, POW3[(size_t)budget]);
    else out = INF;
    return out;
}

static bool in_range(const Node* node, ull target, ull budget) {
    return node->min_value <= target && target <= max_for_budget(node, budget);
}

struct Parser {
    std::istream& in;
    int lookahead = -2;

    explicit Parser(std::istream& input) : in(input) {}

    int peek() {
        if (lookahead == -2) lookahead = in.get();
        return lookahead;
    }

    int get() {
        int c = peek();
        lookahead = -2;
        return c;
    }

    void skip_ws() {
        while (peek() != EOF && std::isspace(static_cast<unsigned char>(peek()))) get();
    }

    void expect(char c) {
        skip_ws();
        if (peek() != c) {
            throw std::runtime_error("parse error: expected character");
        }
        get();
    }

    bool consume(char c) {
        skip_ws();
        if (peek() == c) {
            get();
            return true;
        }
        return false;
    }

    std::string parse_string() {
        skip_ws();
        expect('"');
        std::string out;
        while (peek() != EOF) {
            char c = static_cast<char>(get());
            if (c == '"') return out;
            if (c == '\\') {
                if (peek() == EOF) throw std::runtime_error("parse error: bad escape");
                out.push_back(static_cast<char>(get()));
            } else {
                out.push_back(c);
            }
        }
        throw std::runtime_error("parse error: unterminated string");
    }

    ull parse_uint() {
        skip_ws();
        ull out = 0;
        if (peek() == EOF || !std::isdigit(static_cast<unsigned char>(peek()))) {
            throw std::runtime_error("parse error: expected integer");
        }
        while (peek() != EOF && std::isdigit(static_cast<unsigned char>(peek()))) {
            out = out * 10 + static_cast<ull>(get() - '0');
        }
        return out;
    }

    void skip_value() {
        skip_ws();
        int c = peek();
        if (c == '"') {
            (void)parse_string();
        } else if (c == '{') {
            expect('{');
            if (!consume('}')) {
                while (true) {
                    (void)parse_string();
                    expect(':');
                    skip_value();
                    if (consume('}')) break;
                    expect(',');
                }
            }
        } else if (c == '[') {
            expect('[');
            if (!consume(']')) {
                while (true) {
                    skip_value();
                    if (consume(']')) break;
                    expect(',');
                }
            }
        } else if (std::isdigit(static_cast<unsigned char>(c))) {
            (void)parse_uint();
        } else if (c == 't') {
            expect('t'); expect('r'); expect('u'); expect('e');
        } else if (c == 'f') {
            expect('f'); expect('a'); expect('l'); expect('s'); expect('e');
        } else if (c == 'n') {
            expect('n'); expect('u'); expect('l'); expect('l');
        } else {
            throw std::runtime_error("parse error: cannot skip value");
        }
    }

    void key(const char* expected) {
        std::string got = parse_string();
        if (got != expected) throw std::runtime_error("parse error: unexpected key " + got);
        expect(':');
    }

    std::unique_ptr<Node> parse_tree() {
        expect('{');
        key("kind");
        std::string kind = parse_string();
        auto node = std::unique_ptr<Node>(new Node());
        if (kind == "affine") {
            node->kind = 'A';
            expect(',');
            key("edge_complexity");
            (void)parse_uint();
            expect(',');
            key("constant");
            node->constant = parse_uint();
            expect(',');
            key("child");
            node->child = parse_tree();
            expect('}');
        } else if (kind == "product") {
            node->kind = 'M';
            expect(',');
            key("vertex_complexity");
            (void)parse_uint();
            expect(',');
            key("constant");
            node->constant = parse_uint();
            expect(',');
            key("children");
            expect('[');
            if (!consume(']')) {
                while (true) {
                    node->children.push_back(parse_tree());
                    if (consume(']')) break;
                    expect(',');
                }
            }
            expect('}');
        } else {
            throw std::runtime_error("parse error: unknown node kind");
        }
        compute_props(node.get());
        return node;
    }

    Pair parse_pair() {
        Pair pair;
        expect('{');
        key("base_complexity");
        pair.base_complexity = parse_uint();
        expect(',');
        key("degree");
        pair.degree = static_cast<int>(parse_uint());
        expect(',');
        key("tree");
        pair.tree = parse_tree();
        expect('}');
        return pair;
    }

    static void compute_props(Node* node) {
        if (node->kind == 'A') {
            Node* child = node->child.get();
            node->degree = 1 + child->degree;
            node->min_value = cap_add(child->min_value, node->constant);
            node->max_coeff = std::max(child->max_coeff, node->constant);
            node->term_count = child->term_count + 1;
        } else {
            node->degree = 0;
            node->min_value = node->constant;
            node->max_coeff = node->constant;
            node->term_count = 1;
            for (const auto& child : node->children) {
                node->degree += child->degree;
                node->min_value = cap_mul(node->min_value, child->min_value);
                node->max_coeff = cap_mul(node->max_coeff, child->max_coeff);
                node->term_count = cap_mul(node->term_count, child->term_count);
            }
        }
    }
};

static ull gcd_u64(ull a, ull b) {
    while (b) {
        ull r = a % b;
        a = b;
        b = r;
    }
    return a;
}

static ull add_mod(ull a, ull b, ull m) {
    a %= m;
    b %= m;
    if (a >= m - b) return a - (m - b);
    return a + b;
}

static ull mul_mod(ull a, ull b, ull m) {
    ull out = 0;
    a %= m;
    while (b) {
        if (b & 1) out = add_mod(out, a, m);
        b >>= 1;
        if (b) a = add_mod(a, a, m);
    }
    return out;
}

static ull pow_mod(ull a, ull e, ull m) {
    ull out = 1 % m;
    while (e) {
        if (e & 1) out = mul_mod(out, a, m);
        e >>= 1;
        if (e) a = mul_mod(a, a, m);
    }
    return out;
}

static bool is_prime_u64(ull n) {
    if (n < 2) return false;
    static const ull small[] = {2,3,5,7,11,13,17,19,23,29,31,37};
    for (ull p : small) {
        if (n % p == 0) return n == p;
    }
    ull d = n - 1, s = 0;
    while ((d & 1) == 0) {
        d >>= 1;
        ++s;
    }
    static const ull bases[] = {2,3,5,7,11,13,17,19,23,29,31,37};
    for (ull a : bases) {
        if (a >= n) continue;
        ull x = pow_mod(a, d, n);
        if (x == 1 || x == n - 1) continue;
        bool ok = false;
        for (ull r = 1; r < s; ++r) {
            x = mul_mod(x, x, n);
            if (x == n - 1) {
                ok = true;
                break;
            }
        }
        if (!ok) return false;
    }
    return true;
}

static ull pollard(ull n) {
    if (n % 2 == 0) return 2;
    if (n % 3 == 0) return 3;
    for (ull c = 1;; ++c) {
        ull x = 2, y = 2, d = 1;
        while (d == 1) {
            x = add_mod(mul_mod(x, x, n), c, n);
            y = add_mod(mul_mod(y, y, n), c, n);
            y = add_mod(mul_mod(y, y, n), c, n);
            ull diff = x > y ? x - y : y - x;
            d = gcd_u64(diff, n);
        }
        if (d != n) return d;
    }
}

static void factor_rec(ull n, std::map<ull, int>& out) {
    if (n == 1) return;
    if (is_prime_u64(n)) {
        out[n]++;
        return;
    }
    ull d = pollard(n);
    factor_rec(d, out);
    factor_rec(n / d, out);
}

static std::unordered_map<ull, std::vector<ull>> divisor_cache;

static const std::vector<ull>& divisors_of(ull n) {
    auto it = divisor_cache.find(n);
    if (it != divisor_cache.end()) return it->second;
    std::map<ull, int> factors;
    factor_rec(n, factors);
    std::vector<ull> divs(1, 1);
    for (const auto& kv : factors) {
        ull p = kv.first;
        int exp = kv.second;
        std::vector<ull> next;
        ull power = 1;
        for (int e = 0; e <= exp; ++e) {
            for (ull d : divs) next.push_back(d * power);
            power *= p;
        }
        divs.swap(next);
    }
    std::sort(divs.begin(), divs.end());
    auto inserted = divisor_cache.emplace(n, std::move(divs));
    return inserted.first->second;
}

static ull v3(ull n) {
    ull out = 0;
    while (n % 3 == 0) {
        n /= 3;
        ++out;
    }
    return out;
}

static std::string pretty(const Node* node) {
    if (node->kind == 'A') {
        return "(" + pretty(node->child.get()) + ")3^_+" + std::to_string(node->constant);
    }
    std::string out;
    if (!(node->constant == 1 && !node->children.empty())) {
        out += std::to_string(node->constant);
    }
    for (const auto& child : node->children) {
        out += "(" + pretty(child.get()) + ")";
    }
    return out;
}

static std::string json_escape(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '"' || c == '\\') {
            out.push_back('\\');
            out.push_back(c);
        } else if (c == '\n') {
            out += "\\n";
        } else {
            out.push_back(c);
        }
    }
    return out;
}

using SolutionCallback = std::function<bool(ull)>;

static bool enumerate_tree(const Node* node, ull target, ull budget,
                           std::vector<ull>& acc, const SolutionCallback& callback);

static bool enumerate_children(const std::vector<std::unique_ptr<Node>>& children,
                               size_t index, ull target, ull budget,
                               std::vector<ull>& acc, const SolutionCallback& callback) {
    if (index == children.size()) {
        if (target == 1) {
            return callback(0);
        }
        return false;
    }

    const Node* child = children[index].get();
    const std::vector<ull>& divs = divisors_of(target);
    for (ull d : divs) {
        if (!in_range(child, d, budget)) continue;
        size_t before = acc.size();
        bool stopped = enumerate_tree(child, d, budget, acc, [&](ull child_used) {
            if (child_used > budget) return false;
            size_t child_end = acc.size();
            bool rest_stopped = enumerate_children(
                children, index + 1, target / d, budget - child_used, acc,
                [&](ull rest_used) {
                    return callback(child_used + rest_used);
                }
            );
            if (!rest_stopped) acc.resize(child_end);
            return rest_stopped;
        });
        if (stopped) {
            return true;
        }
        acc.resize(before);
    }
    return false;
}

static bool enumerate_tree(const Node* node, ull target, ull budget,
                           std::vector<ull>& acc, const SolutionCallback& callback) {
    if (!in_range(node, target, budget)) return false;
    if (node->kind == 'A') {
        if (target <= node->constant) return false;
        ull diff = target - node->constant;
        ull limit = std::min(v3(diff), budget);
        ull power = 1;
        for (ull e = 0; e <= limit; ++e) {
            if (diff % power == 0) {
                ull child_target = diff / power;
                size_t before = acc.size();
                acc.push_back(e);
                bool stopped = enumerate_tree(node->child.get(), child_target, budget - e, acc,
                                              [&](ull child_used) {
                    return callback(e + child_used);
                });
                if (stopped) {
                    return true;
                }
                acc.resize(before);
            }
            if (e != limit) power *= 3;
        }
        return false;
    }

    if (node->constant == 0 || target % node->constant != 0) return false;
    ull rem = target / node->constant;
    if (node->children.empty()) {
        if (rem == 1) {
            return callback(0);
        }
        return false;
    }
    return enumerate_children(node->children, 0, rem, budget, acc, callback);
}

static bool solve_pair(const Pair& pair, const Case& c, Survivor& survivor, ull pair_index) {
    if (pair.base_complexity > c.bound) return false;
    ull max_e = v3(c.n);
    ull power = 1;
    for (ull e = 0; e <= max_e; ++e) {
        ull exponent_budget = (c.bound - pair.base_complexity) / 3;
        if (e <= exponent_budget) {
            ull target = c.n / power;
            std::vector<ull> exps;
            ull found_used = 0;
            bool found = enumerate_tree(pair.tree.get(), target, exponent_budget - e, exps,
                                        [&](ull used) {
                found_used = used;
                return true;
            });
            if (found) {
                survivor.found = true;
                survivor.pair_index = pair_index;
                survivor.e = e;
                survivor.k = exps;
                survivor.complexity = pair.base_complexity + 3 * (e + found_used);
                survivor.polynomial = pretty(pair.tree.get()) + " : "
                    + std::to_string(pair.base_complexity);
                return true;
            }
        }
        if (e != max_e) power *= 3;
    }
    return false;
}

static std::vector<Case> target_cases() {
    std::vector<Case> cases;
    int bs[] = {1, 6, 8, 9};
    for (int m = 49; m <= 56; ++m) {
        for (int b : bs) {
            Case c;
            c.m = m;
            c.b = b;
            c.n = (1ULL << m) - static_cast<ull>(b);
            c.bound = static_cast<ull>(2 * m - 2);
            cases.push_back(c);
        }
    }
    return cases;
}

static std::string json_bool(bool b) { return b ? "true" : "false"; }

int main(int argc, char** argv) {
    if (argc != 2 && argc != 3) {
        std::cerr << "usage: native_verify_near_powers S_46.json [out.json]\n";
        return 2;
    }

    std::ifstream in(argv[1], std::ios::binary);
    if (!in) {
        std::cerr << "could not open input\n";
        return 2;
    }
    Parser parser(in);
    ull threshold = 0;
    ull declared_pair_count = 0;
    bool saw_pairs = false;

    parser.expect('{');
    while (true) {
        std::string top_key = parser.parse_string();
        parser.expect(':');
        if (top_key == "threshold_multiple") {
            threshold = parser.parse_uint();
        } else if (top_key == "pair_count") {
            declared_pair_count = parser.parse_uint();
        } else if (top_key == "pairs") {
            parser.expect('[');
            saw_pairs = true;
            break;
        } else {
            parser.skip_value();
        }
        if (parser.consume('}')) break;
        parser.expect(',');
    }

    if (!saw_pairs) throw std::runtime_error("missing pairs");

    std::vector<Case> cases = target_cases();
    std::vector<Survivor> survivors(cases.size());
    std::vector<ull> degree_hist(8, 0);
    ull parsed_pairs = 0;
    int max_degree = 0;

    while (true) {
        parser.skip_ws();
        if (parser.consume(']')) break;
        Pair pair = parser.parse_pair();
        if (pair.degree >= static_cast<int>(degree_hist.size())) degree_hist.resize(pair.degree + 1, 0);
        degree_hist[pair.degree]++;
        max_degree = std::max(max_degree, pair.degree);
        for (size_t i = 0; i < cases.size(); ++i) {
            if (!survivors[i].found) {
                solve_pair(pair, cases[i], survivors[i], parsed_pairs);
            }
        }
        parsed_pairs++;
        parser.skip_ws();
        if (parser.consume(']')) break;
        parser.expect(',');
    }

    bool all_excluded = true;
    bool survivors_empty = true;
    for (const Survivor& s : survivors) {
        all_excluded = all_excluded && !s.found;
        survivors_empty = survivors_empty && !s.found;
    }
    bool pair_count_matches_declared =
        declared_pair_count == 0 || declared_pair_count == parsed_pairs;
    bool certificate_succeeded =
        threshold == 46
        && pair_count_matches_declared
        && max_degree <= 4
        && cases.size() == 32
        && all_excluded
        && survivors_empty;

    std::ostringstream out;
    out << "{";
    out << "\"backend\":\"native_cpp_streaming\",";
    out << "\"threshold_multiple\":" << threshold << ",";
    out << "\"declared_pair_count\":" << declared_pair_count << ",";
    out << "\"pair_count\":" << parsed_pairs << ",";
    out << "\"pair_count_matches_declared\":" << json_bool(pair_count_matches_declared) << ",";
    out << "\"max_degree\":" << max_degree << ",";
    out << "\"degree_histogram\":{";
    bool first = true;
    for (size_t i = 0; i < degree_hist.size(); ++i) {
        if (degree_hist[i] == 0) continue;
        if (!first) out << ",";
        first = false;
        out << "\"" << i << "\":" << degree_hist[i];
    }
    out << "},";
    out << "\"target_count\":" << cases.size() << ",";
    out << "\"all_excluded\":" << json_bool(all_excluded) << ",";
    out << "\"survivors_empty\":" << json_bool(survivors_empty) << ",";
    out << "\"certificate_succeeded\":" << json_bool(certificate_succeeded) << ",";
    out << "\"cases\":[";
    for (size_t i = 0; i < cases.size(); ++i) {
        if (i) out << ",";
        const Case& c = cases[i];
        const Survivor& s = survivors[i];
        out << "{";
        out << "\"m\":" << c.m << ",\"b\":" << c.b << ",\"N\":" << c.n
            << ",\"complexity_bound\":" << c.bound
            << ",\"excluded\":" << json_bool(!s.found)
            << ",\"survivors\":";
        if (!s.found) {
            out << "[]";
        } else {
            out << "[{\"pair_index\":" << s.pair_index
                << ",\"e\":" << s.e
                << ",\"k\":[";
            for (size_t j = 0; j < s.k.size(); ++j) {
                if (j) out << ",";
                out << s.k[j];
            }
            out << "],\"complexity\":" << s.complexity
                << ",\"polynomial\":\"" << json_escape(s.polynomial) << "\"}]";
        }
        out << "}";
    }
    out << "]}";
    if (argc == 3) {
        std::ofstream report_out(argv[2], std::ios::binary);
        if (!report_out) {
            std::cerr << "could not open output\n";
            return 2;
        }
        report_out << out.str() << "\n";
    } else {
        std::cout << out.str() << "\n";
    }
    return 0;
}
