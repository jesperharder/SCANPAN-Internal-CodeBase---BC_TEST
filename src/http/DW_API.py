
### SOAP
###
### 2025.07 JH           Soap Request for API test
###
### detailed explanation of how to construct and use a SOAP request to invoke the ReadMultiple operation on the
### GLEntry page web service in Microsoft Dynamics 365 Business Central.
### The purpose of this request is to retrieve G/L Entry records, optionally filtered by specific criteria such as Entry No. and Posting Date.
### This can be used for data integration, reporting, or any scenario where you need to programmatically access G/L Entry data from Business Central.



url = "http://srvbcapp1.scanpan.dk:7648/BC_TEST_UP/ODataV4/Company('SCANPAN%20Danmark')/GLEntry?$select=entryNo"

while url:
    response = requests.get(url, headers=headers)
    result = response.json()

    # process result['value'] here

    url = result.get('@odata.nextLink')  # Automatically gets next page URL, or None when done

