# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Finance & Accounting Space
# =============================================================================
puts "Creating Finance questions..."

finance_space = Space.find_by!(slug: "finance")

# Expense report question
create_qa(
  space: finance_space,
  author: SEED_BUSINESS_EMPLOYEES["steve.hoffman@example.com"],
  title: "How long does expense reimbursement take? Submitted 2 weeks ago...",
  body: <<~BODY,
    I submitted an expense report for a client dinner ($280) two weeks ago and still haven't been reimbursed.

    - What's the normal turnaround time?
    - How can I check the status?
    - Is there someone I can follow up with?
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["susan.baker@example.com"],
      body: <<~ANSWER,
        Sorry for the delay! Here's how our expense reimbursement process works:

        **Standard Timeline:**
        - Submission → Manager approval: 1-3 business days
        - Manager approval → Finance review: 2-3 business days
        - Finance approval → Payment: 3-5 business days
        - **Total typical time: 7-10 business days**

        **Checking Status:**
        1. Log into Concur
        2. Go to "Reports" > "Submitted"
        3. Click on your report to see approval chain
        4. Status will show: Submitted → Pending Manager → Pending Finance → Approved → Payment Scheduled

        **Common Delays:**
        - Missing receipt (we need itemized receipts over $25)
        - Missing business purpose description
        - Manager hasn't approved (nudge them!)
        - Expense exceeds policy limits (needs additional approval)

        **Your Specific Case:**
        I'll look into your report today. Client dinners require business purpose + attendee list. If that's missing, it might be why it's stuck.

        For urgent issues: finance@company.com or drop by Finance (Building A, 3rd floor)

        **Pro tip:** Check "My Tasks" in Concur - sometimes there's an action item waiting on you!
      ANSWER
      votes: 19,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
      body: <<~ANSWER,
        Had a similar issue - turned out my manager was on PTO and hadn't delegated approval. Worth checking if your manager's email is the right person in the approval chain!
      ANSWER
      votes: 8,
      correct: false
    }
  ],
  created_ago: 4.days
)

# Purchase order question
create_qa(
  space: finance_space,
  author: SEED_PRODUCT_STAFF["lisa.bernstein@example.com"],
  title: "When do I need a PO vs just using my corporate card?",
  body: <<~BODY,
    I need to buy some software licenses for our team (~$2,000). Can I just use my corporate card or do I need to go through the PO process?

    I've never done a PO before - how complicated is it?
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["richard.chang@example.com"],
      body: <<~ANSWER,
        Great question! Here's when you need a Purchase Order:

        **Corporate Card OK (no PO needed):**
        - One-time purchases under $1,000
        - Travel expenses
        - Business meals
        - Office supplies
        - Conference registrations

        **PO Required:**
        - Any purchase **$1,000 or more** (your case!)
        - Recurring/subscription services
        - Hardware purchases
        - Professional services/contractors
        - Software licenses (usually)

        **Why POs?**
        - Ensures budget availability before purchase
        - Creates audit trail for larger expenses
        - Enables vendor payment terms (Net 30/60)
        - Required for accounting controls

        **PO Process (it's not that bad!):**
        1. Submit request in Coupa (our procurement system)
        2. Include: vendor, amount, business justification, budget code
        3. Routes for approval based on amount:
           - Under $5,000: Manager only
           - $5,000-$25,000: Manager + Director
           - Over $25,000: Manager + Director + VP + Finance
        4. Once approved, Procurement issues PO to vendor
        5. Vendor invoices against PO number
        6. Finance pays vendor directly

        **Timeline:** Usually 2-5 business days for under $5K

        **Your Software Purchase:**
        $2,000 for licenses = PO required. Submit in Coupa, tag it as "Software/SaaS", and it should route to your manager only. Let me know if you need help!
      ANSWER
      votes: 32,
      correct: true
    }
  ],
  created_ago: 11.days
)

# Budget question
create_qa(
  space: finance_space,
  author: SEED_PMO_STAFF["nicole.adams@example.com"],
  title: "How do I check my department's remaining budget for the quarter?",
  body: <<~BODY,
    I'm planning a team offsite and need to know if we have budget for it.

    - Where can I see our department budget vs. actuals?
    - Is there a tool or do I need to ask someone?
    - How do I request budget if we're over?
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["elizabeth.moore@example.com"],
      body: <<~ANSWER,
        Budget visibility is important! Here's how to access the information:

        **Self-Service Budget Reports:**
        1. Log into Oracle (Financials module)
        2. Navigator > Financial Reports > Department Budget vs Actual
        3. Select your cost center and date range
        4. Report shows: Budget, Committed (POs), Spent, Available

        **Not sure of your cost center?**
        - Check any approved expense report - it lists the cost center
        - Or ask your manager - they have full visibility

        **If You Don't Have Oracle Access:**
        Your manager or director does. Ask them for a budget snapshot, or request view-only access through IT.

        **Budget Reallocation Options:**
        If you're over budget:
        1. **Within your dept:** Move money between line items (travel → team building)
        2. **Small overage:** Request approval from Finance for 10% flex
        3. **Larger amounts:** Submit Budget Modification Request in Oracle

        **For Your Team Offsite:**
        - Check "Training & Development" or "Team Building" budget lines
        - These are often underspent mid-year
        - Many teams do offsites in Q4 to use remaining budget

        **Timing tip:** Budget requests for next quarter due by the 15th of the prior month!
      ANSWER
      votes: 26,
      correct: true
    },
    {
      author: SEED_PMO_STAFF["brandon.lee@example.com"],
      body: <<~ANSWER,
        Pro tip: Your Finance Business Partner (FBP) can help you navigate budgets. Each department has one assigned. They can also suggest creative ways to fund things within policy.

        Check the Finance intranet page for FBP assignments.
      ANSWER
      votes: 15,
      correct: false
    }
  ],
  created_ago: 9.days
)

# Invoice question
create_qa(
  space: finance_space,
  author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
  title: "Vendor keeps asking when they'll get paid - how do I check invoice status?",
  body: <<~BODY,
    I hired a contractor for a project and they've sent two follow-up emails asking about payment. I submitted their invoice 3 weeks ago.

    How do I:
    1. Check the status of the invoice
    2. Escalate if there's a problem
    3. Communicate back to the vendor
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["susan.baker@example.com"],
      body: <<~ANSWER,
        I understand the urgency - vendor relationships are important! Here's how to track invoices:

        **Checking Invoice Status:**
        1. Open Coupa
        2. Go to Invoices > View Invoices
        3. Search by vendor name or invoice number
        4. Status shows: Received → Pending Approval → Approved → Scheduled → Paid

        **Common Reasons for Delays:**
        - **No matching PO:** Invoice must reference a valid PO number
        - **PO amount exceeded:** Invoice is more than PO authorized
        - **Three-way match fail:** Invoice/PO/Receipt don't match
        - **Missing approvals:** Stuck waiting for someone
        - **Vendor setup incomplete:** New vendor W-9 or banking info missing

        **Escalation Path:**
        1. First: Check Coupa for specific hold reason
        2. Email ap@company.com with PO# and invoice#
        3. Urgent: Slack #finance-help or call ext. 4500
        4. I can also flag invoices for expedited processing

        **Communicating with Vendor:**
        - Let them know you're following up internally
        - Ask them to confirm PO number on invoice
        - Standard payment terms are Net 30 from invoice approval (not receipt)

        **Your Case:**
        3 weeks is longer than normal. Send me the PO number and I'll investigate today. If it's a new vendor, often the holdup is banking setup - we can expedite that.
      ANSWER
      votes: 23,
      correct: true
    }
  ],
  created_ago: 2.days
)

# 401k question
create_qa(
  space: finance_space,
  author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
  title: "401k match - when does it vest and how much does company match?",
  body: <<~BODY,
    I'm trying to figure out the best strategy for my 401k contributions.

    - What's the company match percentage?
    - Is there a vesting schedule?
    - When do contributions hit my account?
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["michael.torres@example.com"],
      body: <<~ANSWER,
        Great that you're thinking about retirement savings! Here's our 401k structure:

        **Company Match:**
        - We match **100% of the first 4%** of your salary that you contribute
        - Plus **50% of the next 2%**
        - **Maximum company contribution: 5%** of your salary

        **Example (on $100k salary):**
        | Your Contribution | Company Match | Total |
        |-------------------|---------------|-------|
        | 4% ($4,000) | 4% ($4,000) | 8% ($8,000) |
        | 6% ($6,000) | 5% ($5,000) | 11% ($11,000) |

        **Vesting Schedule:**
        - Your contributions: **Always 100% vested**
        - Company match: 3-year cliff vesting
          - Year 1: 0%
          - Year 2: 0%
          - Year 3+: 100%

        **Contribution Timing:**
        - Deducted from each paycheck (bi-weekly)
        - Match deposited same pay period
        - Shows in Fidelity account within 3-4 business days

        **Maximizing Your Benefit:**
        - At minimum, contribute 6% to get full match (free money!)
        - 2024 IRS limit: $23,000 (under 50) / $30,500 (50+)
        - Consider Roth 401k option for tax diversification

        **Changes:**
        You can adjust contributions anytime in Workday > Benefits > 401k. Changes take effect next pay period.

        Log into Fidelity NetBenefits to see your balance and investment options!
      ANSWER
      votes: 38,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["paul.adams@example.com"],
      body: <<~ANSWER,
        One thing that helped me: Fidelity has free 1-on-1 planning sessions. They'll look at your whole financial picture, not just our 401k. Booked through their website.

        Also consider the Mega Backdoor Roth if you want to contribute more than the IRS limit - HR has a guide on this.
      ANSWER
      votes: 21,
      correct: false
    }
  ],
  created_ago: 16.days
)

# Corporate card question
create_qa(
  space: finance_space,
  author: SEED_BUSINESS_EMPLOYEES["margaret.king@example.com"],
  title: "Lost my corporate card - what do I do?",
  body: <<~BODY,
    I think I left my corporate card at a restaurant last night. I've already called the restaurant but they don't have it.

    - How do I report it lost/stolen?
    - Am I liable for fraudulent charges?
    - How long to get a replacement?
  BODY
  answers: [
    {
      author: SEED_FINANCE_STAFF["jennifer.kim@example.com"],
      body: <<~ANSWER,
        Don't panic - this happens! Here's what to do immediately:

        **Step 1: Lock the Card NOW**
        - Open the Amex mobile app
        - Go to your corporate card
        - Toggle "Lock Card" on
        - This prevents any new charges instantly

        **Step 2: Report to Amex**
        - Call: 1-800-XXX-XXXX (corporate card line - 24/7)
        - Or report in app > More > Report Lost/Stolen
        - They'll cancel the card and issue a new one

        **Step 3: Notify Finance**
        - Email corporate.cards@company.com
        - Include last 4 digits and when you noticed it missing
        - We'll monitor for any suspicious activity

        **Liability:**
        - You are **NOT personally liable** for fraudulent charges
        - Report within 24 hours for full protection
        - Finance will dispute any charges you didn't make
        - You ARE responsible for any legitimate charges you made

        **Replacement Timeline:**
        - Standard: 5-7 business days
        - Expedited: 2-3 business days (additional fee, but company covers it for lost/stolen)
        - Request expedited if you have upcoming travel

        **While Waiting:**
        - Use personal card and expense it
        - Your manager can issue a temporary card for urgent needs

        Breathe - you're doing the right thing by acting quickly!
      ANSWER
      votes: 31,
      correct: true
    }
  ],
  created_ago: 1.day
)

puts "  Created Finance questions"
