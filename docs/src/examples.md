# Examples

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