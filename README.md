# Likelihood of experiencing a wildfire-induced power outage in California

Shenyue Jia

A study on the likelihood of experiencing a wildfire-induced power outage in California

## Convert the original poweroutage.us data to long-form

The original data from [poweroutage.us](https://poweroutage.us/) are scrapped from APIs of utility companies at around a 10-minute interval. To make it easier for us to identify continuous temporal sections with continuously high numbers of customers out of power, we can unpack the original data to a long form, which means the time series will contain many zeros due to this dataset's nature.

- R notebook to convert the original data to long-form (01/01/2017 - 12/31/2020)
  - [R notebook](https://htmlpreview.github.io/?https://github.com/jiashenyue/ca-poweroutage-likelihood-study/blob/main/code/00_long_form_data_gen.nb.html)
  - Long form for each county
    - Each 10-min interval contains the number of customers who are out of power within the county
    - Generates data as CSV files
  - Long form for each city
    - City here means census-designated place (CDP), a geographical unit used by U.S. Census Bureau for populous areas
    - Each 10-min interval contains the number of customers who are out of power within the city (CDP)
    - Generates data as RDS files

## Break long-form data into power outage events

