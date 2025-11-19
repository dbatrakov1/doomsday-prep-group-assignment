# Database II Group Project Doomsday
## Databases will survive the Apocalypse
Group has been assigned to create a database for a doomsday scenario.

##Tables discussion:

The database contains 13 tables and 5 junction tables.

FoodShelf represents a facility controlled by the military.
Homesteads from different cities can belong to different FoodShelves and receive supplies from them.

Inventory represents a warehouse. Multiple inventories used to separate food, chemicals, and other goods that require specific conditions such as humidity, UV protection, or temperature control.

There is no separate Category table for items because items can be filtered by the item_type attribute in the Item table.

A Survivor can belong to a Homestead, but does not have to.
If they do not belong to a Homestead, they can be assigned to the last city where they were seen.
A survivor can have more than one Position (Role).

A MedicalFacility can be controlled by one Homestead. It has different medical specialists.
(I am not sure if I really need the MedicalFacility_Position junction table.)

I am not sure about currencies — it could be food stamps, gold, ammunition, or canned food.

GasStation sells fuel produced by the micro homestead plant.
It sells low-quality fuel such as biofuel (vegetable oil, water-ethanol mix) or used motor oil.


