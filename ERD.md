erDiagram
    direction TB
    Regions {
        Char region_id PK
        Varchar region_name
    }
    Survivors {
        Char survivor_id PK
        Varchar survivor_name
    }
    Jobs {
        Char job_id PK
        Varchar job_name
    }
    Skills{
        Char skill_id PK
        Varchar skill_name
    }
    Safehouses {
        Char safehouse_id PK
        Varchar safehouse_name
    }
    Factions {
        Char faction_id PK
        Varchar faction_name
    }
    Inventory {
        Char inventory_id PK
        Varchar item_name
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
    }

    Events ||--|| Factions : ""
    Events ||--|| Safehouses : ""
    Regions ||--|| Events : ""
    Safehouses ||--|| Survivors : ""
    Factions ||--|| Safehouses : ""
    Regions ||--|| Currency : ""
    Factions ||--|| Regions : ""
    Regions ||--|| Safehouses : ""
    Survivors ||--|| Jobs : ""
    Survivors ||--|| Skills : ""
    Factions ||--|| Survivors : ""
    Inventory ||--|| Item_Category : ""
    Safehouses ||--|| Inventory : ""