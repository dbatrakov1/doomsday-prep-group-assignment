erDiagram
    direction LR
    Regions {
        Char region_id PK
        Varchar region_name
    }
    Survivors {
        Char survivor_id PK
        Varchar survivor_name
        bool deceased
        bool infected
        date birthdate
    }
    Jobs {
        Char job_id PK
        Varchar job_name
        VarChar description
    }
    Skills{
        Char skill_id PK
        Varchar skill_name
    }
    Safehouses {
        Char safehouse_id PK
        Varchar safehouse_name
        int capacity
        bool infected
        char inventory_id FK
        char faction_id FK
    }
    Factions {
        Char faction_id PK
        Varchar faction_name
        varchar faction_type
        char currency_id FK
    }
    Inventory {
        Char inventory_id PK
        
    }
    Item_Category {
        Char item_category_id PK
        Varchar item_category_name
    }
    Currency {
        Char currency_id PK
        Varchar currency_name
    }
    Events {
        Char event_id PK
        Varchar event_name
        VarChar description
        date event_date
    }
    Items {
        char item_id PK
        VarChar item_name
        decimal weight
        varchar description
        Char category_id FK
    }
    Resources {
        char resource_id PK
        VarChar resource_name
        varchar resource_type
    }


    Region_Events {
        Char region_id PK
        Char event_id PK
    }
    Survivor_Events {
        Char survivor_id PK
        Char event_id PK
    }
    Faction_Events {
        Char faction_id PK
        Char event_id PK
    }
    Survivor_Skills {
        Char survivor_id
        Char skill_id
        int skill_level
    }
    Region_Currency {
        char region_id
        char currency_id
    }
    Inventory_Item {
        char inventory_id
        char item_id
        int quantity
        decimal value
    }
    Region_Resource {
        char region_id
        char resource_id
    }
    Item_Resource {
        char item_id
        char resource_id
    }
    Safehouse_Resource {
        char safehouse_id
        char resource_id
    }

    Events ||--|| Faction_Events : ""
    Events ||--|| Survivor_Events : ""
    Regions ||--|| Region_Events : ""
    Regions ||--|| Region_Resource : ""
    Region_Events ||--|| Events : ""
    Faction_Events ||--|| Factions : ""
    Survivor_Events ||--|| Survivors : ""
    Survivor_Skills ||--|| Survivors : ""
    Skills ||--|| Survivor_Skills : ""
    Safehouses ||--|| Survivors : ""
    Regions ||--|| Region_Currency : ""
    Region_Currency ||--|| Currency : ""
    Factions ||--|| Currency : ""
    Factions ||--|| Regions : ""
    Regions ||--|| Safehouses : ""
    Survivors ||--|| Jobs : ""
    Factions ||--|| Safehouses : ""
    Inventory ||--|| Inventory_Item : ""
    Safehouses ||--|| Inventory : ""   
    Inventory_Item ||--|| Items : ""
    Items ||--|| Item_Category : ""
    Region_Resource ||--|| Resources : ""
    Resources ||--|| Item_Resource : ""
    Item_Resource ||--|| Items : ""
    Resources ||--|| Safehouse_Resource : ""
    Safehouse_Resource ||--|| Safehouses : ""
    
