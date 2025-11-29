# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Parking & Commuting Space
# =============================================================================
puts "Creating Parking questions..."

parking_space = Space.find_by!(slug: "parking")

# Parking permit question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["steve.hoffman@example.com"],
  title: "How do I get a parking permit? There's a waitlist?",
  body: <<~BODY,
    I just started and need a parking spot. I went to the garage and they said I need a permit.

    - How do I apply for one?
    - I heard there's a waitlist - how long?
    - What are the alternatives if I can't get a spot?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["robert.jenkins@example.com"],
      body: <<~ANSWER,
        Welcome! Yes, parking is our most requested (and limited) resource. Here's the situation:

        **Applying for a Parking Permit:**
        1. Go to ServiceNow > Facilities > Parking Request
        2. Select your preferred garage and level
        3. Submit request
        4. You'll be added to the waitlist

        **Current Waitlist Status:**
        - Building A garage: ~4-6 months
        - Building B garage: ~2-3 months
        - Surface lot: Usually available immediately (but farther)

        **Monthly Costs (pre-tax payroll deduction):**
        - Covered garage: $150/month
        - Surface lot: $75/month
        - Motorcycle: $50/month

        **Alternatives While Waiting:**

        1. **Surface lot** - Available now, 5-minute walk
        2. **Public transit subsidy** - We cover up to $100/month
        3. **Carpool match** - Guaranteed spot if 2+ employees share
        4. **Bike parking** - Free and always available
        5. **Daily visitor parking** - $15/day if you only drive occasionally

        **Pro Tips:**
        - Carpooling bumps you to front of waitlist
        - Some people surrender permits when they go remote - spots open randomly
        - Building B waitlist is shorter and it's a covered walkway to A

        **To Claim Transit Subsidy:**
        Go to Workday > Benefits > Commuter Benefits. Works for bus, train, and ferry!
      ANSWER
      votes: 34,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["linda.garcia@example.com"],
      body: <<~ANSWER,
        I was on the waitlist for 5 months. What I did:
        - Used surface lot for the first 2 months
        - Then found a carpool buddy through the internal Slack #commute channel
        - With carpool, got a garage spot immediately!

        The carpool matching is worth it even if you only carpool 2-3 days/week.
      ANSWER
      votes: 18,
      correct: false
    }
  ],
  created_ago: 14.days
)

# Lost parking badge question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["nancy.white@example.com"],
  title: "Lost my parking badge - how do I get in/out of the garage?",
  body: <<~BODY,
    I can't find my parking badge anywhere. My car is in the garage right now!

    - How do I get my car out today?
    - How do I get a replacement badge?
    - Is there a fee?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["tony.russo@example.com"],
      body: <<~ANSWER,
        Don't worry - we can help you get your car out today!

        **Getting Out Today:**
        1. Go to the security desk in Building A lobby
        2. Show your employee badge (or ID)
        3. They'll give you a temporary exit pass
        4. Use the pass at the exit gate (insert like a credit card)

        **Getting a Replacement Badge:**
        1. Submit ServiceNow ticket: Facilities > Parking > Badge Replacement
        2. Include: your parking spot number, vehicle info
        3. Pick up new badge at Security desk within 24-48 hours

        **Cost:**
        - First replacement: Free
        - Second replacement: $25
        - Third+ replacement: $50

        **Entry/Exit Without Badge (temporary):**
        - Entry: Use the call box, give your name and spot number
        - Exit: Security desk can buzz you out
        - This works for 1-2 days while waiting for replacement

        **If Badge Was Stolen:**
        Report it immediately! We'll deactivate the old badge to prevent unauthorized access. No charge for stolen badge replacement (with police report if available).

        **Prevention Tip:**
        The badge works in your phone via Apple Wallet / Google Pay. I'd recommend setting that up as a backup once you get your new badge.
      ANSWER
      votes: 22,
      correct: true
    }
  ],
  created_ago: 3.days
)

# EV charging question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
  title: "Do we have EV charging stations? How do I use them?",
  body: <<~BODY,
    I just got an electric car! Do we have charging stations at the office?

    - Where are they located?
    - Is there a cost?
    - Do I need to sign up for something?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["robert.jenkins@example.com"],
      body: <<~ANSWER,
        Congrats on going electric! Yes, we have EV charging available:

        **Locations:**
        - Building A garage: Level 2, Row E (8 chargers)
        - Building B garage: Level 1, Row A (4 chargers)
        - Surface lot: East end (6 chargers)

        **Charger Types:**
        - Level 2 chargers (240V) - most stations
        - 2 DC fast chargers in Building A (Level 2 only)

        **How to Use:**

        1. **Register first:**
           - Download ChargePoint app
           - Create account with work email
           - Add your vehicle info

        2. **At the station:**
           - Tap your phone or ChargePoint card
           - Plug in
           - You'll get notifications when charging completes

        3. **Move when done!**
           - 4-hour limit during business hours
           - You'll get a reminder notification
           - Overstay fee: $5/hour after limit

        **Cost:**
        - First 4 hours: **Free!**
        - After 4 hours: $2.50/hour (to encourage turnover)
        - DC fast charging: $0.20/kWh

        **Etiquette:**
        - Don't hog spots - unplug when full
        - Don't "ICE" the EV spots (parking without charging)
        - Join #ev-drivers Slack for real-time spot availability
        - If all spots are full, use ChargePoint app to get waitlist notification

        **Coming Soon:**
        We're adding 10 more chargers next quarter based on demand. If you want one in a specific location, let me know!
      ANSWER
      votes: 41,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["paul.adams@example.com"],
      body: <<~ANSWER,
        Fellow EV driver here! The #ev-drivers Slack channel is super helpful. People post when they're done charging so others know spots are free.

        Also, Level 1 in Building A is closest to the stairs - easier for quick plug/unplug if you just need a top-up.
      ANSWER
      votes: 15,
      correct: false
    }
  ],
  created_ago: 9.days
)

# Bike storage question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
  title: "Is there secure bike parking? I don't want my bike stolen",
  body: <<~BODY,
    I'd like to bike to work but I have a nice bike and I'm worried about theft.

    - Is there indoor/secure bike parking?
    - What about showering after riding in?
    - Any other bike commuter perks?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        We love our bike commuters! Here's what we offer:

        **Bike Storage Options:**

        | Location | Security | Capacity | Access |
        |----------|----------|----------|--------|
        | Bike cage (B1) | Highest - badge access, cameras | 40 bikes | Request access in ServiceNow |
        | Outdoor racks | Medium - on camera | 20 bikes | Always available |
        | Office bike hook | Varies | Limited | Ask your manager |

        **Bike Cage Access:**
        - Request in ServiceNow > Facilities > Bike Storage
        - Usually approved within 24 hours
        - Badge access only - very secure
        - Includes a personal locker for helmet/gear

        **Showers:**
        - Building A basement: 2 showers (M/F)
        - Building B basement: 1 shower (unisex)
        - Towels provided
        - Lockers available (day-use)

        **Bike Commuter Perks:**
        - **Bike purchase subsidy:** $200/year toward bike purchase/maintenance
        - **Commuter benefit:** $50/month for bike maintenance/gear
        - **Repair stand:** Located in bike cage with basic tools
        - **Air pump:** Free to use at cage entrance

        **How to Claim Bike Subsidy:**
        Submit receipt in Concur with expense type "Commuter - Bike"

        **Safety:**
        - Register your bike with campus security (photo + serial number)
        - We have Kryptonite U-locks available for checkout
        - Report any suspicious activity immediately

        **Community:**
        Join #bike-commuters Slack! People share route tips, form ride groups, and warn about weather/road conditions.
      ANSWER
      votes: 33,
      correct: true
    }
  ],
  created_ago: 11.days
)

# Visitor parking question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["charles.allen@example.com"],
  title: "Client visiting - how do I arrange visitor parking?",
  body: <<~BODY,
    I have an important client visiting next Tuesday. How do I make sure they have parking when they arrive?

    - Can I reserve a spot for them?
    - How do they get in the gate?
    - Is there a cost?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["tony.russo@example.com"],
      body: <<~ANSWER,
        Good thinking to plan ahead! Here's how visitor parking works:

        **Reserving Visitor Parking:**
        1. Go to ServiceNow > Facilities > Visitor Parking Request
        2. Enter:
           - Visitor name
           - Company
           - Date and expected arrival time
           - Your name as host
           - Duration (half day/full day)
        3. Submit at least 24 hours in advance

        **What Your Visitor Receives:**
        - Confirmation email with instructions
        - Parking code for gate entry
        - Parking spot number

        **Entry Process for Visitors:**
        1. At the gate, press "Visitor" button
        2. Enter code from email
        3. Gate opens, display shows spot number
        4. Park in designated visitor area (near lobby)

        **Cost:**
        - **Free** for business visitors (billed to your department)
        - Daily rate: $15 if not pre-registered (visitor pays)

        **VIP/Executive Visitors:**
        For C-level visitors or important clients:
        - Request "VIP" designation in ServiceNow
        - They get a reserved spot closest to entrance
        - Meet-and-greet option (security escorts them in)

        **Day-of Issues:**
        If visitor forgot the code or it's not working:
        - Have them use the call box
        - Gate attendant can look up by name
        - You can also go down and escort them in

        **For Next Tuesday:**
        Submit the request today and you're all set! Your client will get the email automatically.
      ANSWER
      votes: 27,
      correct: true
    }
  ],
  created_ago: 5.days
)

# Carpool question
create_qa(
  space: parking_space,
  author: SEED_BUSINESS_EMPLOYEES["dorothy.green@example.com"],
  title: "How does the carpool program work? Looking for a carpool buddy",
  body: <<~BODY,
    I live in the suburbs and would love to carpool to save money and get a better parking spot.

    - How does the company carpool program work?
    - How do I find people near me?
    - What are the benefits?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["robert.jenkins@example.com"],
      body: <<~ANSWER,
        Carpooling is great - for you AND the planet! Here's the program:

        **Carpool Benefits:**

        | Benefit | Details |
        |---------|---------|
        | Reserved parking | Front-row spots guaranteed |
        | Skip waitlist | Immediate access to garage |
        | Reduced cost | Split parking fee (or company waives for 3+) |
        | Commuter bonus | Extra $50/month pretax benefit |

        **Requirements:**
        - Minimum 3 days/week carpooling
        - 2+ employees registered
        - Live within reasonable distance of each other
        - Log carpool trips in app (honor system)

        **Finding Carpool Partners:**

        1. **Official matching:**
           - Go to the Commuter portal on intranet
           - Enter your home address (kept private)
           - System suggests potential matches
           - You can view match by neighborhood, not exact address

        2. **Slack channel:**
           - #carpool-matching
           - Post your general area and schedule
           - Many matches happen here!

        3. **Commute map:**
           - Facilities has a heat map of where employees live
           - Request a neighborhood report

        **How to Register:**
        1. Find your carpool partner(s)
        2. Both submit Carpool Registration in ServiceNow
        3. Include: names, schedules, primary driver
        4. Receive carpool permit within 3 days

        **Flexibility:**
        - You don't have to carpool every day (3/5 minimum)
        - If partner is sick/traveling, you can still use the spot
        - Can have rotating drivers

        **Pro Tip:**
        Even alternating days works - e.g., you drive Mon/Wed, partner drives Tue/Thu, Fridays flexible.
      ANSWER
      votes: 29,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
      body: <<~ANSWER,
        I found my carpool buddy on #carpool-matching! We live 10 min apart and alternate driving weeks.

        Unexpected benefit: we've become good friends and the commute time flies by now. Highly recommend!

        Also - we split gas costs through Splitwise app. Makes it easy to track.
      ANSWER
      votes: 16,
      correct: false
    }
  ],
  created_ago: 8.days
)

puts "  Created Parking questions"
