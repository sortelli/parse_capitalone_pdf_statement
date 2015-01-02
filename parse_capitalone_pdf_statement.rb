require 'pdf-reader'
require 'json'

class CapitalOneStatement
  TRANSACTION_REGEX = /^(\d+) +(\d\d) ([A-Z][A-Z][A-Z]) (.+[^ ]) +(\(?\$[0-9,.]+\)?) *$/

  def initialize(pdf_path)
    @transactions       = []
    @payments           = []
    @previous_balance   = nil
    @total_payments     = nil
    @total_fees         = nil
    @total_transactions = nil
    @new_balance        = nil

    @reader = PDF::Reader.new(pdf_path)
    @reader.pages.each_with_index do |page, page_num|
      page.text.split("\n").each do |line|
        if @previous_balance.nil?
          amount_strs = line.scan(/\$[\d,.]+/)
          if amount_strs.size == 5
            @previous_balance,
            @total_payments,
            @total_fees,
            @total_transactions,
            @new_balance = amount_strs.map {|amount| parse_amount(amount)}
          end
        end

        trx_strs = if page_num == 0
          [line[5, 72]]
        else
          [line[0, 72], line[82..-1]]
        end

        transactions, payments = trx_strs.map do |str|
          parse_transaction(str)
        end.compact.partition do |trx|
          trx[:amount] >= 0
        end

        @transactions += transactions
        @payments     += payments
      end
    end
  end

  def to_json
    JSON.pretty_generate({
      :previous_balance   => @previous_balance,
      :total_payments     => @total_payments,
      :total_fees         => @total_fees,
      :total_transactions => @total_transactions,
      :new_balance        => @new_balance,
      :payments           => @payments,
      :transactions       => @transactions
    })
  end

  private

  def parse_transaction(line)
    return nil unless line =~ TRANSACTION_REGEX

    {
      :number     => $1,
      :day        => $2,
      :month      => $3,
      :desc       => $4,
      :amount_str => $5,
      :amount     => parse_amount($5)
    }
  end

  def parse_amount(amount)
    num = amount.gsub(/[^\d.]/, '').to_f
    amount.start_with?(?() ? -num : num
  end
end
