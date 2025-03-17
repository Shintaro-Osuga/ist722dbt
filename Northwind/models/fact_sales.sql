with stg_orders as
(
    select 
        OrderId,
        {{ dbt_utils.generate_surrogate_key(["customerid"]) }} as customerkey,
        {{ dbt_utils.generate_surrogate_key(["employeeid"]) }} as employeekey,
        replace(to_date(orderdate)::varchar,'-','')::int as orderdatekey,
    from {{source("northwind","Orders")}}
),
stg_order_details as
(
    select
        orderid, 
        {{ dbt_utils.generate_surrogate_key(["productid"]) }} as productkey,
        sum(Quantity) as quantity,
        sum(Quantity*UnitPrice) as extendedpriceamount,
        sum(Quantity*UnitPrice*Discount) as discountamount,
        sum((Quantity*UnitPrice) - (Quantity*UnitPrice*Discount)) as soldamount
    from {{source("northwind","Order_Details")}}
    group by orderid, productid
)
select 
    o.*,
    od.productkey, od.quantity, od.extendedpriceamount,
    od.discountamount, od.soldamount
    from stg_orders o
        join stg_order_details od on o.orderid = od.orderid