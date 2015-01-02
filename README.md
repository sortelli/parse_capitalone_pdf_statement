# parse_capitalone_pdf_statement.rb

The Capital One website only provides a way to download structured
data of credit card transaction history for the previous 180 days.
However, you are able to download PDF account statements for the
previous few years.

This library allows you to parse a Capital One PDF statement, and
access structured transaction history data.

# Convert PDF to JSON

Use the ```capitalone_pdf_to_json.rb``` script to convert a PDF
statement to JSON.

```bash
% ./capitalone_pdf_to_json.rb my_statement.pdf > my_statement.json
```

# License

Copyright (c) 2014 Joe Sortelli

MIT License
