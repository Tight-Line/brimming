# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Product Management Space
# =============================================================================
puts "Creating Product Management questions..."

product_space = Space.find_by!(slug: "product-management")

# Feature prioritization question
create_qa(
  space: product_space,
  author: SEED_PRODUCT_STAFF["raj.patel@example.com"],
  title: "What framework do we use for feature prioritization?",
  body: <<~BODY,
    I'm new to the PM team and trying to understand how we decide what goes into each sprint.

    - Do we have a standard prioritization framework?
    - How do we balance customer requests vs. tech debt vs. new features?
    - Where does the prioritized backlog live?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["derek.washington@example.com"],
      body: <<~ANSWER,
        Welcome to the team! Here's how we handle prioritization:

        **Our Framework: RICE + Business Value**

        We score features using RICE (Reach, Impact, Confidence, Effort) adjusted for strategic alignment:

        | Factor | Weight | Description |
        |--------|--------|-------------|
        | Reach | 20% | How many users affected (monthly) |
        | Impact | 25% | Improvement to user experience (1-3 scale) |
        | Confidence | 15% | How sure are we about estimates |
        | Effort | 25% | Engineering effort in person-weeks |
        | Strategic Fit | 15% | Alignment to annual OKRs |

        **Balancing Different Work Types:**
        - **60%** Customer-facing features
        - **20%** Tech debt & infrastructure
        - **15%** Bug fixes
        - **5%** Research/spikes

        Tech debt has protected capacity - engineering leads advocate for what's needed each quarter.

        **Where to Find the Backlog:**
        - **ProductBoard** - Feature requests, customer feedback, scoring
        - **Jira** - Sprint-level backlog, engineering work
        - **Roadmap** - Quarterly view in ProductBoard (link on PM wiki)

        **Process:**
        1. Ideas → ProductBoard with customer evidence
        2. Monthly: PM team reviews and scores
        3. Quarterly: Leadership approves roadmap themes
        4. Bi-weekly: Sprint planning pulls from prioritized backlog

        I'd recommend sitting in on our next prioritization session - it's next Tuesday!
      ANSWER
      votes: 24,
      correct: true
    },
    {
      author: SEED_PRODUCT_STAFF["casey.miller@example.com"],
      body: <<~ANSWER,
        To add to Derek's answer - the scoring spreadsheet template is on the PM wiki. It auto-calculates RICE scores.

        Also, we review closed-lost deals monthly with Sales to catch feature gaps that might be costing revenue. Those get fast-tracked in scoring.
      ANSWER
      votes: 11,
      correct: false
    }
  ],
  created_ago: 8.days
)

# Roadmap question
create_qa(
  space: product_space,
  author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
  title: "Where can I see the product roadmap? Customer asking about upcoming features",
  body: <<~BODY,
    I'm on a call with a customer tomorrow and they want to know when we're adding SSO support.

    - Is there a roadmap I can share externally?
    - What can I tell customers about upcoming features?
    - Who do I escalate to if the feature is a deal-breaker?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["amanda.foster@example.com"],
      body: <<~ANSWER,
        Good question - we have different roadmaps for different audiences:

        **Internal Roadmap (employees only):**
        - Full details in ProductBoard
        - Shows committed features with tentative timelines
        - Link on PM wiki

        **Customer-Facing Roadmap:**
        - High-level themes, no specific dates
        - Located at: roadmap.company.com
        - Updated quarterly after planning

        **SSO Specifically:**
        - SSO is on our Q1 roadmap (committed)
        - Public messaging: "Available in early Q1"
        - For enterprise prospects: we can share more details under NDA

        **What You Can/Can't Share:**

        ✅ **Can share:**
        - Features on public roadmap
        - General timing (Q1, Q2, first half of year)
        - "We're investing heavily in security/enterprise features"

        ❌ **Don't share:**
        - Specific release dates
        - Features not on public roadmap
        - Competitive details

        **If It's a Deal-Breaker:**
        1. Log the request in ProductBoard (Customer Requests board)
        2. Tag me or the PM owner
        3. If urgent/large deal: Slack #product-sales-escalations
        4. We can do a Product call with the customer if needed

        For your SSO call - happy to join if helpful. We can discuss specifics under NDA.
      ANSWER
      votes: 29,
      correct: true
    }
  ],
  created_ago: 5.days
)

# PRD question
create_qa(
  space: product_space,
  author: SEED_PRODUCT_STAFF["lisa.bernstein@example.com"],
  title: "What should be in a PRD? Need a template",
  body: <<~BODY,
    I'm writing my first PRD for a medium-sized feature (new dashboard). Looking for guidance on:

    - What sections to include
    - How detailed should it be?
    - Is there a template I should use?
    - Who reviews/approves PRDs?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["derek.washington@example.com"],
      body: <<~ANSWER,
        We have a standard PRD template - grab it from the PM wiki under Templates.

        **Standard PRD Sections:**

        ```
        1. Overview
           - Problem statement (1-2 sentences)
           - Hypothesis
           - Success metrics (OKRs/KPIs)

        2. Background & Research
           - Customer evidence (interviews, data)
           - Competitive analysis
           - Assumptions & risks

        3. Requirements
           - User stories with acceptance criteria
           - In scope / Out of scope (important!)
           - Dependencies

        4. Design
           - Link to Figma designs
           - Key user flows
           - Edge cases

        5. Technical Considerations
           - Engineering input on approach
           - Data requirements
           - Performance/scale considerations

        6. Launch Plan
           - Rollout strategy (beta, % rollout, GA)
           - Success criteria for each phase
           - Rollback plan

        7. Open Questions
           - Things to resolve before starting
        ```

        **Level of Detail:**
        - Medium feature like a dashboard: ~4-6 pages
        - More detail on requirements/acceptance criteria
        - Less on background if well-understood problem

        **Review Process:**
        1. Draft → Engineering lead review (technical feasibility)
        2. Update → Design review (UX alignment)
        3. Final → PM Director sign-off
        4. Engineering kicks off sprint planning

        **Tips:**
        - User stories > feature lists (focus on outcomes)
        - Include mockups early - visual > words
        - "Out of scope" is as important as "in scope"
        - Write for engineers - they're your primary audience
      ANSWER
      votes: 35,
      correct: true
    },
    {
      author: SEED_PRODUCT_STAFF["casey.miller@example.com"],
      body: <<~ANSWER,
        One thing I've learned: write the success metrics FIRST. It forces you to think about what "done" looks like and helps scope creep.

        Also, our engineering partners appreciate when you call out known unknowns upfront rather than surprising them mid-sprint.
      ANSWER
      votes: 18,
      correct: false
    }
  ],
  created_ago: 12.days
)

# A/B testing question
create_qa(
  space: product_space,
  author: SEED_PRODUCT_STAFF["casey.miller@example.com"],
  title: "How do we run A/B tests? Want to test a new signup flow",
  body: <<~BODY,
    I want to test a simplified signup flow against our current one. I've heard we have experimentation infrastructure but don't know how to use it.

    - What tool do we use?
    - How long should tests run?
    - Who needs to approve experiments?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["amanda.foster@example.com"],
      body: <<~ANSWER,
        Great that you're thinking about testing! Here's our experimentation process:

        **Platform: Split.io**
        - Feature flags + experiment framework
        - Analytics integration with Amplitude
        - Self-serve for simple flags, managed for experiments

        **Running an Experiment:**

        1. **Define hypothesis** in experiment doc template
           - "If we simplify signup to 2 steps, then conversion will increase by 15%"

        2. **Calculate sample size**
           - Use the calculator in Split.io
           - Rule of thumb: need ~2 weeks for signup tests (high traffic)

        3. **Get approval** (for customer-facing experiments)
           - PM Director sign-off
           - Data team review of metrics setup
           - Legal review if collecting new data

        4. **Set up in Split.io**
           - Create experiment
           - Define variants (control, treatment)
           - Set traffic allocation (usually start at 10%, ramp to 50/50)
           - Configure metrics to track

        5. **Run for required duration**
           - Minimum 1 full week to account for day-of-week effects
           - Until statistical significance (p < 0.05)
           - Don't peek! Wait for full results

        6. **Analyze and decide**
           - Review in Split.io or Amplitude
           - Document learnings in experiment doc
           - Ship winner or iterate

        **Signup Flow Specifically:**
        - This is a high-impact area - I'd want to review your test plan
        - Consider: conversion rate, time to value, drop-off rates
        - Watch for segment differences (mobile vs desktop)

        Let's chat before you start - I can help with hypothesis and metrics!
      ANSWER
      votes: 27,
      correct: true
    }
  ],
  created_ago: 6.days
)

# Customer interview question
create_qa(
  space: product_space,
  author: SEED_PRODUCT_STAFF["raj.patel@example.com"],
  title: "Best practices for customer discovery interviews?",
  body: <<~BODY,
    I'm doing customer research for a new feature area and need to conduct interviews. I've done some before but want to make sure I'm doing it right.

    - How do you recruit interview participants?
    - What questions should I avoid?
    - How do I synthesize findings?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["derek.washington@example.com"],
      body: <<~ANSWER,
        Customer interviews are foundational to good product decisions! Here's my playbook:

        **Recruiting Participants:**

        1. **Internal sources:**
           - Ask CSMs for customers who've given feedback on this area
           - Check ProductBoard for relevant feedback submitters
           - Pull from NPS detractors who mentioned related issues

        2. **External tools:**
           - User Interviews (userinterviews.com) for B2C
           - Respondent.io for B2B professionals
           - LinkedIn outreach for specific personas

        3. **Incentives:**
           - $50-100 gift card for 30-min consumer interviews
           - $150-200 for B2B professionals
           - For existing customers: early access, feature input credit

        **Interview Best Practices:**

        ✅ **Do:**
        - Ask about past behavior ("Tell me about the last time...")
        - Understand context and workflow
        - Follow up with "Why?" (5 whys technique)
        - Stay curious and neutral
        - Record (with permission) for later review

        ❌ **Avoid:**
        - Leading questions ("Don't you think X is frustrating?")
        - Asking about future behavior ("Would you use X?")
        - Pitching your solution
        - Yes/No questions
        - Showing designs too early

        **Sample Questions:**
        - "Walk me through how you currently do [task]"
        - "What's the hardest part of [problem area]?"
        - "Tell me about a time when [scenario]"
        - "What have you tried to solve this?"

        **Synthesizing Findings:**

        1. After each interview: write key observations (not interpretations)
        2. After 5+ interviews: identify patterns/themes
        3. Create affinity map (I use Miro or Dovetail)
        4. Write research summary:
           - Key findings (with quotes)
           - Insights & implications
           - Recommendations

        **Resources:**
        - "The Mom Test" by Rob Fitzpatrick (must-read!)
        - Our interview guide template on PM wiki
        - I'm happy to shadow your first few interviews!
      ANSWER
      votes: 42,
      correct: true
    }
  ],
  created_ago: 18.days
)

# Stakeholder alignment question
create_qa(
  space: product_space,
  author: SEED_PRODUCT_STAFF["lisa.bernstein@example.com"],
  title: "Stakeholders keep changing requirements mid-sprint - how to handle?",
  body: <<~BODY,
    I'm struggling with scope creep. Sales keeps bringing "urgent" requests, executives add features in demos, and my sprint plans are constantly disrupted.

    How do you push back professionally without damaging relationships?
  BODY
  answers: [
    {
      author: SEED_PRODUCT_STAFF["amanda.foster@example.com"],
      body: <<~ANSWER,
        This is one of the hardest parts of product management! Here's what's worked for me:

        **Mindset Shift:**
        Stakeholders aren't the enemy - they're bringing you signal. Your job is to **filter signal from noise** and protect the team's focus.

        **Tactical Approaches:**

        **1. The Parking Lot**
        - "Great idea! Let me add it to the backlog for prioritization."
        - Physically write it down in front of them
        - They feel heard, you don't commit

        **2. Trade-off Conversation**
        - "We can do that. What should we cut to make room?"
        - Makes the cost concrete
        - Often they self-select out

        **3. The Sprint Buffer**
        - Reserve 10-15% of capacity for unplanned work
        - When "urgent" comes in, it fits in the buffer
        - If buffer's full, it waits for next sprint

        **4. Request Triage**
        - For Sales requests: "Is this blocking a signed deal?"
        - For Executive requests: "What's the strategic rationale?"
        - For Customer requests: "How many customers asked for this?"

        **5. Async Updates**
        - Weekly email: what shipped, what's coming, what moved
        - Proactive communication reduces "drive-by" requests

        **When to Say Yes:**
        - Truly urgent (outage, legal, security)
        - CEO-level strategic bet
        - Easy win (< 2 hours) that unblocks big deal

        **Setting Expectations:**
        - Document your prioritization framework
        - Share sprint goals at the start
        - In standups, name what you're NOT doing

        **Long-term:**
        - Build credibility by shipping consistently
        - Share customer evidence for your decisions
        - Celebrate wins publicly (people trust winners)

        It gets easier with experience. Happy to role-play any tough conversations!
      ANSWER
      votes: 51,
      correct: true
    },
    {
      author: SEED_PRODUCT_STAFF["derek.washington@example.com"],
      body: <<~ANSWER,
        One thing I'd add: **document everything**.

        Keep a log of requests that came in and their outcomes. After a quarter, share a summary:
        - "We had 47 ad-hoc requests"
        - "22 were addressed in planned work"
        - "15 were de-prioritized because..."

        Data makes these conversations much easier and builds trust that you're not just saying no.
      ANSWER
      votes: 28,
      correct: false
    }
  ],
  created_ago: 3.days
)

puts "  Created Product Management questions"
