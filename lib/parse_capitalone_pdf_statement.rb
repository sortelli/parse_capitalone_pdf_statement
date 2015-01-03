require 'parse_capitalone_pdf_statement/version'
require 'pdf-reader'
require 'json'
require 'date'

# CapitalOneStatement object, with data parsed from a PDF monthly statement.
#
# @!attribute start_date [r]
#    @return [Date] the first day of the monthly statement
#
# @!attribute end_date [r]
#    @return [Date] the final day of the monthly statement
#
# @!attribute previous_balance [r]
#    @return [Float] the "Previous Balance" field listed in the statement
#
# @!attribute total_payments [r]
#    @return [Float] the "Payments and Credits" field listed in the statement
#
# @!attribute total_fees [r]
#    @return [Float] the "Fees and Interest Charged" field listed in the statement
#
# @!attribute total_transactions [r]
#    @return [Float] the "Transactions" field listed in the statement
#
# @!attribute new_balance [r]
#    @return [Float] the New Balance listed in the statement
#
# @!attribute payments [r]
#    @return [Array<CapitalOneStatement::Transaction>] array of payment transactions
#
# @!attribute transactions [r]
#    @return [Array<CapitalOneStatement::Transaction>] array of charge transactions
#
# @!attribute fees [r]
#    @return [Array<CapitalOneStatement::Transaction>] array of fee transactions

class CapitalOneStatement
  DATE_REGEX        = /(\w{3})\. (\d\d) - (\w{3})\. (\d\d), (\d{4})/
  AMOUNT_REGEX      = /\(?\$[\d,]+\.\d\d\)?/
  AMOUNT_ONLY_REGEX = /^ *#{AMOUNT_REGEX.source} *$/
  FEES_REGEX        = /Total Fees This Period +(#{AMOUNT_REGEX.source})/
  INTEREST_REGEX    = /Total Interest This Period +(#{AMOUNT_REGEX.source})/
  TRANSACTION_REGEX = /^ *(\d+) +(\d\d) ([A-Z][A-Z][A-Z]) (.+[^ ]) +(#{
                        AMOUNT_REGEX.source
                      }) *$/

  attr_reader :start_date,
              :end_date,
              :previous_balance,
              :total_payments,
              :total_fees,
              :total_transactions,
              :new_balance,
              :payments,
              :transactions

  def initialize(pdf_path)
    @dec_from_prev_year = nil
    @year               = nil
    @start_date         = nil
    @end_date           = nil
    @previous_balance   = nil
    @new_balance        = nil
    @total_payments     = nil
    @total_transactions = nil
    @total_fees         = nil
    @payments           = []
    @transactions       = []
    @fees               = []

    parse_from_pdf pdf_path

    %w{payments transactions fees}.each do |type|
      trxs  = "@#{type}"
      total = "@total_#{type}"

      instance_variable_set(trxs, instance_variable_get(trxs).sort_by {|trx| trx[:id]})

      check_total(
        type,
        instance_variable_get(total),
        instance_variable_get(trxs).inject(0) {|sum, trx| sum += trx[:amount]}
      )
    end
  end

  def to_json(*args)
    {
      :start_date         => @start_date,
      :end_date           => @end_date,
      :previous_balance   => @previous_balance,
      :total_payments     => @total_payments,
      :total_fees         => @total_fees,
      :total_transactions => @total_transactions,
      :new_balance        => @new_balance,
      :payments           => @payments,
      :transactions       => @transactions,
      :fees               => @fees
    }.to_json(*args)
  end

  private

  def parse_from_pdf(pdf_path)
    PDF::Reader.new(pdf_path).pages.each_with_index do |page, page_num|
      if @year.nil?
        walker = Struct.new(:year, :offset, :start_date, :end_date) do
          def respond_to?(_)
            true
          end

          def method_missing(name, *args)
            return unless name =~ /show_text/

            if args.any? {|str| str.to_s =~ DATE_REGEX}
              self.offset     = ($1.upcase == 'DEC' && $3.upcase == 'JAN') ? 1 : 0
              self.year       = $5.to_i
              self.start_date = Date.parse('%s-%s-%s' % [year - offset, $1, $2])
              self.end_date   = Date.parse('%s-%s-%s' % [year, $3, $4])
            end
          end
        end.new

        page.walk walker

        @dec_from_prev_year = walker.offset == 1
        @year               = walker.year
        @start_date         = walker.start_date
        @end_date           = walker.end_date
      end

      enum = page.text.split("\n").each

      loop do
        current_line = enum.next
        enum.next until (enum.peek rescue nil) != ''
        next_line    = (enum.peek rescue nil)

        parse_pdf_line page_num, current_line, next_line
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

        @total_payments = -@total_payments
      end
    end

    if line =~ FEES_REGEX && $1 != '$0.00'
      check_billing_cycle
      @fees << Transaction.new(
        @fees.size + 1,
        @end_date, "CAPITAL ONE MEMBER FEE",
        $1,
        parse_amount($1)
      )
    end

    if line =~ INTEREST_REGEX && $1 != '$0.00'
      check_billing_cycle
      @fees << Transaction.new(
        @fees.size + 1,
        @end_date, "INTEREST CHARGE:PURCHASES",
        $1,
        parse_amount($1)
      )
    end

    transactions, payments = [(0..78), (80..-1)].map do |index|
      str      = line     .to_s[index].to_s
      next_str = next_line.to_s[index].to_s

      repair_transaction_line str, next_str
    end.map do |str|
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
    return nil unless line =~ TRANSACTION_REGEX &&
                      $4   != "CAPITAL ONE MEMBER FEE"

    check_billing_cycle

    year = ($3.upcase == 'DEC' && @dec_from_prev_year) ? @year - 1 : @year
    date = Date.parse('%s-%s-%s' % [year, $3, $2])

    Transaction.new($1.to_i, date, $4, $5, parse_amount($5))
  end

  def parse_amount(amount)
    num = amount.gsub(/[^\d.]/, '').to_f
    amount.start_with?(?() ? -num : num
  end

  def check_billing_cycle
    raise "Failed to determine billing cycle dates" if @year.nil?
  end

  def check_total(type, expected, actual)
    return if actual.round(2) == expected.round(2)

    raise "Calculated %s payments mismatch %.2f != %.2f" % [
      type,
      actual,
      expected
    ]
  end

  # CapitalOneStatement::Transaction represents a single credit transaction
  class CapitalOneStatement::Transaction < Struct.new(
                                             :id,
                                             :date,
                                             :description,
                                             :amount_str,
                                             :amount
                                           )
    # @!attribute id
    #    @return [Fixnum] transaction id
    #
    # @!attribute date
    #    @return [Date] the date of the transaction
    #
    # @!attribute description
    #    @return [String] the description of the transaction
    #
    # @!attribute amount_str
    #    @return [String] the dollar amount string of the transaction
    #
    # @!attribute amount
    #    @return [Float] the dollar amount parsed into a Float, negative for payments

    # @return [String] JSON representation of Transaction
    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
