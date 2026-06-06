# Annapurna

Canteen management system created for book-keeping purposes. App created for simple CRUD operations to create, track, fulfil food orders. Deployed in a stack of multiple docker containers to avoid dependency hell. I'm very dumb and stingy to pay and follow some course to learn all this so I'll be raw-dogging an entire application by reading docs, vibe-coding, correcting that vibe-coded slop and then blaming myself for not learning all this while in college. If you are interested in setting up this app for your own canteen, do message me. (and do please pay me, motorcycling is not a cheap hobby :') )


# Why is annapurna created?
Solving a real-world problem, in a small scale food canteen where every order created is maintained on a physical book; it's difficult to back-track and find deferred orders. This digital application will resolve the issue to  back-tracking and provided added bonus of daily scheduled EoD reports for KPIs

## Approach
Nothing much to say here, just refer the flow chart

```mermaid
flowchart TD

A[Take Order] --> B{Order Served?}
B -->|No| C[Send Reminder]
B -->|Yes| D[Acknowledge Order Served]
C --> D

D --> E{New Order Required?}
E -->|Yes| A
E -->|No| F{Payment?}

F -->|No| G[Add to Person Account and Send Reminder]
G --> F
F -->|Yes| H[Payment Received and Acknowledged]

H --> I[Close Order]
```

## Tech Stack

- **Front-End :** React TypeScript (not that good of a front-end dev so going for type safety)
- **Backend:** Java Springboot
- **Database:** PostgreSQL

## DB Schema

Creating custom DB schema based on the flowchart

```mermaid
erDiagram

    FOO_FOOD_MST {
        int Item_ID
        string Item_Code
        string Item_Desc 
        date Creation_Date
        boolean In_Use
    }

    FOO_COST_SHEET {
        int Item_ID
        float Cost
        boolean Is_Active
        date Creation_Date
        date Inactive_Date
    }

    OM_ORDER_HEADERS {
        int Header_ID
        int Order_Number
        int Customer_ID
        date Creation_Date
        date Ordered_When
        String Payment_Status
        float Order_Amount
        float Amount_Paid
        date Paid_On
        int Payment_ID
    }

    OM_ORDER_LINES {
        int Line_ID
        int Header_ID
        date Creation_Date
        int Item_ID
        int Quantity
        int Line_Cost
        boolean Is_served
    }

    CUST_PERSON_ACC {
        int Customer_ID
        string Customer_Number
        string Name
        string Phone
        date Creation_Date
        boolean Is_Active
    }

    CUST_ORDER_HIST {
        int Customer_ID
        int Payment_ID
        int Header_ID
        float Order_Amount
        float Total_Cost
        float Amount_Paid
        float Paid_On
    }

    CUST_PAYMENT_HIST {
        int Payment_ID
        date Creation_Date
        boolean Is_Paid
        date Payment_Date
        float Amount_Paid
        float Amount_Remaining
    }

    %% Relationships

    FOO_FOOD_MST ||--o{ FOO_COST_SHEET : "Header Line relationship model"
    OM_ORDER_LINES ||--o{ FOO_COST_SHEET : "Fetching Item info"

    OM_ORDER_HEADERS ||--o{ OM_ORDER_LINES : "seperate layer to store ordered items"
    OM_ORDER_HEADERS ||--o{ CUST_PAYMENT_HIST : "record payments"

    CUST_PERSON_ACC ||--o{ CUST_ORDER_HIST : "maintains history"
    CUST_ORDER_HIST ||--o{ CUST_PAYMENT_HIST : "tracks payment"

    OM_ORDER_HEADERS ||--o{ CUST_ORDER_HIST : "updates history if known customer"
```


## Wanna deploy it?

**Dependencies:** 
 - Arch Linux (btw 'cause I have a potato laptop and got to manual package installation for optimized performance but you do you and get your preferred linux distro)
 - Docker and docker compose (easily available on official arch repo)
 - Java 17 (not too old, not too cutting edge, suitable for LTS)
 - PostgreSQL 15 (got that in-built notification feature)
 - NodeJs and NPM
 - Portainer (optional, just a GUI for docker container, really helpful tho if you sshing in prod env)
 
**Steps**

```
$ https://github.com/bleak-alpha/annapurna.git
$ cd annapurna
$ docker-compose up
```

and all set (iykyk)
