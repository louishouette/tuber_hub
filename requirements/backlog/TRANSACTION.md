## Transaction
- has many line_items

## LineItem
- belongs to a Transaction
- references a Variant
- weight_in_grams
- number_of_truffles
- unit_price
- discount_in_cents
- discount_in_value
- final_price

## Product
- name ('Truffe', 'Beurre de Truffe', 'Huile de Truffe')
- certification_label ('Bio', 'En conversion 2ème année')
- freshness ('Fresh', 'Flash-frozen')
- species ('Tuber Mélanosporum', 'Tuber Borchii')
- description

## Variant
- product_id references Product
- sales_format ('Retail', 'Bulk')
- quality_category ('EXTRA', 'CAT I', 'CAT II', 'CAT III', 'Brisures')
- brand ('Truffière de Cément', 'Marque blanche')
- packaging ('Sous-vide avec emballage normé et traçabilité', 'En boite', '50 grammes', '100 grammes', '250 grammes', '25 centilitres')
- SKU