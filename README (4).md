# Customer Churn and Retention Analysis: Online Retail

**Live dashboard:** https://public.tableau.com/views/CustomerChurnandRetentionAnalysis-OnlineRetail/Dashboard1

## Business problem

An online gift retailer is losing repeat customers. Which customers have stopped buying, which segments are most valuable, and who should the business try to win back first?

## Data

Online Retail II (UCI / Kaggle): about 1.07 million transaction rows from a UK online retailer, December 2009 to December 2011. The raw file is not included in this repository because of its size. Download it from Kaggle (search "Online Retail II UCI") and place it in a `data/` folder to reproduce the analysis.

## Tools

Python (pandas, SQLAlchemy), MySQL, Tableau Public, Excel.

## Approach

1. **Cleaning (Python).** Removed 34,335 duplicate rows and 235,151 rows with no Customer ID, then split cancellations (invoices starting with "C") from sales and kept only rows with a positive quantity and price. Result: 779,425 clean sales rows from 5,878 customers.
2. **Database (MySQL).** Loaded the clean data and re-checked row counts and revenue totals against the Python results.
3. **Net revenue.** Cancellations equal about 6.2% of gross sales. Customer spend is measured net of returns. One customer with 168K in gross sales dropped out of the top 10 once a cancelled order was netted out.
4. **Defining churn (SQL).** Used window functions (LAG) to measure the gap between each customer's consecutive orders. 93.7% of gaps are 180 days or shorter, so a customer with no purchase in 180+ days is flagged as churned, measured as of 10 December 2011. This flags 2,401 customers (40.8%).
5. **RFM segmentation (Python).** Scored every customer 1 to 5 on recency, frequency and net revenue, then grouped them into six segments.
6. **Cohort retention (SQL).** Tracked what share of each first-purchase-month cohort kept buying in later months.
7. **Reporting.** Built a four-chart Tableau dashboard and an Excel summary with a win-back list.

## Key findings

- **Revenue is concentrated.** Champions are 22% of customers (1,290) but generate about 70% of net revenue (11.4M).
- **Churn starts with the first order.** 71.0% of one-time buyers never returned, compared with 45.1% of customers with 2 to 4 orders and 14.1% of customers with 5 or more.
- **Churned customers are low value.** The 2,401 churned customers hold about 12% of net revenue, averaging 836 each versus 4,126 for active customers.
- **A small high-value group is worth winning back.** 224 "At Risk - High Value" customers hold about 832K in lifetime net revenue and have all been silent for 180+ days.
- **Retention levels off instead of falling to zero.** In the January 2010 cohort, about 1 in 5 customers bought again the next month and the share staying active settled at roughly 20%.

## Recommendations

1. Run personal outreach to the top win-back customers, starting with those silent for the shortest time (the list is in `winback_top50.csv`).
2. Introduce a second-purchase offer for new customers, because nearly half of all churn comes from customers who never bought twice.
3. Protect the Champions segment with early-access and loyalty perks, since it carries most of the revenue.
4. Use low-cost automated emails for the large Lapsing segment, because each customer is worth much less.

## Limitations

- The link between order count and churn is an association, not proof that a second-purchase offer would work. It should be tested.
- Customers with a single order have no purchase gap, so the 180-day threshold describes repeat buyers only.
- The December 2009 cohort includes customers who had bought before the data begins, and December 2011 is a partial month. Both are noted in the dashboard.
- Currency is assumed to be GBP, since the retailer is UK-based.

## Repository contents

| File | Description |
|---|---|
| `churn_analysis.sql` | Customer summary, net revenue, churn flag, cohort retention |
| `customer_rfm.csv` | One row per customer with RFM scores and segment |
| `winback_top50.csv` | Top 50 churned customers by net revenue |
| `cohort_retention.csv` | Monthly cohort retention table |
| `churn_summary.xlsx` | Excel summary for managers |
| `dashboard.png` | Screenshot of the Tableau dashboard |

## Author

Hiba P A | [LinkedIn](https://www.linkedin.com/in/hibapa)
