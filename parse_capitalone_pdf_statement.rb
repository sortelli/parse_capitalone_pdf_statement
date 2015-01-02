require 'pdf-reader'
require 'json'

class CapitalOneStatement
  AMOUNT_REGEX      = /\(?\$[\d,]+\.\d\d\)?/
  AMOUNT_ONLY_REGEX = /^ *#{AMOUNT_REGEX.source} *$/
  TRANSACTION_REGEX = /^(\d+) +(\d\d) ([A-Z][A-Z][A-Z]) (.+[^ ]) +(#{
                        AMOUNT_REGEX.source
                      }) *$/

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
      enum = page.text.split("\n").each

      loop do
        parse_pdf_line(page_num, enum.next, (enum.peek() rescue nil))
      end
    end
  end

  def parse_pdf_line(page_num, line, next_line)
    if @previous_balance.nil?
      amount_strs = line.scan AMOUNT_REGEX
      if amount_strs.size == 5
        @previous_balance,
        @total_payments,
        @total_fees,
        @total_transactions,
        @new_balance = amount_strs.map {|amount| parse_amount(amount)}
      end
    end

    indexes  = page_num == 0 ? [(5..76)] : [(0..71), (82..-1)]
    trx_strs = indexes.map do |index|
      repair_transaction_line line[index], next_line.to_s[index].to_s
    end

    transactions, payments = trx_strs.map do |str|
      parse_transaction(str)
    end.compact.partition do |trx|
      trx[:amount] >= 0
    end

    @transactions += transactions
    @payments     += payments
  end

  def repair_transaction_line(line, next_line)
    if next_line =~ AMOUNT_ONLY_REGEX && !(line =~ AMOUNT_REGEX)
      line += " #{next_line.strip}"
    else
      line
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
