describe Inventory do
  let(:inventory) { Inventory.new }
  let(:cart) { inventory.new_cart }

  describe "with no discounts" do
    it "can tell the total price of all products" do
      inventory.register 'The Best of Coltrane CD', '1.99'

      cart.add 'The Best of Coltrane CD'
      cart.add 'The Best of Coltrane CD'

      cart.total.should eq '3.98'.to_d
    end

    it "has some constraints on prices and counts" do
      inventory.register 'Existing', '1.00'
      inventory.register 'Top price', '999.99'
      inventory.register 'A' * 40, '1.99'

      cart.add 'Top price', 99

      expect { inventory.register 'Existing' }.to raise_error
      expect { inventory.register 'Negative', '-10.00' }.to raise_error
      expect { inventory.register 'Zero', '0.00' }.to raise_error
      expect { inventory.register 'L' * 41, '1.00' }.to raise_error
      expect { inventory.register 'Overpriced', '1000.0' }.to raise_error
      expect { cart.add 'Unexisting' }.to raise_error
      expect { cart.add 'Existing', 100 }.to raise_error
      expect { cart.add 'Existing', -1 }.to raise_error
    end

    it "can print an invoice" do
      inventory.register 'Green Tea',    '0.79'
      inventory.register 'Earl Grey',    '0.99'
      inventory.register 'Black Coffee', '1.99'

      cart.add 'Green Tea'
      cart.add 'Earl Grey', 3
      cart.add 'Black Coffee', 2

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                    1 |     0.79 |
| Earl Grey                                    3 |     2.97 |
| Black Coffee                                 2 |     3.98 |
+------------------------------------------------+----------+
| TOTAL                                          |     7.74 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with a 'buy X, get one free' promotion" do
    it "grants every nth item for free" do
      inventory.register 'Gum', '1.00', get_one_free: 4

      cart.add 'Gum', 4

      cart.total.should eq '3.00'.to_d
    end

    it "grants 2 items free, when 8 purchased and every 3rd is free" do
      inventory.register 'Gum', '1.00', get_one_free: 3

      cart.add 'Gum', 8

      cart.total.should eq '6.00'.to_d
    end

    it "shows the discount in the invoice" do
      inventory.register 'Green Tea', '1.00', get_one_free: 3
      inventory.register 'Red Tea', '2.00', get_one_free: 5

      cart.add 'Green Tea', 3
      cart.add 'Red Tea', 8

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                    3 |     3.00 |
|   (buy 2, get 1 free)                          |    -1.00 |
| Red Tea                                      8 |    16.00 |
|   (buy 4, get 1 free)                          |    -2.00 |
+------------------------------------------------+----------+
| TOTAL                                          |    16.00 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with a '% off for every n' promotion" do
    it "gives % off for every group of n" do
      inventory.register 'Sandwich', '1.00', package: {4 => 20}

      cart.add 'Sandwich', 4
      cart.total.should eq '3.20'.to_d

      cart.add 'Sandwich', 4
      cart.total.should eq '6.40'.to_d
    end

    it "does not discount for extra items, that don't fit in a group" do
      inventory.register 'Sandwich', '0.50', package: {4 => 10}

      cart.add 'Sandwich', 4
      cart.total.should eq '1.80'.to_d

      cart.add 'Sandwich', 2
      cart.total.should eq '2.80'.to_d
    end

    it "shows the discount in the invoice" do
      inventory.register 'Green Tea', '1.00', package: {4 => 10}
      inventory.register 'Red Tea',   '2.00', package: {5 => 20}

      cart.add 'Green Tea', 4
      cart.add 'Red Tea', 8

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                    4 |     4.00 |
|   (get 10% off for every 4)                    |    -0.40 |
| Red Tea                                      8 |    16.00 |
|   (get 20% off for every 5)                    |    -2.00 |
+------------------------------------------------+----------+
| TOTAL                                          |    17.60 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with a '% off of every item after the nth' promotion" do
    it "gives a discount for every item after the nth" do
      inventory.register 'Coke', '2.00', threshold: {5 => 10}

      cart.add 'Coke', 8
      cart.total.should eq '15.40'.to_d
    end

    it "does not give a discount if there are no more than n items in the cart" do
      inventory.register 'Coke', '1.00', threshold: {10 => 20}

      cart.add 'Coke', 8
      cart.total.should eq '8.00'.to_d

      cart.add 'Coke', 2
      cart.total.should eq '10.00'.to_d

      cart.add 'Coke', 5
      cart.total.should eq '14.00'.to_d
    end

    it "shows the discount in the ivnoice" do
      inventory.register 'Green Tea', '1.00', threshold: {10 => 10}
      inventory.register 'Red Tea',   '2.00', threshold: {15 => 20}

      cart.add 'Green Tea', 12
      cart.add 'Red Tea', 20

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                   12 |    12.00 |
|   (10% off of every after the 10th)            |    -0.20 |
| Red Tea                                     20 |    40.00 |
|   (20% off of every after the 15th)            |    -2.00 |
+------------------------------------------------+----------+
| TOTAL                                          |    49.80 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with a '% off' coupon" do
    it "gives % off of the total" do
      inventory.register 'Tea', '1.00'
      inventory.register_coupon 'TEATIME', percent: 20

      cart.add 'Tea', 10
      cart.use 'TEATIME'

      cart.total.should eq '8.00'.to_d
    end

    it "applies the coupon discount after product promotions" do
      inventory.register 'Tea', '1.00', get_one_free: 6
      inventory.register_coupon 'TEATIME', percent: 10

      cart.add 'Tea', 12
      cart.use 'TEATIME'

      cart.total.should eq '9.00'.to_d
    end

    it "shows the discount in the invoice" do
      inventory.register 'Green Tea', '1.00'
      inventory.register_coupon 'TEA-TIME', percent: 20

      cart.add 'Green Tea', 10
      cart.use 'TEA-TIME'

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                   10 |    10.00 |
| Coupon TEA-TIME - 20% off                      |    -2.00 |
+------------------------------------------------+----------+
| TOTAL                                          |     8.00 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with an 'amount off' coupon" do
    it "subtracts the amount form the total" do
      inventory.register 'Tea', '1.00'
      inventory.register_coupon 'TEATIME', amount: '10.00'

      cart.use 'TEATIME'

      cart.add 'Tea', 12
      cart.total.should eq '2.00'.to_d
    end

    it "does not result in a negative total" do
      inventory.register 'Tea', '1.00'
      inventory.register_coupon 'TEATIME', amount: '10.00'

      cart.use 'TEATIME'

      cart.add 'Tea', 8
      cart.total.should eq '0.00'.to_d
    end

    it "shows the discount in the invoice" do
      inventory.register 'Green Tea', '1.00'
      inventory.register_coupon 'TEA-TIME', amount: '10.00'

      cart.add 'Green Tea', 5
      cart.use 'TEA-TIME'

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                    5 |     5.00 |
| Coupon TEA-TIME - 10.00 off                    |    -5.00 |
+------------------------------------------------+----------+
| TOTAL                                          |     0.00 |
+------------------------------------------------+----------+
INVOICE
    end
  end

  describe "with multiple discounts" do
    it "can print an invoice" do
      inventory.register 'Green Tea',    '2.79', get_one_free: 2
      inventory.register 'Black Coffee', '2.99', package: {2 => 20}
      inventory.register 'Milk',         '1.79', threshold: {3 => 30}
      inventory.register 'Cereal',       '2.49'

      inventory.register_coupon 'BREAKFAST', percent: 10

      cart.add 'Green Tea', 8
      cart.add 'Black Coffee', 5
      cart.add 'Milk', 5
      cart.add 'Cereal', 3
      cart.use 'BREAKFAST'

      cart.invoice.should eq <<INVOICE
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
| Green Tea                                    8 |    22.32 |
|   (buy 1, get 1 free)                          |   -11.16 |
| Black Coffee                                 5 |    14.95 |
|   (get 20% off for every 2)                    |    -2.39 |
| Milk                                         5 |     8.95 |
|   (30% off of every after the 3rd)             |    -1.07 |
| Cereal                                       3 |     7.47 |
| Coupon BREAKFAST - 10% off                     |    -3.91 |
+------------------------------------------------+----------+
| TOTAL                                          |    35.16 |
+------------------------------------------------+----------+
INVOICE
    end
  end
end
