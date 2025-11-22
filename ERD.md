---
config:
  layout: elk
---
erDiagram
  City ||--o{ Shelter : "has"
  City ||--o{ ResourceSite : "contains"

  PowerSource ||--o{ Shelter_Power : "powers"
  WaterSource ||--o{ Shelter_Water : "supplies"
  Shelter_Power }o--|| Shelter : "powers"
  Shelter_Water }o--|| Shelter : "supplies"

  Shelter ||--o{ Survivor : "houses"
  Shelter ||--o{ Inventory : "owns"

  Survivor ||--o{ DiseaseCase : "has case"
  Survivor ||--o{ SurvivorSkill : "has skill"

  Survivor }o--|| Status : "has status"

  Survivor ||--o{ Survivor_Encounter : "involved in"
  Survivor_Encounter }o--|| Encounter : "involves"
  Skill }o--|| SurvivorSkill : "used by"

  Inventory ||--o{ Item : "holds"

  Faction ||--o{ Faction_Encounter : "involved"
  Faction_Encounter }o--|| Encounter : "involves"
  Faction ||--o{ Faction_Relations : "Relates"
  Faction_Relations }o--|| Faction : "Relates"

  City {
    int city_id PK
    string city_name
    string state
  }

  PowerSource {
    int power_source_id PK
    string power_source_name
    string power_source_description
    bool is_active
    bool transportable
  }

  WaterSource {
    int water_source_id PK
    string water_source_name
    string water_source_description
    string water_quality
  }

  Shelter {
    int shelter_id PK
    int city_id FK
    string shelter_name
    int capacity
  }

  Survivor {
    int survivor_id PK
    int shelter_id FK
    string first_name
    string last_name
    date birth_date
    int status_id
  }

  Skill {
    int skill_id PK
    string skill_name
    string skill_description
  }

  SurvivorSkill {
    int survivor_id FK
    int skill_id FK
    int proficiency_level
  }

  DiseaseCase {
    int disease_case_id PK
    int survivor_id FK
    date diagnosis_date
    date cure_date
  }


  Item {
    int item_id PK
    string item_name
    string category
    bool is_currency
    decimal unit_value
  }

  ResourceSite {
    int resource_site_id PK
    int city_id FK
    string resource_type
    string resource_name
    string resource_description
    bool is_operational
  }

  Faction {
    int faction_id PK
    string faction_name
    string faction_type
    string faction_attitude
  }

  Encounter {
    int encounter_id PK
    date encounter_date
    string encounter_type
    string encounter_vibe
    string encounter_description
  }

  Faction_Relations {
    int faction_id_1 PK
    int faction_id_2 PK
    string related_attitude
  }

  Status {
    int status_id
    string status_name
  }


 Inventory {
    int item_id PK
    int shelter_id PK
    int quantity
  } 
  Shelter_Power {
    int shelter_id PK
    int power_source_id PK
  }
  Shelter_Water {
    int shelter_id PK
    int water_source_id PK
  }
  Survivor_Encounter {
    int encounter_id PK
    int survivor_id PK
  }
  Faction_Encounter {
    int encounter_id PK
    int faction_id PK
  }
