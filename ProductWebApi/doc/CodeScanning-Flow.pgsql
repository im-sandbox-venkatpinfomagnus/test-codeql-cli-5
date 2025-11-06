     [ Developer pushes code / creates pull request ]
                        |
                        v
     ┌─────────────────────────────────────────────┐
     │   GitHub Actions triggers CodeQL workflow   │
     └─────────────────────────────────────────────┘
                        |
                        v
     ┌─────────────────────────────────────────────┐
     │   CodeQL builds DB from codebase (“code as │
     │   data”) and runs queries to detect issues │
     └─────────────────────────────────────────────┘
                        |
                        v
     ┌─────────────────────────────────────────────┐
     │   Scanning results generated → alerts in   │
     │   repository Security tab                 │
     └─────────────────────────────────────────────┘
                    |                    |
                    v                    v
     ┌─────────────────────┐       ┌─────────────────────┐
     │   Developer views   │       │   Developer fixes   │
     │   alerts and triages│   +   │   code and closes   │
     │   issues            │       │   alerts            │
     └─────────────────────┘       └─────────────────────┘
                     |                       |
                     v                       v
     [ Improved code security and reduced vulnerabilities ]