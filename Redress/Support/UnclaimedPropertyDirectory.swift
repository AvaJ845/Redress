import Foundation

struct UnclaimedPropertySource: Identifiable {
    let id = UUID()
    let state: String
    let urlString: String

    var url: URL? { URL(string: urlString) }
}

/// Unclaimed property (an old refund, a forgotten deposit, an uncashed
/// check — money a state is already holding for you) is a fundamentally
/// different shape of data than a class-action settlement: there's no
/// browsable "open case" to discover, only a per-person name search each
/// state's own government database can answer. That's why this isn't a
/// SwiftData model or an ingestion-engine source — there's nothing to
/// list, version, or upsert. Redress just deep-links to the real official
/// site, same as every other source link in this app; it never searches
/// on your behalf.
///
/// Every URL below is each state/territory's own official government
/// unclaimed-property page — sourced directly from NAUPA's own directory
/// (unclaimed.org, the National Association of Unclaimed Property
/// Administrators), never missingmoney.com (that site blocks direct
/// access — see DATA_SOURCES.md) and never a guessed URL. Live-checked
/// 2026-08-23, not assumed: two (California, Indiana) return 403 to a
/// plain scripted request but load fine in a real browser — normal WAF
/// behavior against non-browser clients, not a dead link, and irrelevant
/// here since this app only opens these via `Link`, which hands off to
/// the user's real browser. Wyoming's URL was found dead and corrected to
/// its real current page. The U.S. Virgin Islands has no live unclaimed-
/// property page under its Lieutenant Governor's office anymore — left
/// out rather than guessed.
enum UnclaimedPropertyDirectory {
    static let sources: [UnclaimedPropertySource] = [
        UnclaimedPropertySource(state: "Alabama", urlString: "https://alabama.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "Alaska", urlString: "http://treasury.dor.alaska.gov/Unclaimed-Property.aspx"),
        UnclaimedPropertySource(state: "Arizona", urlString: "https://azdor.gov/unclaimed-property/"),
        UnclaimedPropertySource(state: "Arkansas", urlString: "https://auditor.ar.gov/"),
        UnclaimedPropertySource(state: "California", urlString: "https://sco.ca.gov/upd_msg.html"),
        UnclaimedPropertySource(state: "Colorado", urlString: "https://colorado.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "Connecticut", urlString: "https://ctbiglist.gov/"),
        UnclaimedPropertySource(state: "Delaware", urlString: "https://unclaimedproperty.delaware.gov/"),
        UnclaimedPropertySource(state: "District of Columbia", urlString: "https://dc.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "Florida", urlString: "https://fltreasurehunt.gov/index.jsp"),
        UnclaimedPropertySource(state: "Georgia", urlString: "https://dor.georgia.gov/unclaimed-property-program"),
        UnclaimedPropertySource(state: "Hawaii", urlString: "https://budget.hawaii.gov/finance/unclaimedproperty/"),
        UnclaimedPropertySource(state: "Idaho", urlString: "https://yourmoney.idaho.gov/"),
        UnclaimedPropertySource(state: "Illinois", urlString: "https://icash.illinoistreasurer.gov/"),
        UnclaimedPropertySource(state: "Indiana", urlString: "https://indianaunclaimed.gov/"),
        UnclaimedPropertySource(state: "Iowa", urlString: "https://www.iowatreasurer.gov/for-citizens/great-iowa-treasure-hunt/"),
        UnclaimedPropertySource(state: "Kansas", urlString: "https://kansascash.ks.gov/"),
        UnclaimedPropertySource(state: "Kentucky", urlString: "https://treasury.ky.gov/Pages/index.aspx"),
        UnclaimedPropertySource(state: "Louisiana", urlString: "http://lacashclaim.org"),
        UnclaimedPropertySource(state: "Maine", urlString: "https://maineunclaimedproperty.gov/"),
        UnclaimedPropertySource(state: "Maryland", urlString: "https://www.marylandtaxes.gov/unclaimed-property/index.php"),
        UnclaimedPropertySource(state: "Massachusetts", urlString: "https://www.findmassmoney.com/"),
        UnclaimedPropertySource(state: "Michigan", urlString: "https://unclaimedproperty.michigan.gov/"),
        UnclaimedPropertySource(state: "Minnesota", urlString: "https://mn.gov/commerce/consumers/your-money/find-missing-money/"),
        UnclaimedPropertySource(state: "Mississippi", urlString: "https://treasury.ms.gov/for-citizens/unclaimed-property/"),
        UnclaimedPropertySource(state: "Missouri", urlString: "https://treasurer.mo.gov/UnclaimedProperty/"),
        UnclaimedPropertySource(state: "Montana", urlString: "https://mtrevenue.gov/"),
        UnclaimedPropertySource(state: "Nebraska", urlString: "https://treasurer.nebraska.gov/up/"),
        UnclaimedPropertySource(state: "Nevada", urlString: "http://www.nevadatreasurer.gov/Unclaimed_Property/UP_Home/"),
        UnclaimedPropertySource(state: "New Hampshire", urlString: "https://newhampshire.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "New Jersey", urlString: "https://www.unclaimedproperty.nj.gov/"),
        UnclaimedPropertySource(state: "New Mexico", urlString: "http://www.tax.newmexico.gov/Individuals/search-unclaimed-property.aspx"),
        UnclaimedPropertySource(state: "New York", urlString: "https://www.osc.state.ny.us/ouf/index.htm"),
        UnclaimedPropertySource(state: "North Carolina", urlString: "https://www.nccash.com/"),
        UnclaimedPropertySource(state: "North Dakota", urlString: "https://www.land.nd.gov/UnclaimedProperty/"),
        UnclaimedPropertySource(state: "Ohio", urlString: "https://www.com.ohio.gov/unfd/"),
        UnclaimedPropertySource(state: "Oklahoma", urlString: "https://www.oktreasure.com/"),
        UnclaimedPropertySource(state: "Oregon", urlString: "https://oregon.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "Pennsylvania", urlString: "https://www.patreasury.gov/"),
        UnclaimedPropertySource(state: "Rhode Island", urlString: "https://findrimoney.com/"),
        UnclaimedPropertySource(state: "South Carolina", urlString: "https://www.treasurer.sc.gov/what-we-do/for-citizens/unclaimed-property-program/"),
        UnclaimedPropertySource(state: "South Dakota", urlString: "https://southdakota.findyourunclaimedproperty.com/"),
        UnclaimedPropertySource(state: "Tennessee", urlString: "https://treasury.tn.gov/Unclaimed-Property/Claim-Unclaimed-Property/Find-Your-Missing-Money"),
        UnclaimedPropertySource(state: "Texas", urlString: "https://claimittexas.org/"),
        UnclaimedPropertySource(state: "Utah", urlString: "https://mycash.utah.gov/"),
        UnclaimedPropertySource(state: "Vermont", urlString: "https://www.vermonttreasurer.gov/content/unclaimed-property"),
        UnclaimedPropertySource(state: "Virginia", urlString: "https://vamoneysearch.org/"),
        UnclaimedPropertySource(state: "Washington", urlString: "https://ucp.dor.wa.gov/"),
        UnclaimedPropertySource(state: "West Virginia", urlString: "https://www.wvtreasury.com/"),
        UnclaimedPropertySource(state: "Wisconsin", urlString: "https://www.revenue.wi.gov/Pages/UnclaimedProperty/Home.aspx"),
        UnclaimedPropertySource(state: "Wyoming", urlString: "https://statetreasurer.wyo.gov/unclaimed-property/"),
        UnclaimedPropertySource(state: "Guam", urlString: "http://doa.guam.gov/treasurer-of-guam/"),
        UnclaimedPropertySource(state: "Puerto Rico", urlString: "https://www.ocif.pr.gov/consumidores"),
    ].sorted { $0.state < $1.state }
}
