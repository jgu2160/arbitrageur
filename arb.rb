require "hurley"
require "json"

class Arbitrageur
  def initialize
    response = Hurley.get("http://fx.priceonomics.com/v1/rates/")
    @matrix = clean(response)
    @keys = @matrix.keys
    @opportunities = []
  end

  def clean(response)
    matrix = JSON.parse(response.body)
    matrix.delete_if { |key| key[0..2] == key[4..6] }
    matrix.each { |k,v| matrix[k] = v.to_f }
    matrix
  end

  def three_step
    currencies = @keys.map {|c| c[0..2]}.uniq
    currencies.each do |c|
      first_trades = @keys.select { |key| key[0..2] == c }
      last_trades = @keys.select { |key| key[4..6] == c }
      inter_trades = inter_trades(c)
      arb_value(first_trades, inter_trades, last_trades)
      puts @opportunities
    end
  end

  def inter_trades(currency)
    @keys.select { |key| !key[Regexp.new(currency)] }
  end

  def arb_value(first_trades, inter_trades, last_trades)
    inter_trades.map do |t|
      former = Regexp.new(t[0..2])
      latter = Regexp.new(t[4..6])
      first = first_trades.select { |ft| ft[former] }[0]
      last = last_trades.select { |ft| ft[latter] }[0]
      result = @matrix[first] * @matrix[t] * @matrix[last]
      sequence = { "#{first} -> #{t} -> #{last}" => result }
      @opportunities << sequence if result - 1 > 0
    end
  end
end

Arbitrageur.new.three_step
