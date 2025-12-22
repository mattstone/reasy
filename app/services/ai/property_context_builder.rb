# frozen_string_literal: true

module AI
  # Builds rich context about a property for AI interactions
  # Includes property details, location insights, market data, and user-specific fit analysis
  class PropertyContextBuilder
    VALUE_ASSESSMENTS = {
      opportunity: "Priced below market - potential opportunity",
      fair: "Fairly priced for the area",
      above_market: "Priced above comparable sales",
      unknown: "Insufficient data to assess value"
    }.freeze

    attr_reader :property, :user

    def initialize(property, user = nil)
      @property = property
      @user = user
    end

    # Build full context hash for AI
    def build
      {
        property: property_details,
        location: location_insights,
        scores: score_details,
        market: market_context,
        user_fit: user_fit_analysis,
        risks: risk_factors,
        opportunities: opportunity_factors
      }
    end

    # Build a natural language summary for AI context
    def to_prompt
      parts = []

      parts << property_summary
      parts << location_summary
      parts << score_summary
      parts << market_summary
      parts << user_fit_summary if @user
      parts << risk_summary if risks_present?
      parts << opportunity_summary if opportunities_present?

      parts.compact.join("\n\n")
    end

    # Quick assessment badges for property cards
    def badges
      badges = []

      # Match score badge (if user provided)
      if @user && (match = match_score)
        badges << { type: :match_score, value: match, label: "#{match}% match" }
      end

      # Value assessment badge
      if (value = value_assessment)
        badges << { type: :value, value: value[:type], label: value[:label] }
      end

      # Reasy score badge
      if (score = @property.reasy_score)
        band = @property.reasy_score_band
        badges << { type: :reasy_score, value: score, band: band, label: "#{score.round} Reasy Score" }
      end

      # Risk badges
      if (risks = critical_risks).any?
        risks.each do |risk|
          badges << { type: :risk, value: risk[:type], label: risk[:short_label] }
        end
      end

      # Opportunity badges
      if (opps = key_opportunities).any?
        opps.each do |opp|
          badges << { type: :opportunity, value: opp[:type], label: opp[:short_label] }
        end
      end

      badges
    end

    private

    # Property Details

    def property_details
      {
        id: @property.id,
        address: @property.full_address,
        short_address: @property.short_address,
        property_type: @property.property_type,
        bedrooms: @property.bedrooms,
        bathrooms: @property.bathrooms,
        parking: @property.parking_spaces,
        land_size_sqm: @property.land_size_sqm,
        building_size_sqm: @property.building_size_sqm,
        year_built: @property.year_built,
        status: @property.status,
        listing_intent: @property.listing_intent,
        price_display: @property.price_range_display,
        price_cents: @property.price_cents,
        features: @property.features,
        description: @property.description&.truncate(500)
      }
    end

    def property_summary
      p = @property
      lines = []

      lines << "Property: #{p.full_address}"
      lines << "Type: #{p.property_type&.humanize}"

      specs = []
      specs << "#{p.bedrooms} bed" if p.bedrooms
      specs << "#{p.bathrooms} bath" if p.bathrooms
      specs << "#{p.parking_spaces} parking" if p.parking_spaces
      lines << "Specs: #{specs.join(', ')}" if specs.any?

      lines << "Price: #{p.price_range_display}"
      lines << "Land: #{p.land_size_sqm}sqm" if p.land_size_sqm
      lines << "Building: #{p.building_size_sqm}sqm" if p.building_size_sqm
      lines << "Built: #{p.year_built}" if p.year_built
      lines << "Status: #{p.status&.humanize}"

      lines.join("\n")
    end

    # Location Insights

    def location_insights
      {
        suburb: @property.suburb,
        state: @property.state,
        postcode: @property.postcode,
        suburb_profile: suburb_profile_summary,
        transport: transport_summary,
        education: education_summary,
        amenities: amenities_summary
      }
    end

    def suburb_profile_summary
      profile = @property.suburb_profile || @property.postcode_profile
      return {} unless profile

      {
        median_house_price: format_price(profile.try(:median_house_price_cents)),
        median_unit_price: format_price(profile.try(:median_unit_price_cents)),
        median_rent: format_rent(profile.try(:median_weekly_rent_cents)),
        population: profile.try(:population),
        median_age: profile.try(:median_age),
        seifa_score: profile.try(:seifa_score)
      }
    end

    def transport_summary
      {
        score: @property.transport_score,
        nearest_train: @property.nearest_train_station,
        train_distance_km: @property.train_station_distance_km,
        stations_5km: @property.train_station_count_5km,
        ferry_distance_km: @property.ferry_wharf_distance_km
      }
    end

    def education_summary
      {
        score: @property.education_score,
        school_count: @property.school_count,
        avg_icsea: @property.avg_school_icsea
      }
    end

    def amenities_summary
      {
        places_of_worship: @property.nearby_places_of_worship(radius_km: 2.0, limit: 5).count
      }
    end

    def location_summary
      lines = []
      lines << "Location: #{@property.suburb}, #{@property.state} #{@property.postcode}"

      if @property.transport_score
        ts = @property.transport_score
        desc = case ts
               when 80..100 then "Excellent"
               when 60..79 then "Good"
               when 40..59 then "Average"
               else "Limited"
        end
        lines << "Transport: #{desc} (#{ts}/100)"
        lines << "  Nearest train: #{@property.nearest_train_station} (#{@property.train_station_distance_km}km)" if @property.nearest_train_station
      end

      if @property.education_score
        lines << "Education: #{@property.education_score}/100 (#{@property.school_count} schools nearby, avg ICSEA #{@property.avg_school_icsea})"
      end

      lines.join("\n")
    end

    # Score Details

    def score_details
      breakdown = @property.score_breakdown || {}

      {
        reasy_score: @property.reasy_score,
        reasy_score_band: @property.reasy_score_band,
        user_weighted_score: @user ? @property.reasy_score_for_user(@user) : nil,
        components: {
          growth: breakdown[:growth_score],
          safety: breakdown[:safety],
          transport: breakdown[:transport],
          hazard: breakdown[:hazard],
          education: breakdown[:education],
          tenant_quality: breakdown[:tenant_quality],
          rental_yield: breakdown[:rental_yield]
        },
        details: breakdown
      }
    end

    def score_summary
      score = @property.reasy_score
      return nil unless score

      lines = []
      band = @property.reasy_score_band
      band_desc = case band
                  when :excellent then "Excellent"
                  when :good then "Good"
                  when :average then "Average"
                  when :below_average then "Below Average"
                  else "Low"
      end

      lines << "Reasy Score: #{score.round}/100 (#{band_desc})"

      if @user && @user.buyer_profile&.using_custom_weights?
        user_score = @property.reasy_score_for_user(@user)
        lines << "Your Weighted Score: #{user_score.round}/100 (based on your priorities)"
      end

      # Key component highlights
      highlights = []
      highlights << "Growth: #{@property.land_value_growth_5yr&.round(1)}% (5yr)" if @property.land_value_growth_5yr
      highlights << "Safety: #{@property.crime_score}/100" if @property.crime_score
      highlights << "Yield: #{@property.rental_yield&.round(2)}%" if @property.rental_yield
      lines << "  " + highlights.join(" | ") if highlights.any?

      lines.join("\n")
    end

    # Market Context

    def market_context
      {
        value_assessment: value_assessment,
        comparable_median: comparable_median,
        price_vs_median: price_vs_median,
        rental_yield: @property.rental_yield,
        estimated_rent: @property.estimated_weekly_rent,
        days_on_market: days_on_market,
        land_growth_1yr: @property.land_value_growth_1yr,
        land_growth_5yr: @property.land_value_growth_5yr
      }
    end

    def value_assessment
      ratio = price_vs_median
      return { type: :unknown, label: "Value unknown" } unless ratio

      if ratio < 0.9
        { type: :opportunity, label: "Below market", ratio: ratio }
      elsif ratio <= 1.1
        { type: :fair, label: "Fair value", ratio: ratio }
      else
        { type: :above_market, label: "Above market", ratio: ratio }
      end
    end

    def comparable_median
      is_unit = @property.property_type.in?(%w[apartment unit townhouse])
      profile = @property.suburb_profile || @property.postcode_profile
      return nil unless profile

      if is_unit
        profile.try(:median_unit_price_cents)
      else
        profile.try(:median_house_price_cents)
      end
    end

    def price_vs_median
      return nil unless @property.price_cents && comparable_median

      @property.price_cents.to_f / comparable_median
    end

    def days_on_market
      return nil unless @property.published_at

      (Date.current - @property.published_at.to_date).to_i
    end

    def market_summary
      lines = []

      assessment = value_assessment
      lines << "Market Position: #{assessment[:label]}"

      if (median = comparable_median)
        lines << "  Area median: #{format_price(median)}"
        lines << "  This property: #{@property.price_range_display}"
      end

      if @property.rental_yield
        lines << "  Rental yield: #{@property.rental_yield.round(2)}%"
        lines << "  Est. weekly rent: $#{@property.estimated_weekly_rent}" if @property.estimated_weekly_rent
      end

      if @property.land_value_growth_5yr
        lines << "  Land value growth (5yr): #{@property.land_value_growth_5yr.round(1)}%"
      end

      lines.join("\n")
    end

    # User Fit Analysis

    def user_fit_analysis
      return {} unless @user&.buyer_profile

      {
        match_score: match_score,
        budget_fit: budget_fit,
        feature_matches: feature_matches,
        feature_gaps: feature_gaps,
        location_fit: location_fit,
        strengths: strengths_for_user,
        considerations: considerations_for_user
      }
    end

    def match_score
      return nil unless @user&.buyer_profile

      scores = []
      weights = []

      # Budget fit (30%)
      if (bf = budget_fit)
        scores << bf[:score]
        weights << 30
      end

      # Location fit (25%)
      if (lf = location_fit)
        scores << lf[:score]
        weights << 25
      end

      # Feature fit (25%)
      fm = feature_matches
      if fm[:total] > 0
        feature_score = (fm[:matched].to_f / fm[:total] * 100).round
        scores << feature_score
        weights << 25
      end

      # Reasy score alignment (20%)
      if @property.reasy_score
        user_weighted = @property.reasy_score_for_user(@user)
        scores << user_weighted
        weights << 20
      end

      return nil if scores.empty?

      total_weight = weights.sum
      weighted_sum = scores.zip(weights).sum { |s, w| s * w }
      (weighted_sum / total_weight).round
    end

    def budget_fit
      profile = @user&.buyer_profile
      return nil unless profile&.budget_min && profile&.budget_max && @property.price_cents

      price = @property.price_cents / 100.0
      min = profile.budget_min
      max = profile.budget_max

      if price < min
        { status: :below, score: 100, message: "Below your minimum budget" }
      elsif price <= max
        # Score higher when closer to min (more room to negotiate)
        range = max - min
        position = (price - min) / range
        score = (100 - position * 30).round # 100 at min, 70 at max
        { status: :in_range, score: score, message: "Within your budget" }
      elsif price <= max * 1.1
        { status: :stretch, score: 50, message: "Slightly above budget (#{((price / max - 1) * 100).round}% over)" }
      else
        { status: :over, score: 20, message: "Above your budget" }
      end
    end

    def feature_matches
      profile = @user&.buyer_profile
      return { matched: 0, missing: [], total: 0 } unless profile&.must_have_features&.any?

      must_haves = profile.must_have_features
      property_features = @property.features || []

      matched = must_haves & property_features
      missing = must_haves - property_features

      {
        matched: matched.count,
        matched_features: matched,
        missing: missing,
        total: must_haves.count
      }
    end

    def feature_gaps
      profile = @user&.buyer_profile
      return [] unless profile

      gaps = []

      # Bedrooms
      if profile.bedrooms_min && @property.bedrooms && @property.bedrooms < profile.bedrooms_min
        gaps << { type: :bedrooms, message: "#{profile.bedrooms_min - @property.bedrooms} fewer bedrooms than preferred" }
      end

      gaps
    end

    def location_fit
      profile = @user&.buyer_profile
      return nil unless profile&.search_areas&.any?

      if profile.search_areas.map(&:upcase).include?(@property.suburb&.upcase)
        { status: :preferred, score: 100, message: "In your preferred areas" }
      else
        { status: :other, score: 60, message: "Not in your preferred areas" }
      end
    end

    def strengths_for_user
      strengths = []
      profile = @user&.buyer_profile

      # Budget
      bf = budget_fit
      strengths << bf[:message] if bf && bf[:status] == :in_range

      # Location
      lf = location_fit
      strengths << lf[:message] if lf && lf[:status] == :preferred

      # Features
      fm = feature_matches
      if fm[:matched] > 0
        strengths << "#{fm[:matched]} of #{fm[:total]} must-have features present"
      end

      # Score highlights
      if @property.reasy_score && @property.reasy_score >= 70
        strengths << "Strong Reasy Score (#{@property.reasy_score.round}/100)"
      end

      # Transport
      if profile&.location_preferences&.dig("near_train_station", "enabled") && @property.train_station_distance_km && @property.train_station_distance_km < 1
        strengths << "Close to train station (#{@property.train_station_distance_km}km)"
      end

      # First home buyer benefits
      if profile&.first_home_buyer && @property.price_cents && @property.price_cents <= 80_000_000
        strengths << "May qualify for First Home Buyer concessions"
      end

      strengths
    end

    def considerations_for_user
      considerations = []

      # Budget concerns
      bf = budget_fit
      if bf && bf[:status].in?([:stretch, :over])
        considerations << bf[:message]
      end

      # Feature gaps
      feature_gaps.each do |gap|
        considerations << gap[:message]
      end

      # Missing features
      fm = feature_matches
      if fm[:missing]&.any?
        considerations << "Missing: #{fm[:missing].map(&:humanize).join(', ')}"
      end

      # Location
      lf = location_fit
      considerations << lf[:message] if lf && lf[:status] == :other

      # Risks
      risk_factors.each do |risk|
        considerations << risk[:message] if risk[:severity] == :high
      end

      considerations
    end

    def user_fit_summary
      return nil unless @user

      lines = []
      score = match_score

      if score
        quality = case score
                  when 80..100 then "Excellent"
                  when 65..79 then "Good"
                  when 50..64 then "Moderate"
                  else "Low"
        end
        lines << "Match Score: #{score}% (#{quality} fit for your criteria)"
      end

      # Strengths
      strengths = strengths_for_user
      if strengths.any?
        lines << "\nStrengths for you:"
        strengths.each { |s| lines << "  + #{s}" }
      end

      # Considerations
      considerations = considerations_for_user
      if considerations.any?
        lines << "\nThings to consider:"
        considerations.each { |c| lines << "  - #{c}" }
      end

      lines.join("\n")
    end

    # Risk Factors

    def risk_factors
      risks = []

      # Natural hazards
      if @property.flood_risk && @property.flood_risk > 50
        risks << { type: :flood, severity: :high, message: "Flood risk area", short_label: "Flood risk" }
      end

      if @property.bushfire_risk && @property.bushfire_risk > 50
        risks << { type: :bushfire, severity: :high, message: "Bushfire prone area", short_label: "Bushfire" }
      end

      if @property.coastal_risk && @property.coastal_risk > 50
        risks << { type: :coastal, severity: :medium, message: "Coastal erosion/inundation risk", short_label: "Coastal" }
      end

      # Crime
      if @property.crime_score && @property.crime_score < 40
        risks << { type: :crime, severity: :medium, message: "Higher than average crime rate", short_label: "High crime" }
      end

      # Market risks
      if @property.land_value_growth_5yr && @property.land_value_growth_5yr < 0
        risks << { type: :growth, severity: :medium, message: "Negative land value growth (#{@property.land_value_growth_5yr.round(1)}% over 5 years)", short_label: "Declining" }
      end

      # Strata/body corporate (inferred from property type)
      if @property.property_type.in?(%w[apartment unit townhouse])
        risks << { type: :strata, severity: :info, message: "Strata property - check levies and sinking fund", short_label: "Strata" }
      end

      risks
    end

    def critical_risks
      risk_factors.select { |r| r[:severity] == :high }
    end

    def risks_present?
      risk_factors.any?
    end

    def risk_summary
      return nil unless risks_present?

      lines = ["Risk Factors:"]
      risk_factors.each do |risk|
        icon = case risk[:severity]
               when :high then "!!"
               when :medium then "!"
               else "i"
        end
        lines << "  [#{icon}] #{risk[:message]}"
      end
      lines.join("\n")
    end

    # Opportunity Factors

    def opportunity_factors
      opportunities = []

      # Value opportunity
      if (va = value_assessment) && va[:type] == :opportunity
        opportunities << { type: :value, message: "Priced below area median", short_label: "Below market" }
      end

      # Strong growth
      if @property.land_value_growth_5yr && @property.land_value_growth_5yr > 10
        opportunities << { type: :growth, message: "Strong land value growth (#{@property.land_value_growth_5yr.round(1)}% over 5 years)", short_label: "High growth" }
      end

      # Good yield
      if @property.rental_yield && @property.rental_yield > 5
        opportunities << { type: :yield, message: "Strong rental yield (#{@property.rental_yield.round(2)}%)", short_label: "High yield" }
      end

      # Top investment area
      if @property.top_investment_area?
        opportunities << { type: :investment, message: "Top investment area (Reasy Score 80+)", short_label: "Top area" }
      end

      # Price reduced (if we track this)
      if @property.respond_to?(:price_reduced?) && @property.price_reduced?
        opportunities << { type: :reduced, message: "Price recently reduced", short_label: "Reduced" }
      end

      opportunities
    end

    def key_opportunities
      opportunity_factors.first(2)
    end

    def opportunities_present?
      opportunity_factors.any?
    end

    def opportunity_summary
      return nil unless opportunities_present?

      lines = ["Opportunities:"]
      opportunity_factors.each do |opp|
        lines << "  + #{opp[:message]}"
      end
      lines.join("\n")
    end

    # Helpers

    def format_price(cents)
      return nil unless cents

      price = cents / 100
      if price >= 1_000_000
        "$#{(price / 1_000_000.0).round(2)}M"
      elsif price >= 1_000
        "$#{(price / 1_000.0).round}K"
      else
        "$#{price}"
      end
    end

    def format_rent(cents)
      return nil unless cents

      "$#{(cents / 100).round}/week"
    end
  end
end
