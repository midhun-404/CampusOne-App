# CampusOne Smart Management System - Sequence Diagram

This document contains the core workflow sequence diagram for the **Gatepass Request, Approval, & Verification Process**. It follows the standard lifecycle of a gatepass flowing through the Student, App, Cloud Database, Mentor, HOD, and finally the Security Guard.

## 1. Mermaid Version (Preview)

This version tracks the timeline from top to bottom. It will render automatically in Markdown viewers that support Mermaid.js.

```mermaid
sequenceDiagram
    autonumber
    actor S as Student
    participant UI as Flutter App
    participant DB as Firestore DB
    actor M as Mentor
    actor H as HOD
    actor Sec as Security Guard

    Note over S,UI: Initiation Phase
    S->>UI: Select Details & Submit Request
    UI->>DB: Create Gatepass (Status: Pending)
    DB-->>UI: Confirm Save
    UI-->>S: Display "Pending Mentor Approval"

    Note over M,DB: Mentor Approval Phase
    M->>DB: Fetch Pending Requests
    DB-->>M: Return List of Requests
    M->>DB: Approve Gatepass (Update Status)
    DB-->>M: Success

    Note over H,DB: HOD Approval Phase
    H->>DB: Fetch Mentor-Approved Requests
    DB-->>H: Return List of Requests
    H->>DB: Final Approve (Update Status)
    
    Note over S,DB: Real-time Update
    DB-->>UI: Push Status: Approved + QR Code Stream
    UI-->>S: Display Approved Status & Generated QR

    Note over S,Sec: Physical Exit Phase
    S->>Sec: Present QR Code at Campus Gate
    Sec->>UI: Scan QR Code (Security Feed)
    UI->>DB: Verify Authenticity
    DB-->>UI: Return Valid Gatepass Details
    UI-->>Sec: Show "Valid Access" Profile
    Sec->>DB: Trigger Entry -> Update Status "Exited"
    DB-->>Sec: Confirm Activity Logged
```

## 2. PlantUML Version (Strict UML Layout)

If you are using this in a formal architecture documentation book, run the following code in any PlantUML editor to generate the strictly compliant architectural structure.

```plantuml
@startuml
skinparam maxMessageSize 150
skinparam ParticipantPadding 20
skinparam BoxPadding 10
skinparam defaultFontName Arial
skinparam sequence {
    ArrowColor #05445E
    LifeLineBorderColor #05445E
    LifeLineBackgroundColor #D4F1F4
    ParticipantBorderColor #05445E
    ParticipantBackgroundColor #E6E6FA
    ActorBorderColor #05445E
    ActorBackgroundColor #FAFAFA
}

actor "Student" as std
box "Frontend App" #F8F9FA
participant "Mobile UI" as ui
end box
box "Backend" #E3F2FD
participant "Cloud Firestore" as db
end box
actor "Mentor" as mnt
actor "HOD" as hod
actor "Security" as sec

== Initiation Phase ==
std -> ui : Input Reason, Dates & Submit
activate ui
ui -> db : Save Gatepass Document \n(Status: Pending)
activate db
db --> ui : Acknowledge Document ID
deactivate db
ui -> std : Display "Pending Mentor Approval"
deactivate ui

== Mentor Approval Phase ==
mnt -> db : Views Pending Requests
activate db
mnt -> db : Approve Request \n(Status -> Mentor Approved)
db --> db : Notify HOD (FCM)
deactivate db

== HOD Approval Phase ==
hod -> db : Views Mentor-Approved Requests
activate db
hod -> db : Finalize Request \n(Status -> Approved)
db --> db : Notify Student (FCM)
deactivate db

== Real-time Client Update ==
db --> ui : Listen Snapshot \n(Status: Approved)
activate ui
ui -> std : Display Approved Status \n& Render QR Code
deactivate ui

== Physical Exit Phase ==
std -> sec : Present Gatepass QR Code
activate sec
sec -> ui : Scan QR Code (Security End)
activate ui
ui -> db : Validate QR JWT/Hash
activate db
db --> ui : Return Validated Details \n& Student Photo
deactivate db
ui --> sec : Show Approved Profile
sec -> db : Log Exit \n(Status -> Exited)
activate db
db --> sec : Confirm Logged
deactivate db
deactivate ui
deactivate sec

@enduml
```
