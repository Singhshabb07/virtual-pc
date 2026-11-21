#!/usr/bin/env python3
"""
Codevern Cloud PC - Cost Modeling & Simulation Tool
Calculates hourly, weekly, and monthly costs against the ₹6,000 INR (~$70 USD) budget.
"""

import sys
import json
import argparse
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

DATA_FILE = Path(__file__).parent / "cost_breakdown.json"

def load_pricing():
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def calculate_monthly_cost(
    hours_per_day: float,
    days_per_month: int = 30,
    os_type: str = "windows",
    use_spot: bool = False,
    storage_gb: int = 500,
    stream_bitrate_mbps: float = 20.0
):
    pricing = load_pricing()
    total_hours = hours_per_day * days_per_month

    # 1. Compute Cost
    g4dn = pricing["ec2_pricing"]["g4dn.xlarge"]
    if os_type == "windows":
        hourly_rate = g4dn["windows_spot_hourly_approx"] if use_spot else g4dn["windows_on_demand_hourly"]
    else:
        hourly_rate = g4dn["linux_spot_hourly_approx"] if use_spot else g4dn["linux_on_demand_hourly"]
    
    compute_cost = total_hours * hourly_rate

    # 2. Storage Cost (gp3)
    gb_rate = pricing["ebs_gp3_pricing"]["storage_per_gb_month"]
    storage_cost = storage_gb * gb_rate

    # 3. Data Transfer Out
    # 20 Mbps = 2.5 MB/s = ~9 GB / hr
    gb_per_hour = (stream_bitrate_mbps * 3600) / (8 * 1024)
    total_dto_gb = total_hours * gb_per_hour
    billable_dto_gb = max(0.0, total_dto_gb - pricing["data_transfer_out"]["free_tier_gb"])
    dto_cost = billable_dto_gb * pricing["data_transfer_out"]["per_gb_after_free_tier"]

    # 4. Total and Budget Comparison
    total_usd = compute_cost + storage_cost + dto_cost
    inr_rate = pricing["inr_exchange_rate"]
    total_inr = total_usd * inr_rate
    budget_inr = pricing["monthly_budget_inr"]
    budget_usd = pricing["monthly_budget_usd"]

    # Max allowed hours under budget
    remaining_for_compute = budget_usd - storage_cost
    if remaining_for_compute > 0 and hourly_rate > 0:
        max_allowed_hours = remaining_for_compute / hourly_rate
    else:
        max_allowed_hours = 0.0

    return {
        "parameters": {
            "os_type": os_type,
            "purchasing_model": "Spot" if use_spot else "On-Demand",
            "storage_gb": storage_gb,
            "hours_per_day": hours_per_day,
            "days_per_month": days_per_month,
            "total_monthly_hours": total_hours,
            "hourly_rate_usd": hourly_rate
        },
        "breakdown_usd": {
            "compute": round(compute_cost, 2),
            "storage_ebs": round(storage_cost, 2),
            "data_transfer": round(dto_cost, 2),
            "total_usd": round(total_usd, 2)
        },
        "totals": {
            "total_inr": round(total_inr, 2),
            "budget_inr": budget_inr,
            "within_budget": total_inr <= budget_inr,
            "variance_inr": round(budget_inr - total_inr, 2),
            "max_hours_under_budget": round(max_allowed_hours, 1),
            "max_hours_per_day": round(max_allowed_hours / days_per_month, 2)
        }
    }

def print_simulation_report(result):
    p = result["parameters"]
    b = result["breakdown_usd"]
    t = result["totals"]

    print("=" * 65)
    print(f"  Codevern Cloud PC - Cost Simulation ({p['os_type'].capitalize()} | {p['purchasing_model']})")
    print("=" * 65)
    print(f" Storage Profile      : {p['storage_gb']} GB gp3 EBS")
    print(f" Active Workload      : {p['hours_per_day']} hrs/day x {p['days_per_month']} days = {p['total_monthly_hours']} hrs/month")
    print(f" Hourly Compute Rate  : ${p['hourly_rate_usd']:.3f} / hour")
    print("-" * 65)
    print(f" Compute Cost         : ${b['compute']:>7.2f} USD")
    print(f" Storage (gp3) Cost   : ${b['storage_ebs']:>7.2f} USD")
    print(f" Data Transfer Out    : ${b['data_transfer']:>7.2f} USD")
    print("-" * 65)
    status = "PASS (WITHIN BUDGET)" if t["within_budget"] else "FAIL (EXCEEDS BUDGET)"
    print(f" TOTAL ESTIMATED COST : ${b['total_usd']:>7.2f} USD  (~INR {t['total_inr']:>8.2f})")
    print(f" Monthly Hard Budget  : INR {t['budget_inr']:.2f} (~${t['budget_inr']/85.5:.2f} USD)")
    print(f" Budget Verdict       : {status}")
    print(f" Remaining Headroom   : INR {t['variance_inr']:+.2f}")
    print("-" * 65)
    print(f" Max Safe Monthly Run : {t['max_hours_under_budget']} hours (~{t['max_hours_per_day']} hrs/day)")
    print("=" * 65)

def main():
    parser = argparse.ArgumentParser(description="Codevern Cloud PC Cost Calculator")
    parser.add_argument("--hours", type=float, default=1.0, help="Active hours per day (default: 1.0)")
    parser.add_argument("--days", type=int, default=30, help="Days per month (default: 30)")
    parser.add_argument("--os", choices=["windows", "ubuntu"], default="windows", help="OS target")
    parser.add_argument("--spot", action="store_true", help="Use EC2 Spot instance pricing")
    parser.add_argument("--storage", type=int, default=500, help="EBS storage in GB (default: 500)")
    parser.add_argument("--bitrate", type=float, default=20.0, help="Streaming bitrate in Mbps (default: 20)")
    args = parser.parse_args()

    result = calculate_monthly_cost(
        hours_per_day=args.hours,
        days_per_month=args.days,
        os_type=args.os,
        use_spot=args.spot,
        storage_gb=args.storage,
        stream_bitrate_mbps=args.bitrate
    )
    print_simulation_report(result)

if __name__ == "__main__":
    main()
