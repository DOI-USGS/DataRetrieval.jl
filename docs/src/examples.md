# Examples

## Index

```@contents
Pages = ["examples.md"]
```

## Examining Site 01491000

In this example we fetch some data for site "01491000" located on the
Choptank River near Greensboro, MD.

First we will obtain information about the site itself.

```@example 01491000
using DataRetrieval
siteNumber = "01491000"
df, response = readNWISsite(siteNumber);

# print the site information table
df
```

We can also look at the raw API GET query response, which is kept as a
`HTTP.Messages.Response` object. For example, we can look at the status of
the GET request; a 200 code, for example, indicates a successful response.

```@example 01491000
# print the response status code
response.status
```

So as you can see, we were successful in our query (which we knew from
looking at our formatted data frame earlier anyway).

We can also get actual measurement data for this site, such as daily discharge
values. We will obtain daily discharge values for the first three days in
January of 1980 below.

```@example 01491000
df, response = readNWISdv(siteNumber, "00060",
                          startDate="1980-01-01", endDate="1980-01-03")

# print the data frame containing discharge values
df
```

Once again we can also examine the raw GET request object. Rather than just
look at the status of the GET query, this time we will look at the request
itself, which contains information such as the actual GET query and the
API host.

```@example 01491000
response.request
```

## Plotting One Day's Flow Data for Site 01646500

In this example we will plot the flow data for one day for site "01646500".
Site "01646500" is located on the Potomac River near Washington D.C. at the
Little Falls pump station.

First we can query the instantaneous flow data from December 1, 2022:

```@example 01646500
using DataRetrieval
siteNumber = "01646500"
df, response = readNWISiv(siteNumber, "00060", startDate="2022-12-01",
                          endDate="2022-12-01");
# display the first row of the data frame
first(df)
```

We have requested discharge data using the parameter code "00060". We can
get additional information about this parameter code, such as the units
discharge is measured in, by using the `readNWISpCode` function.

```@example 01646500
pcodedf, response = readNWISpCode("00060")
pcodedf
```

We can see that the units for discharge are cubic feet per second. Now when
we plot the discharge data, we can properly label the y-axis.

```@example 01646500
# convert the date time column to a DateTime type
using Dates
timestamps = Dates.DateTime.(df.datetime, "yyy-mm-dd HH:MM");
# convert the discharge values to a float type
discharge = map(x->parse(Float64,x),df."69928_00060");
# make the plot
using Plots
plot(timestamps, discharge,
     title="Discharge at Little Falls Pump Station, Dec. 1, 2022",
     ylabel="Discharge (ft³/s)",
     xlabel="Timestamp",
     xrotation=60,
     label="Discharge")
```