# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Office Services Space
# =============================================================================
puts "Creating Office Services questions..."

office_space = Space.find_by!(slug: "office-services")

# Office supplies question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["ruth.nelson@example.com"],
  title: "Where do I get office supplies? Need pens, notebooks, etc.",
  body: <<~BODY,
    I'm out of pens and could use some sticky notes. Where do we get office supplies from?

    Also - is there a limit on what I can take?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["jason.reed@example.com"],
      body: <<~ANSWER,
        Office supplies are easy to get! Here's how:

        **Supply Closets:**
        - Building A: 2nd floor, near kitchen (Room 204)
        - Building B: 1st floor, by the copy room (Room 108)
        - Both are stocked with common items

        **What's Available (self-serve):**
        - Pens, pencils, highlighters
        - Sticky notes, notepads
        - Staplers, tape, scissors
        - Folders, binders, labels
        - Paper clips, rubber bands
        - Whiteboard markers

        **For Larger Orders:**
        If you need bulk items or something not stocked:
        1. Submit request in ServiceNow > Office Services > Supplies Request
        2. We order from Staples (next-day delivery)
        3. Items delivered to your desk or mail stop

        **Special Items:**
        - Ergonomic supplies (wrist rests, etc.): Go through Facilities
        - Tech accessories (cables, adapters): Go through IT
        - Branded items (swag): Go through Marketing

        **Limits:**
        - No formal limits for reasonable personal use
        - Don't take home or resell (yes, it's happened 😅)
        - Large quantities (100+ of same item): Please request via ServiceNow

        **Out of Something?**
        If the supply closet is missing something, Slack #office-services or email me. I restock weekly and can add items based on demand.

        Take what you need! We want you to have the tools to be productive.
      ANSWER
      votes: 24,
      correct: true
    }
  ],
  created_ago: 6.days
)

# Mail/packages question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["joe.scott@example.com"],
  title: "Can I have personal packages delivered to the office?",
  body: <<~BODY,
    I work from home sometimes and package thieves are a problem in my neighborhood.

    Can I have Amazon/personal packages shipped here? What's the policy?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["kevin.murphy@example.com"],
      body: <<~ANSWER,
        Good question! Here's our package policy:

        **Personal Package Delivery:**
        ✅ **Yes, allowed** with some guidelines:
        - Use your name + department + "Building A" (or B)
        - Example: "John Smith - Marketing, Building A, 123 Main St..."
        - We'll notify you via Slack when it arrives

        **Mail Room Hours:**
        - Receiving: 8 AM - 5 PM Monday-Friday
        - Package pickup: 8 AM - 6 PM Monday-Friday
        - Location: Building A, Ground floor, Room G15

        **Guidelines:**
        - Pick up within 2 business days (we have limited space!)
        - No oversized items (furniture, large appliances)
        - No perishables (unless you're picking up same-day)
        - No live animals (it's happened... please don't)
        - No hazardous materials

        **Notifications:**
        You'll get a Slack message from @mailroom-bot when your package arrives. Reply with "picked up" to clear it from the system.

        **Sending Packages:**
        - Personal outbound: You can use the mail room for drop-off (not shipping on company account)
        - Business outbound: Submit Shipping Request in ServiceNow for FedEx/UPS pickup

        **During WFH Days:**
        - We'll hold packages for you
        - If urgent, ask a colleague to grab it
        - We can forward to your home ($5 handling fee + shipping)

        **Holiday Season:**
        We get SLAMMED in December. Please be extra prompt picking up to help us manage space!
      ANSWER
      votes: 31,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["linda.garcia@example.com"],
      body: <<~ANSWER,
        I use this all the time! Pro tip: put your phone number on the shipping label too. Delivery drivers sometimes call if they can't find the loading dock.

        Also - the mail room folks are awesome. They've held packages for me when I was traveling and even wrapped one as a gift once!
      ANSWER
      votes: 12,
      correct: false
    }
  ],
  created_ago: 10.days
)

# Catering question
create_qa(
  space: office_space,
  author: SEED_PMO_STAFF["nicole.adams@example.com"],
  title: "How do I order catering for a meeting?",
  body: <<~BODY,
    I'm hosting a lunch meeting for 15 people next week. How do I order food?

    - Is there a preferred caterer?
    - What's the lead time?
    - Budget limits?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        Happy to help with catering! Here's the process:

        **How to Order:**
        1. Go to **CaterCow** portal (link on intranet under Quick Links)
        2. Select date, time, location, headcount
        3. Browse menus from approved vendors
        4. Submit order (routes to your manager for approval)

        **Approved Vendors (negotiated rates):**
        - **Everyday meetings:** Panera, Chipotle, Corner Bakery
        - **Client/special events:** Local caterer (varies by location)
        - **Pizza/casual:** Domino's, Papa John's, local options

        **Lead Times:**
        - Standard orders: **3 business days** minimum
        - Large events (50+): **1 week** minimum
        - Rush orders (<3 days): Call Office Services directly

        **Budget Guidelines:**

        | Meal Type | Per Person Budget |
        |-----------|-------------------|
        | Breakfast | $15 |
        | Lunch | $20 |
        | Dinner | $35 |
        | Snacks/coffee | $10 |

        Budgets are guidelines - client meetings or special occasions can go higher with manager approval.

        **Setup & Cleanup:**
        - Delivery to your meeting room is included
        - Basic setup (layout, napkins, utensils) included
        - Full-service setup (plating, cleanup): Additional fee

        **Dietary Restrictions:**
        CaterCow tracks common restrictions. You'll see options for:
        - Vegetarian/Vegan
        - Gluten-free
        - Kosher/Halal
        - Allergies (nuts, dairy, etc.)

        **Your 15-Person Lunch:**
        I'd recommend Panera or Chipotle bowls for that size - easy to customize for dietary needs and within budget. Order by Thursday for next-week Tuesday!
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 4.days
)

# Printing question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["charles.allen@example.com"],
  title: "How do I print? Printers keep asking for a code",
  body: <<~BODY,
    I tried to print something and the printer is asking for a code. What code?

    Also, where's the color printer?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["jason.reed@example.com"],
      body: <<~ANSWER,
        The printers use "secure print" to prevent paper waste and protect sensitive documents. Here's how it works:

        **Setting Up Secure Print:**
        1. First time: Install printer driver from IT self-service portal
        2. Set your PIN: IT will email you initial PIN, or set in printer web interface
        3. Your PIN is a 4-6 digit code you choose

        **Printing Process:**
        1. Print from your computer like normal
        2. Go to any printer on the floor
        3. Tap badge or enter PIN
        4. Select your print job from queue
        5. Hit "Print" (or "Print All")

        Jobs not printed within 24 hours are automatically deleted.

        **Printer Locations:**

        **Building A:**
        - 2nd floor: Copy room (B&W + Color)
        - 3rd floor: Kitchen area (B&W only)
        - 4th floor: Copy room (B&W + Color + Large format)

        **Building B:**
        - 1st floor: Near reception (B&W + Color)
        - 2nd floor: Copy room (B&W only)

        **Color Printing:**
        - Available at locations marked above
        - Select "Color" in print dialog
        - Slightly more expensive (charged to department)

        **Large/Professional Print Jobs:**
        For presentations, posters, or bulk printing:
        - Submit Print Request in ServiceNow
        - We can do binding, laminating, large format
        - Usually 1-2 day turnaround

        **Stuck Job or Error?**
        - Check paper tray (usually the issue)
        - Try a different printer
        - Slack #it-help if it's a technical problem
      ANSWER
      votes: 22,
      correct: true
    }
  ],
  created_ago: 12.days
)

# Lost and found question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["margaret.king@example.com"],
  title: "Lost my AirPods in the office - is there a lost and found?",
  body: <<~BODY,
    I think I left my AirPods in a conference room yesterday but can't remember which one. Is there a lost and found?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        Yes! We have a lost and found process. Here's how to check:

        **Lost and Found Locations:**
        - Building A: Security desk, main lobby
        - Building B: Office Services desk, 1st floor

        **What to Do:**
        1. First, check the conference room(s) you used - sometimes items are still there
        2. Check with security desk - most found items end up there within 24 hours
        3. Submit Lost Item Report in ServiceNow (helps us look out for it)

        **For AirPods Specifically:**
        - Use "Find My" app to see last known location
        - Play a sound if they're nearby
        - This has helped us locate many lost items!

        **What Happens to Found Items:**
        - Cleaning crew finds item → turned into security
        - Security logs item with date, location, description
        - Items held for **30 days**
        - Unclaimed items after 30 days: donated or disposed

        **Tip:**
        Check "Find My" RIGHT NOW while they might still be in range. If you can narrow down the room, I can have someone check immediately.

        Also - label your AirPods case! A small label with your email helps us return items faster.

        Hope you find them!
      ANSWER
      votes: 19,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
      body: <<~ANSWER,
        Lost my AirPods last month too! The "Find My" app showed they were still in the building. Security helped me narrow it down to the 3rd floor kitchen - they'd fallen between couch cushions.

        Pro tip: Check under chair cushions and between seat/back of conference chairs. Common hiding spots!
      ANSWER
      votes: 11,
      correct: false
    }
  ],
  created_ago: 2.days
)

# Notary question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["paul.adams@example.com"],
  title: "Does the company have a notary? Need something notarized for my house closing",
  body: <<~BODY,
    I'm closing on a house next week and need some documents notarized. I heard the company might have a notary?

    Is this a thing? Or do I need to go to UPS/bank?
  BODY
  answers: [
    {
      author: SEED_TRAVEL_STAFF["diane.cooper@example.com"],
      body: <<~ANSWER,
        Yes! We have notary services available in-house. 🎉

        **In-House Notaries:**
        - Building A: Me! (Diane Cooper, Executive Admin, 4th floor)
        - Building B: Reception desk (Sarah) - available M/W/F

        **How It Works:**
        1. Bring your documents and valid photo ID
        2. Walk-ins welcome, but scheduling ensures I'm at my desk
        3. Do NOT sign the documents beforehand - you sign in front of the notary

        **What You'll Need:**
        - The documents to be notarized
        - Government-issued photo ID (driver's license, passport)
        - Any witnesses required (rare, but check your docs)
        - Know the date of the document if pre-dated

        **Cost:**
        - **Free** for employees (personal or work documents)
        - Limit: 10 documents per visit (for sanity)

        **Scheduling:**
        - Slack me @diane.cooper or email
        - Put 15-30 min on my calendar (I'll accept)
        - Best availability: Mid-morning or early afternoon

        **Can't Do:**
        - Documents in languages I can't read (get translated version)
        - Blank documents or incomplete forms
        - Anything illegal (obviously!)

        **For Your House Closing:**
        Mortgage docs often need multiple notarizations. Block 30 min with me and bring everything at once. Congrats on the new house!
      ANSWER
      votes: 35,
      correct: true
    }
  ],
  created_ago: 7.days
)

# Kitchen etiquette question
create_qa(
  space: office_space,
  author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
  title: "Kitchen etiquette - who cleans the shared fridge? My lunch keeps getting thrown out",
  body: <<~BODY,
    Twice now I've come back to find my lunch gone from the fridge. It wasn't expired!

    What's the policy on fridge cleanouts? How do I prevent this?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        Sorry about your lunch! Here's the fridge policy and how to protect your food:

        **Fridge Cleanout Schedule:**
        - **Every Friday at 5 PM** fridges are cleaned out
        - All unmarked/undated items are discarded
        - Anything that looks spoiled is removed regardless of date

        **How to Protect Your Food:**
        1. **Label it!** Put your name + date on container
        2. Labels are available in the kitchen supply drawer
        3. Use clear containers so contents are visible
        4. Take items home Friday if you won't use them

        **Why We Clean Weekly:**
        - Prevents science experiments 🧪
        - Makes room for everyone
        - Health and safety requirement

        **Fridge Etiquette:**
        ✅ Label everything
        ✅ Take your stuff home Friday
        ✅ Clean up spills immediately
        ✅ Throw away your own leftovers when done

        ❌ Don't take others' food (it happens - please don't)
        ❌ Don't leave food for weeks
        ❌ Don't put smelly food uncovered (sorry, no fish in microwave!)
        ❌ Don't hog freezer space

        **If Food Goes Missing (not during cleanout):**
        - Unfortunately, food theft does happen
        - Consider an insulated lunch bag at your desk
        - Label clearly "DO NOT TAKE"
        - Report chronic issues to Office Services

        **Mystery Food:**
        Unlabeled items that look fresh are put on the "Free Food" counter Friday morning. Check there if something went missing recently!
      ANSWER
      votes: 27,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["dorothy.green@example.com"],
      body: <<~ANSWER,
        I started using a small insulated lunchbox at my desk - keeps things cold until lunch and I never worry about fridge space or cleanouts.

        Also, there's a "Community Food" shelf in the kitchen for things people want to share. Check there - sometimes there are surprise treats!
      ANSWER
      votes: 14,
      correct: false
    }
  ],
  created_ago: 5.days
)

puts "  Created Office Services questions"
