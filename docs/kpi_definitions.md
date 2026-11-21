# KPI Definitions and DAX Measures

Project: Olist E-Commerce Sales & Delivery Analysis
Source model: `star` schema in PostgreSQL (loaded into Power BI)

This file defines how every number on the dashboard is calculated, so the SQL, the DAX and the findings all use the same logic.

---

## 1. Data model (Power BI)

Grain of the fact table: **one row per order item**.

| From (many side) | To (one side) | Column | Direction |
|---|---|---|---|
| `fact_order_items` | `dim_date` | `purchase_date` → `date_key` | Single |
| `fact_order_items` | `dim_customers` | `customer_id` | Single |
| `fact_order_items` | `dim_products` | `product_id` | Single |
| `fact_order_items` | `dim_sellers` | `seller_id` | Single |

After loading:
1. Mark `dim_date` as the date table (Table tools → Mark as date table → `date_key`).
2. Hide the key columns in the fact table from Report view, so people use the dimensions to slice.
3. Create a separate table named `_Measures` to hold all measures (Home → Enter data → empty table), so they stay in one place.

---

## 2. Business rules

| Rule | Decision | Reason |
|---|---|---|
| Revenue | Sum of `price` from order items | Payments include freight, installment effects and vouchers, so they are not a clean sales figure |
| Freight | Reported separately, never inside Revenue | Freight is a shipping cost paid by the customer, not product revenue |
| Order counts | Always `DISTINCTCOUNT(order_id)` | The fact table has one row per item, so counting rows would count items, not orders |
| Late delivery | Delivered order where `delivered_ts` is later than `estimated_ts` | Uses the promised date shown to the customer |
| Delivery days | Only for orders with a valid delivery (delivered, with a timestamp not earlier than purchase) | Avoids negative or empty durations pulling the average |
| Review score | Latest review per order | Some orders have more than one review |
| Money | Never rounded in the data, only formatted in the visuals | Keeps totals exact |

---

## 3. Measures

Create these in the `_Measures` table.

### Sales

**Revenue**
```dax
Revenue = SUM ( fact_order_items[price] )
```
Total product sales. Format: Currency (R$), 2 decimals.

**Freight**
```dax
Freight = SUM ( fact_order_items[freight_value] )
```
Total shipping charged.

**Items Sold**
```dax
Items Sold = COUNTROWS ( fact_order_items )
```
Number of order items (not orders).

**Orders**
```dax
Orders = DISTINCTCOUNT ( fact_order_items[order_id] )
```
Number of distinct orders that contain at least one item.

**Average Order Value**
```dax
Average Order Value = DIVIDE ( [Revenue], [Orders] )
```
Revenue per order.

**Average Item Price**
```dax
Average Item Price = DIVIDE ( [Revenue], [Items Sold] )
```

**Freight % of Revenue**
```dax
Freight % of Revenue = DIVIDE ( [Freight], [Revenue] )
```
Shows how much shipping adds on top of the product price. Format: Percentage, 1 decimal.

### Growth

**Revenue Prior Month**
```dax
Revenue Prior Month =
CALCULATE ( [Revenue], DATEADD ( dim_date[date_key], -1, MONTH ) )
```

**Revenue MoM %**
```dax
Revenue MoM % =
DIVIDE ( [Revenue] - [Revenue Prior Month], [Revenue Prior Month] )
```
Month-over-month change. Use it on a monthly axis. It returns blank for the first month, which is expected.

### Customers

**Unique Customers**
```dax
Unique Customers =
DISTINCTCOUNT ( dim_customers[customer_unique_id] )
```
Counts real people, not `customer_id`, which is new for every order.

### Delivery

**Delivered Orders**
```dax
Delivered Orders =
CALCULATE (
    DISTINCTCOUNT ( fact_order_items[order_id] ),
    fact_order_items[order_status] = "delivered"
)
```

**Late Orders**
```dax
Late Orders =
CALCULATE (
    DISTINCTCOUNT ( fact_order_items[order_id] ),
    fact_order_items[order_status] = "delivered",
    fact_order_items[is_late] = TRUE ()
)
```

**Late Delivery %**
```dax
Late Delivery % = DIVIDE ( [Late Orders], [Delivered Orders] )
```
Format: Percentage, 1 decimal.

**Average Delivery Days**
```dax
Average Delivery Days =
AVERAGEX (
    VALUES ( fact_order_items[order_id] ),
    CALCULATE ( MAX ( fact_order_items[delivery_days] ) )
)
```
Averaged per order, so an order with 3 items is not counted 3 times. Blank delivery days are ignored automatically.

### Customer satisfaction

**Average Review Score**
```dax
Average Review Score =
AVERAGEX (
    VALUES ( fact_order_items[order_id] ),
    CALCULATE ( MAX ( fact_order_items[review_score] ) )
)
```
Averaged per order, for the same reason. Orders without a review are ignored. Format: Decimal, 2 places.

---

## 4. Validation: numbers the model must match

Check these in a Card or Table visual with no filters applied. If they differ, fix the model before building any visual.

| Measure | Expected value |
|---|---|
| Revenue | R$ 13,591,643.70 |
| Freight | R$ 2,251,909.54 |
| Items Sold | 112,650 |
| Orders | slightly under 99,441 (some orders have no items) |
| Late Orders | 7,827 |
| Late Delivery % | about 8.1% |
| Average Review Score | about 4.09 |

---

## 5. Dashboard page plan

| Page | Questions it answers | Key measures |
|---|---|---|
| 1. Executive Overview | How big is the business and how is it trending? | Revenue, Orders, AOV, Revenue MoM %, Unique Customers |
| 2. Product & Seller Performance | Which categories and sellers drive sales? Where is freight heavy? | Revenue, Items Sold, Average Item Price, Freight % of Revenue |
| 3. Customer & Delivery | Where are deliveries late and what does it do to reviews? | Late Delivery %, Average Delivery Days, Average Review Score |

Slicers on every page: Year, Month (from `dim_date`), Customer State.

---

## 6. Findings to look for

Fill these in with real numbers once the dashboard is built.

1. Late deliveries vs review score: compare Average Review Score for late and on-time orders. TODO
2. States with the highest Late Delivery %. TODO
3. Top product categories by Revenue and their share of the total. TODO
4. Freight % of Revenue by category (heavy or bulky products). TODO
5. Revenue trend over time and any seasonal peak. TODO
