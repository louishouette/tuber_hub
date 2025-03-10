The search field is not working properly for the labels in findings.
The pattern of a label qrcode attribute is domain-orchard-parcel-row-plant
domain : will always be FBH
orchard : will always be a 2 letters code
parcel : can be a 1 or 2 characters code (alphanumeric)
row : starts with a R followed by the rank of the row, a decimal number from 0 to 100
plant : starts with a p followed by the number of the plant, a decimal number from 0 to 100
I want to find any label which qrcode contains the submitted minimum 3 chars in the order they are submitted. There can be a undefined number of wildcare characters between any of the minimum 3 submitted characters.
Suggest changes to implement exactly that