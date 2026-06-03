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
    ull n_v3;
};

struct Miss {
    ull diff = INF;
    ull value = 0;
    ull e = 0;
    std::vector<ull> k;
};

struct HardCase {
    ull pair_index = 0;
    ull base_complexity = 0;
    int degree = 0;
    int m = 0;
    int b = 0;
    ull n = 0;
    ull total_exponent_sum_max = 0;
    ull tuples_checked = 0;
    std::string tuple_count_method = "combinatorial_bounded_exponent_space";
    std::string polynomial;
    std::vector<Miss> closest;
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

static ull cap_mul_to(ull a, ull b, ull cap) {
    if (a == 0 || b == 0) return 0;
    if (a > cap / b) return cap;
    ull out = a * b;
    return out > cap ? cap : out;
}

static ull cap_add_to(ull a, ull b, ull cap) {
    if (a > cap - b) return cap;
    ull out = a + b;
    return out > cap ? cap : out;
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

struct Bitset {
    int modulus = 1;
    std::vector<ull> words;

    Bitset() {}
    explicit Bitset(int m) : modulus(m), words((m + 63) / 64, 0) {}

    void add(int residue) {
        residue %= modulus;
        if (residue < 0) residue += modulus;
        words[(size_t)residue / 64] |= 1ULL << (residue % 64);
    }

    bool contains(int residue) const {
        residue %= modulus;
        if (residue < 0) residue += modulus;
        return (words[(size_t)residue / 64] >> (residue % 64)) & 1ULL;
    }

    bool empty() const {
        for (ull w : words) {
            if (w) return false;
        }
        return true;
    }

    void merge_from(const Bitset& other) {
        for (size_t i = 0; i < words.size(); ++i) words[i] |= other.words[i];
    }

    std::vector<int> values() const {
        std::vector<int> out;
        for (int r = 0; r < modulus; ++r) {
            if (contains(r)) out.push_back(r);
        }
        return out;
    }
};

static ull v_p(ull n, ull p) {
    ull out = 0;
    while (n % p == 0) {
        n /= p;
        ++out;
    }
    return out;
}

static int residue_v3(int residue) {
    if (residue == 0) return 99;
    int out = 0;
    while (residue % 3 == 0) {
        residue /= 3;
        ++out;
    }
    return out;
}

static std::vector<int> pow3_mod_table(int modulus, int budget) {
    std::vector<int> p((size_t)budget + 1, 1 % modulus);
    for (int i = 1; i <= budget; ++i) p[(size_t)i] = (p[(size_t)i - 1] * 3) % modulus;
    return p;
}

static std::vector<Bitset> residue_dp(const Node* node, int budget, int modulus) {
    std::vector<Bitset> out((size_t)budget + 1, Bitset(modulus));
    if (node->kind == 'A') {
        std::vector<Bitset> child = residue_dp(node->child.get(), budget, modulus);
        std::vector<int> pow3 = pow3_mod_table(modulus, budget);
        for (int used = 0; used <= budget; ++used) {
            if (child[(size_t)used].empty()) continue;
            std::vector<int> child_residues = child[(size_t)used].values();
            for (int k = 0; used + k <= budget; ++k) {
                Bitset& dest = out[(size_t)(used + k)];
                int mult = pow3[(size_t)k];
                for (int r : child_residues) {
                    dest.add((r * mult + static_cast<int>(node->constant % (ull)modulus)) % modulus);
                }
            }
        }
        return out;
    }

    out[0].add(static_cast<int>(node->constant % (ull)modulus));
    for (const auto& child_node : node->children) {
        std::vector<Bitset> child = residue_dp(child_node.get(), budget, modulus);
        std::vector<Bitset> next((size_t)budget + 1, Bitset(modulus));
        for (int left_used = 0; left_used <= budget; ++left_used) {
            if (out[(size_t)left_used].empty()) continue;
            std::vector<int> left_values = out[(size_t)left_used].values();
            for (int child_used = 0; left_used + child_used <= budget; ++child_used) {
                if (child[(size_t)child_used].empty()) continue;
                std::vector<int> child_values = child[(size_t)child_used].values();
                Bitset& dest = next[(size_t)(left_used + child_used)];
                for (int a : left_values) {
                    for (int b : child_values) {
                        dest.add((a * b) % modulus);
                    }
                }
            }
        }
        out.swap(next);
    }
    return out;
}

static bool residue_possible_up_to(const std::vector<Bitset>& dp, int budget, ull target, int modulus) {
    int residue = static_cast<int>(target % (ull)modulus);
    budget = std::min<int>(budget, static_cast<int>(dp.size()) - 1);
    for (int used = 0; used <= budget; ++used) {
        if (dp[(size_t)used].contains(residue)) return true;
    }
    return false;
}

static bool v3_possible_up_to(const std::vector<Bitset>& dp, int budget, int wanted_v3) {
    budget = std::min<int>(budget, static_cast<int>(dp.size()) - 1);
    for (int used = 0; used <= budget; ++used) {
        std::vector<int> values = dp[(size_t)used].values();
        for (int r : values) {
            if (residue_v3(r) == wanted_v3) return true;
        }
    }
    return false;
}

static ull eval_node(const Node* node, const std::vector<ull>& exps, size_t& pos, ull cap) {
    if (node->kind == 'A') {
        ull k = exps[(size_t)pos++];
        ull child_value = eval_node(node->child.get(), exps, pos, cap);
        ull power = k < POW3.size() ? POW3[(size_t)k] : cap;
        return cap_add_to(cap_mul_to(child_value, power, cap), node->constant, cap);
    }
    ull value = node->constant;
    for (const auto& child : node->children) {
        ull child_value = eval_node(child.get(), exps, pos, cap);
        value = cap_mul_to(value, child_value, cap);
    }
    return value;
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

static std::string shape_signature(const Node* node) {
    if (node->kind == 'A') {
        return "A(" + shape_signature(node->child.get()) + ")";
    }
    if (node->children.empty()) return "P0";
    std::string out = "P(";
    for (size_t i = 0; i < node->children.size(); ++i) {
        if (i) out += "*";
        out += shape_signature(node->children[i].get());
    }
    out += ")";
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
            c.n_v3 = v_p(c.n, 3);
            cases.push_back(c);
        }
    }
    return cases;
}

static std::string c_bucket(ull c) {
    ull lo = (c / 10) * 10;
    ull hi = lo + 9;
    char buf[64];
    std::snprintf(buf, sizeof(buf), "C%03llu_%03llu", lo, hi);
    return std::string(buf);
}

static std::string target_key(const Case& c) {
    return "m" + std::to_string(c.m) + "_b" + std::to_string(c.b);
}

static void add_count(std::map<std::string, ull>& m, const std::string& key, ull amount = 1) {
    m[key] += amount;
}

static void add_nested(std::map<std::string, std::map<std::string, ull>>& m,
                       const std::string& outer,
                       const std::string& inner) {
    m[outer][inner]++;
}

static void add_miss(std::vector<Miss>& closest, const Miss& miss) {
    if (miss.diff == 0) return;
    closest.push_back(miss);
    std::sort(closest.begin(), closest.end(), [](const Miss& a, const Miss& b) {
        if (a.diff != b.diff) return a.diff < b.diff;
        if (a.value != b.value) return a.value < b.value;
        return a.e < b.e;
    });
    if (closest.size() > 3) closest.resize(3);
}

static ull abs_diff(ull a, ull b) {
    return a >= b ? a - b : b - a;
}

static ull choose_small(ull n, int k) {
    if (k < 0) return 0;
    if (k == 0) return 1;
    if (k > static_cast<int>(n)) return 0;
    if (k > static_cast<int>(n - k)) k = static_cast<int>(n - k);
    ull out = 1;
    for (int i = 1; i <= k; ++i) {
        out = (out * (n - static_cast<ull>(k - i))) / static_cast<ull>(i);
    }
    return out;
}

static ull bounded_tuple_count(int degree, ull exponent_budget, ull top_v3) {
    ull max_e = std::min(exponent_budget, top_v3);
    ull out = 0;
    for (ull e = 0; e <= max_e; ++e) {
        out += choose_small(exponent_budget - e + static_cast<ull>(degree), degree);
    }
    return out;
}

static void enumerate_k_tuples(const Node* tree,
                               int degree,
                               int index,
                               ull remaining,
                               std::vector<ull>& k,
                               ull top_e,
                               ull n,
                               ull eval_cap,
                               ull& tuples_checked,
                               bool& found,
                               std::vector<Miss>& closest) {
    if (index == degree) {
        size_t pos = 0;
        ull f_value = eval_node(tree, k, pos, eval_cap);
        ull total = cap_mul_to(f_value, top_e < POW3.size() ? POW3[(size_t)top_e] : eval_cap, eval_cap);
        tuples_checked++;
        if (total == n) {
            found = true;
            return;
        }
        Miss miss;
        miss.diff = abs_diff(total, n);
        miss.value = total;
        miss.e = top_e;
        miss.k = k;
        add_miss(closest, miss);
        return;
    }

    for (ull value = 0; value <= remaining; ++value) {
        k[(size_t)index] = value;
        enumerate_k_tuples(tree, degree, index + 1, remaining - value, k, top_e, n,
                           eval_cap, tuples_checked, found, closest);
        if (found) return;
    }
}

static HardCase brute_force_hard_case(const Pair& pair, const Case& c, ull pair_index, ull exponent_budget) {
    HardCase hard;
    hard.pair_index = pair_index;
    hard.base_complexity = pair.base_complexity;
    hard.degree = pair.degree;
    hard.m = c.m;
    hard.b = c.b;
    hard.n = c.n;
    hard.total_exponent_sum_max = exponent_budget;
    hard.polynomial = pretty(pair.tree.get());

    ull eval_cap = c.n > (INF - 1) / 2 ? INF : (2 * c.n + 1);
    ull max_e = std::min(c.n_v3, exponent_budget);
    std::vector<ull> k((size_t)pair.degree, 0);
    bool found = false;
    for (ull e = 0; e <= max_e; ++e) {
        enumerate_k_tuples(pair.tree.get(), pair.degree, 0, exponent_budget - e, k, e, c.n,
                           eval_cap, hard.tuples_checked, found, hard.closest);
        if (found) break;
    }
    return hard;
}

static HardCase summarize_hard_case(const Pair& pair, const Case& c, ull pair_index, ull exponent_budget) {
    HardCase hard;
    hard.pair_index = pair_index;
    hard.base_complexity = pair.base_complexity;
    hard.degree = pair.degree;
    hard.m = c.m;
    hard.b = c.b;
    hard.n = c.n;
    hard.total_exponent_sum_max = exponent_budget;
    hard.tuples_checked = bounded_tuple_count(pair.degree, exponent_budget, c.n_v3);
    hard.polynomial = pretty(pair.tree.get());
    return hard;
}

struct PairResidues {
    int max_budget = -1;
    std::map<int, std::vector<Bitset>> by_modulus;

    const std::vector<Bitset>& get(const Node* root, int budget, int modulus) {
        auto it = by_modulus.find(modulus);
        if (it == by_modulus.end() || max_budget < budget) {
            if (budget > max_budget) {
                max_budget = budget;
                by_modulus.clear();
            }
            it = by_modulus.emplace(modulus, residue_dp(root, max_budget, modulus)).first;
        }
        return it->second;
    }
};

struct Analyzer {
    std::vector<Case> cases = target_cases();
    std::map<std::string, ull> obstruction_counts;
    std::map<std::string, std::map<std::string, ull>> by_degree;
    std::map<std::string, std::map<std::string, ull>> by_complexity_bucket;
    std::map<std::string, std::map<std::string, ull>> by_shape;
    std::map<std::string, std::map<std::string, ull>> by_target;
    std::map<std::string, ull> degree_histogram;
    std::map<std::string, ull> modular_detail_counts;
    std::vector<HardCase> hard_cases;
    ull hard_case_count = 0;
    ull survivor_count = 0;
    ull pair_target_count = 0;
    ull max_hard_records = 100000;
    int max_degree = 0;

    explicit Analyzer(ull max_records) : max_hard_records(max_records) {}

    void record(const Pair& pair, const Case& c, const std::string& obstruction,
                const std::string& shape, const std::string& detail = "") {
        pair_target_count++;
        add_count(obstruction_counts, obstruction);
        add_nested(by_degree, std::to_string(pair.degree), obstruction);
        add_nested(by_complexity_bucket, c_bucket(pair.base_complexity), obstruction);
        add_nested(by_shape, "D" + std::to_string(pair.degree) + ":" + shape, obstruction);
        add_nested(by_target, target_key(c), obstruction);
        if (!detail.empty()) add_count(modular_detail_counts, detail);
    }

    std::string classify(const Pair& pair, const Case& c, PairResidues& residues,
                         std::string* detail, HardCase* hard) {
        if (pair.base_complexity > c.bound) {
            return "cost_bound_impossible";
        }

        ull exponent_budget = (c.bound - pair.base_complexity) / 3;
        ull max_e = std::min(c.n_v3, exponent_budget);

        if (pair.degree == 0) {
            bool matched = false;
            ull power = 1;
            for (ull e = 0; e <= max_e; ++e) {
                if (c.n % power == 0 && c.n / power == pair.tree->min_value) {
                    matched = true;
                    break;
                }
                if (e != max_e) power *= 3;
            }
            if (!matched) return "degree_max_exponent_bound_impossible";
            survivor_count++;
            return "survivor_found";
        }

        if (exponent_budget == 0 && c.n != pair.tree->min_value) {
            return "degree_max_exponent_bound_impossible";
        }

        bool size_possible = false;
        ull power = 1;
        for (ull e = 0; e <= max_e; ++e) {
            ull target = c.n / power;
            if (in_range(pair.tree.get(), target, exponent_budget - e)) {
                size_possible = true;
                break;
            }
            if (e != max_e) power *= 3;
        }
        if (!size_possible) {
            return "size_interval_impossible";
        }

        const std::vector<Bitset>& mod243_for_v3 =
            residues.get(pair.tree.get(), static_cast<int>(exponent_budget), 243);
        bool valuation_possible = false;
        power = 1;
        for (ull e = 0; e <= max_e; ++e) {
            int wanted = static_cast<int>(c.n_v3 - e);
            if (v3_possible_up_to(mod243_for_v3, static_cast<int>(exponent_budget - e), wanted)) {
                valuation_possible = true;
                break;
            }
            if (e != max_e) power *= 3;
        }
        if (!valuation_possible) {
            return "v_3_obstruction";
        }

        static const int moduli[] = {16, 64, 81, 243};
        for (int modulus : moduli) {
            const std::vector<Bitset>& dp = residues.get(pair.tree.get(), static_cast<int>(exponent_budget), modulus);
            bool residue_possible = false;
            power = 1;
            for (ull e = 0; e <= max_e; ++e) {
                ull target = c.n / power;
                if (residue_possible_up_to(dp, static_cast<int>(exponent_budget - e), target, modulus)) {
                    residue_possible = true;
                    break;
                }
                if (e != max_e) power *= 3;
            }
            if (!residue_possible) {
                if (detail) *detail = "mod_" + std::to_string(modulus);
                return "modular_obstruction";
            }
        }

        if (pair.tree->kind == 'M' && pair.tree->constant != 0) {
            bool constant_divides = false;
            power = 1;
            for (ull e = 0; e <= max_e; ++e) {
                ull target = c.n / power;
                if (target % pair.tree->constant == 0) {
                    constant_divides = true;
                    break;
                }
                if (e != max_e) power *= 3;
            }
            if (!constant_divides) {
                return "factorization_obstruction";
            }
        }

        if (hard) {
            *hard = summarize_hard_case(pair, c, hard->pair_index, exponent_budget);
        }
        return "exhaustive_exponent_enumeration_needed";
    }
};

static void write_count_map(std::ostream& out, const std::map<std::string, ull>& m) {
    out << "{";
    bool first = true;
    for (const auto& kv : m) {
        if (!first) out << ",";
        first = false;
        out << "\"" << json_escape(kv.first) << "\":" << kv.second;
    }
    out << "}";
}

static void write_nested_map(std::ostream& out,
                             const std::map<std::string, std::map<std::string, ull>>& m) {
    out << "{";
    bool first_outer = true;
    for (const auto& outer : m) {
        if (!first_outer) out << ",";
        first_outer = false;
        out << "\"" << json_escape(outer.first) << "\":";
        write_count_map(out, outer.second);
    }
    out << "}";
}

static void write_miss(std::ostream& out, const Miss& miss) {
    out << "{";
    out << "\"diff\":" << miss.diff << ",";
    out << "\"value\":" << miss.value << ",";
    out << "\"e\":" << miss.e << ",";
    out << "\"k\":[";
    for (size_t i = 0; i < miss.k.size(); ++i) {
        if (i) out << ",";
        out << miss.k[i];
    }
    out << "]}";
}

static void write_hard_case(std::ostream& out, const HardCase& h) {
    out << "{";
    out << "\"pair_index\":" << h.pair_index << ",";
    out << "\"base_complexity\":" << h.base_complexity << ",";
    out << "\"degree\":" << h.degree << ",";
    out << "\"m\":" << h.m << ",";
    out << "\"b\":" << h.b << ",";
    out << "\"N\":" << h.n << ",";
    out << "\"allowed_exponent_sum_min\":0,";
    out << "\"allowed_exponent_sum_max\":" << h.total_exponent_sum_max << ",";
    out << "\"exponent_tuples_checked\":" << h.tuples_checked << ",";
    out << "\"tuple_count_method\":\"" << json_escape(h.tuple_count_method) << "\",";
    out << "\"polynomial\":\"" << json_escape(h.polynomial) << "\",";
    out << "\"closest_misses\":[";
    for (size_t i = 0; i < h.closest.size(); ++i) {
        if (i) out << ",";
        write_miss(out, h.closest[i]);
    }
    out << "]}";
}

static void write_hard_cases_json(const std::string& path,
                                  const std::string& covering_path,
                                  const Analyzer& analyzer) {
    std::ofstream out(path, std::ios::binary);
    if (!out) throw std::runtime_error("could not open hard case output");
    out << "{";
    out << "\"covering_path\":\"" << json_escape(covering_path) << "\",";
    out << "\"hard_case_count\":" << analyzer.hard_case_count << ",";
    out << "\"recorded_count\":" << analyzer.hard_cases.size() << ",";
    out << "\"truncated\":" << (analyzer.hard_cases.size() < analyzer.hard_case_count ? "true" : "false") << ",";
    out << "\"hard_cases\":[";
    for (size_t i = 0; i < analyzer.hard_cases.size(); ++i) {
        if (i) out << ",";
        write_hard_case(out, analyzer.hard_cases[i]);
    }
    out << "]}\n";
}

static void write_summary_json(const std::string& path,
                               const std::string& covering_path,
                               ull threshold,
                               ull declared_pair_count,
                               ull parsed_pairs,
                               const Analyzer& analyzer) {
    std::ofstream out(path, std::ios::binary);
    if (!out) throw std::runtime_error("could not open summary output");
    out << "{";
    out << "\"analyzer\":\"native_cpp_obstruction_streaming\",";
    out << "\"covering_path\":\"" << json_escape(covering_path) << "\",";
    out << "\"threshold_multiple\":" << threshold << ",";
    out << "\"declared_pair_count\":" << declared_pair_count << ",";
    out << "\"pair_count\":" << parsed_pairs << ",";
    out << "\"pair_count_matches_declared\":"
        << ((declared_pair_count == 0 || declared_pair_count == parsed_pairs) ? "true" : "false") << ",";
    out << "\"max_degree\":" << analyzer.max_degree << ",";
    out << "\"target_count\":" << analyzer.cases.size() << ",";
    out << "\"pair_target_count\":" << analyzer.pair_target_count << ",";
    out << "\"survivor_count\":" << analyzer.survivor_count << ",";
    out << "\"hard_case_count\":" << analyzer.hard_case_count << ",";
    out << "\"hard_cases_recorded\":" << analyzer.hard_cases.size() << ",";
    out << "\"classification_order\":[";
    const char* order[] = {
        "cost_bound_impossible",
        "degree_max_exponent_bound_impossible",
        "size_interval_impossible",
        "v_3_obstruction",
        "modular_obstruction",
        "factorization_obstruction",
        "exhaustive_exponent_enumeration_needed"
    };
    for (size_t i = 0; i < sizeof(order) / sizeof(order[0]); ++i) {
        if (i) out << ",";
        out << "\"" << order[i] << "\"";
    }
    out << "],";
    out << "\"obstruction_definitions\":{";
    out << "\"cost_bound_impossible\":\"base complexity C exceeds 2m-2\",";
    out << "\"degree_max_exponent_bound_impossible\":\"degree zero or zero exponent budget leaves no exact exponent freedom compatible with N\",";
    out << "\"size_interval_impossible\":\"for every allowed top exponent e, N/3^e is outside the exact min and coefficient-sum upper interval for the remaining budget\",";
    out << "\"v_3_obstruction\":\"residue sets modulo 3^5 show that no allowed assignment can have the required 3-adic valuation\",";
    out << "\"modular_obstruction\":\"residue sets modulo the first failing small modulus among 16,64,81,243 exclude N/3^e for every allowed e\",";
    out << "\"factorization_obstruction\":\"root product constant divisibility excludes every allowed top exponent after earlier filters\",";
    out << "\"exhaustive_exponent_enumeration_needed\":\"earlier exact filters did not exclude the pair-target; the existing verifier's exact exponent enumeration is the remaining exclusion mechanism. The analyzer records the exact bounded exponent-tuple search-space size without re-evaluating every tuple.\"";
    out << "},";
    out << "\"obstruction_counts\":";
    write_count_map(out, analyzer.obstruction_counts);
    out << ",\"degree_histogram\":";
    write_count_map(out, analyzer.degree_histogram);
    out << ",\"by_degree\":";
    write_nested_map(out, analyzer.by_degree);
    out << ",\"by_base_complexity_bucket\":";
    write_nested_map(out, analyzer.by_complexity_bucket);
    out << ",\"by_polynomial_shape\":";
    write_nested_map(out, analyzer.by_shape);
    out << ",\"by_target\":";
    write_nested_map(out, analyzer.by_target);
    out << ",\"modular_detail_counts\":";
    write_count_map(out, analyzer.modular_detail_counts);
    out << "}\n";
}

int main(int argc, char** argv) {
    if (argc < 4 || argc > 5) {
        std::cerr << "usage: analyze_obstructions S_46.json summary.json hard_cases.json [max_hard_records]\n";
        return 2;
    }

    std::string covering_path = argv[1];
    ull max_hard_records = 100000;
    if (argc == 5) {
        max_hard_records = static_cast<ull>(std::strtoull(argv[4], nullptr, 10));
    }

    std::ifstream in(covering_path, std::ios::binary);
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

    Analyzer analyzer(max_hard_records);
    ull parsed_pairs = 0;

    while (true) {
        parser.skip_ws();
        if (parser.consume(']')) break;
        Pair pair = parser.parse_pair();
        analyzer.max_degree = std::max(analyzer.max_degree, pair.degree);
        add_count(analyzer.degree_histogram, std::to_string(pair.degree));
        std::string shape = shape_signature(pair.tree.get());
        PairResidues residues;
        for (const Case& c : analyzer.cases) {
            std::string detail;
            HardCase hard;
            hard.pair_index = parsed_pairs;
            std::string obstruction = analyzer.classify(pair, c, residues, &detail, &hard);
            if (obstruction == "exhaustive_exponent_enumeration_needed") {
                analyzer.hard_case_count++;
                if (analyzer.hard_cases.size() < analyzer.max_hard_records) {
                    analyzer.hard_cases.push_back(std::move(hard));
                }
            }
            analyzer.record(pair, c, obstruction, shape, detail);
        }
        parsed_pairs++;
        if (parsed_pairs % 100000 == 0) {
            std::cerr << "analyzed_pairs=" << parsed_pairs
                      << " hard_cases=" << analyzer.hard_case_count
                      << " survivors=" << analyzer.survivor_count << "\n";
        }
        parser.skip_ws();
        if (parser.consume(']')) break;
        parser.expect(',');
    }

    write_summary_json(argv[2], covering_path, threshold, declared_pair_count, parsed_pairs, analyzer);
    write_hard_cases_json(argv[3], covering_path, analyzer);
    return 0;
}
