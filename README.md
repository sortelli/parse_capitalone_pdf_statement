# parse_capitalone_pdf_statement

[![Gem Version](https://badge.fury.io/rb/parse_capitalone_pdf_statement.svg)](http://badge.fury.io/rb/parse_capitalone_pdf_statement)
[![Build Status](https://travis-ci.org/sortelli/parse_capitalone_pdf_statement.svg?branch=develop)](https://travis-ci.org/sortelli/parse_capitalone_pdf_statement)
[![Dependency Status](https://gemnasium.com/sortelli/parse_capitalone_pdf_statement.svg)](https://gemnasium.com/sortelli/parse_capitalone_pdf_statement)


The Capital One website only provides a way to download structured
data of credit card transaction history for the previous 180 days.
However, you are able to download monthly PDF account statements
for the previous few years.

This library allows you to parse a Capital One PDF monthly statement,
and access structured transaction history data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parse_capitalone_pdf_statement'
```

And then execute:

```bash
% bundle
```

Or install it yourself as:

```bash
% gem install parse_capitalone_pdf_statement
```

## Convert PDF to JSON

Use the ```capitalone_pdf_to_json.rb``` script to convert a PDF
montly statement to JSON.

```bash
% capitalone_pdf_to_json.rb my_monthly_statement.pdf > my_monthly_statement.json
```

## API Example

Parse a PDF monthly statement and print all payments:

```ruby
require 'parse_capitalone_pdf_statement'

statement = CapitalOneStatement.new('/path/to/my_monthly_statement.pdf')

statement.payments.each do |payment|
  puts 'Transaction ID: %d'   % payment.id
  puts 'Card Number:    %d'   % payment.card_number
  puts 'Date:           %s'   % payment.date
  puts 'Description:    %s'   % payment.description
  puts 'Amount:         %.2f' % payment.amount
end
```

See the [API
Documentation](http://sortelli.github.io/parse_capitalone_pdf_statement/frames.html#!CapitalOneStatement.html)
for more information.

## License

Copyright (c) 2014 Joe Sortelli

MIT License
