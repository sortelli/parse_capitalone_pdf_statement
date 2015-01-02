require 'pdf-reader'
require 'json'

class CapitalOneStatement
  TRANSACTION_REGEX = /^(\d+) +(\d\d) ([A-Z][A-Z][A-Z]) (.+[^ ]) +(\(?\$[0-9,.]+\)?) *$/

  def initialize(pdf_path)
    @previous_balance   = nil
    @total_payments     = nil
    @total_fees         = nil
    @total_transactions = nil
    @new_balance        = nil
    @payments           = []
    @transactions       = []

    parse_from_pdf pdf_path

    sort_by_trx_num = lambda {|trx| trx[:number]}

    @payments     = @payments    .sort_by &sort_by_trx_num
    @transactions = @transactions.sort_by &sort_by_trx_num

    check_total(
      'payments',
      @total_payments,
      @payments.inject(0) {|sum, trx| sum -= trx[:amount]}
    )

    check_total(
      'transactions',
      @total_transactions,
      @transactions.inject(0) {|sum, trx| sum += trx[:amount]}
    )
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

  def parse_from_pdf(pdf_path)
    reader = PDF::Reader.new(pdf_path)
    reader.pages.each_with_index do |page, page_num|
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

  def parse_transaction(line)
    return nil unless line =~ TRANSACTION_REGEX

    {
      :number     => $1.to_i,
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

  def check_total(type, expected, actual)
    return if actual.round(2) == expected.round(2)

    raise "WARNING: Calculated %s payments mismatch %.2f != %.2f" % [
      type,
      actual,
      expected
    ]
  end
end
