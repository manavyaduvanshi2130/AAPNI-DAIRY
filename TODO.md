# TODO List for Milk Entry and Customer Registration Updates

## 1. Add Tab Navigation to Milk Entry Screen
- [x] Add FocusNodes for each TextFormField (customerId, quantity, fat, snf)
- [x] Wrap form in FocusTraversalGroup
- [x] Implement tab key handling to move focus between fields

## 2. Add Edit/Delete Options to Customer Registration Screen
- [x] Modify ListTile in customer list to include trailing Row with edit and delete icons
- [x] Implement edit functionality: Show dialog with TextField for new name, call updateCustomer
- [x] Implement delete functionality: Show confirmation dialog, call deleteCustomer, then reset IDs

## 3. Implement Customer ID Reset Logic
- [x] Add resetCustomerIds method in DatabaseHelper: Disable FK, recreate customers table with new sequential IDs, update milk_entries references, re-enable FK
- [x] Call resetCustomerIds after successful delete in CustomerRegistrationScreen

## 4. Testing and Verification
- [x] Test tab navigation in MilkEntryScreen
- [x] Test edit customer name
- [x] Test delete customer and verify ID reset
- [x] Verify milk_entries are updated correctly after ID reset
