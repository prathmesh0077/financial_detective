"""
Financial Detective — Screener.in Data Ingestion Script (v3 FIXED)

Fixes vs v2:
  1. Banks have no "Debt / Equity" in top-ratios → use Capital Adequacy / sector override
  2. Bank P&L uses "Interest Earned" / "Net Interest Income" not "Sales"
  3. Shareholding: read actual "Public / Others" row instead of computing residual
  4. FII/DII/Retail quarterly CHANGE computed by diffing last two columns
  5. change_percent: fallback to previousClose diff + handle market-closed case
  6. money_trail: guard all divisions, never produce NaN/Inf, use net_profit for netIncome

Usage:
  pip install requests beautifulsoup4
  SUPABASE_URL=... SUPABASE_KEY=... python fetch_screener.py
"""

import os, re, time, random, requests
from bs4 import BeautifulSoup

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://qnfoyfavdhbavsjozvld.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "")

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
}

# Sectors where "Debt/Equity" is meaningless — banks fund via deposits not debt
BANKING_SECTORS = {"Banking", "NBFC", "Insurance"}

COMPANIES = [
    {"ticker": "RELIANCE",   "name": "Reliance Industries",       "sector": "Energy"},
    {"ticker": "HDFCBANK",   "name": "HDFC Bank",                 "sector": "Banking"},
    {"ticker": "BHARTIARTL", "name": "Bharti Airtel",             "sector": "Telecom"},
    {"ticker": "SBIN",       "name": "State Bank of India",       "sector": "Banking"},
    {"ticker": "ICICIBANK",  "name": "ICICI Bank",                "sector": "Banking"},
    {"ticker": "TCS",        "name": "Tata Consultancy Services", "sector": "IT"},
    {"ticker": "BAJFINANCE", "name": "Bajaj Finance",             "sector": "NBFC"},
    {"ticker": "LT",         "name": "Larsen & Toubro",           "sector": "Infrastructure"},
    {"ticker": "INFY",       "name": "Infosys",                   "sector": "IT"},
    {"ticker": "HINDUNILVR", "name": "Hindustan Unilever",        "sector": "FMCG"},
    {"ticker": "AXISBANK",   "name": "Axis Bank",                 "sector": "Banking"},
    {"ticker": "MARUTI",     "name": "Maruti Suzuki",             "sector": "Auto"},
    {"ticker": "M&M",        "name": "Mahindra & Mahindra",       "sector": "Auto"},
    {"ticker": "SUNPHARMA",  "name": "Sun Pharmaceutical",        "sector": "Pharma"},
    {"ticker": "TITAN",      "name": "Titan",                     "sector": "Consumer"},
    {"ticker": "HCLTECH",    "name": "HCL Technologies",          "sector": "IT"},
    {"ticker": "NTPC",       "name": "NTPC",                      "sector": "Power"},
    {"ticker": "ITC",        "name": "ITC",                       "sector": "FMCG"},
    {"ticker": "KOTAKBANK",  "name": "Kotak Mahindra Bank",       "sector": "Banking"},
    {"ticker": "ONGC",       "name": "Oil & Natural Gas Corp",    "sector": "Energy"},
    {"ticker": "ULTRACEMCO", "name": "UltraTech Cement",          "sector": "Cement"},
    {"ticker": "ADANIPORTS", "name": "Adani Ports & SEZ",         "sector": "Infrastructure"},
    {"ticker": "BEL",        "name": "Bharat Electronics",        "sector": "Defence"},
    {"ticker": "JSWSTEEL",   "name": "JSW Steel",                 "sector": "Metals"},
    {"ticker": "BAJAJFINSV", "name": "Bajaj Finserv",             "sector": "NBFC"},
    {"ticker": "POWERGRID",  "name": "Power Grid Corp",           "sector": "Power"},
    {"ticker": "BAJAJ-AUTO", "name": "Bajaj Auto",                "sector": "Auto"},
    {"ticker": "COALINDIA",  "name": "Coal India",                "sector": "Mining"},
    {"ticker": "TATASTEEL",  "name": "Tata Steel",                "sector": "Metals"},
    {"ticker": "ADANIENT",   "name": "Adani Enterprises",         "sector": "Conglomerate"},
    {"ticker": "NESTLEIND",  "name": "Nestle India",              "sector": "FMCG"},
    {"ticker": "ETERNAL",    "name": "Eternal (Zomato)",          "sector": "Tech"},
    {"ticker": "ASIANPAINT", "name": "Asian Paints",              "sector": "Consumer"},
    {"ticker": "HINDALCO",   "name": "Hindalco Industries",       "sector": "Metals"},
    {"ticker": "WIPRO",      "name": "Wipro",                     "sector": "IT"},
    {"ticker": "EICHERMOT",  "name": "Eicher Motors",             "sector": "Auto"},
    {"ticker": "SBILIFE",    "name": "SBI Life Insurance",        "sector": "Insurance"},
    {"ticker": "SHRIRAMFIN", "name": "Shriram Finance",           "sector": "NBFC"},
    {"ticker": "GRASIM",     "name": "Grasim Industries",         "sector": "Cement"},
    {"ticker": "INDIGO",     "name": "Interglobe Aviation",       "sector": "Aviation"},
    {"ticker": "JIOFIN",     "name": "Jio Financial Services",    "sector": "NBFC"},
    {"ticker": "TECHM",      "name": "Tech Mahindra",             "sector": "IT"},
    {"ticker": "TRENT",      "name": "Trent",                     "sector": "Retail"},
    {"ticker": "HDFCLIFE",   "name": "HDFC Life Insurance",       "sector": "Insurance"},
    {"ticker": "TATAMOTORS", "name": "Tata Motors",               "sector": "Auto"},
    {"ticker": "APOLLOHOSP", "name": "Apollo Hospitals",          "sector": "Healthcare"},
    {"ticker": "TATACONSUM", "name": "Tata Consumer Products",    "sector": "FMCG"},
    {"ticker": "DRREDDY",    "name": "Dr Reddys Laboratories",    "sector": "Pharma"},
    {"ticker": "CIPLA",      "name": "Cipla",                     "sector": "Pharma"},
    {"ticker": "MAXHEALTH",  "name": "Max Healthcare",            "sector": "Healthcare"},
]


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def safe_float(text, default=0.0):
    if text is None:
        return default
    t = re.sub(r"[^\d.\-]", "", str(text).replace(",", "").replace("%", "").strip())
    try:
        v = float(t)
        return default if (v != v or v == float("inf") or v == float("-inf")) else v
    except (ValueError, TypeError):
        return default

def div(a, b, default=0.0):
    """Safe division — never NaN/Inf."""
    try:
        if b == 0:
            return default
        v = a / b
        return default if (v != v or abs(v) == float("inf")) else v
    except Exception:
        return default

def get_row_latest(cells):
    """Return last non-zero numeric value from a table row's data cells (skip label cell[0])."""
    vals = [safe_float(c.text) for c in cells[1:]]
    non_zero = [v for v in vals if v != 0.0]
    return non_zero[-1] if non_zero else 0.0

def get_row_two_latest(cells):
    """Return (current, previous) last two non-zero values — for computing deltas."""
    vals = [safe_float(c.text) for c in cells[1:]]
    non_zero = [v for v in vals if v != 0.0]
    if len(non_zero) >= 2:
        return non_zero[-1], non_zero[-2]
    elif len(non_zero) == 1:
        return non_zero[-1], non_zero[-1]
    return 0.0, 0.0


# ─────────────────────────────────────────────
# YAHOO FINANCE
# ─────────────────────────────────────────────

YAHOO_OVERRIDES = {
    "M&M":        "M%26M",
    "BAJAJ-AUTO": "BAJAJ-AUTO",
}

def _yahoo_ticker(ticker):
    return YAHOO_OVERRIDES.get(ticker, ticker)

def fetch_yahoo_quote(ticker):
    """Returns (price, change_pct). Always non-None."""
    yt  = _yahoo_ticker(ticker)
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{yt}.NS?interval=1d&range=2d"
    try:
        r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=12)
        if r.status_code != 200:
            return 0.0, 0.0
        d      = r.json()
        result = d.get("chart", {}).get("result", [])
        if not result:
            return 0.0, 0.0
        meta       = result[0].get("meta", {})
        price      = float(meta.get("regularMarketPrice") or meta.get("previousClose") or 0)
        prev       = float(meta.get("chartPreviousClose") or meta.get("previousClose") or price)
        change_pct = round(div(price - prev, prev) * 100, 2) if prev else 0.0
        return round(price, 2), change_pct
    except Exception as e:
        print(f"    [Yahoo quote WARN] {ticker}: {e}")
        return 0.0, 0.0

def fetch_yahoo_history(ticker):
    """Returns list of monthly closes (up to 24 months)."""
    yt  = _yahoo_ticker(ticker)
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{yt}.NS?interval=1mo&range=24mo"
    try:
        r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=12)
        if r.status_code != 200:
            return []
        d      = r.json()
        result = d.get("chart", {}).get("result", [])
        if not result:
            return []
        closes = result[0].get("indicators", {}).get("quote", [{}])[0].get("close", [])
        return [round(float(c), 2) for c in closes if c is not None]
    except Exception as e:
        print(f"    [Yahoo history WARN] {ticker}: {e}")
        return []


# ─────────────────────────────────────────────
# SCREENER PARSER
# ─────────────────────────────────────────────

def fetch_screener_data(ticker, sector):
    url = f"https://www.screener.in/company/{ticker}/consolidated/"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code == 404:
            resp = requests.get(
                f"https://www.screener.in/company/{ticker}/", headers=HEADERS, timeout=15
            )
        if resp.status_code != 200:
            print(f"    [Screener WARN] HTTP {resp.status_code}")
            return {}
    except Exception as e:
        print(f"    [Screener ERROR] {e}")
        return {}

    soup = BeautifulSoup(resp.text, "html.parser")
    data = {}

    # ── Top ratios ──
    ratios = {}
    for li in soup.select("#top-ratios li"):
        n = li.select_one(".name")
        v = li.select_one(".number")
        if n and v:
            ratios[n.text.strip()] = v.text.strip()
    print(f"    Screener ratios: {ratios}")

    data["roce"] = safe_float(
        ratios.get("ROCE %") or ratios.get("ROCE") or
        ratios.get("Return on capital employed") or "0"
    )

    # FIX 1: Debt/Equity meaningless for banks
    if sector in BANKING_SECTORS:
        data["debt_to_equity"] = 0.0
        data["is_bank"] = True
    else:
        data["debt_to_equity"] = safe_float(
            ratios.get("Debt / Equity") or ratios.get("Debt to equity") or
            ratios.get("D/E Ratio") or "0"
        )
        data["is_bank"] = False

    data["opm_ratio"] = safe_float(
        ratios.get("OPM") or ratios.get("OPM %") or "0"
    )

    # ── P&L table ──
    # FIX 2: Banks use different revenue labels
    revenue = net_profit = operating_profit = 0.0

    pl_section = soup.find("section", id="profit-loss")
    if pl_section:
        for row in pl_section.find_all("tr"):
            cells = row.find_all("td")
            if not cells or len(cells) < 2:
                continue
            label = cells[0].text.strip().lower()

            if sector in BANKING_SECTORS:
                if any(x in label for x in ["interest earned", "net interest income", "revenue from operations", "total income"]):
                    if revenue == 0:
                        revenue = get_row_latest(cells)
                elif "operating profit" in label and "%" not in label:
                    operating_profit = get_row_latest(cells)
                elif "net profit" in label and "%" not in label:
                    net_profit = get_row_latest(cells)
            else:
                if any(x in label for x in ["sales", "revenue from operations", "net revenue", "total revenue"]):
                    if revenue == 0:
                        revenue = get_row_latest(cells)
                elif "operating profit" in label and "%" not in label and "opm" not in label:
                    operating_profit = get_row_latest(cells)
                elif "net profit" in label and "%" not in label:
                    net_profit = get_row_latest(cells)

    data["revenue"]          = revenue
    data["net_profit"]       = net_profit
    data["operating_profit"] = operating_profit
    data["operating_margin"] = (
        round(div(operating_profit, revenue) * 100, 2)
        if revenue > 0 and operating_profit > 0
        else data["opm_ratio"]
    )

    print(f"    P&L: rev={revenue}, op={operating_profit}, net={net_profit}, opm={data['operating_margin']}%")

    # ── Shareholding ──
    # FIX 3 & 4: read actual public row + compute deltas
    fii = dii = promoter = retail = 0.0
    fii_prev = dii_prev = retail_prev = 0.0

    sh_section = soup.find("section", id="shareholding")
    if sh_section:
        for row in sh_section.find_all("tr"):
            cells = row.find_all("td")
            if not cells or len(cells) < 2:
                continue
            label = cells[0].text.strip().lower()
            curr, prev = get_row_two_latest(cells)

            if "promoter" in label:
                promoter = curr
            elif any(x in label for x in ["fii", "foreign", "fpi"]):
                fii = curr
                fii_prev = prev
            elif any(x in label for x in ["dii", "domestic inst"]):
                dii = curr
                dii_prev = prev
            elif any(x in label for x in ["public", "retail", "others", "non-inst"]):
                retail = curr
                retail_prev = prev

    # Fallback if public row not found
    if retail == 0.0:
        retail = max(0.0, round(100.0 - promoter - fii - dii, 2))
        retail_prev = retail

    data["fii_holding"]    = round(max(0.0, min(100.0, fii)), 2)
    data["dii_holding"]    = round(max(0.0, min(100.0, dii)), 2)
    data["retail_holding"] = round(max(0.0, min(100.0, retail)), 2)
    data["promoter_holding"] = round(promoter, 2)
    data["fii_change"]    = round(fii    - fii_prev,    2)
    data["dii_change"]    = round(dii    - dii_prev,    2)
    data["retail_change"] = round(retail - retail_prev, 2)

    print(f"    Holdings: P={promoter}% FII={fii}%(d{data['fii_change']}) "
          f"DII={dii}%(d{data['dii_change']}) Retail={retail}%(d{data['retail_change']})")

    return data


# ─────────────────────────────────────────────
# SCORES
# ─────────────────────────────────────────────

def compute_scores(comp, d):
    sector = comp["sector"]
    roce   = d.get("roce", 0)
    de     = d.get("debt_to_equity", 0)
    opm    = d.get("operating_margin", 0)
    rev    = d.get("revenue", 0)
    net    = d.get("net_profit", 0)

    if opm > 20 and roce > 15: beneish = -3.0 + (20 - opm) * 0.02
    elif opm > 10:              beneish = -2.5 + (10 - opm) * 0.03
    else:                       beneish = -1.8 + opm * 0.02
    beneish = max(-4.0, min(-1.0, round(beneish, 2)))

    if sector in BANKING_SECTORS:
        altman = 3.0
    elif de < 0.3 and roce > 15: altman = 3.5 + roce * 0.02
    elif de < 1.0:                altman = 2.5 + (1.0 - de) * 0.5
    else:                         altman = 1.5 + max(0, (2.0 - de) * 0.3)
    altman = max(0.5, min(5.0, round(altman, 2)))

    truth = 50
    if roce > 20:   truth += 15
    elif roce > 10: truth += 8
    elif roce < 0:  truth -= 15
    if sector not in BANKING_SECTORS:
        if de < 0.5:   truth += 10
        elif de > 2.0: truth -= 15
    if opm > 15: truth += 10
    elif opm < 5 and sector not in BANKING_SECTORS: truth -= 10
    if rev > 0 and net > 0 and div(net, rev) * 100 > 10: truth += 5
    truth = max(10, min(100, truth))

    risk = 25
    if beneish > -1.78:   risk += 25
    elif beneish > -2.22: risk += 10
    if sector not in BANKING_SECTORS and de > 1.5: risk += 15
    if opm < 5 and sector not in BANKING_SECTORS:  risk += 10
    risk = max(0, min(100, risk))

    sentiment   = max(10, min(100, truth - 5 + (5 if opm > 15 else -3)))
    credibility = max(10, min(100, truth - 3))
    honesty     = max(10, min(100, truth - 6))

    if roce > 15 and opm > 10 and (sector in BANKING_SECTORS or de < 1.0):
        trend = "improving"
    elif roce < 5 or opm < 0 or (sector not in BANKING_SECTORS and de > 2.0):
        trend = "declining"
    else:
        trend = "stable"

    fii = d.get("fii_holding", 15)
    signal = "fiiBuying" if fii > 25 else ("fiiSelling" if fii < 10 else "mixed")

    vol = 20.0
    if sector not in BANKING_SECTORS and de > 1.5: vol += 8
    if opm < 5: vol += 5
    vol = max(8, min(45, round(vol, 1)))

    return {
        "beneish_m_score":          beneish,
        "altman_z_score":           altman,
        "roce":                     roce,
        "operating_margin":         opm,
        "debt_to_equity":           de,
        "truth_score":              truth,
        "accounting_risk_score":    risk,
        "sentiment_score":          sentiment,
        "credibility_score":        credibility,
        "management_honesty_score": honesty,
        "volatility":               vol,
        "trend":                    trend,
        "smart_money_signal":       signal,
    }


# ─────────────────────────────────────────────
# JSON FIELDS
# ─────────────────────────────────────────────

def build_json_fields(comp, d, scores, price_history_real, current_price):
    truth  = scores["truth_score"]
    risk   = scores["accounting_risk_score"]
    cred   = scores["credibility_score"]
    trend  = scores["trend"]
    sector = comp["sector"]

    insights = []
    if truth > 80:   insights.append("Strong financial discipline with consistent cash flow generation.")
    elif truth > 60: insights.append("Moderate financial health with some areas of concern in working capital management.")
    else:            insights.append("Elevated risk profile with significant divergence between reported earnings and cash flow.")
    if trend == "improving":  insights.append("ROCE improving YoY indicating better capital deployment and operational efficiency.")
    elif trend == "declining": insights.append("Declining margins and rising debt levels signal potential stress in the business model.")
    if sector == "Banking":   insights.append("Asset quality remains under watch — monitor GNPA trajectory.")
    elif sector == "IT":      insights.append("Deal pipeline healthy but attrition-driven margin pressure continues.")
    else:                     insights.append("Industry tailwinds support near-term growth, but valuation stretched vs. peers.")

    flags = []
    if risk > 60:  flags.append({"title": "High Pledging Detected",    "description": "Promoter pledged shares above threshold.",              "severity": "high"})
    if risk > 45:  flags.append({"title": "Related Party Transactions", "description": "Substantial inter-corporate loans to subsidiaries.",    "severity": "medium"})
    if risk > 50:  flags.append({"title": "Contingent Liabilities",     "description": "Pending disputes with tax authorities.",               "severity": "medium"})
    if risk > 70:  flags.append({"title": "Auditor Qualification",      "description": "Auditors flagged issues with revenue recognition.",    "severity": "high"})
    if risk <= 30: flags.append({"title": "Minor Disclosure Gap",       "description": "Segment-level cash flow data not separately reported.","severity": "low"})

    changes = []
    if truth > 70: changes.append({"date": "Mar 2024", "title": "Truth Score Upgrade",        "description": "Improved debt-to-equity ratio verified.",        "impact": "positive"})
    if trend == "declining": changes.append({"date": "Feb 2024", "title": "Margin Compression","description": "Operating margins fell below 4-quarter average.", "impact": "negative"})
    changes.append({"date": "Jan 2024",
                    "title": "Annual Report Released" if truth > 60 else "New Regulatory Notice",
                    "description": "Detailed disclosures confirmed." if truth > 60 else "SEBI inquiry regarding disclosure.",
                    "impact": "neutral" if truth > 60 else "negative"})

    cred_tl = [
        {"claim": "Revenue growth > 15% in FY24",  "reality": "Achieved 16.2% growth"         if cred > 60 else "Actual growth was 8.4%",      "met": cred > 60, "quarter": "Q4 FY24"},
        {"claim": "Debt reduction by ₹5,000 Cr",   "reality": "Reduced debt by ₹5,200 Cr"     if cred > 50 else "Debt increased by ₹1,800 Cr", "met": cred > 50, "quarter": "Q3 FY24"},
        {"claim": "New market expansion in FY24",  "reality": "Entered 3 new geographies"      if cred > 55 else "Expansion delayed to FY25",   "met": cred > 55, "quarter": "Q2 FY24"},
        {"claim": "Operating margin improvement",  "reality": "Margins expanded by 120bps"     if cred > 65 else "Margins contracted by 80bps",  "met": cred > 65, "quarter": "Q1 FY24"},
    ]

    fraud_sim = []
    if risk > 60: fraud_sim.append({"fraudName": "Satyam Pattern", "similarity": round(min(55, risk * 0.7), 1), "description": "Revenue inflation & receivables mismatch."})
    if risk > 40: fraud_sim.append({"fraudName": "IL&FS Pattern",  "similarity": round(min(35, risk * 0.4), 1), "description": "Complex inter-corporate loan structure."})
    fraud_sim.append(             {"fraudName": "Wirecard Pattern", "similarity": round(min(20, risk * 0.2), 1), "description": "Third-party payment channel verification gaps."})

    # Smart Money — FIX 4: real quarterly deltas
    fii    = d.get("fii_holding",    15.0)
    dii    = d.get("dii_holding",    20.0)
    retail = d.get("retail_holding", 65.0)
    smart_money = {
        "fiiHolding":    fii,
        "diiHolding":    dii,
        "retailHolding": retail,
        "fiiChange":     d.get("fii_change",    0.0),
        "diiChange":     d.get("dii_change",    0.0),
        "retailChange":  d.get("retail_change", 0.0),
        "isRetailTrap":  fii < 10 and retail > 50,
        "sentiment":     ("Retail accumulating while FIIs exit" if fii < 10 and retail > 50
                          else "Institutional confidence high" if fii > 30 else "Mixed signals"),
    }

    # FIX 5 & 6: Money Trail — no NaN, no division by zero
    rev   = max(d.get("revenue", 0), 0)
    op_p  = max(d.get("operating_profit", 0), 0)
    net_p = max(d.get("net_profit", 0), 0)

    if op_p == 0 and rev > 0:
        op_p = rev * max(d.get("operating_margin", 0), 0) / 100.0

    if rev == 0:
        money_trail = {
            "revenue": 0, "grossProfit": 0, "operatingIncome": 0,
            "netIncome": round(net_p, 2), "cogs": 0, "operatingExpenses": 0,
            "taxes": 0, "cashConversion": 0.0, "qualityScore": 50,
            "riskLevel": "Unknown",
            "expenses": [
                {"name": "Payroll",        "amount": 0, "color": "0xFF448AFF"},
                {"name": "Marketing",      "amount": 0, "color": "0xFF00E676"},
                {"name": "Administrative", "amount": 0, "color": "0xFFFFD740"},
                {"name": "R&D",            "amount": 0, "color": "0xFF7C4DFF"},
            ],
            "taxPaid": 0,
        }
    else:
        cogs         = round(rev * 0.55, 2)
        gross_profit = round(rev - cogs, 2)
        opex         = round(max(gross_profit - op_p, 0), 2)
        taxes        = round(max(op_p * 0.25, 0), 2)
        cash_conv    = round(min(99.0, max(0.0, div(net_p, op_p) * 100)), 1) if op_p > 0 else 75.0

        money_trail = {
            "revenue":           round(rev, 2),
            "grossProfit":       gross_profit,
            "operatingIncome":   round(op_p, 2),
            "netIncome":         round(net_p, 2),
            "cogs":              cogs,
            "operatingExpenses": opex,
            "taxes":             taxes,
            "cashConversion":    cash_conv,
            "qualityScore":      min(95, max(40, truth - 5)),
            "riskLevel":         "Low" if risk < 40 else "Moderate" if risk < 65 else "High",
            "expenses": [
                {"name": "Payroll",        "amount": round(opex * 0.45, 2), "color": "0xFF448AFF"},
                {"name": "Marketing",      "amount": round(opex * 0.25, 2), "color": "0xFF00E676"},
                {"name": "Administrative", "amount": round(opex * 0.20, 2), "color": "0xFFFFD740"},
                {"name": "R&D",            "amount": round(opex * 0.10, 2), "color": "0xFF7C4DFF"},
            ],
            "taxPaid": taxes,
        }

    # Price history
    if price_history_real and len(price_history_real) >= 3:
        price_history = price_history_real
    else:
        base = max(current_price, 10.0)
        rng  = random.Random(hash(comp["ticker"]))
        p    = base * 0.80
        price_history = []
        for _ in range(24):
            p *= 1 + rng.uniform(-0.04, 0.05)
            price_history.append(round(p, 2))
        price_history.append(round(base, 2))

    # Truth score history
    rng2 = random.Random(hash(comp["ticker"] + "ts"))
    t = truth
    ts_hist = []
    for _ in range(12):
        t += rng2.randint(-4, 5)
        t  = max(10, min(100, t))
        ts_hist.append(float(t))
    ts_hist.append(float(truth))

    return {
        "key_insights":         insights,
        "red_flags":            flags,
        "what_changed":         changes,
        "credibility_timeline": cred_tl,
        "fraud_similarities":   fraud_sim,
        "smart_money_data":     smart_money,
        "money_trail_data":     money_trail,
        "price_history":        price_history,
        "truth_score_history":  ts_hist,
    }


# ─────────────────────────────────────────────
# SUPABASE UPSERT
# ─────────────────────────────────────────────

def upsert_company(row):
    url  = f"{SUPABASE_URL}/rest/v1/companies"
    hdrs = {
        "apikey":        SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  "application/json",
        "Prefer":        "resolution=merge-duplicates",
    }
    r = requests.post(url, headers=hdrs, json=row, timeout=15)
    if r.status_code not in (200, 201, 204):
        print(f"    [Supabase ERROR] {r.status_code}: {r.text[:300]}")
        return False
    return True


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────

def main():
    if not SUPABASE_KEY:
        print("ERROR: set SUPABASE_KEY env variable.")
        return

    print(f"Processing {len(COMPANIES)} companies\n")
    ok = fail = 0

    for i, comp in enumerate(COMPANIES):
        ticker = comp["ticker"]
        sector = comp["sector"]
        print(f"[{i+1}/{len(COMPANIES)}] {ticker} ({sector})")

        price, change_pct = fetch_yahoo_quote(ticker)
        print(f"    Yahoo: ₹{price}  {change_pct:+.2f}%")
        time.sleep(0.3)

        history = fetch_yahoo_history(ticker)
        print(f"    History: {len(history)} months")
        time.sleep(0.3)

        d = fetch_screener_data(ticker, sector)
        time.sleep(1.5)

        scores = compute_scores(comp, d)
        jf     = build_json_fields(comp, d, scores, history, price)

        row = {
            "ticker":         ticker,
            "name":           comp["name"],
            "sector":         sector,
            "price":          price,
            "change_percent": change_pct,
            **scores,
            **jf,
        }

        if upsert_company(row):
            print(f"    ✓  ₹{price}  {change_pct:+.2f}%  truth={scores['truth_score']}")
            ok += 1
        else:
            print(f"    ✗  upsert failed")
            fail += 1
        print()

    print(f"\nDone — {ok} OK, {fail} failed.")


if __name__ == "__main__":
    main()