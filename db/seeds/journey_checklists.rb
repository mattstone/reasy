# frozen_string_literal: true

# Seed file for Journey Checklists
# Run with: rails runner db/seeds/journey_checklists.rb

puts "Seeding Journey Checklists..."

# ============================================================================
# BUYER CHECKLIST
# ============================================================================
buyer_checklist = JourneyChecklist.find_or_create_by!(journey_type: "buyer", name: "Property Buyer Journey") do |c|
  c.description = "Your complete guide to buying property in Australia. Follow these steps to ensure nothing is missed."
  c.position = 1
  c.active = true
end

buyer_items = [
  # Pre-Offer Phase
  {
    key: "buyer_complete_profile",
    title: "Complete Your Buyer Profile",
    description: "Set up your buyer profile with your preferences, budget, and requirements.",
    help_text: "Your profile helps us match you with suitable properties and gives sellers confidence in your offer.",
    why_important: "A complete profile shows sellers you're a serious buyer and helps Reasy recommend properties that truly match your needs.",
    points: 15,
    category: "pre_offer",
    position: 1
  },
  {
    key: "buyer_setup_finance",
    title: "Arrange Your Finance",
    description: "Get pre-approval from a lender or confirm your cash position.",
    help_text: "Pre-approval shows sellers you can afford the property. For cash buyers, have proof of funds ready.",
    why_important: "Finance is the #1 reason property deals fall through. Getting this sorted first gives you confidence and makes your offer stronger.",
    points: 25,
    category: "pre_offer",
    position: 2,
    requires_document: true,
    document_types: ["pre_approval"]
  },
  {
    key: "buyer_engage_conveyancer",
    title: "Engage a Conveyancer or Solicitor",
    description: "Find a licensed conveyancer or solicitor to handle your legal matters.",
    help_text: "Your conveyancer will review contracts, conduct searches, and guide you through settlement.",
    why_important: "Property law is complex. A good conveyancer protects your interests and ensures everything is legally sound.",
    points: 20,
    category: "pre_offer",
    position: 3,
    requires_service_provider: true,
    service_provider_types: ["conveyancer", "solicitor"]
  },
  {
    key: "buyer_research_suburbs",
    title: "Research Your Target Suburbs",
    description: "Use Reasy Score to understand suburb demographics, growth potential, and safety.",
    help_text: "Check crime rates, school ratings, transport links, and price trends for areas you're interested in.",
    why_important: "Buying in the right suburb can mean hundreds of thousands in value growth. Research now pays dividends for years.",
    points: 15,
    category: "pre_offer",
    position: 4
  },
  {
    key: "buyer_create_search_alerts",
    title: "Set Up Search Alerts",
    description: "Create saved searches to get notified when matching properties are listed.",
    help_text: "Don't miss out on your dream property. Alerts ensure you see new listings first.",
    why_important: "In hot markets, properties sell fast. Being first to know gives you a competitive advantage.",
    points: 10,
    category: "pre_offer",
    position: 5
  },

  # Property Evaluation Phase
  {
    key: "buyer_view_property",
    title: "Inspect the Property",
    description: "Visit the property in person to assess its condition and suitability.",
    help_text: "Look beyond the staging. Check for issues like dampness, structural problems, and noise.",
    why_important: "Photos never tell the full story. An in-person inspection reveals details that affect your daily life and the property's true value.",
    points: 15,
    category: "property_evaluation",
    position: 6
  },
  {
    key: "buyer_request_contract",
    title: "Request the Contract of Sale",
    description: "Ask the agent or seller for a copy of the contract of sale.",
    help_text: "This document contains all the legal terms of the sale including special conditions.",
    why_important: "Understanding the contract before you offer prevents nasty surprises. Some contracts contain clauses that significantly affect your rights.",
    points: 10,
    category: "property_evaluation",
    position: 7,
    requires_document: true,
    document_types: ["contract"]
  },
  {
    key: "buyer_ai_contract_analysis",
    title: "Get AI Contract Analysis",
    description: "Have your AI assistant analyze the contract for unusual clauses and risks.",
    help_text: "Our AI scans the contract and flags anything unusual compared to standard contracts.",
    why_important: "Contract language can hide risks. AI analysis gives you a head start in understanding what you're signing.",
    points: 20,
    category: "property_evaluation",
    position: 8,
    required_for_next: "buyer_request_contract"
  },
  {
    key: "buyer_review_section32",
    title: "Review Section 32/Vendor Statement",
    description: "Review the vendor's disclosure document for property information.",
    help_text: "This document reveals important information about the property including encumbrances, zoning, and services.",
    why_important: "The Section 32 contains legally required disclosures. Missing something here could cost you dearly.",
    points: 15,
    category: "property_evaluation",
    position: 9,
    requires_document: true,
    document_types: ["section_32", "zoning_certificate"]
  },
  {
    key: "buyer_order_building_inspection",
    title: "Order Building Inspection",
    description: "Engage a qualified building inspector to assess the property's structural condition.",
    help_text: "A building inspection reveals hidden defects like structural issues, termite damage, and maintenance problems.",
    why_important: "Major building defects can cost tens of thousands to fix. A few hundred dollars for an inspection could save you from a money pit.",
    points: 20,
    category: "property_evaluation",
    position: 10,
    requires_service_provider: true,
    service_provider_types: ["building_inspector"],
    requires_document: true,
    document_types: ["building_report"]
  },
  {
    key: "buyer_order_pest_inspection",
    title: "Order Pest Inspection",
    description: "Engage a pest inspector to check for termites and other pest issues.",
    help_text: "Termites cause billions in damage annually. Early detection is critical.",
    why_important: "Termite damage isn't always visible and isn't covered by insurance. This inspection is essential protection.",
    points: 20,
    category: "property_evaluation",
    position: 11,
    requires_service_provider: true,
    service_provider_types: ["pest_inspector"],
    requires_document: true,
    document_types: ["pest_report"]
  },
  {
    key: "buyer_conveyancer_contract_review",
    title: "Get Conveyancer Contract Review",
    description: "Have your conveyancer review the contract and advise on any concerns.",
    help_text: "Your conveyancer provides professional legal advice on the contract terms and conditions.",
    why_important: "Legal professionals catch things you might miss. Their advice protects you from signing unfavorable terms.",
    points: 20,
    category: "property_evaluation",
    position: 12,
    required_for_next: "buyer_engage_conveyancer"
  },

  # Offer Phase
  {
    key: "buyer_submit_offer",
    title: "Submit Your Offer",
    description: "Prepare and submit your formal offer to purchase the property.",
    help_text: "Include your offer price, deposit amount, settlement period, and any conditions.",
    why_important: "This is the moment you stake your claim. A well-structured offer shows you're serious and professional.",
    points: 25,
    category: "offer",
    position: 13
  },
  {
    key: "buyer_negotiate_terms",
    title: "Negotiate Terms (if needed)",
    description: "Work through any counter-offers to reach an agreement.",
    help_text: "Negotiation is normal. Stay calm and focus on what matters most to you.",
    why_important: "Good negotiation can save you thousands or secure better terms. It's worth taking your time to get it right.",
    points: 15,
    category: "offer",
    position: 14
  },
  {
    key: "buyer_offer_accepted",
    title: "Offer Accepted",
    description: "Congratulations! Your offer has been accepted by the seller.",
    help_text: "This triggers the formal transaction process including the cooling-off period.",
    why_important: "You're now in contract! This milestone marks the beginning of your journey to ownership.",
    points: 50,
    category: "offer",
    position: 15
  },

  # Due Diligence Phase (Cooling-Off)
  {
    key: "buyer_finance_approved",
    title: "Finance Formally Approved",
    description: "Receive formal unconditional approval from your lender.",
    help_text: "This is different from pre-approval. Formal approval means the lender has approved THIS specific purchase.",
    why_important: "Without formal approval, you may need to terminate and lose your deposit. This confirms you can definitely proceed.",
    points: 25,
    category: "due_diligence",
    position: 16
  },
  {
    key: "buyer_building_passed",
    title: "Building Inspection Passed",
    description: "Review your building inspection report and confirm you're satisfied.",
    help_text: "Discuss any issues found with your inspector. Decide if they're acceptable or need negotiation.",
    why_important: "This is your last chance to identify major structural issues before you're locked in.",
    points: 20,
    category: "due_diligence",
    position: 17
  },
  {
    key: "buyer_pest_passed",
    title: "Pest Inspection Passed",
    description: "Review your pest inspection report and confirm you're satisfied.",
    help_text: "Check for any active termite issues or evidence of past problems.",
    why_important: "Pest issues can escalate quickly. Knowing the property is clear gives you peace of mind.",
    points: 20,
    category: "due_diligence",
    position: 18
  },
  {
    key: "buyer_strata_reviewed",
    title: "Strata Report Reviewed (if applicable)",
    description: "Review the strata report for units, apartments, or townhouses.",
    help_text: "Check for special levies, disputes, building defects, and financial health of the body corporate.",
    why_important: "Strata issues can mean unexpected costs of tens of thousands. The strata report reveals the true picture.",
    points: 15,
    category: "due_diligence",
    position: 19,
    requires_document: true,
    document_types: ["strata_report"]
  },
  {
    key: "buyer_final_conveyancer_signoff",
    title: "Final Conveyancer Sign-Off",
    description: "Get final confirmation from your conveyancer that all searches and checks are satisfactory.",
    help_text: "Your conveyancer confirms title is clear and all legal requirements are met.",
    why_important: "This professional confirmation ensures you're making a sound legal purchase.",
    points: 20,
    category: "due_diligence",
    position: 20
  },

  # Settlement Phase
  {
    key: "buyer_deposit_paid",
    title: "Pay Full Deposit",
    description: "Pay the agreed deposit (typically 10%) to the trust account.",
    help_text: "The deposit is held in trust until settlement. It shows your commitment to the purchase.",
    why_important: "Paying your deposit demonstrates commitment and triggers the countdown to your new home.",
    points: 25,
    category: "settlement",
    position: 21
  },
  {
    key: "buyer_pre_settlement_inspection",
    title: "Pre-Settlement Inspection",
    description: "Conduct a final inspection before settlement to ensure the property is as expected.",
    help_text: "Check that fixtures are intact, nothing is damaged, and any agreed repairs are complete.",
    why_important: "This is your last chance to identify issues before you take ownership. Don't skip it!",
    points: 15,
    category: "settlement",
    position: 22
  },
  {
    key: "buyer_settlement_complete",
    title: "Settlement Complete - Collect Keys!",
    description: "Settlement is done! Collect your keys and welcome to your new home!",
    help_text: "Your conveyancer will confirm when settlement is complete. Then it's time to celebrate!",
    why_important: "You did it! You're now a property owner. This is the culmination of all your hard work.",
    points: 100,
    category: "settlement",
    position: 23
  }
]

buyer_items.each do |item|
  ChecklistItem.find_or_create_by!(journey_checklist: buyer_checklist, key: item[:key]) do |ci|
    ci.title = item[:title]
    ci.description = item[:description]
    ci.help_text = item[:help_text]
    ci.why_important = item[:why_important]
    ci.points = item[:points]
    ci.category = item[:category]
    ci.position = item[:position]
    ci.required_for_next = item[:required_for_next]
    ci.requires_document = item[:requires_document] || false
    ci.document_types = item[:document_types] || []
    ci.requires_service_provider = item[:requires_service_provider] || false
    ci.service_provider_types = item[:service_provider_types] || []
  end
end

puts "  Created #{buyer_items.count} buyer checklist items"

# ============================================================================
# SELLER CHECKLIST
# ============================================================================
seller_checklist = JourneyChecklist.find_or_create_by!(journey_type: "seller", name: "Property Seller Journey") do |c|
  c.description = "Your complete guide to selling property in Australia. Follow these steps for a smooth sale."
  c.position = 1
  c.active = true
end

seller_items = [
  # Pre-Listing Phase
  {
    key: "seller_complete_profile",
    title: "Complete Your Seller Profile",
    description: "Set up your seller profile with your preferences and requirements.",
    help_text: "Your profile helps buyers understand what you're looking for in terms of settlement and conditions.",
    why_important: "A complete profile helps serious buyers submit offers that match your needs, saving everyone time.",
    points: 15,
    category: "pre_listing",
    position: 1
  },
  {
    key: "seller_engage_conveyancer",
    title: "Engage a Conveyancer or Solicitor",
    description: "Find a licensed conveyancer or solicitor to prepare your contract and handle settlement.",
    help_text: "They'll prepare the contract of sale and ensure all legal requirements are met.",
    why_important: "Starting with a conveyancer ensures your contract is legally sound and protects your interests from day one.",
    points: 20,
    category: "pre_listing",
    position: 2,
    requires_service_provider: true,
    service_provider_types: ["conveyancer", "solicitor"]
  },
  {
    key: "seller_obtain_valuation",
    title: "Get a Property Valuation",
    description: "Understand your property's market value with a professional valuation or market appraisal.",
    help_text: "Compare valuations from multiple sources to set a realistic price expectation.",
    why_important: "Pricing correctly from the start attracts more buyers and leads to faster sales at better prices.",
    points: 20,
    category: "pre_listing",
    position: 3
  },
  {
    key: "seller_gather_documents",
    title: "Gather Property Documents",
    description: "Collect all relevant property documents including title, surveys, and certificates.",
    help_text: "Having documents ready speeds up the sale process and builds buyer confidence.",
    why_important: "Missing documents slow down sales and can make buyers nervous. Being organized shows you're a serious seller.",
    points: 15,
    category: "pre_listing",
    position: 4,
    requires_document: true,
    document_types: ["title_search", "survey", "zoning_certificate"]
  },
  {
    key: "seller_prepare_contract",
    title: "Prepare Contract of Sale",
    description: "Work with your conveyancer to prepare the contract of sale.",
    help_text: "The contract includes the terms of sale, special conditions, and required disclosures.",
    why_important: "A well-prepared contract protects you legally and prevents delays during negotiation.",
    points: 25,
    category: "pre_listing",
    position: 5,
    requires_document: true,
    document_types: ["contract", "section_32"]
  },
  {
    key: "seller_professional_photos",
    title: "Get Professional Photography",
    description: "Arrange for professional property photography.",
    help_text: "Professional photos make your property stand out online and attract more buyers.",
    why_important: "First impressions matter. Properties with professional photos sell faster and often for more money.",
    points: 15,
    category: "pre_listing",
    position: 6
  },
  {
    key: "seller_property_presentation",
    title: "Prepare Property for Sale",
    description: "Declutter, clean, and stage your property for inspections.",
    help_text: "Consider professional staging or at least thorough cleaning and minor repairs.",
    why_important: "Presentation dramatically affects buyer perception. A well-presented home can add thousands to your sale price.",
    points: 15,
    category: "pre_listing",
    position: 7
  },

  # Listing Phase
  {
    key: "seller_property_listed",
    title: "Property Listed and Active",
    description: "Your property is now live on Reasy and ready for buyers!",
    help_text: "Monitor your listing performance and adjust if needed.",
    why_important: "You're now on the market! Every view is a potential buyer discovering your property.",
    points: 25,
    category: "listing",
    position: 8
  },
  {
    key: "seller_open_home_scheduled",
    title: "Schedule Open Homes",
    description: "Set up open home inspection times for potential buyers.",
    help_text: "Regular open homes give buyers the opportunity to experience your property in person.",
    why_important: "Open homes create urgency and competition. Multiple buyers at once can drive up your sale price.",
    points: 15,
    category: "listing",
    position: 9
  },
  {
    key: "seller_enquiries_responded",
    title: "Respond to Enquiries",
    description: "Promptly respond to buyer enquiries and questions.",
    help_text: "Quick responses keep buyers engaged and show you're a motivated seller.",
    why_important: "Buyers are often looking at multiple properties. Fast responses keep yours top of mind.",
    points: 10,
    category: "listing",
    position: 10
  },

  # Offer Phase
  {
    key: "seller_offer_received",
    title: "Receive an Offer",
    description: "A buyer has submitted a formal offer on your property.",
    help_text: "Review the offer carefully including price, conditions, and settlement terms.",
    why_important: "This is a significant moment. Someone wants to buy your property!",
    points: 25,
    category: "offer",
    position: 11
  },
  {
    key: "seller_counter_offer",
    title: "Counter-Offer (if needed)",
    description: "Negotiate with the buyer to reach mutually agreeable terms.",
    help_text: "Don't be afraid to counter. Most buyers expect some negotiation.",
    why_important: "Skillful negotiation can add thousands to your final price. Take your time to get it right.",
    points: 15,
    category: "offer",
    position: 12
  },
  {
    key: "seller_offer_accepted",
    title: "Accept an Offer",
    description: "You've accepted an offer! The property is now under contract.",
    help_text: "This triggers the cooling-off period and begins the settlement countdown.",
    why_important: "You've found your buyer! This milestone marks the beginning of the end of your selling journey.",
    points: 50,
    category: "offer",
    position: 13
  },

  # Settlement Phase
  {
    key: "seller_buyer_conditions_satisfied",
    title: "Buyer's Conditions Satisfied",
    description: "The buyer has satisfied all their conditions (finance, inspections, etc.).",
    help_text: "Once conditions are satisfied, the contract becomes unconditional.",
    why_important: "This is when the sale becomes rock-solid. The biggest risks are now behind you.",
    points: 25,
    category: "settlement",
    position: 14
  },
  {
    key: "seller_cooling_off_complete",
    title: "Cooling-Off Period Complete",
    description: "The statutory cooling-off period has ended.",
    help_text: "The buyer can no longer rescind without significant penalty.",
    why_important: "You're now past the point where the buyer can easily walk away. The sale is increasingly certain.",
    points: 20,
    category: "settlement",
    position: 15
  },
  {
    key: "seller_pre_settlement_access",
    title: "Arrange Pre-Settlement Access",
    description: "Coordinate with the buyer for their pre-settlement inspection.",
    help_text: "Be accommodating with timing and ensure the property is in the agreed condition.",
    why_important: "A smooth pre-settlement inspection builds buyer confidence and prevents last-minute issues.",
    points: 10,
    category: "settlement",
    position: 16
  },
  {
    key: "seller_final_meter_readings",
    title: "Final Utility Meter Readings",
    description: "Take final readings for electricity, gas, and water meters.",
    help_text: "These readings are used to calculate adjustments at settlement.",
    why_important: "Accurate readings ensure fair settlement adjustments. Don't leave money on the table.",
    points: 10,
    category: "settlement",
    position: 17
  },
  {
    key: "seller_settlement_complete",
    title: "Settlement Complete - Handover Keys!",
    description: "Settlement is done! Hand over the keys and receive your funds.",
    help_text: "Your conveyancer will confirm settlement and your funds will be transferred.",
    why_important: "Congratulations! You've successfully sold your property. Time to celebrate and move on to your next adventure!",
    points: 100,
    category: "settlement",
    position: 18
  }
]

seller_items.each do |item|
  ChecklistItem.find_or_create_by!(journey_checklist: seller_checklist, key: item[:key]) do |ci|
    ci.title = item[:title]
    ci.description = item[:description]
    ci.help_text = item[:help_text]
    ci.why_important = item[:why_important]
    ci.points = item[:points]
    ci.category = item[:category]
    ci.position = item[:position]
    ci.required_for_next = item[:required_for_next]
    ci.requires_document = item[:requires_document] || false
    ci.document_types = item[:document_types] || []
    ci.requires_service_provider = item[:requires_service_provider] || false
    ci.service_provider_types = item[:service_provider_types] || []
  end
end

puts "  Created #{seller_items.count} seller checklist items"

# ============================================================================
# SERVICE PROVIDER CHECKLIST - CONVEYANCER
# ============================================================================
conveyancer_checklist = JourneyChecklist.find_or_create_by!(journey_type: "service_provider", name: "Conveyancer Job Checklist") do |c|
  c.description = "Standard checklist for conveyancing services."
  c.position = 1
  c.active = true
end

conveyancer_items = [
  {
    key: "conv_initial_consultation",
    title: "Initial Client Consultation",
    description: "Meet with the client to understand their needs and explain the process.",
    help_text: "Cover fees, timeline, and what they should expect.",
    why_important: "Setting clear expectations upfront leads to smoother transactions and happier clients.",
    points: 15,
    category: "service_delivery",
    position: 1
  },
  {
    key: "conv_contract_review",
    title: "Contract Review Completed",
    description: "Thoroughly review the contract of sale and advise the client.",
    help_text: "Identify any unusual clauses, risks, or concerns.",
    why_important: "Your expertise protects clients from unfavorable contract terms.",
    points: 25,
    category: "service_delivery",
    position: 2
  },
  {
    key: "conv_title_search",
    title: "Title Search Conducted",
    description: "Conduct a title search to verify ownership and encumbrances.",
    help_text: "Check for caveats, mortgages, easements, and covenants.",
    why_important: "Title issues can derail settlements. Early detection is critical.",
    points: 20,
    category: "service_delivery",
    position: 3
  },
  {
    key: "conv_special_conditions_reviewed",
    title: "Special Conditions Reviewed",
    description: "Review and explain all special conditions to the client.",
    help_text: "Ensure the client understands their obligations and rights.",
    why_important: "Clients rely on you to decode legal language into actionable advice.",
    points: 15,
    category: "service_delivery",
    position: 4
  },
  {
    key: "conv_client_advice_provided",
    title: "Client Advice Provided",
    description: "Provide formal written advice on the transaction.",
    help_text: "Document your advice for the client's records.",
    why_important: "Written advice protects both you and the client.",
    points: 20,
    category: "service_delivery",
    position: 5
  },
  {
    key: "conv_contracts_exchanged",
    title: "Contracts Exchanged",
    description: "Facilitate the exchange of contracts between parties.",
    help_text: "Ensure all signatures are complete and copies distributed.",
    why_important: "Exchange is a critical milestone that locks in the sale.",
    points: 25,
    category: "service_delivery",
    position: 6
  },
  {
    key: "conv_deposit_confirmed",
    title: "Deposit Confirmation",
    description: "Confirm receipt of deposit in trust account.",
    help_text: "Issue receipt and notify all parties.",
    why_important: "Proper deposit handling is a legal and ethical requirement.",
    points: 15,
    category: "service_delivery",
    position: 7
  },
  {
    key: "conv_settlement_statement",
    title: "Settlement Statement Prepared",
    description: "Prepare and verify the settlement statement.",
    help_text: "Calculate all adjustments for rates, water, strata, etc.",
    why_important: "Accurate statements ensure fair settlement for all parties.",
    points: 20,
    category: "service_delivery",
    position: 8
  },
  {
    key: "conv_settlement_attended",
    title: "Settlement Attended",
    description: "Attend or facilitate electronic settlement.",
    help_text: "Ensure all documents are in order and funds transfer correctly.",
    why_important: "This is the culmination of your work. Everything must go smoothly.",
    points: 25,
    category: "service_delivery",
    position: 9
  },
  {
    key: "conv_post_settlement",
    title: "Post-Settlement Tasks Complete",
    description: "Complete all post-settlement tasks including transfer registration.",
    help_text: "Lodge transfer documents and confirm registration.",
    why_important: "The job isn't done until the new owner is registered on title.",
    points: 20,
    category: "service_delivery",
    position: 10
  }
]

conveyancer_items.each do |item|
  ChecklistItem.find_or_create_by!(journey_checklist: conveyancer_checklist, key: item[:key]) do |ci|
    ci.title = item[:title]
    ci.description = item[:description]
    ci.help_text = item[:help_text]
    ci.why_important = item[:why_important]
    ci.points = item[:points]
    ci.category = item[:category]
    ci.position = item[:position]
  end
end

puts "  Created #{conveyancer_items.count} conveyancer checklist items"

# ============================================================================
# SERVICE PROVIDER CHECKLIST - BUILDING INSPECTOR
# ============================================================================
inspector_checklist = JourneyChecklist.find_or_create_by!(journey_type: "service_provider", name: "Building Inspector Job Checklist") do |c|
  c.description = "Standard checklist for building inspection services."
  c.position = 2
  c.active = true
end

inspector_items = [
  {
    key: "insp_booking_confirmed",
    title: "Booking Confirmed",
    description: "Confirm inspection booking with client and property access.",
    help_text: "Ensure you have all access details and any specific concerns to check.",
    why_important: "Proper preparation ensures a thorough inspection.",
    points: 10,
    category: "service_delivery",
    position: 1
  },
  {
    key: "insp_exterior_complete",
    title: "Exterior Inspection Complete",
    description: "Complete exterior inspection including roof, walls, and drainage.",
    help_text: "Check for cracks, water damage, roof condition, and guttering.",
    why_important: "Exterior issues often indicate deeper structural problems.",
    points: 20,
    category: "service_delivery",
    position: 2
  },
  {
    key: "insp_interior_complete",
    title: "Interior Inspection Complete",
    description: "Complete interior inspection of all accessible areas.",
    help_text: "Check walls, ceilings, floors, doors, and windows.",
    why_important: "Interior condition affects livability and value.",
    points: 20,
    category: "service_delivery",
    position: 3
  },
  {
    key: "insp_wet_areas_checked",
    title: "Wet Areas Checked",
    description: "Inspect all bathrooms, laundry, and kitchen for water damage.",
    help_text: "Check for leaks, mold, ventilation issues, and waterproofing.",
    why_important: "Wet area problems are common and expensive to fix.",
    points: 15,
    category: "service_delivery",
    position: 4
  },
  {
    key: "insp_subfloor_checked",
    title: "Subfloor/Underhouse Inspected",
    description: "Inspect subfloor area if accessible.",
    help_text: "Check for moisture, ventilation, stumps, and pest evidence.",
    why_important: "Subfloor issues are often invisible but can be serious.",
    points: 15,
    category: "service_delivery",
    position: 5
  },
  {
    key: "insp_roof_space_checked",
    title: "Roof Space Inspected",
    description: "Inspect roof space if accessible.",
    help_text: "Check for insulation, ventilation, leaks, and structural integrity.",
    why_important: "Roof issues can cause cascading problems throughout the home.",
    points: 15,
    category: "service_delivery",
    position: 6
  },
  {
    key: "insp_photos_taken",
    title: "Photographic Evidence Captured",
    description: "Take comprehensive photos of all findings.",
    help_text: "Document any defects with clear photos.",
    why_important: "Photos provide evidence and help clients understand findings.",
    points: 10,
    category: "service_delivery",
    position: 7
  },
  {
    key: "insp_report_prepared",
    title: "Report Prepared",
    description: "Prepare comprehensive written report.",
    help_text: "Include all findings, photos, and recommendations.",
    why_important: "Your report is the deliverable clients are paying for.",
    points: 25,
    category: "service_delivery",
    position: 8
  },
  {
    key: "insp_report_delivered",
    title: "Report Delivered",
    description: "Deliver report to client within agreed timeframe.",
    help_text: "Be available to answer questions about findings.",
    why_important: "Timely delivery is crucial for client's buying decisions.",
    points: 15,
    category: "service_delivery",
    position: 9
  },
  {
    key: "insp_follow_up",
    title: "Client Follow-Up",
    description: "Follow up with client to answer any questions.",
    help_text: "Explain findings and provide guidance on priorities.",
    why_important: "Good service leads to referrals and repeat business.",
    points: 10,
    category: "service_delivery",
    position: 10
  }
]

inspector_items.each do |item|
  ChecklistItem.find_or_create_by!(journey_checklist: inspector_checklist, key: item[:key]) do |ci|
    ci.title = item[:title]
    ci.description = item[:description]
    ci.help_text = item[:help_text]
    ci.why_important = item[:why_important]
    ci.points = item[:points]
    ci.category = item[:category]
    ci.position = item[:position]
  end
end

puts "  Created #{inspector_items.count} building inspector checklist items"

puts "Journey Checklists seeding complete!"
puts "  Total checklists: #{JourneyChecklist.count}"
puts "  Total items: #{ChecklistItem.count}"
