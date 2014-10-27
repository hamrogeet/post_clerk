module OfficeClerk
  class Post < ShippingMethod

    DEFAULTS ={   :weight_table     => '1 2 5 10 20' , 
                  :price_table      => '2 5 10 15 18' ,
                  :max_item_weight  => "18" ,
                  :max_price        => "120" ,
                  :handling_max     => "20" ,
                  :handling_fee     => "2" ,
                  :default_weight   => "1" }
                  
    def initialize data
      super DEFAULTS.merge(data)
      @prices = @data[:price_table].split.map(&:to_f)
      @weights = @data[:weight_table].split.map(&:to_f)
      @max_item_weight = @data[:max_item_weight].to_f
      @max_price = @data[:max_price].to_f
      @handling_max = @data[:handling_max].to_f
      @handling_fee = @data[:handling_fee].to_f
      @default_weight = @data[:default_weight].to_f
    end
    attr_reader :prices , :weights , :max_item_weight , :max_price , :handling_fee , :handling_max , :default_weight

    # Determine if weight or size goes over bounds.
    def available?(basket)
      basket.items.each do |item|
        if( weight = item.product.weight)
          return false if weight > max_item_weight
        end
      end
      true
    end

    def price_for(basket)
      total_price = basket.items.map { |item| item.total }.reduce(:+)
      return 0.0 if total_price > max_price

      total_weight = basket.items.map {|item| item.quantity * (item.product.weight || default_weight) }.reduce(:+)
      shipping =  0

      while total_weight > weights.last # In several packets if need be.
        total_weight -= weights.last
        shipping += prices.last
      end

      [shipping, prices[compute_index(total_weight)], calc_handling_fee(total_price)].compact.sum
    end

    private
    
    def compute_index(total_weight)
      index = weights.length - 2
      while index >= 0
        break if total_weight > weights[index]
        index -= 1
      end
      index + 1
    end

    def calc_handling_fee(total_price)
      handling_max < total_price ? 0 : handling_fee
    end
  end
end