हो — तपाईंले खोजिरहनुभएको कुरा साधारण Notepad clone होइन। यो वास्तवमा lightweight, cross-platform, research-grade “Next-Gen Notes OS” जस्तो हुनुपर्छ।
तपाईंको requirement लाई आधार मान्दा म यसको architecture यसरी बनाउँथेँ:
🚀 Proposed Product: MindSparQ Notes
Tagline: Capture. Think. Research. Create.
मुख्य लक्ष्य:
Notion को flexibility + Apple Notes को UX + Obsidian को knowledge graph + Word को editing power — तर RAM/CPU consumption धेरै कम।
सबै कुरा एकैपटक भारी बनाउने होइन। Core lightweight, advanced features modular/lazy-loaded।

1. पहिले Product Philosophy
यसलाई 5 वटा principle मा बाँधौँ:
Principle
Meaning
⚡ Fast
App instant-open, typing latency नगण्य
🪶 Lightweight
Low RAM/CPU, background processes न्यून
🎨 Premium UX
macOS/iOS-जस्तो clean, smooth interface
🧩 Modular
प्रयोग नगरेको feature ले resource नखाओस्
🔓 Open Source
transparent, extensible, self-hostable
सबैभन्दा महत्वपूर्ण:
Local-first + Cloud-optional
Internet नभए पनि:
Note create
Edit
Search
Image
PDF attachment
Tags
Folders
Formatting
Research notes
सबै चल्नुपर्छ।
Internet आएपछि मात्र:
Sync
AI
Collaboration
Cloud backup
Publishing
integrations

2. Recommended Technology Stack
यदि तपाईं Windows + Linux + macOS + Android + iOS सबै सोचिरहनुभएको छ भने:
Frontend
Flutter
किनभने तपाईंको existing ecosystem पनि Flutter हो।
Flutter UI
    ↓
Dart Application Layer
    ↓
Local Database
    ↓
Sync Engine
    ↓
Optional Cloud Backend
तर editor को लागि साधारण TextField प्रयोग गर्ने होइन।
Editor
एकदम महत्वपूर्ण architectural decision:
Block-based document model + Rich Text editor
उदाहरण:
Document
 ├── Paragraph
 ├── Heading
 ├── Quote
 ├── Checklist
 ├── Code
 ├── Image
 ├── Table
 ├── Divider
 ├── File
 └── Embed
यसले पछि mobile/web/desktop सबैमा एउटै document structure reuse गर्न सजिलो हुन्छ।

3. Editor लाई दुई Layer मा बनाउने
Layer A — Simple Editing
साधारण user ले खोल्दा:
+ New Note

Title

Start writing...
बस।
Toolbar देखाएर user लाई डराउने होइन।

Layer B — Smart Editing
Text select गरेपछि contextual toolbar:
Bold | Italic | Underline
Highlight
Color
Link
Heading
Align
List
Quote
Code
Comment
Image
अर्थात् progressive disclosure।
Beginner लाई simple।
Power user लाई powerful।

4. Rich Text Features
तपाईंले माग्नुभएको भन्दा अलि अगाडि जान्छु।
Basic
Bold
Italic
Underline
Strikethrough
Superscript
Subscript
Font size
Font family
Text color
Highlight
Clear formatting
Paragraph
H1–H6
Alignment
Indentation
Line spacing
Paragraph spacing
Block quote
Callout
Divider
Lists
Bullet
Numbered
Nested list
Checklist
Task list
Custom bullets
Advanced
Tables
Code block
Inline code
LaTeX / Math
Footnotes
Citations
Comments
Mentions
Links
Anchors
Bookmarks

5. 🖼️ Image Editing — यो तपाईंको app को ठूलो differentiator हुन सक्छ
Image insert गरेपछि:
          ┌─────────────┐
           │    IMAGE    │
           └─────────────┘

Align:
[Left] [Center] [Right]

Wrap:
[Square] [Tight] [Through] [None]

Size:
25% ─────●────── 100%

Caption:
"Figure 1: Research Model"

Border
Radius
Crop
Rotate
Flip
Opacity
तर तपाईंले भनेको image को side मा text लेख्ने feature अझ महत्वपूर्ण छ।
Example
┌──────────────┐   This is the research
│              │   explanation related
│    IMAGE     │   to this figure.
│              │   Students can explain
└──────────────┘   the diagram here.
यसलाई text wrapping / floating objects architecture बाट implement गर्ने।
Image editing
Basic built-in editor:
Crop
Resize
Rotate
Flip
Brightness
Contrast
Saturation
Blur
Sharpen
Annotation
Arrow
Rectangle
Circle
Text
Highlight
Blur sensitive area
तर Photoshop बनाउने होइन।
Research/document-oriented lightweight image editor बनाउने।

6. 📚 Research Mode
यो feature चाहिँ तपाईंको app लाई सामान्य Notes app भन्दा धेरै माथि लैजान सक्छ।
एक click:
Convert Note → Research Workspace
त्यसपछि:
Research Project
│
├── Research Question
├── Literature Review
├── Methodology
├── Data
├── Findings
├── Discussion
├── References
└── Appendix
प्रत्येक note लाई:
Source
Author
Year
DOI
URL
Citation
Tags
सँग link गर्न मिल्ने।

7. Citation Manager
Student/researcher का लागि:
Insert Citation

[ Sharma, 2025 ]

Style:
APA 7
MLA
Chicago
Harvard
IEEE
Vancouver
अनि अन्त्यमा:
Generate References
यो research-oriented killer feature हुन्छ।

8. PDF Research System
PDF खोल्दा:
PDF Viewer
───────────────
Page 24

Highlight
Underline
Comment
Bookmark
Add Note
अनि:
“Create note from highlight”
भनेपछि:
PDF
 ↓
Highlight
 ↓
Research Note
 ↓
Citation
 ↓
Reference
Automatic relationship बनाउने।

9. Web Research Capture
Future feature:
Browser extension:
Save to MindSparQ
वेबबाट:
Article
Screenshot
Selected text
URL
Title
Author
Date
capture गर्न मिल्ने।
उदाहरण:
Research → Sources

BBC Article
↓
Selected paragraph
↓
My interpretation
↓
Citation

10. Knowledge Graph
Obsidian-style graph चाहिन्छ तर default UI मा थोपर्ने होइन।
उदाहरण:
Marketing
   │
   ├── CRM
   │    ├── Customer Loyalty
   │    └── Retention
   │
   └── Digital Marketing
        └── Social Media
Note मा:
Related Notes
• CRM
• Customer Loyalty
• Consumer Behaviour
Graph view optional।

11. 🧠 AI — तर AI लाई Core मा नघुसाउने
यो अत्यन्त महत्वपूर्ण छ।
AI लाई app को foundation बनाएर:
"हरेक ठाउँमा AI"
गर्नु हुँदैन।
बरु:
Core Notes
     ↓
AI Service Layer
     ↓
Gemini / Local Model / Other Provider
AI optional module।
AI commands
Select text:
✨ Improve
✨ Summarize
✨ Explain
✨ Translate
✨ Generate Questions
✨ Create Flashcards
✨ Extract Key Points
✨ Find Contradictions
✨ Generate Citation

12. Local AI
Future मा:
MindSparQ Notes
      ↓
Local AI
      ↓
No Internet required
Research documents लाई local model ले analyse गर्न सक्ने।
त्यसपछि cloud AI optional:
Local AI
Gemini
OpenAI
Other provider
Provider abstraction राख्ने।
यसले तपाईंलाई future vendor lock-in बाट बचाउँछ।

13. 🎨 UX/UI — Apple-inspired तर Apple copy होइन
तपाईंले चाहेको aesthetic:
Window
┌──────────────────────────────────────────────┐
│ ● ● ●       Search              + New Note  │
├────────────┬─────────────────────────────────┤
│            │                                 │
│ Notes      │        My Research Notes       │
│            │                                 │
│ Folders    │        Introduction             │
│ Tags       │                                 │
│ Favorites  │        Start writing...        │
│ Recent     │                                 │
│            │                                 │
└────────────┴─────────────────────────────────┘
Sidebar
Inbox
Notes
Folders
Favorites
Recent
Shared
Research
Archive
Trash

14. Theme System
सिर्फ Dark/Light होइन।
Built-in
Light
Dark
System
Future custom themes
Theme Engine
 ├── Typography
 ├── Background
 ├── Surface
 ├── Accent
 ├── Editor
 └── Code
तर default theme clean neutral।
रंगको आतङ्क होइन। 😄

15. Typography
Premium feel को ठूलो भाग typography हो।
Use:
System font
Inter
Noto Sans
Noto Sans Devanagari
Nepali + English mixed documents राम्रो देखिनुपर्छ।
उदाहरण:
Research Methodology
अनुसन्धान विधि भनेको...
Line height, paragraph spacing, heading hierarchy excellent हुनुपर्छ।

16. 🇳🇵 Nepali-first capability
तपाईंको use case मा यो विशेष advantage हुन सक्छ।
Support:
नेपाली Unicode
English + Nepali mixed typing
Nepali search
English search
Transliteration
Spell checking
Nepali formatting
PDF export
Nepali citations
Future:
Roman Nepali → नेपाली
जस्तै:
ma aaja research gardai chu

↓
म आज अनुसन्धान गर्दै छु।

17. Guest Mode
तपाईंले भनेको feature:
Open App
Welcome

[ Continue as Guest ]

[ Sign In ]

[ Create Account ]
Guest mode मा:
Notes
Editing
Images
Search
Export
चल्छ।
तर:
Cloud Sync
Cross-device sync
Collaboration
का लागि login।
यसले friction घटाउँछ।

18. Login Architecture
Login system लाई editor बाट अलग राख्नु।
Authentication
│
├── Guest
├── Email
├── Google
└── Future providers
Backend:
Supabase
तर document editing Supabase मा निर्भर हुँदैन।

19. Local Database
यसलाई अत्यन्त carefully design गर्नुपर्छ।
SQLite
   ↓
Local Repository
   ↓
Document Engine
प्रत्येक edit मा cloud API call गर्ने गल्ती नगर्नु।
पहिले:
User types
 ↓
Local memory
 ↓
Local DB
पछि background sync:
Local DB
 ↓
Sync Queue
 ↓
Cloud
यसले typing smooth बनाउँछ।

20. 🔄 Sync Engine
Future multi-device का लागि अहिलेबाट architecture तयार।
Windows
     ↘
      Sync Engine
     ↗
Android

      ↓

Supabase
Conflict हुँदा:
Conflict detected

Your version
Cloud version

[Keep Mine]
[Keep Cloud]
[Merge]
Advanced version मा CRDT/operation-based synchronization प्रयोग गर्न सकिन्छ।

21. Version History
प्रत्येक important document:
Version History

10:42 AM
10:18 AM
Yesterday
Sep 28
Sep 20
Restore:
Restore this version
Research/assignment मा यो अत्यन्त useful हुन्छ।

22. Autosave
User ले Ctrl + S थिच्नुपर्ने होइन।
Typing...
    ↓
Autosave locally
    ↓
✓ Saved
Status:
Saved locally
Internet हुँदा:
Synced

23. Command Palette
Power users का लागि:
Ctrl + K
Search commands...

Create Note
Insert Image
Insert Table
Toggle Dark Mode
Export PDF
Open Research
Insert Citation
Find
Replace
यो productivity का लागि fantastic हुन्छ।

24. Keyboard-first Design
Desktop users का लागि:
Ctrl + N       New Note
Ctrl + P       Command Palette
Ctrl + F       Search
Ctrl + Shift + F Global Search
Ctrl + S       Save
Ctrl + Z       Undo
Ctrl + Shift + Z Redo
Ctrl + B       Bold
Ctrl + I       Italic
Ctrl + K       Link
Mac मा automatically:
Cmd + ...

25. Search Engine
साधारण filename search पर्याप्त छैन।
Search:
Search everything...

"customer satisfaction"
ले खोज्ने:
Note title
Note content
Tags
Image captions
PDFs
Metadata
References
Future:
semantic search
"customer loyalty को कारण"
भनेर concept-based notes भेटाउने।

26. Tags + Smart Folders
Example:
#MBA
#Research
#Marketing
#CRM
#Nepal
Smart Folder:
Research
WHERE tag = Research
AND modified < 30 days

27. Templates
Student:
📄 Assignment
📄 Research Proposal
📄 Thesis
📄 Literature Review
📄 Class Notes
📄 Meeting Notes
Business:
📄 Meeting
📄 Business Plan
📄 SOP
📄 Project
📄 Strategy

28. Flashcard / Study Mode
Research note बाट:
Generate Flashcards
Output:
Q: What is CRM?

A: Customer Relationship Management...
पछि:
Study Mode
Spaced repetition समेत थप्न सकिन्छ।
यसले note → learning system बनाउँछ।

29. Mind Map
Note बाट:
Generate Mind Map
          CRM
          /   \
    Customer   Data
       /         \
 Loyalty       Analytics
Optional module।

30. Export System
एकदम राम्रो export engine चाहिन्छ।
Export

PDF
DOCX
Markdown
HTML
TXT
JSON
EPUB
Research को लागि:
APA PDF
Academic DOCX
Markdown

31. Import
Existing ecosystem बाट migrate गर्न:
Import

TXT
Markdown
DOCX
PDF
HTML
CSV
JSON
Future:
Evernote
Notion
OneNote
Obsidian
importers।

32. Open-source Architecture
Repository यसरी:
mindsparq-notes/
│
├── apps/
│   ├── desktop/
│   ├── mobile/
│   └── web/
│
├── packages/
│   ├── editor/
│   ├── document_engine/
│   ├── database/
│   ├── sync/
│   ├── search/
│   ├── auth/
│   ├── ai/
│   ├── image_editor/
│   ├── pdf/
│   └── export/
│
├── docs/
│
├── tests/
│
└── plugins/
यो future-proof हुन्छ।

33. Plugin Architecture
यो चाहिँ सुरुबाट सोच्नुहोस्।
Core:
Notes
Editor
Database
Search
Plugins:
AI
Calendar
Google Drive
Notion
GitHub
WhatsApp
CRM
Research
Citation
Mind Map
यसरी plugin ले core app भारी बनाउँदैन।

34. Performance Architecture
तपाईंको 12 GB RAM laptop जस्तो hardware मा पनि smooth चलाउनुपर्छ भने:
Avoid
❌ unnecessary Electron-style overhead
❌ background AI process
❌ constant network calls
❌ giant in-memory document trees
❌ loading every PDF/image at startup
❌ unnecessary animations
Use
✅ lazy loading
✅ virtualization
✅ image thumbnails
✅ SQLite indexing
✅ background workers
✅ debounced search
✅ incremental autosave
✅ GPU-appropriate rendering
✅ caching
✅ pagination

35. Startup Target
Engineering targets नै बनाऔँ:
Metric
Target
Cold startup
< 1 sec*
Empty idle RAM
~100–200 MB target
Typing latency
<16 ms target
Search
<100 ms for local index target
Autosave
<100 ms perceived
UI animation
60 FPS target
Offline operation
100% core
*Hardware/document size अनुसार वास्तविक performance फरक पर्छ।

36. Security
Guest भए पनि local notes सुरक्षित हुनुपर्छ।
Security layers
App
 ↓
Local encrypted database
 ↓
OS keychain
 ↓
Optional cloud encryption
Never:
API key inside Flutter source
AI keys:
Secure backend
वा user-provided key encrypted storage।

37. Backup
User लाई:
Automatic Local Backup
दिनुहोस्।
Backups
├── Today
├── Yesterday
├── Last Week
└── Custom
Optional:
Google Drive
OneDrive
Dropbox
S3-compatible storage

38. Collaboration — Future
पछि:
Share Note

Can View
Can Comment
Can Edit
Owner
Realtime collaboration पछि।
यो Phase 1 मा हाल्नुपर्दैन।

39. Mobile UX
Desktop UI लाई mobile मा जबरजस्ती squeeze नगर्नु।
Desktop:
Sidebar | Editor | Inspector
Mobile:
Notes
  ↓
Editor
  ↓
Bottom contextual toolbar
Same document engine।
Different UI layer।

40. Tablet
iPad/Android tablet:
Sidebar | Editor
Keyboard + touch + stylus support future मा।

41. Web
Browser version पनि पछि:
notes.mindsparq...
तर core architecture:
Document Format
       ↓
Universal
       ↓
Desktop
Mobile
Web
यसैले एउटा device मा बनाएको document अर्कोमा बिग्रिँदैन।

42. File Format — अत्यन्त महत्वपूर्ण
म proprietary binary format मात्र प्रयोग गर्दिनँ।
Better:
Document
   ↓
JSON / structured document model
Attachment:
assets/
 ├── image-001.webp
 ├── pdf-001.pdf
 └── audio-001.m4a
यसले:
portability
backup
migration
open-source ecosystem
future integrations
सजिलो बनाउँछ।

43. “Autonomous” भन्नाले के?
तपाईंले autonomous भन्नुभएको कुरा म यसरी design गर्छु:
Smart background system
User stops typing
        ↓
Autosave
        ↓
Index
        ↓
Sync
        ↓
Backup
AI enabled भए:
Document changed
       ↓
AI detects optional action
       ↓
Suggest:
"Add this to Research Sources?"
तर AI ले आफैं user को data modify गर्ने होइन।
User approval चाहिन्छ।

44. Smart Note Assistant
Future मा प्रत्येक note मा:
✨ Assistant
Click गर्दा:
Summarize
Explain
Organize
Find related notes
Generate outline
Generate questions
Generate flashcards
Check references

45. Research Copilot
यो तपाईंको strongest future feature हुन सक्छ।
Research Workspace
       ↓
Papers
       ↓
Highlights
       ↓
Notes
       ↓
Citations
       ↓
AI Analysis
       ↓
Literature Matrix
Literature matrix:
Author
Year
Topic
Method
Finding
Gap
MBA thesis गर्ने विद्यार्थीलाई निकै उपयोगी।

46. Nepal-specific Opportunity
यदि तपाईंले यो genuinely open-source बनाउनु भयो भने:
Nepal Education Mode
Class Notes
Assignment
Research
Thesis
Exam Preparation
Nepali + English।
Universities/colleges ले self-host गर्न सक्ने।
School ले आफ्नै server/cloud मा deploy गर्न सक्ने।
त्यो बेला यो सिर्फ personal notes app होइन — education knowledge platform बन्छ।

47. Development Roadmap
सबै कुरा एकैपटक बनाउने गल्ती नगर्नु।
🟢 Phase 1 — Core
पहिलो version:
Desktop
Light/Dark
Guest
Local notes
Folders
Tags
Rich text
Images
Tables
Search
Autosave
Export PDF/Markdown
Keyboard shortcuts

🟡 Phase 2 — Premium Editor
Image wrapping
Image editing
Callouts
Code blocks
Math
Templates
Command palette
Version history
Advanced search
Drag/drop
Split view

🟠 Phase 3 — Research
PDF annotation
Citation manager
References
Research workspace
Literature matrix
Web clipper
Academic templates

🔵 Phase 4 — Cloud
Supabase
Google login
JWT
Sync
Backup
Multi-device
Sharing

🟣 Phase 5 — AI
Gemini
Local AI
RAG
Summarization
Research assistant
Flashcards
Mind maps
Semantic search

🔴 Phase 6 — Ecosystem
Android
iOS
Web
Plugins
API
MCP
Integrations
Collaboration

48. अन्तिम Architecture
म अन्ततः यसलाई यस्तो बनाउँथेँ:
                   ┌───────────────────┐
                    │   MindSparQ Notes │
                    └─────────┬─────────┘
                              │
             ┌────────────────┼────────────────┐
             │                │                │
          Editor           Research           AI
             │                │                │
       Rich Text         PDF/Citation      Gemini/Local
             │                │                │
             └────────────────┼────────────────┘
                              │
                       Document Engine
                              │
                 ┌────────────┴────────────┐
                 │                         │
            Local Storage              Search
                 │                         │
              SQLite                  Index
                 │
             Sync Engine
                 │
             Supabase
                 │
       ┌─────────┼──────────┐
       │         │          │
    Windows    Android    iOS/Web

49. मेरो विचारमा सबैभन्दा महत्वपूर्ण 10 differentiators
यदि तपाईंले “यो app किन प्रयोग गर्ने?” भन्ने प्रश्नको उत्तर खोज्नुभयो भने:
⚡ Extremely fast
🪶 Lightweight
🍎 Premium Apple-like UX
📝 Powerful rich-text editor
🖼️ Advanced image + text wrapping
📚 Research-first workflow
🔗 Citation + PDF system
🧠 Optional AI + local AI
🔄 Offline-first + seamless sync
🔓 Open-source + plugin architecture

एउटा महत्वपूर्ण strategic निर्णय
म यसको पहिलो release मा Notion clone बनाउँदिनँ।
Notion ले जे गर्छ सबै copy गर्दा application फेरि भारी हुन्छ।
बरु यसको identity:
“The fastest serious note-taking and research workspace.”
हुन्छ।
अर्थात्:
Apple Notes जस्तो खोल्न सजिलो → Word जस्तो लेख्न शक्तिशाली → Obsidian जस्तो knowledge जोड्न सक्ने → Research tool जस्तो स्रोत व्यवस्थापन गर्न सक्ने → AI चाहिँ optional.
यही architecture राख्दा तपाईंले आज Windows desktop app बाट सुरु गरेर पछि Linux → macOS → Android → iOS → Web मा एउटै document engine र sync ecosystem विस्तार गर्न सक्नुहुन्छ।
----------------------------------------------------------------------------------------------------------------------------------------
# MindSparQ Notes

## Master Implementation Specification

### Lightweight • Fast • Local-First • Research-Ready • Cross-Platform • Open Source

---

# 01. PROJECT MISSION

Build a production-quality, open-source, lightweight note-taking and research application called:

**MindSparQ Notes**

The application must combine:

* Apple-inspired clean UX
* Microsoft Notepad simplicity
* Modern rich-text editing
* Research-grade organization
* Local-first architecture
* Optional cloud synchronization
* Optional AI
* Cross-platform architecture
* Extensible plugin architecture

The application must NOT become a bloated Notion clone.

Primary philosophy:

> **Simple to start. Powerful when needed. Fast everywhere. Local-first by default.**

---

# 02. NON-NEGOTIABLE RULES

Antigravity MUST follow these rules throughout development.

## 2.1 No fake implementation

Never create:

* mock buttons pretending to work
* placeholder screens presented as completed features
* simulated API responses
* fake authentication
* fake synchronization
* fake AI
* dead navigation
* TODO-only implementations for core functionality

If a feature cannot be fully implemented yet:

1. document the limitation,
2. isolate it behind a proper interface,
3. do not present it as functional.

---

## 2.2 No unnecessary dependencies

Before adding a dependency:

1. determine whether Flutter/Dart/platform APIs can solve the problem,
2. check maintenance status,
3. check license,
4. check platform compatibility,
5. check performance impact.

Prefer fewer high-quality dependencies.

---

## 2.3 Performance is a core feature

The application must remain responsive on modest hardware.

Target environment includes machines with approximately:

* Intel Core i3-class CPU
* 8–12 GB RAM
* integrated graphics

Avoid architecture that unnecessarily consumes CPU/RAM.

Never continuously run:

* AI models
* network polling
* expensive database queries
* full-document re-rendering
* unnecessary animations

---

# 03. TARGET PLATFORMS

Primary:

1. Windows
2. Linux

Architecture-ready:

3. macOS
4. Android
5. iOS
6. Web

Do NOT create completely separate business logic for every platform.

Use shared application/domain/data layers.

Only presentation/platform integrations should differ where necessary.

---

# 04. RECOMMENDED TECHNOLOGY

Primary framework:

**Flutter + Dart**

Architecture:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Data
    ↓
Infrastructure
```

Local storage:

**SQLite**

Use a clean repository abstraction.

Cloud backend:

**Supabase**

Authentication:

* Guest
* Email/password
* Google OAuth

Authentication must be isolated from note editing.

---

# 05. PROJECT ARCHITECTURE

Create the project with a scalable structure similar to:

```text
mindsparq_notes/
│
├── lib/
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   ├── theme/
│   │   └── localization/
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── logging/
│   │   ├── performance/
│   │   ├── security/
│   │   └── utils/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── services/
│   │
│   ├── data/
│   │   ├── database/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── migrations/
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   ├── notes/
│   │   ├── editor/
│   │   ├── folders/
│   │   ├── tags/
│   │   ├── search/
│   │   ├── attachments/
│   │   ├── research/
│   │   ├── pdf/
│   │   ├── citations/
│   │   ├── settings/
│   │   ├── auth/
│   │   ├── sync/
│   │   ├── ai/
│   │   └── export/
│   │
│   └── main.dart
│
├── test/
├── integration_test/
├── docs/
├── assets/
├── scripts/
└── README.md
```

Keep feature modules isolated.

---

# 06. DOCUMENT MODEL

Do NOT store the entire document as an unstructured HTML string.

Create a structured document model.

Conceptually:

```text
Document
 ├── metadata
 ├── blocks[]
 └── attachments[]
```

Supported block types:

```text
paragraph
heading
quote
callout
bullet_list
numbered_list
checklist
code
table
image
file
divider
math
embed
```

Every block should have a stable ID.

Example conceptual structure:

```text
Document
 ├── id
 ├── title
 ├── createdAt
 ├── updatedAt
 ├── folderId
 ├── tags[]
 ├── blocks[]
 └── metadata
```

The document format must be portable.

It should eventually support:

* JSON
* Markdown
* HTML
* DOCX
* PDF

without losing important information wherever technically possible.

---

# 07. DATABASE

Use SQLite for local-first storage.

Minimum entities:

```text
notes
folders
tags
note_tags
attachments
documents
document_blocks
settings
recent_items
search_index
sync_queue
versions
research_sources
citations
```

Do not over-normalize unnecessarily.

Database queries must be indexed appropriately.

---

# 08. LOCAL-FIRST PRINCIPLE

All core operations must work without Internet.

The following MUST work offline:

* create note
* edit note
* delete note
* rename note
* move note
* folders
* tags
* search
* formatting
* images
* attachments
* autosave
* version history
* export

Cloud features are optional.

Never make note typing dependent on network latency.

---

# 09. AUTOSAVE

Implement intelligent autosave.

Flow:

```text
User types
    ↓
Editor state changes
    ↓
Debounce
    ↓
Persist locally
    ↓
Update search index
```

Do not write to disk for every keystroke.

Use a small debounce interval and immediate save on:

* focus loss
* document close
* application exit
* explicit save

Display:

```text
Saved locally
```

and, when cloud sync exists:

```text
Synced
```

---

# 10. APPLICATION SHELL

Desktop layout:

```text
┌─────────────────────────────────────────────────────────┐
│ Window controls       Search              + New Note    │
├───────────────┬─────────────────────────┬───────────────┤
│ Sidebar       │ Editor                  │ Inspector     │
│               │                         │               │
│ Inbox         │ Title                   │ Properties    │
│ Notes         │                         │ Tags          │
│ Favorites     │ Content                 │ Attachments   │
│ Folders       │                         │ Backlinks     │
│ Research      │                         │               │
│ Recent        │                         │               │
│ Archive       │                         │               │
└───────────────┴─────────────────────────┴───────────────┘
```

Inspector should be collapsible.

On smaller screens:

```text
Sidebar → hidden/collapsible
Inspector → hidden/collapsible
Editor → primary
```

---

# 11. UX DESIGN SYSTEM

Create a centralized design system.

Define:

* spacing
* typography
* radii
* shadows
* elevation
* icons
* buttons
* inputs
* cards
* dialogs
* menus
* tooltips
* animations

Use system-aware appearance.

Themes:

```text
System
Light
Dark
```

Avoid excessive gradients.

Avoid excessive glassmorphism.

Avoid unnecessary animation.

Target smooth 60 FPS UI.

---

# 12. APPLE-INSPIRED UX PRINCIPLES

Do not copy Apple's proprietary UI.

Instead use principles:

* visual hierarchy
* generous spacing
* subtle surfaces
* predictable navigation
* minimal chrome
* contextual controls
* smooth transitions
* consistent typography
* clear focus states
* excellent keyboard support

The UI should feel premium without being visually noisy.

---

# 13. ONBOARDING

First launch:

```text
MindSparQ Notes

Capture. Think. Research. Create.

[ Continue as Guest ]

[ Sign In ]
```

Guest mode must immediately enter the application.

Do not force account creation for basic local note-taking.

---

# 14. GUEST MODE

Guest users can:

* create notes
* edit notes
* organize notes
* attach images/files
* search
* export
* use local features

When a cloud-only feature is selected:

```text
This feature requires an account.

[ Sign In ]
[ Continue Locally ]
```

Never delete guest data during account conversion.

Provide migration from guest/local data into authenticated account.

---

# 15. AUTHENTICATION

Implement authentication behind an abstraction.

Providers:

```text
Guest
Email
Google
```

Backend:

Supabase.

Use secure session handling.

Never store plaintext passwords.

Never hard-code secrets.

Never expose privileged Supabase keys in client code.

---

# 16. RICH TEXT EDITOR

The editor is the heart of the application.

Implement:

### Text

* bold
* italic
* underline
* strikethrough
* superscript
* subscript
* font size
* text color
* highlight

### Paragraph

* headings
* alignment
* indentation
* block quote
* callout
* divider
* line spacing

### Lists

* bullet
* numbered
* nested
* checklist

### Advanced

* code block
* inline code
* table
* math
* links
* bookmarks
* comments
* footnotes

Do not show every feature simultaneously.

Use contextual toolbars and menus.

---

# 17. CONTEXTUAL TOOLBAR

When text is selected:

```text
Bold
Italic
Underline
Highlight
Color
Link
Heading
List
Align
Quote
Code
Comment
More
```

On desktop, support keyboard shortcuts.

On mobile, use compact contextual controls.

---

# 18. SLASH COMMANDS

Support:

```text
/
```

Inside the editor.

Example:

```text
/heading
/table
/image
/checklist
/code
/quote
/callout
/math
/divider
```

Searchable command menu.

---

# 19. COMMAND PALETTE

Desktop shortcut:

```text
Ctrl + K
```

Mac:

```text
Cmd + K
```

Commands:

```text
New Note
Search
Insert Image
Insert Table
Toggle Sidebar
Toggle Inspector
Export
Change Theme
Open Research
Insert Citation
Open Settings
```

Command system must be extensible.

---

# 20. IMAGE SYSTEM

Support:

* insert
* drag/drop
* paste from clipboard
* resize
* crop
* rotate
* flip
* brightness
* contrast
* saturation
* opacity
* border
* corner radius
* caption
* annotation

Image alignment:

```text
Left
Center
Right
```

Image wrapping:

```text
None
Square
Tight
```

Text must be able to flow beside a floating image.

Example:

```text
┌───────────────┐  Research explanation
│               │  can continue here
│     IMAGE     │  beside the image.
│               │
└───────────────┘
```

This feature must be architected properly rather than hacked into paragraph rendering.

---

# 21. LIGHTWEIGHT IMAGE EDITOR

Do not build Photoshop.

Build document-oriented image editing.

Tools:

```text
Crop
Rotate
Flip
Brightness
Contrast
Saturation
Blur
Sharpen
Arrow
Rectangle
Circle
Text
Highlight
Pixelate/Blur area
```

Edits should be non-destructive where practical.

Use generated thumbnails for large images.

Do not load full-resolution images unnecessarily.

---

# 22. FILE ATTACHMENTS

Support:

* PDF
* images
* documents
* audio
* other files

Attachments must be stored separately from document text.

Use metadata:

```text
filename
mimeType
size
hash
createdAt
storagePath
```

---

# 23. SEARCH

Implement fast local search.

Search fields:

* title
* body
* tags
* folder
* captions
* attachments metadata
* research sources

Use indexed local search.

Support:

```text
keyword search
phrase search
tag search
folder filtering
date filtering
```

Future-ready:

semantic/vector search.

Do not introduce embeddings into the core search path until required.

---

# 24. FOLDERS

Support:

```text
Inbox
Favorites
Recent
Archive
Trash
Custom folders
Nested folders
```

Drag-and-drop organization.

---

# 25. TAGS

Support:

```text
#MBA
#Research
#Marketing
#CRM
#Thesis
```

Tag autocomplete.

Tag filtering.

Multiple tags per note.

---

# 26. FAVORITES

Any note can be marked favorite.

Favorite state must be persisted locally.

---

# 27. RECENT NOTES

Track recently opened notes.

Do not track sensitive document content unnecessarily.

Store only required metadata.

---

# 28. VERSION HISTORY

Create local document versions.

User can:

```text
View version
Compare version
Restore version
```

Do not create unlimited full database copies.

Use a storage strategy appropriate for performance and disk usage.

---

# 29. UNDO/REDO

Editor-level undo/redo must work reliably.

Never lose undo history unexpectedly during normal editing.

Test:

* text
* formatting
* image insertion
* deletion
* block movement

---

# 30. DRAG AND DROP

Support:

* reorder blocks
* move notes
* move files
* import files
* drop images
* drop PDFs

Use clear drop indicators.

---

# 31. RESEARCH WORKSPACE

Create optional Research mode.

Structure:

```text
Research Project
 ├── Research Question
 ├── Notes
 ├── Sources
 ├── Literature Review
 ├── Methodology
 ├── Findings
 ├── Discussion
 ├── References
 └── Appendix
```

Do not force normal users to use Research mode.

---

# 32. RESEARCH SOURCES

Source metadata:

```text
title
author
year
publisher
journal
DOI
URL
ISBN
notes
tags
```

Allow manual source creation.

Future-ready for import.

---

# 33. CITATION SYSTEM

Support citation styles through a modular citation engine.

Initial targets:

```text
APA 7
MLA
Chicago
Harvard
IEEE
```

Architecture:

```text
Citation
   ↓
CitationStyle
   ↓
FormattedCitation
```

Do not hard-code formatting logic directly into UI.

---

# 34. PDF RESEARCH

PDF viewer must support:

* page navigation
* zoom
* search
* highlight
* underline
* bookmark
* annotation

Allow:

```text
PDF highlight
      ↓
Create Note
      ↓
Attach source
```

Preserve source/page metadata.

---

# 35. LITERATURE MATRIX

Allow users to build:

```text
Author
Year
Topic
Method
Sample
Finding
Research Gap
```

Exportable as CSV/XLSX later.

---

# 36. WEB CLIPPER — FUTURE MODULE

Do not block core application for this.

Architecture should eventually support:

```text
Browser
 ↓
Web Clipper
 ↓
MindSparQ Notes
```

Capture:

* URL
* title
* selected text
* author
* publication date
* screenshot

---

# 37. AI ARCHITECTURE

AI MUST be optional.

Never make the basic editor depend on AI.

Create:

```text
AIProvider
```

Possible implementations:

```text
GeminiProvider
OpenAIProvider
LocalAIProvider
```

AI service layer must not be tightly coupled to one provider.

---

# 38. AI FEATURES

Implement later:

```text
Summarize
Explain
Rewrite
Translate
Generate outline
Extract key points
Generate questions
Generate flashcards
Organize notes
Find related notes
Research assistance
```

AI actions should normally require user confirmation before modifying content.

---

# 39. LOCAL AI

Design for future local models.

Possible architecture:

```text
MindSparQ Notes
      ↓
AI Gateway
      ├── Local Model
      ├── Gemini
      └── Other Provider
```

Local AI must be optional.

Never automatically download a large model during first launch.

---

# 40. SEMANTIC SEARCH / RAG

Future architecture:

```text
Documents
   ↓
Chunking
   ↓
Embeddings
   ↓
Vector Index
   ↓
Retriever
   ↓
AI
```

Keep this outside the basic local keyword search system.

---

# 41. EXPORT

Implement:

```text
Markdown
HTML
TXT
JSON
PDF
```

Architecture-ready:

```text
DOCX
EPUB
```

Export must preserve formatting as much as the target format allows.

---

# 42. IMPORT

Initial:

```text
TXT
Markdown
HTML
JSON
PDF
```

Future:

```text
DOCX
Notion
Evernote
OneNote
Obsidian
```

Import should never silently destroy original files.

---

# 43. SYNC ENGINE

Cloud sync is separate from local storage.

Architecture:

```text
Local Database
      ↓
Change Detector
      ↓
Sync Queue
      ↓
Sync Service
      ↓
Supabase
```

Never block UI on sync.

Use background synchronization.

---

# 44. CONFLICT HANDLING

When conflicts occur:

```text
Local Version
Cloud Version
```

Offer:

```text
Keep Local
Keep Cloud
Merge
```

Do not silently overwrite user data.

---

# 45. BACKUP

Implement local backup architecture.

Allow:

```text
Export all data
Backup database
Restore backup
```

Future integrations:

```text
Google Drive
OneDrive
Dropbox
S3-compatible storage
```

---

# 46. CROSS-DEVICE ARCHITECTURE

Document format must remain platform-independent.

Target:

```text
Windows
Linux
macOS
Android
iOS
Web
```

Do not duplicate domain logic per platform.

---

# 47. MOBILE UI

Do not simply shrink desktop UI.

Mobile should use:

* bottom sheets
* contextual toolbar
* touch-friendly controls
* collapsible navigation
* floating actions where appropriate

Editor remains the primary screen.

---

# 48. TABLET UI

Support adaptive layout:

```text
Sidebar | Editor
```

Optional inspector.

Keyboard support.

Future stylus support.

---

# 49. ACCESSIBILITY

Implement:

* keyboard navigation
* focus indicators
* scalable text
* semantic labels
* screen reader support
* sufficient contrast
* reduced motion support

---

# 50. INTERNATIONALIZATION

Initial languages:

```text
English
Nepali
```

Do not hard-code UI strings.

Use localization files.

The entire UI must be switchable between languages.

Support mixed English/Nepali document content naturally.

---

# 51. NEPALI SUPPORT

Ensure:

* Unicode Devanagari
* Nepali text search
* mixed-language text
* proper rendering
* PDF export
* copy/paste

Future:

```text
Roman Nepali → Nepali
Nepali spell checking
Nepali grammar assistance
```

---

# 52. KEYBOARD SHORTCUTS

Minimum:

```text
Ctrl/Cmd + N       New note
Ctrl/Cmd + K       Command palette
Ctrl/Cmd + F       Search
Ctrl/Cmd + Shift+F Global search
Ctrl/Cmd + S       Save
Ctrl/Cmd + Z       Undo
Ctrl/Cmd + Shift+Z Redo
Ctrl/Cmd + B       Bold
Ctrl/Cmd + I       Italic
Ctrl/Cmd + U       Underline
Ctrl/Cmd + Shift+P Print/Export
```

Allow future customization.

---

# 53. SETTINGS

Settings sections:

```text
Appearance
Editor
Shortcuts
Language
Storage
Backup
Privacy
Account
Sync
AI
Research
Advanced
About
```

---

# 54. PRIVACY

Default philosophy:

> User data belongs to the user.

Core notes should remain local unless the user explicitly enables cloud functionality.

Do not collect unnecessary analytics.

No hidden telemetry.

If telemetry is ever introduced:

* opt-in
* documented
* disableable

---

# 55. SECURITY

Implement:

* secure credential storage
* OS keychain where available
* encrypted secrets
* safe file handling
* input validation
* secure Supabase rules
* least privilege

Never commit:

```text
API keys
passwords
service-role keys
OAuth secrets
private tokens
```

to Git.

---

# 56. SUPABASE SECURITY

Use:

* Row Level Security
* authenticated user ownership
* proper policies
* minimal permissions

A user must never be able to read another user's private notes through manipulated requests.

---

# 57. PERFORMANCE ENGINEERING

Implement:

### Lazy loading

Only load visible data.

### Virtualization

For large note lists and documents.

### Debouncing

Search/autosave where appropriate.

### Caching

Use memory cache carefully.

### Background work

Move expensive operations away from UI thread.

### Image optimization

Generate thumbnails.

### PDF optimization

Load pages on demand.

---

# 58. PERFORMANCE BUDGET

Establish measurable targets.

Target:

```text
Startup:
< 1 second where practical

Typing:
No visible lag

Search:
Near-instant for normal local datasets

Scrolling:
60 FPS target

Idle:
Minimal CPU

Memory:
Keep reasonable on 8–12 GB systems
```

Do not claim these as guaranteed until benchmarked.

Create benchmarks.

---

# 59. ERROR HANDLING

Never crash the entire application because of one bad document or attachment.

Use:

```text
Error boundary
Repository errors
Recovery UI
Logging
Crash-safe autosave
```

Example:

```text
Unable to open this attachment.

[Retry]
[Open externally]
```

---

# 60. LOGGING

Create structured logging.

Levels:

```text
debug
info
warning
error
critical
```

Never log:

* passwords
* access tokens
* private note content
* API keys

---

# 61. TESTING STRATEGY

Create:

### Unit tests

For:

* document model
* database
* repositories
* search
* formatting
* sync
* citation
* export

### Widget tests

For:

* editor
* sidebar
* toolbar
* dialogs
* themes

### Integration tests

For:

* create note
* edit note
* save
* reopen
* search
* export
* guest mode
* authentication
* sync

---

# 62. TEST-FIRST CRITICAL PATH

Before calling a core feature complete:

```text
Implement
 ↓
Test
 ↓
Run analyzer
 ↓
Build
 ↓
Run integration test
 ↓
Fix
 ↓
Repeat
```

Never stop at “code compiles.”

---

# 63. CI/CD

Configure GitHub Actions for:

```text
format
analyze
unit tests
widget tests
integration tests
build
```

Build targets:

```text
Windows
Linux
```

Add other platforms when supported.

---

# 64. CODE QUALITY

Use:

* strong typing
* null safety
* clear naming
* small reusable components
* dependency inversion
* repository interfaces
* service interfaces

Avoid:

* giant widgets
* giant services
* duplicated logic
* magic strings
* global mutable state everywhere

---

# 65. STATE MANAGEMENT

Choose one consistent state management strategy.

Do not mix multiple state-management architectures without a clear reason.

Separate:

```text
UI state
Application state
Domain state
Persistence state
```

---

# 66. DESIGN COMPONENTS

Build reusable components:

```text
AppButton
AppIconButton
AppTextField
AppSearchField
AppDialog
AppMenu
AppTooltip
AppCard
AppEmptyState
AppLoading
AppErrorView
```

This keeps UX consistent.

---

# 67. EMPTY STATES

Every empty screen must be useful.

Example:

```text
No notes yet.

Create your first note and start capturing ideas.

[New Note]
```

Do not show blank screens.

---

# 68. CONTEXT MENUS

Notes:

```text
Open
Rename
Duplicate
Move
Favorite
Export
Share
Archive
Delete
```

Folders:

```text
Rename
New note
New folder
Move
Delete
```

---

# 69. TRASH

Deleted notes should first move to Trash.

Support:

```text
Restore
Delete permanently
Empty Trash
```

---

# 70. SEARCH UX

Global search should feel instant.

Search result:

```text
Note title
matching snippet
folder
tags
updated date
```

Highlight matching text.

---

# 71. EDITOR UX

The editor should feel calm.

Default:

```text
Title

Start writing...
```

Avoid always-visible heavy toolbars.

Show tools contextually.

---

# 72. RESEARCH + NORMAL NOTES

Normal:

```text
Note
```

Research:

```text
Research Project
```

Both must use the same underlying document engine.

Do not create two incompatible editors.

---

# 73. PLUGIN ARCHITECTURE

Future plugins:

```text
AI
Calendar
Cloud storage
Citation providers
Web clipper
Mind map
Flashcards
OCR
Translation
Publishing
```

Plugins should not modify core database directly without defined interfaces.

---

# 74. API / SDK FUTURE

Create internal service boundaries so future external API is possible.

Potential:

```text
Notes API
Search API
Document API
Sync API
AI API
Plugin API
```

Do not build a public API prematurely.

---

# 75. MCP FUTURE

Design AI integration so that future MCP tools can expose:

```text
search_notes
create_note
update_note
get_note
list_notes
search_research
get_sources
```

All destructive actions must require appropriate authorization.

---

# 76. OFFLINE SAFETY

If cloud becomes unavailable:

```text
Cloud unavailable
        ↓
Continue locally
        ↓
Queue changes
        ↓
Sync later
```

Never make users lose work because the Internet disappeared.

---

# 77. DATA MIGRATION

Database schema must use versioned migrations.

Never manually change production database structure without migration files.

---

# 78. DOCUMENT MIGRATION

Document schema must include a version:

```text
documentVersion
```

Future versions can migrate old documents.

---

# 79. OPEN SOURCE

Create:

```text
LICENSE
README.md
CONTRIBUTING.md
SECURITY.md
CODE_OF_CONDUCT.md
CHANGELOG.md
ARCHITECTURE.md
```

Document:

* setup
* build
* test
* architecture
* contribution process
* security reporting

---

# 80. LICENSE

Before choosing a license, document the project's goals.

Prefer a permissive open-source license unless project requirements dictate otherwise.

Do not include third-party code whose license is incompatible.

Maintain dependency license documentation.

---

# 81. DEVELOPMENT PHASES

Antigravity must NOT attempt to implement every future feature at once.

Use incremental milestones.

---

## PHASE 0 — PROJECT AUDIT

Before writing major code:

1. inspect existing repository
2. inspect Flutter/Dart version
3. inspect current dependencies
4. inspect existing screens
5. inspect existing architecture
6. inspect build configuration
7. inspect platform support
8. identify broken/deprecated code
9. identify duplicated code
10. create architecture report

Output:

```text
docs/PROJECT_AUDIT.md
```

Do not destroy existing working functionality without understanding it.

---

# PHASE 1 — FOUNDATION

Implement:

* Flutter project structure
* theme system
* routing
* localization
* core error handling
* logging
* SQLite
* repository layer
* document model
* settings
* dependency injection

Acceptance:

Application launches successfully on Windows and Linux.

---

# PHASE 2 — NOTES CORE

Implement:

* create note
* edit note
* delete
* trash
* restore
* folders
* tags
* favorites
* recent notes
* autosave
* local search

Acceptance:

Application is fully usable offline.

---

# PHASE 3 — EDITOR

Implement:

* rich text
* headings
* lists
* checklist
* quote
* callout
* links
* code
* tables
* slash commands
* contextual toolbar
* undo/redo
* keyboard shortcuts

Acceptance:

User can comfortably create a complete document without external Word-like software for normal note-taking.

---

# PHASE 4 — MEDIA

Implement:

* image insert
* clipboard
* drag/drop
* resize
* crop
* rotate
* alignment
* wrapping
* captions
* annotations
* attachments

Acceptance:

Image + text wrapping works correctly.

---

# PHASE 5 — RESEARCH

Implement:

* Research workspace
* sources
* citations
* references
* PDF viewer
* PDF annotations
* literature matrix

Acceptance:

A student can organize a research project locally.

---

# PHASE 6 — EXPORT / IMPORT

Implement:

* Markdown
* HTML
* TXT
* JSON
* PDF

Then evaluate:

* DOCX
* EPUB

---

# PHASE 7 — CLOUD

Implement:

* Supabase
* authentication
* Google login
* JWT/session handling
* sync queue
* background sync
* conflict handling
* cloud backup

Acceptance:

Local-first behavior remains unchanged if cloud is unavailable.

---

# PHASE 8 — AI

Implement:

* AI provider abstraction
* Gemini provider
* optional local AI provider
* summarization
* explanation
* rewriting
* outline
* flashcards
* research assistance

AI must remain optional.

---

# PHASE 9 — CROSS-PLATFORM

Adapt UI and test:

* Windows
* Linux
* macOS
* Android
* iOS
* Web

Do not claim platform support until actual builds/tests succeed.

---

# 82. DEFINITION OF DONE

A feature is DONE only when:

```text
Code exists
+
UI works
+
Persistence works
+
Error handling exists
+
Tests exist
+
Analyzer passes
+
Build succeeds
+
No obvious dead buttons
+
Documentation updated
```

---

# 83. ANTI-BLOAT RULE

Every feature must answer:

> Does this improve note-taking, research, organization, or productivity?

If not:

Do not add it to core.

Move it to:

```text
Plugin
Future
Optional
```

---

# 84. ANTI-CRASH RULE

Before every release:

Test:

```text
Open app
Create note
Type continuously
Paste large text
Insert image
Insert large image
Delete content
Undo
Redo
Close app during save
Restart
Open note
Search
Export
Import
```

The application must recover safely.

---

# 85. DATA-SAFETY TEST

Test:

```text
Kill application during autosave
Disconnect Internet
Reconnect Internet
Force cloud failure
Open corrupted attachment
Open very large document
Open many notes
```

No silent data loss.

---

# 86. PERFORMANCE TEST

Benchmark:

```text
100 notes
1,000 notes
10,000 notes
large document
large image
large PDF
```

Measure:

* startup
* search
* memory
* CPU
* scrolling
* editing latency

Document results.

---

# 87. USER EXPERIENCE TEST

Test with:

### Beginner

Can they create a note without instructions?

### Student

Can they organize class/research notes?

### Researcher

Can they manage sources and citations?

### Power user

Can they work primarily through keyboard shortcuts?

---

# 88. DEVELOPMENT WORKFLOW FOR ANTIGRAVITY

For EVERY task:

```text
1. Inspect
2. Plan
3. Implement
4. Format
5. Analyze
6. Test
7. Build
8. Review
9. Fix
10. Document
```

Do not blindly generate large amounts of code.

---

# 89. BEFORE EACH MAJOR CHANGE

Create or update:

```text
docs/IMPLEMENTATION_STATUS.md
```

Track:

```text
Feature
Status
Files changed
Tests
Known limitations
Next step
```

Statuses:

```text
PLANNED
IN_PROGRESS
IMPLEMENTED
TESTING
VERIFIED
BLOCKED
```

---

# 90. AUTONOMOUS DEVELOPMENT BEHAVIOR

Antigravity should work autonomously within the project.

It may:

* inspect files
* inspect dependencies
* create files
* refactor architecture
* run tests
* run analyzer
* run builds
* fix errors
* update documentation

But it must NOT:

* delete major functionality without inspection
* expose secrets
* overwrite user data
* invent APIs
* mark untested features as complete
* introduce unnecessary dependencies

---

# 91. WHEN A BUILD ERROR OCCURS

Do not stop immediately.

Process:

```text
Read error
 ↓
Identify root cause
 ↓
Inspect relevant files
 ↓
Apply smallest correct fix
 ↓
Run analyzer
 ↓
Run test
 ↓
Build again
```

Do not hide errors.

Do not suppress compiler warnings simply to make the build green.

---

# 92. WHEN DEPENDENCY IS BROKEN

Do NOT immediately downgrade the entire project.

Check:

1. current package version
2. Flutter compatibility
3. Dart compatibility
4. platform compatibility
5. maintained alternatives

Then choose the smallest safe solution.

Document the decision.

---

# 93. UI QUALITY GATE

Before declaring UI complete:

Check:

* spacing
* typography
* alignment
* hover states
* pressed states
* focus states
* keyboard navigation
* dark mode
* light mode
* empty states
* error states
* loading states
* responsive layout

No generic-looking default Flutter UI.

---

# 94. FINAL PRODUCT STRUCTURE

The final product should conceptually provide:

```text
                    MindSparQ Notes
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
      Notes             Research             AI
        │                  │                  │
     Editor              PDFs              Optional
        │                  │                  │
      Media            Citations             │
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    Document Engine
                           │
                ┌──────────┴──────────┐
                │                     │
             SQLite               Search
                │
            Sync Queue
                │
             Supabase
                │
       Windows / Linux / macOS
       Android / iOS / Web
```

---

# 95. FIRST EXECUTION COMMAND FOR ANTIGRAVITY

When this specification is added to the repository, Antigravity should NOT immediately generate the entire application.

First execute:

```text
Read MASTER_IMPLEMENTATION_SPEC.md completely.

Then inspect the existing repository, project structure, Flutter/Dart versions, dependencies, platform configuration, current source code, tests, assets, and documentation.

Do not implement features yet.

Create:

docs/PROJECT_AUDIT.md
docs/ARCHITECTURE.md
docs/IMPLEMENTATION_STATUS.md

The audit must identify:
1. What already exists
2. What works
3. What is broken
4. What should be reused
5. What should be refactored
6. What should be removed
7. Missing architecture components
8. Dependency risks
9. Performance risks
10. Security risks
11. Recommended Phase 0 → Phase 1 implementation sequence

After completing the audit, STOP and present the implementation plan before making major architectural changes.
```

---

# 96. AFTER AUDIT

Once the audit is reviewed, give Antigravity:

```text
Proceed with PHASE 1 — FOUNDATION.

Follow MASTER_IMPLEMENTATION_SPEC.md exactly.

Implement only the foundation.

Do not implement future features yet.

After implementation:

1. run dart format
2. run flutter analyze
3. run all available tests
4. build Windows
5. build Linux if environment supports it
6. fix all blocking errors
7. update docs/IMPLEMENTATION_STATUS.md
8. report exactly what was implemented
9. report tests executed
10. report remaining issues

Do not claim success without actual verification.
```

---

# 97. PHASE-BY-PHASE EXECUTION COMMANDS

After Phase 1 is verified:

```text
Proceed with PHASE 2 — NOTES CORE.

Implement only the features defined in PHASE 2.

Reuse the established architecture.

Do not rewrite working foundation code unnecessarily.

Follow the Definition of Done.

Test everything before declaring the phase complete.
```

Then repeat the same pattern for:

```text
PHASE 3 — EDITOR
PHASE 4 — MEDIA
PHASE 5 — RESEARCH
PHASE 6 — EXPORT/IMPORT
PHASE 7 — CLOUD
PHASE 8 — AI
PHASE 9 — CROSS-PLATFORM
```

---

# 98. FINAL COMMAND

When all planned phases are implemented:

```text
Perform a complete production-readiness audit of MindSparQ Notes.

Inspect:

Architecture
Performance
Memory usage
CPU usage
UI/UX
Accessibility
Security
Authentication
Local storage
Sync
Data recovery
Editor
Images
PDF
Research
Citations
AI
Exports
Imports
Testing
Documentation
Open-source compliance

Run all available tests and builds.

Find incomplete, fake, broken, dead, duplicated, deprecated, or unnecessarily complex code.

Fix issues where safe.

Do not introduce unnecessary features.

Then produce:

docs/PRODUCTION_READINESS_REPORT.md

Include:

- verified features
- failed tests
- known limitations
- performance results
- security findings
- dependency findings
- technical debt
- recommended next steps

Only mark a feature VERIFIED when it has actually been tested.
```

---

# 99. PRODUCT NORTH STAR

The final application should feel like this:

> Open instantly.
>
> Start writing instantly.
>
> Never worry about saving.
>
> Never lose work.
>
> Stay offline when necessary.
>
> Organize simply.
>
> Research deeply when needed.
>
> Use AI only when useful.
>
> Sync only when wanted.
>
> Own your data.

The application should remain:

**Fast enough to disappear. Powerful enough to replace several separate tools.**

---

# 100. SUCCESS CRITERIA

MindSparQ Notes is successful when a user can:

```text
Open application
      ↓
Continue as Guest
      ↓
Create Note
      ↓
Write rich content
      ↓
Insert image
      ↓
Write text beside image
      ↓
Attach PDF
      ↓
Highlight research
      ↓
Create source
      ↓
Insert citation
      ↓
Organize with folders/tags
      ↓
Search instantly
      ↓
Export PDF/Markdown
      ↓
Close application
      ↓
Reopen
      ↓
Everything remains intact
```

And later:

```text
Sign in
   ↓
Sync
   ↓
Open another device
   ↓
Continue exactly where the user stopped.
```

This is the core product vision.
