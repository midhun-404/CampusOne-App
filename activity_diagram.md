# CampusOne Smart Management System - Activity Diagram

This document contains the core Activity Diagram for the **Gatepass Application flow**. It emphasizes the flowchart sequence involving decisions (diamonds), parallel processes, actions, and terminations across the Gatepass lifecycle.

## 1. Mermaid Version (Preview)

Viewable in GitHub, Notion, or VS Code markdown previews. It shows the logical flow of actions.

```mermaid
flowchart TD
    %% Node Stylings
    classDef startEnd fill:#111,stroke:#333,stroke-width:2px,color:#fff,shape:circle
    classDef action fill:#FAFAFA,stroke:#333,stroke-width:2px,rx:10,ry:10
    classDef decision fill:#D4F1F4,stroke:#05445E,stroke-width:2px,shape:diamond
    classDef rejected fill:#FFEBEE,stroke:#C62828,stroke-width:2px,rx:10,ry:10
    classDef success fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,rx:10,ry:10
    
    %% Flow Start
    Start((Start)):::startEnd --> A[Student Submits Gatepass Request]:::action
    
    %% Mentor Check
    A --> B{Is Mentor<br>Assigned?}:::decision
    B -- Yes --> C[Mentor Reviews Request]:::action
    B -- No --> D[Route to HOD]:::action
    
    C --> E{Mentor<br>Approves?}:::decision
    E -- No --> F[Gatepass Rejected]:::rejected
    E -- Yes --> D

    %% HOD Check
    D --> G[HOD Reviews Request]:::action
    G --> H{HOD<br>Approves?}:::decision
    H -- No --> F
    H -- Yes --> I[Gatepass Approved & QR Generated]:::success
    
    %% Exit Process
    I --> J[Student Presents QR at Gate]:::action
    J --> K[Security Scans QR & Cloud Verifies]:::action
    
    K --> L{QR is<br>Valid?}:::decision
    L -- No --> M[Access Denied]:::rejected
    L -- Yes --> N[Mark Entry/Exit Status]:::success
    
    %% End States
    F --> End((End)):::startEnd
    M --> End
    N --> End
```

## 2. PlantUML Version (Strict UML Standardization)

If you are using this in formal architecture documentation, copy and run this code in [PlantText](https://www.planttext.com/) or the PlantUML CLI. It generates a perfectly strictly-compliant UML Activity Diagram (using black circles for start/stop, rounded boxes for actions, and diamonds for conditions).

```plantuml
@startuml
skinparam maxMessageSize 150
skinparam ActivityBackgroundColor #FAFAFA
skinparam ActivityBorderColor #05445E
skinparam ActivityDiamondBackgroundColor #D4F1F4
skinparam ActivityDiamondBorderColor #05445E
skinparam ArrowColor #05445E
skinparam defaultFontName Arial
skinparam DefaultFontSize 13

start

:Student Submits Gatepass Request;

if (Mentor Assigned?) then (Yes)
  :Mentor Reviews Pending Request;
  if (Mentor Approves?) then (Yes)
    ' Proceeds to HOD
  else (No)
    #FFEBEE:Gatepass Rejected;
    stop
  endif
else (No)
  ' Direct route to HOD
endif

:HOD Reviews Mentor-Approved Request;

if (HOD Approves?) then (Yes)
  #E8F5E9:Gatepass Approved & QR Generated;
  
  :Student Presents QR at Campus Gate;
  :Security Scans QR Code;
  
  if (Scan is Valid & Authentic?) then (Yes)
    #E8F5E9:Log Transaction Status as "Exited";
  else (No)
    #FFEBEE:Access Denied (Invalid QR);
    stop
  endif
else (No)
  #FFEBEE:Gatepass Rejected;
  stop
endif

stop
@enduml
```
