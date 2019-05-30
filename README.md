# cope

### Description

COPE : Chain Of Physical Event

To manage a set of condition-result of numerical simulation corresponding to chains of physical events, filesystem and support libraries are developed. 

---

### file system

```
cope
├── config                              | configurations
├── lib                                 | APIs
│   ├── condition                       | for condition setup processing
│   │   └── sentaku                     |
│   ├── db                              | for logical database processing
│   ├── gis                             | for GIS processing
│   ├── init                            | for DEM as base layer processing
│   ├── prepost                         | for pre-post processing
│   └── proc                            | for event-chain simulation processing
└── universe                            | a space
    ├── OBS                             | observation space
    │   ├── record                      | containing record data
    │   └── analysis                    | containing analyzed data
    └── SIM                             | simulation space
        ├── field                       |
        │   └── merapi                  | location
        │       └── 2010                | time
        │           ├── case            | containing cases
        │           ├── chain           | containing event-chains simulation results
        │           ├── condition       | containing sub-field conditions
        │           └── tmp             |
        ├── measure                     | measures of field condition
        │   ├── LHR2D                   |
        │   └── PYR2D                   |
        └── phenomena                   | approximate time-space integration
            ├── LHR2D                   |
            │   ├── API                 | specific simulation APIs 
            │   │   ├── nakayasu        |
            │   │   └── setting         |
            │   ├── engine              | specific simulation program
            │   └── template            |
            └── PYR2D                   |
                ├── API                 |
                │   └── setting         |
                ├── engine              |
                └── template            |
```

---
