# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Travel & Expenses Space
# =============================================================================
puts "Creating Travel questions..."

travel_space = Space.find_by!(slug: "travel")

# Booking question
create_qa(
  space: travel_space,
  author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
  title: "How do I book business travel? Do I use a travel agency or book myself?",
  body: <<~BODY,
    I need to travel to our NYC office next month for meetings. This is my first business trip.

    - Do I book flights/hotels myself or go through someone?
    - Are there preferred vendors I should use?
    - What's the approval process?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["barbara.stone@example.com"],
      body: <<~ANSWER,
        Welcome to business travel! Here's how it works:

        **Booking Process:**

        1. **Get trip approved FIRST**
           - Submit Travel Request in Concur
           - Include: destination, dates, business purpose, estimated cost
           - Manager approval required (VP approval for international)

        2. **Book through Concur Travel**
           - Integrated with our booking tool
           - Shows preferred vendors and negotiated rates
           - Automatically applies corporate discounts

        3. **Alternative: Self-book (if needed)**
           - For unusual routes or special circumstances
           - Book and submit receipts manually
           - Must still follow policy limits

        **Preferred Vendors (best rates + rewards):**
        - **Air:** United, Delta, American (in that order)
        - **Hotel:** Marriott, Hilton, Hyatt
        - **Car:** Enterprise, National
        - **Ground:** Uber for Business (linked in app)

        **Policy Highlights:**
        - Economy class for flights under 6 hours
        - Premium economy for 6+ hours (manager approval)
        - Hotels: up to $250/night in major cities, $175 elsewhere
        - Rental cars: Intermediate class standard

        **For Your NYC Trip:**
        1. Submit Travel Request in Concur
        2. Once approved, book in Concur Travel
        3. NYC hotels fill fast - book early!
        4. Consider train (Amtrak) - often faster door-to-door from some cities

        **Need Help?**
        - Concur issues: travel@company.com
        - Complex itineraries: I can help arrange
        - Last-minute travel: Call our emergency line (on travel portal)
      ANSWER
      votes: 28,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
      body: <<~ANSWER,
        Pro tip: Join the loyalty programs for our preferred airlines and hotels! Book through Concur but use your personal loyalty numbers. You keep the points/status.

        Also, Uber for Business is linked to your work account - just select "Work" as the trip type and it charges directly. No expense report needed!
      ANSWER
      votes: 19,
      correct: false
    }
  ],
  created_ago: 12.days
)

# Per diem question
create_qa(
  space: travel_space,
  author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
  title: "What's the meal per diem and do I need to keep receipts?",
  body: <<~BODY,
    I'm traveling for 3 days next week. Questions about meals:

    - Is there a daily allowance for food?
    - Do I need to keep every receipt?
    - What about alcohol with dinner?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["barbara.stone@example.com"],
      body: <<~ANSWER,
        Good questions! Here's our meal policy:

        **Meal Allowances (per day):**

        | Meal | Amount | Notes |
        |------|--------|-------|
        | Breakfast | $20 | If not included in hotel |
        | Lunch | $25 | |
        | Dinner | $45 | |
        | **Total** | **$90/day** | Domestic travel |

        *International rates vary by country - check GSA rates in Concur*

        **Receipt Requirements:**
        - **Under $25:** No receipt required
        - **$25 and over:** Itemized receipt required
        - **Tip:** Take photos of receipts immediately (they fade!)

        **What's Covered:**
        ✅ Meals while traveling
        ✅ Room service (counts toward meal allowance)
        ✅ Coffee/snacks (within daily limit)
        ✅ Reasonable gratuity (15-20%)

        **What's NOT Covered:**
        ❌ Meals at home (travel days partial)
        ❌ Excessive tips
        ❌ Mini-bar (unless it's meal replacement)

        **Alcohol:**
        - **With client/customer:** Reasonable wine/beer with dinner is OK
        - **Solo travel:** Company preference is no alcohol reimbursement
        - **Never:** Excessive alcohol, shots, bottle service

        **Travel Day Pro-Rating:**
        - Departure day: Lunch + Dinner
        - Return day: Breakfast + Lunch
        - Full days: All meals

        **Tips:**
        - The Concur app lets you snap receipts on the go
        - Group meals: One person pays, splits the bill in expense report
        - If meal is provided (conference, team dinner), don't claim per diem
      ANSWER
      votes: 35,
      correct: true
    }
  ],
  created_ago: 8.days
)

# International travel question
create_qa(
  space: travel_space,
  author: SEED_PRODUCT_STAFF["derek.washington@example.com"],
  title: "International travel checklist - what do I need to do before going abroad?",
  body: <<~BODY,
    I'm traveling to our London office in 6 weeks. I've never traveled internationally for work.

    What do I need to prepare? Passport, visa, anything else?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["barbara.stone@example.com"],
      body: <<~ANSWER,
        International travel requires more prep! Here's your checklist:

        **6+ Weeks Before:**
        - [ ] Check passport expiration (must be valid 6+ months beyond return)
        - [ ] Verify visa requirements (UK = no visa needed for US citizens < 6 months)
        - [ ] Submit international travel request (VP approval required)
        - [ ] Review country-specific security briefing (on Travel portal)

        **4 Weeks Before:**
        - [ ] Book flights and hotels through Concur
        - [ ] Register trip with corporate travel security (mandatory)
        - [ ] Get corporate credit card enabled for international use
        - [ ] Check mobile phone plan (international coverage)

        **2 Weeks Before:**
        - [ ] Confirm meetings and on-site contacts
        - [ ] Review expense policies for destination country
        - [ ] Get local currency or notify bank of travel
        - [ ] Download offline maps and translation apps

        **1 Week Before:**
        - [ ] Confirm all bookings (flights, hotels, car service)
        - [ ] Share itinerary with manager and emergency contact
        - [ ] Review health/safety guidance (especially post-COVID)
        - [ ] Pack appropriate power adapters (UK uses Type G plugs)

        **Day of Travel:**
        - [ ] Bring passport, booking confirmations, emergency contacts
        - [ ] Have travel security app installed (shows nearest assistance)
        - [ ] Know local emergency numbers (UK: 999)

        **UK-Specific Notes:**
        - No visa required for US citizens (business travel < 6 months)
        - You'll go through UK e-gates with US passport
        - Our London office is in Canary Wharf (Jubilee line)
        - Per diem rates are higher for London (~$120/day)

        **Insurance:**
        - Company travel insurance covers you (medical, evacuation)
        - Policy details on Travel portal
        - Keep emergency card in wallet

        **Need Help?**
        Our travel agency (Amex GBT) can help with complex international itineraries. Contact info on Travel portal.
      ANSWER
      votes: 42,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["paul.adams@example.com"],
      body: <<~ANSWER,
        A few lessons from my London trips:

        1. **Jet lag:** Arrive a day early if possible. Important meetings the morning after a red-eye are brutal.

        2. **Oyster card:** Get one for the Tube - it's way cheaper than buying individual tickets.

        3. **Work phone:** Check if IT can set up international roaming or get a local SIM. Data roaming charges are real.

        4. **Time zones:** London is 5 hours ahead of East Coast. Schedule calls thoughtfully!
      ANSWER
      votes: 23,
      correct: false
    }
  ],
  created_ago: 20.days
)

# Expense report deadline question
create_qa(
  space: travel_space,
  author: SEED_BUSINESS_EMPLOYEES["dorothy.green@example.com"],
  title: "Expense report deadline - do I really have to submit within 30 days?",
  body: <<~BODY,
    I just realized I have expenses from a trip 6 weeks ago that I haven't submitted. Am I going to have a problem?

    Also, why is there a deadline anyway?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["kevin.murphy@example.com"],
      body: <<~ANSWER,
        Yes, the 30-day policy is real! Here's the deal:

        **The Policy:**
        - Expenses must be submitted within **30 days** of being incurred
        - For travel, clock starts when you return
        - Reports submitted 30-60 days: Require manager + Finance Director approval
        - Reports submitted 60+ days: Require VP approval + explanation

        **Why It Matters:**

        1. **Accounting accuracy**
           - Expenses need to hit the right fiscal period
           - Late expenses mess up budget tracking and forecasting

        2. **Tax compliance**
           - IRS requires "timely" substantiation of expenses
           - Older expenses face more scrutiny in audits

        3. **Cash management**
           - Company needs to predict cash outflows
           - Late reports create surprises

        4. **Memory fades**
           - After 30 days, do you remember why you spent $47.38?
           - Managers can't approve what they don't remember

        **Your 6-Week Expense:**
        - It's not too late! Submit it now.
        - Add a note explaining the delay
        - Your manager will need to approve with acknowledgment it's late
        - If over $500 total, Finance Director will also review

        **Going Forward:**
        - Concur app: Snap receipts as you get them
        - Set calendar reminder for trip return +7 days
        - Use "SmartScan" in Concur - takes 2 minutes per receipt

        **Pro Tip:**
        If you're always late with expenses, set up a weekly 15-min "expense time" on Fridays. Much easier than a big catch-up session!
      ANSWER
      votes: 26,
      correct: true
    }
  ],
  created_ago: 4.days
)

# Ride share question
create_qa(
  space: travel_space,
  author: SEED_BUSINESS_EMPLOYEES["steve.hoffman@example.com"],
  title: "Uber vs taxi vs rental car - what should I use when traveling?",
  body: <<~BODY,
    I'm traveling to Austin for a conference. Should I rent a car or just use Uber everywhere?

    What's the policy on ground transportation?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["barbara.stone@example.com"],
      body: <<~ANSWER,
        Great question - it depends on your trip! Here's the guidance:

        **When to Rent a Car:**
        - Multiple site visits in a day
        - Suburban/rural destinations (limited rideshare)
        - Trip is 3+ days AND you'll use it daily
        - Total rental + gas < estimated rideshare cost

        **When to Use Rideshare:**
        - Urban destination with good coverage
        - Short trip (1-2 days)
        - Conference travel (in one location mostly)
        - You don't want parking hassle

        **When to Use Taxi:**
        - Airport taxi queue is faster
        - Rideshare surge pricing is extreme
        - You need a receipt immediately

        **Policy Details:**

        | Transportation | Policy |
        |----------------|--------|
        | Uber/Lyft | Uber for Business preferred (auto-expensed) |
        | Rental car | Intermediate class standard |
        | Taxi | Reimbursable with receipt |
        | Personal car | $0.67/mile + tolls + parking |
        | Parking | Covered (airport, hotel, client site) |

        **For Austin Conference:**
        I'd recommend Uber for Business:
        - Austin has great Uber coverage
        - Downtown/convention area is compact
        - No parking hassles at conference venue
        - Cost will likely be lower than rental + parking

        **Uber for Business Setup:**
        1. Download Uber app
        2. Go to Settings > Business > Add business profile
        3. Enter work email - we're already in their system
        4. When riding for work, select "Company Name" as payment

        Rides automatically expense to the right cost center!

        **One Exception:**
        If you're visiting our Austin satellite office (up in Round Rock), consider a rental - it's 25 min from downtown with no public transit.
      ANSWER
      votes: 31,
      correct: true
    }
  ],
  created_ago: 6.days
)

# Travel cancellation question
create_qa(
  space: travel_space,
  author: SEED_BUSINESS_EMPLOYEES["margaret.king@example.com"],
  title: "Trip got cancelled - how do I handle the flight and hotel cancellations?",
  body: <<~BODY,
    My client meeting next week got cancelled. I've already booked flights and hotel through Concur.

    - Can I cancel without fees?
    - Do I need to do anything special?
    - What if I have non-refundable bookings?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["barbara.stone@example.com"],
      body: <<~ANSWER,
        Cancellations happen! Here's how to handle them:

        **Step 1: Cancel in Concur First**
        - Go to your trip in Concur Travel
        - Select "Cancel Trip"
        - This notifies our travel agency and starts refund process

        **Airline Cancellation:**

        | Booking Type | What Happens |
        |--------------|--------------|
        | Refundable fare | Full refund in 7-10 days |
        | Non-refundable (most) | Credit for future travel (same airline, 1 year) |
        | Basic Economy | Usually no refund/credit |

        **Good News:** Our corporate rates are usually refundable or have waived change fees!

        **Hotel Cancellation:**
        - Most hotels: Cancel 24-48 hours before = no charge
        - Check your confirmation for specific policy
        - Prepaid rates: Usually non-refundable (contact hotel directly)

        **What You Need to Do:**
        1. Cancel in Concur (this is documentation)
        2. Check for cancellation confirmations via email
        3. If credits issued, note them (they're company money)
        4. If you incurred fees, explain in a note

        **Non-Refundable Bookings:**
        - If you booked per policy and trip was cancelled by business need, company absorbs the cost
        - Document the reason for cancellation
        - Manager approval for any losses over $250

        **Credits:**
        - Airline credits stay in your name but are company funds
        - Use for your next business trip
        - Track in Concur (there's a "unused tickets" report)
        - Credits typically expire in 1 year

        **For Future:**
        Consider booking refundable rates if meeting isn't confirmed, especially for flights over $500.
      ANSWER
      votes: 29,
      correct: true
    }
  ],
  created_ago: 2.days
)

puts "  Created Travel questions"
