\# NOVA Market — E-Commerce Analytics



\*\*PostgreSQL | SQL | Data Analytics\*\*



A portfolio project analyzing a simulated e-commerce business using PostgreSQL. The project focuses on turning transactional data into customer, product, revenue and operational insights.



\## 📊 Project Overview



The analysis covers:



\* Revenue and order performance

\* Customer spending and behavior

\* Product and category performance

\* Monthly revenue trends

\* Customer segmentation

\* Repeat and inactive customers

\* Payment methods and return rates

\* Customer Lifetime Value

\* Advanced SQL and window functions

\* Customer-level KPI development



\## 🗄️ Database



The analysis uses five relational tables:



```text

customers

products

orders

order\_items

payments

```



Key relationships:



```text

customers → orders → order\_items → products

&#x20;                   ↓

&#x20;                payments

```



\## 🔍 Key Analysis



The SQL project contains \*\*40 analytical questions\*\*, including:



\* Data-quality and referential-integrity checks

\* Total and monthly revenue

\* Average Order Value (AOV)

\* Top products and categories

\* Top customers

\* Customer spending and segmentation

\* Repeat-customer analysis

\* Revenue contribution by customer

\* Month-over-month revenue growth

\* Running revenue totals

\* Three-month moving average

\* Top 3 products within each category

\* Second-highest-spending customer by city

\* Customer Lifetime Value

\* High-volume / low-revenue products

\* Customer KPI analytical view



\## 🛠️ SQL Techniques



The project demonstrates:



\* `JOIN`

\* `GROUP BY` / `HAVING`

\* CTEs

\* Subqueries

\* Aggregate functions

\* `CASE`

\* `COUNT(DISTINCT)`

\* `RANK()`

\* `ROW\_NUMBER()`

\* `LAG()`

\* Window functions

\* Moving averages

\* Analytical views



\## 📈 Revenue Methodology



For sales analysis:



```text

Revenue = quantity × unit\_price

```



Revenue analysis generally uses \*\*Completed orders\*\*.



Payment analysis is handled separately because payment transactions and calculated order revenue represent different analytical concepts.



\## 🔎 Data Quality



Before performing business analysis, the project checks for:



\* Orders without order items

\* Invalid order/product references

\* Multiple payments for an order

\* Cancelled orders with payments

\* Order/payment amount discrepancies



This ensures that business conclusions are based on validated data.



\## ⚠️ Dataset



NOVA Market is a \*\*simulated e-commerce dataset\*\* created for portfolio and learning purposes.



Some definitions, such as customer segmentation, inactivity and CLV, are analytical assumptions documented in the SQL.



\## 📁 Repository



```text

nova-market-ecommerce-analytics/

│

├── SQL/

│   └── ecommerce\_analysis.sql

│

└── README.md

```



Additional Excel, Python and Power BI components may be added as the project develops.



\## 👤 Author



\*\*Snehasis Sarkar\*\*



M.Sc. Mathematical Physics | Aspiring Data Analyst



\*\*Current skills:\*\* PostgreSQL / SQL, with Excel, Power BI and Python being developed.



