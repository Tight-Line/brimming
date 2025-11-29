# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Human Resources Space
# =============================================================================
puts "Creating Human Resources questions..."

hr_space = Space.find_by!(slug: "human-resources")

# PTO rollover question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["steve.hoffman@example.com"],
  title: "Does unused PTO roll over to next year or do we lose it?",
  body: <<~BODY,
    I have about 5 days of PTO left this year and I'm trying to plan whether I need to use it before December 31st or if it carries over.

    I couldn't find a clear answer in the employee handbook. Does anyone know the policy?

    Also, is there a maximum amount that can roll over?
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["daniel.oconnor@example.com"],
      body: <<~ANSWER,
        Great question! Here's the official policy:

        **PTO Rollover Rules:**
        - Up to **5 days (40 hours)** of unused PTO rolls over to the next year
        - Any amount over 5 days is forfeited on December 31st
        - Rolled-over PTO must be used by **March 31st** of the following year or it expires

        **Tips:**
        - Check your balance in Workday under Time Off > Balance Summary
        - If you have more than 5 days, coordinate with your manager now to schedule time off
        - We cannot pay out unused PTO except upon termination

        If you have special circumstances (extended illness, critical project deadlines), reach out to HR and we can discuss options on a case-by-case basis.
      ANSWER
      votes: 24,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["linda.garcia@example.com"],
      body: <<~ANSWER,
        I learned this the hard way last year - lost 3 days because I didn't realize there was a cap on rollover.

        Pro tip: Set a calendar reminder for early November to check your balance and plan accordingly!
      ANSWER
      votes: 8,
      correct: false
    }
  ],
  created_ago: 15.days
)

# Benefits enrollment question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["nancy.white@example.com"],
  title: "When is open enrollment and can I add my spouse mid-year?",
  body: <<~BODY,
    I just got married last month and want to add my spouse to my health insurance.

    Questions:
    1. Do I have to wait until open enrollment?
    2. If not, what's the deadline to add them after a life event?
    3. What documents do I need to provide?

    Thanks!
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["daniel.oconnor@example.com"],
      body: <<~ANSWER,
        Congratulations on your marriage! 🎉

        **Good news**: Marriage is a qualifying life event (QLE), so you don't have to wait for open enrollment!

        **Timeline:**
        - You have **30 days** from your marriage date to make changes
        - Changes are effective the 1st of the month following enrollment

        **Documents needed:**
        1. Marriage certificate (copy is fine)
        2. Spouse's SSN and date of birth
        3. Completed Dependent Addition form (in Workday)

        **Steps:**
        1. Log into Workday
        2. Go to Benefits > Life Events
        3. Select "Marriage" and enter the date
        4. Add your spouse as a dependent
        5. Upload marriage certificate
        6. Select plans for your spouse

        **FYI**: Adding a spouse will increase your premium. You can preview the cost in Workday before submitting.

        Open enrollment is in **November** each year (typically Nov 1-15) for January 1 effective date.
      ANSWER
      votes: 31,
      correct: true
    }
  ],
  created_ago: 22.days
)

# Remote work policy question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
  title: "What's the current policy on working from home? Is it still 3 days in office?",
  body: <<~BODY,
    My team has been pretty flexible about WFH but I heard there might be changes coming.

    What's the official policy? Do different departments have different rules?

    Also, I'm wondering if I could request to be fully remote - I'm considering moving out of state to be closer to family.
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["patricia.wells@example.com"],
      body: <<~ANSWER,
        Good timing on this question - we just updated the policy last quarter.

        **Current Hybrid Policy (effective Q2):**
        - Standard expectation is **3 days in-office, 2 days remote** per week
        - "Core days" (Tues/Wed/Thurs) are strongly encouraged for in-person collaboration
        - Department heads can set team-specific requirements based on business needs

        **Requesting Full Remote Status:**
        This is possible but requires approval chain:
        1. Your direct manager
        2. Department head
        3. HR review

        **Considerations for full remote:**
        - Must be in a state where we have tax presence (currently 32 states)
        - May affect eligibility for certain roles requiring on-site presence
        - Annual in-person meetings (usually quarterly) at your expense

        **To Apply:**
        Submit a Remote Work Arrangement Request through ServiceNow. Include:
        - Business justification
        - Proposed work schedule
        - Equipment needs
        - New state/location

        Happy to chat more if you want to discuss your specific situation!
      ANSWER
      votes: 45,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
      body: <<~ANSWER,
        I went through the full remote approval process last year. A few tips:

        - Be specific about WHY you need it (caregiving, spouse job relocation, etc.)
        - Propose how you'll maintain team collaboration
        - Check the state tax implications - HR can connect you with Payroll for this
        - Decision took about 3 weeks for me

        Good luck!
      ANSWER
      votes: 19,
      correct: false
    }
  ],
  created_ago: 8.days
)

# Performance review question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
  title: "How do performance reviews work here? What should I expect?",
  body: <<~BODY,
    I'm coming up on my first annual review and I'm a bit nervous. I've never had a formal performance review before.

    - What format does it follow?
    - How should I prepare?
    - Do reviews affect salary/promotions?
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["james.wright@example.com"],
      body: <<~ANSWER,
        Don't be nervous - our review process is designed to be developmental, not punitive!

        **Review Timeline:**
        - **Self-assessment** due 2 weeks before your review date
        - **Peer feedback** collected (3-5 colleagues you select)
        - **Manager assessment** written before meeting
        - **Review meeting** (typically 1 hour)
        - **Final calibration** across teams

        **Rating Scale:**
        - Exceeds Expectations
        - Meets Expectations
        - Developing
        - Below Expectations

        **How to Prepare:**
        1. Review your goals from the beginning of the year
        2. Document your accomplishments with specific examples
        3. Note any challenges and how you addressed them
        4. Think about growth areas and development goals
        5. Come with questions for your manager

        **Impact on Compensation:**
        - Reviews inform annual merit increases (typically 2-5% depending on rating and budget)
        - "Exceeds" ratings make you eligible for promotion consideration
        - Reviews are one factor in bonus calculations for eligible roles

        **Pro tip:** Keep a "win journal" throughout the year so you don't have to remember everything at review time!
      ANSWER
      votes: 38,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["charles.allen@example.com"],
      body: <<~ANSWER,
        Former manager here - a few things that help:

        - Don't be humble in your self-assessment. If you did good work, say so clearly.
        - Ask your peers for feedback before selecting them - gives them a heads up and lets you know what they'll say
        - Have 1-2 development goals ready that show you're thinking about growth

        The review is as much about the future as the past.
      ANSWER
      votes: 22,
      correct: false
    }
  ],
  created_ago: 12.days
)

# Referral bonus question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["joe.scott@example.com"],
  title: "Employee referral bonus - how does it work and when do you get paid?",
  body: <<~BODY,
    I referred a friend for a position and they got hired! 🎉

    I know there's a referral bonus but I have questions:
    - How much is the bonus?
    - When is it paid out?
    - Is it taxed differently?
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["maria.santos@example.com"],
      body: <<~ANSWER,
        Congrats on the successful referral! Here's how the program works:

        **Bonus Amounts:**
        - Standard roles: **$2,000**
        - Hard-to-fill roles (engineering, data science): **$4,000**
        - Executive/Director+: **$5,000**

        **Payment Timeline:**
        - **50%** paid after referred employee completes 30 days
        - **50%** paid after referred employee completes 90 days

        **Tax Treatment:**
        - Yes, it's taxed as regular income (shows up on your paycheck)
        - Expect roughly 30-35% withheld depending on your bracket
        - Will be reflected in your W-2

        **Important Notes:**
        - Both you AND the new hire must be employed when each payment is due
        - You must have submitted the referral through Workday BEFORE they applied
        - HR, Recruiting, and hiring managers are not eligible for referrals into their own teams

        Check Workday > My Referrals to see your referral status and expected payment dates!
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 5.days
)

# Parental leave question
create_qa(
  space: hr_space,
  author: SEED_BUSINESS_EMPLOYEES["margaret.king@example.com"],
  title: "Parental leave policy - birth parent vs non-birth parent?",
  body: <<~BODY,
    My spouse and I are expecting our first child in a few months. I want to understand the parental leave policy.

    - How much leave do I get as the non-birth parent?
    - Does it need to be taken all at once?
    - Can I use PTO to extend it?
  BODY
  answers: [
    {
      author: SEED_HR_STAFF["patricia.wells@example.com"],
      body: <<~ANSWER,
        Congratulations! Here's our parental leave policy:

        **Leave Duration:**
        - **Birth parent**: 16 weeks fully paid
        - **Non-birth parent**: 8 weeks fully paid
        - **Adoption/Foster**: 12 weeks fully paid

        **Flexibility:**
        - Leave can be taken in **one continuous block** or split into **two blocks**
        - If splitting, both blocks must be taken within 12 months of birth/placement
        - Minimum block size is 2 weeks

        **Extending Leave:**
        - Yes! You can use accrued PTO before or after parental leave
        - Unpaid leave may also be available (discuss with your manager)
        - FMLA provides job protection for up to 12 weeks total

        **Benefits During Leave:**
        - Health insurance continues (company continues paying their portion)
        - You continue to accrue PTO during paid leave
        - 401k match continues if you're contributing

        **To Apply:**
        1. Notify HR at least 30 days in advance (when possible)
        2. Submit leave request in Workday
        3. Meet with Benefits team to review coverage

        Feel free to schedule time with me to discuss your specific plans!
      ANSWER
      votes: 52,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["paul.adams@example.com"],
      body: <<~ANSWER,
        I took my non-birth parent leave last year. Some additional tips:

        - Talk to your manager early about coverage plans
        - Set up email auto-responder and delegate access to shared inboxes
        - Take ALL of it - you won't get this time back!
        - The split option was great for us - I took 6 weeks at birth, then 2 weeks when my spouse returned to work

        Congrats and enjoy those newborn snuggles!
      ANSWER
      votes: 33,
      correct: false
    }
  ],
  created_ago: 18.days
)

puts "  Created Human Resources questions"
