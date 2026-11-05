# Research and Data Sources

**Research checked:** 5 November 2026. Web pages can change; access dates are the date checked. This is desk research, not user validation.

## Product comparisons (published product information)

| Product | Observed evidence | Product implication | Limitation |
|---|---|---|---|
| Healthify | Its official app page describes food logging with macro/fibre breakdown, coaching, and Ria AI coaching: [Healthify app](https://www.healthifyme.com/app/) (accessed 2026-10-28). | Logging feedback and localized foods are familiar category expectations; MacroMate can differentiate through explicit local cost and source confidence. | Marketing copy is not independent evidence of accuracy, outcomes, or willingness to pay. Pricing was not treated as stable evidence. |
| MyFitnessPal | Official help describes free, Premium, and Premium+ feature differences; Premium+ includes meal planning and grocery-list features: [membership comparison](https://support.myfitnesspal.com/hc/en-us/articles/34889191368077-The-difference-between-Free-Premium-and-Premium) (accessed 2026-10-28). | Keep basic logging useful; possible paid value is convenience and planning depth rather than access to personal records. | Feature availability and pricing can vary by country, platform, and date. |
| Cronometer | Its support article explains multiple food-data sources and differentiates reviewed database records and user-entered foods: [data sources](https://support.cronometer.com/hc/en-us/articles/360018239472-Data-Sources) (accessed 2026-10-28). Search results can expose nutrition/source information before logging: [food search](https://support.cronometer.com/hc/en-us/articles/360018239512-Search-Food) (accessed 2026-10-28). | Expose provenance and record quality at selection time; distinguish generic composition values from package-label data. | Cronometer's data process is its own product claim and does not validate MacroMate's seed rows. |

## Interaction patterns reviewed

- MyFitnessPal's official logging guide shows a short path from diary meal slot → food search/detail → serving adjustment → save, and recommends reusable saved meals for frequent combinations: [How to log food](https://support.myfitnesspal.com/hc/en-us/articles/360032274592-How-to-log-food-to-your-diary) (accessed 2026-11-05).
- Its meal-planner help describes swapping recipes, logging a planned meal directly into the diary, and turning a plan into a grocery list: [Meal Planner](https://support.myfitnesspal.com/hc/en-us/articles/34603055097869-How-to-use-the-Meal-Planner) (accessed 2026-11-05).
- Cronometer distinguishes database source classes in food search, supporting a visible difference between estimates, user-entered prices, and stronger references: [Data Sources](https://support.cronometer.com/hc/en-us/articles/360018239472-Data-Sources) (accessed 2026-11-05).

MacroMate adapts these into offline search/detail, adjustable portions, reusable local recipes, and clear low-confidence price/nutrition labels. No competitor database or brand assets are copied.

These examples inform design hypotheses only. No interface or proprietary algorithm is copied. Direct product usability testing and current India-specific pricing research remain outstanding.

## Food composition references

- ICMR-NIN's [Indian Food Composition Tables 2017](https://www.nin.res.in/ebooks/IFCT2017.pdf), catalogued by [FAO INFOODS](https://www.fao.org/food-composition/tables-and-databases/detail/%28country--date%29-title-9/en), is an authoritative Indian reference for the foods and components it covers (checked 2026-10-28). ICMR describes IFCT 2017 as covering 151 components for 528 foods: [ICMR research page](https://www.icmr.gov.in/advancing-biomedical-research?q=nutrition) (checked 2026-10-28).
- IFCT coverage is not exhaustive and a matching item must use the correct food, analytical basis, preparation state, and edible portion. Values must not be copied to cooked recipes without a documented yield calculation.
- **Repository finding:** current seeded values do not include row-level IFCT food identifiers, page/table citations, or extraction records. The previous global seed disclaimer overstated provenance. Seed values are now labeled as unverified starter estimates; no individual value is certified against IFCT by this project.

## Price sources and geographic limits

- The Department of Consumer Affairs Price Monitoring Division states that daily retail and wholesale prices are collected for essential commodities at reporting centres and explains the source network: [Price Monitoring Division](https://consumeraffairs.gov.in/pages/price-monitoring-division) (checked 2026-10-28).
- The department's [daily average retail price report](https://fcainfoweb.nic.in/Reports/DB/DBprices.aspx) provides monitored commodity averages (checked 2026-10-28). The portal notes monitored commodity/centre quality can vary and its scope is a limited essential-commodity list; it does not provide a current price for every prepared food, brand, market, or student meal.
- MoSPI's [CPI overview](https://mospi.gov.in/web/mospi/cpi) describes CPI as price change over time for a consumption basket. CPI is useful for inflation context, not as a direct current rupee-per-kg quote for a particular campus.
- Practical approach: use DoCA data only where commodity, unit, date and location align; collect user-entered campus/local vendor prices for other foods and show observation date and geography. Do not substitute national averages for local prices. This project has not yet collected local prices.

## Findings versus interpretation

Published product pages show that food logging, macro feedback, source distinction, and planning/list features exist in established products. **Interpretation:** visible provenance and local price correction fit MacroMate's intended budget decision. This is a design inference, not evidence that students want the feature or will pay for it. No interviews, surveys, or observed usability sessions are currently documented.

## Student interview protocol (planned)

Recruit 5–8 students or beginner gym-goers with varied living/cooking arrangements. Ask open-ended questions; do not pitch before learning current behavior. Record consent, anonymize notes, and report sample and limitations.

1. Tell me about the last time you decided what to eat for a day.
2. How do you decide whether a meal fits your food spending? Show me how you worked it out, if possible.
3. Which foods do you regularly buy or get from a mess/canteen? Where and how often do prices change?
4. Have you tried tracking meals or nutrition? What caused you to continue or stop?
5. What makes logging one meal slow or inaccurate for you?
6. How do you plan shopping for the next few days, if at all?
7. What would make a nutrition estimate trustworthy enough to use? What would make you reject it?
8. Which cooking, storage, dietary, or time constraints matter in practice?
9. After showing a tested prototype task, what was confusing or missing? Please complete a daily budget/meal decision without coaching.
10. Have you paid for a related app/service? What did you pay for, and what would need to be true to pay again?

Do not infer market demand or willingness to pay from this small exploratory sample.
