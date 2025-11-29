# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Project Management Space
# =============================================================================
puts "Creating Project Management questions..."

project_space = Space.find_by!(slug: "project-management")

# Jira vs other tools question
create_qa(
  space: project_space,
  author: SEED_BUSINESS_EMPLOYEES["linda.garcia@example.com"],
  title: "What project management tools do we use? I keep getting links to different systems",
  body: <<~BODY,
    I'm confused about our project management tools. I've seen links to Jira, Asana, Monday.com, and spreadsheets.

    - What's the "official" tool?
    - When should I use which?
    - How do I get access/training?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["stephanie.clark@example.com"],
      body: <<~ANSWER,
        Good question - we know the tool landscape is confusing! Here's the official guidance:

        **Our Tool Stack:**

        | Tool | Purpose | Teams |
        |------|---------|-------|
        | **Jira** | Engineering work, sprints, bugs | Engineering, Product |
        | **Asana** | Cross-functional projects, business initiatives | All departments |
        | **Monday.com** | Marketing campaigns only | Marketing |
        | **Smartsheet** | Finance/PMO reporting, resource planning | Finance, PMO |

        **Rule of Thumb:**
        - Building software? → Jira
        - Business/cross-team project? → Asana
        - Need a quick tracker? → Asana (not spreadsheets!)

        **Why Multiple Tools?**
        - Teams chose tools optimized for their workflows
        - We're consolidating where possible (RIP Trello)
        - Integrations connect them (Jira-Asana sync for product launches)

        **Getting Access:**
        - Jira: IT ticket + manager approval
        - Asana: Self-serve signup with work email
        - Monday.com: Marketing team admin only
        - Smartsheet: Request through PMO

        **Training:**
        - Recorded training on Confluence for each tool
        - Monthly "Tool Tips" sessions (calendar on PMO page)
        - 1:1 help: Slack #project-management-help

        **Pro Tip:** Check the PMO wiki for "Project Intake" - we have a form that helps you pick the right tool and template!
      ANSWER
      votes: 33,
      correct: true
    }
  ],
  created_ago: 10.days
)

# Status report question
create_qa(
  space: project_space,
  author: SEED_BUSINESS_EMPLOYEES["charles.allen@example.com"],
  title: "How do I write a good project status report?",
  body: <<~BODY,
    My manager asked me to send weekly status reports on my project. I've never done formal status reporting before.

    - What format should I use?
    - What do stakeholders actually care about?
    - How much detail is too much?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["brandon.lee@example.com"],
      body: <<~ANSWER,
        Status reports are a key communication skill! Here's the format that works:

        **The Executive Summary Format (recommended):**

        ```
        PROJECT: [Name]
        STATUS: 🟢 Green / 🟡 Yellow / 🔴 Red
        OWNER: [Your name]
        DATE: [Date]

        SUMMARY: [1-2 sentences on overall health]

        KEY ACCOMPLISHMENTS:
        • [Completed item 1]
        • [Completed item 2]

        COMING UP:
        • [Next milestone 1] - [date]
        • [Next milestone 2] - [date]

        RISKS/BLOCKERS:
        • [Issue] - [Owner] - [Mitigation]

        HELP NEEDED:
        • [Specific ask if any]

        KEY METRICS:
        • Budget: $X spent of $Y
        • Timeline: On track / X days behind
        • Scope: No changes / +X items added
        ```

        **What Stakeholders Care About:**
        1. Are we on track? (status color + summary)
        2. What changed since last week? (accomplishments)
        3. What's coming that might affect them? (upcoming)
        4. Is anything at risk? (risks/blockers)
        5. Do you need anything from me? (help needed)

        **How Much Detail:**
        - Executive stakeholders: Just the summary and status
        - Project sponsors: Full report, focus on risks
        - Team members: More granular (use Jira/Asana instead)

        **Status Color Guidelines:**
        - 🟢 **Green**: On track for scope, timeline, budget
        - 🟡 **Yellow**: Risk to one dimension, mitigation in progress
        - 🔴 **Red**: Off track, escalation needed

        **Tips:**
        - Send at same time each week (consistency builds trust)
        - No surprises - if it's red, stakeholders should know why before the report
        - Call out wins! Good news gets buried
        - Link to detail (don't include it)
      ANSWER
      votes: 41,
      correct: true
    },
    {
      author: SEED_PMO_STAFF["amy.wilson@example.com"],
      body: <<~ANSWER,
        One thing I'd add: ask your audience what they want!

        A quick "Hey, what would be most useful in my weekly update?" goes a long way. Some managers want bullet points, others want narrative. Some want daily, some want monthly.

        Also - if nothing changed since last week, say so. "No update" is better than filler.
      ANSWER
      votes: 22,
      correct: false
    }
  ],
  created_ago: 7.days
)

# Agile vs Waterfall question
create_qa(
  space: project_space,
  author: SEED_BUSINESS_EMPLOYEES["nancy.white@example.com"],
  title: "Agile vs Waterfall - which methodology should I use for my project?",
  body: <<~BODY,
    I'm leading a new project that involves both engineering work and a marketing launch.

    Engineering wants to be agile, marketing has fixed dates. How do I make this work?

    Also - what does "agile" actually mean in practice here?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["chris.taylor@example.com"],
      body: <<~ANSWER,
        Welcome to the classic "hybrid project" challenge! Here's how we handle it:

        **First: Understand the Methodologies**

        **Waterfall:**
        - Sequential phases: Requirements → Design → Build → Test → Deploy
        - Fixed scope, fixed timeline
        - Good for: Predictable work, regulatory requirements, fixed deadlines

        **Agile (Scrum):**
        - Iterative sprints (2 weeks)
        - Flexible scope, fixed capacity
        - Good for: Evolving requirements, software development, learning as you go

        **Hybrid Approach (what we typically do):**

        ```
        [Phase 1: Discovery] - Waterfall
        • Gather requirements
        • Define MVP scope
        • Align on fixed dates

        [Phase 2: Build] - Agile
        • Engineering works in sprints
        • Product backlog is prioritized
        • Scope adjusts within constraints

        [Phase 3: Launch] - Waterfall
        • Fixed date go-live
        • Marketing runs campaign plan
        • Training and enablement
        ```

        **Making It Work:**

        1. **Anchor milestones** - Fixed dates that engineering builds toward
           - "Beta by Oct 1" is non-negotiable
           - WHAT ships by Oct 1 is negotiable

        2. **Rolling wave planning**
           - Detail near-term work (sprint level)
           - High-level plans for later phases
           - Re-plan as you learn

        3. **Integration points**
           - Sprint demos include marketing stakeholders
           - Marketing gets early access for content creation
           - Weekly sync across workstreams

        4. **Buffer for unknowns**
           - Build in 10-20% buffer for tech work
           - Have "must have" vs "nice to have" features defined

        **Your Situation:**
        Schedule a kickoff with all leads. Document the fixed constraints (launch date, budget) and the flexible ones (feature scope). Then plan backward from the launch date.

        Happy to help facilitate - this is bread and butter for PMO!
      ANSWER
      votes: 38,
      correct: true
    }
  ],
  created_ago: 14.days
)

# Resource allocation question
create_qa(
  space: project_space,
  author: SEED_PMO_STAFF["nicole.adams@example.com"],
  title: "How do I get engineering resources allocated to my project?",
  body: <<~BODY,
    I have a business project that needs engineering support (building an internal tool). Engineering says they're "at capacity."

    - How does resource allocation work?
    - Who decides what engineers work on?
    - Is there a way to expedite or escalate?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["stephanie.clark@example.com"],
      body: <<~ANSWER,
        Resource allocation is one of the most common friction points! Here's how it works:

        **How Engineering Capacity is Allocated:**

        1. **Quarterly Planning (OKRs)**
           - Engineering commits capacity to strategic priorities
           - Product and business leaders negotiate at leadership level
           - Results in a "roadmap" of committed work

        2. **Sprint Level**
           - Teams pull from backlog based on priorities
           - Engineering managers protect capacity for maintenance
           - ~20% reserved for operational work

        3. **Unplanned Work**
           - Buffer for bugs, incidents, urgent requests
           - Competes with your request

        **Who Decides:**
        - **What** to build: Product Management + Business stakeholders
        - **When** to build: Engineering leadership based on capacity
        - **How** to build: Engineering teams

        **Getting Resources for Your Project:**

        1. **Product Intake Request**
           - Submit through ProductBoard (even for internal tools)
           - Include: business case, urgency, scope estimate

        2. **Make the Business Case**
           - Revenue impact? Cost savings? Risk mitigation?
           - Quantify if possible ("saves 10 hrs/week × 50 people")

        3. **Negotiate Timing**
           - Maybe not this quarter, but can be planned for next
           - "What would it take to prioritize this?"

        4. **Explore Alternatives**
           - Can contractors do it?
           - Buy vs build?
           - Simpler MVP that fits in available capacity?

        **Escalation Path:**
        - Your manager → Engineering Director → CTO
        - But escalation should be rare and justified

        **Reality Check:**
        "At capacity" often means "your request isn't high enough priority." Focus on making the case stronger rather than fighting for resources.
      ANSWER
      votes: 29,
      correct: true
    },
    {
      author: SEED_PMO_STAFF["brandon.lee@example.com"],
      body: <<~ANSWER,
        Couple of tactical tips:

        1. **Get an engineering advocate** - Find someone on an engineering team who sees the value. Peer advocacy goes a long way.

        2. **Reduce scope** - "I need 2 engineers for 3 months" is hard. "I need 4 hours of help setting this up" is easy.

        3. **Timing matters** - End of quarter is usually tightest. Beginning of quarter has more flexibility.
      ANSWER
      votes: 16,
      correct: false
    }
  ],
  created_ago: 5.days
)

# Meeting overload question
create_qa(
  space: project_space,
  author: SEED_BUSINESS_EMPLOYEES["joe.scott@example.com"],
  title: "Too many meetings! How to run projects without meeting overload?",
  body: <<~BODY,
    I'm spending 80% of my day in meetings for my project. Status meetings, alignment meetings, stakeholder meetings...

    How do other PMs manage this? What meetings are actually necessary?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["chris.taylor@example.com"],
      body: <<~ANSWER,
        Meeting overload is real! Here's how to take back your calendar:

        **Essential Project Meetings:**

        | Meeting | Frequency | Duration | Attendees |
        |---------|-----------|----------|-----------|
        | Standup | Daily | 15 min | Core team |
        | Sprint Planning | Bi-weekly | 1-2 hr | Dev team + PM |
        | Sprint Review | Bi-weekly | 30 min | Team + stakeholders |
        | Retrospective | Bi-weekly | 45 min | Core team |
        | Steering Committee | Monthly | 1 hr | Sponsors + leads |

        **Meetings to Kill:**

        ❌ **Status meetings with no decisions**
        - Replace with: Written status updates
        - Tool: Slack standup bot, email, or Loom video

        ❌ **"Alignment" meetings with 10+ people**
        - Replace with: Async document review
        - Tool: Google Doc with comment period

        ❌ **Recurring meetings "just in case"**
        - Replace with: On-demand scheduling
        - Cancel if no agenda 24 hours before

        **Tactics That Work:**

        1. **Office hours** instead of 1:1s
           - "I'm available Tues/Thurs 2-4 for questions"
           - People self-select out of non-urgent items

        2. **Async-first** for updates
           - Record 5-min Loom instead of 30-min meeting
           - Written decisions with comment period

        3. **Meeting audit**
           - Every month, review recurring meetings
           - Ask: "If this didn't exist, would I create it?"

        4. **Meeting-free blocks**
           - Block 2-3 hours daily for focused work
           - Make it visible ("Focus Time - no meetings")

        5. **Decline with grace**
           - "I don't think I'm needed here - can you send notes?"
           - "Can we handle this async? Here's a doc."

        **PM-Specific Tip:**
        Your job is to make decisions, not attend meetings. Ask yourself: "Am I here to decide something, or just to observe?"
      ANSWER
      votes: 47,
      correct: true
    },
    {
      author: SEED_PMO_STAFF["amy.wilson@example.com"],
      body: <<~ANSWER,
        One thing that helped me: I track my meeting time vs. execution time weekly.

        Set a target (I aim for 50% meeting max) and review each Friday. If I'm over, I audit which meetings to cut or shorten next week.

        Also - you can leave meetings! "I need to drop at :45" is totally acceptable if you've contributed what you need to.
      ANSWER
      votes: 24,
      correct: false
    }
  ],
  created_ago: 2.days
)

# Risk management question
create_qa(
  space: project_space,
  author: SEED_PMO_STAFF["nicole.adams@example.com"],
  title: "How do I create and maintain a project risk register?",
  body: <<~BODY,
    My project sponsor is asking for a risk register. I understand the concept but:

    - What format should it be in?
    - How often do I update it?
    - What do I do when a risk actually happens?
  BODY
  answers: [
    {
      author: SEED_PMO_STAFF["stephanie.clark@example.com"],
      body: <<~ANSWER,
        Risk management is essential! Here's our approach:

        **Risk Register Format:**

        | ID | Risk | Probability | Impact | Score | Owner | Mitigation | Status |
        |----|------|-------------|--------|-------|-------|------------|--------|
        | R1 | Key engineer leaves | Medium | High | 6 | PM | Cross-train team members | Monitoring |
        | R2 | Vendor delays integration | High | Medium | 6 | Lead | Weekly vendor check-ins | Active |
        | R3 | Budget overrun | Low | High | 4 | PM | Monthly budget review | Monitoring |

        **Scoring:**
        - Probability: Low (1) / Medium (2) / High (3)
        - Impact: Low (1) / Medium (2) / High (3)
        - Score = Probability × Impact (1-9 scale)

        **Update Frequency:**
        - **Review weekly** in team meetings
        - **Update register** when status changes
        - **Report to sponsors** monthly or when high risks emerge

        **When Risk Becomes Reality (Issue):**

        1. **Move to Issues Log** (separate from risks)
        2. **Assign owner** responsible for resolution
        3. **Define resolution plan** with timeline
        4. **Escalate if needed** (impacts timeline/budget/scope)
        5. **Communicate to stakeholders** immediately if material

        **Issues Log Format:**

        | ID | Issue | Date Identified | Owner | Resolution Plan | Due Date | Status |
        |----|-------|-----------------|-------|-----------------|----------|--------|
        | I1 | Vendor integration delayed 2 weeks | 11/15 | Lead | Negotiate expedited timeline | 11/22 | In Progress |

        **Categories to Consider:**
        - Technical (dependencies, complexity, skills)
        - Resource (availability, turnover, skills gaps)
        - Schedule (dependencies, estimates, external factors)
        - Budget (estimates, scope changes, vendor costs)
        - Organizational (priorities, politics, change)
        - External (vendors, market, regulations)

        **Templates:**
        Grab our risk register template from Confluence → PMO → Templates. Pre-filled with common risks to prompt your thinking!
      ANSWER
      votes: 35,
      correct: true
    }
  ],
  created_ago: 9.days
)

puts "  Created Project Management questions"
