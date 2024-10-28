-- Used explicit joins and pushed up filtering of month seq inside the join
SELECT 
    i_product_name,
    i_brand,
    i_class,
    i_category,
    AVG(inv_quantity_on_hand) AS qoh
FROM 
    inventory
JOIN 
    date_dim ON inv_date_sk = d_date_sk AND d_month_seq BETWEEN 1201 AND 1212
JOIN 
    item ON inv_item_sk = i_item_sk
GROUP BY 
    ROLLUP(i_product_name, i_brand, i_class, i_category)
ORDER BY 
    qoh, i_product_name, i_brand, i_class, i_category
LIMIT 100;