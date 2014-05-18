require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { Spree::Order.create }
  subject { described_class.new(order) }

  context "#add" do
    #let(:variant) { create(:variant) }
    #let(:variant) { double('Variant', :name => "T-Shirt", :options_text => "Size: M") }
    let(:variant) { Spree::Variant.find_by_sku("845-0167-1") }

    # 3/5/14 DH: Starting BDD by creating a test for an aspect that doesn't work as I want
    # 4/5/14 DH: This works by testing the ActiveRecord association 'create_bsc_req' method with an incomplete record hash

    # [BSC spec Unit/Functional Testing]

    it "should reject an incomplete BSC req set but not raise error" do
      line_item = subject.add(variant)
      line_item.bsc_spec = "width=14,drop=7,lining=cotton,heading=pencil pleat"
      
      reqs = Spree::BscReq.createBscReqHash(line_item.bsc_spec)
      
      reqs.delete("width")
      
      expect { line_item.create_bsc_req(reqs) }.to_not raise_error
      #expect { line_item.create_bsc_req(reqs) }.to raise_error

      line_item.bsc_req.should_not be_valid
      #line_item.bsc_req.should be_valid
    end
    
    # 4/5/14 DH: This simulates 'orders#populate' being called with an incomplete BSC Spec string
    # 4/5/14 DH: It is a more abstract level than the validity checking done in 'Spree::OrderContents#add_to_line_item'
    #            ie "should reject an incomplete BSC req set but not raise error"

    # [BSC spec Integration Testing]

    it "should give an error message on incomplete BSC req set" do
      subject.bscDynamicPrice = 69
      #subject.bscSpec = "width=14,drop=7,lining=cotton,heading=pencil pleat"
      subject.bscSpec = "drop=7,lining=cotton,heading=pencil pleat"
      
      message = "The BSC requirement set is missing a value"
      expect { line_item = subject.add(variant) }.to raise_error(message)
    end

    context "given quantity is not explicitly provided" do
      it "should add one line item" do
        line_item = subject.add(variant)
        line_item.quantity.should == 1
        order.line_items.size.should == 1
      end
    end

    it "should add line item if one does not exist" do
      order.line_items.size.should == 0
      line_item = subject.add(variant, 1)
      line_item.quantity.should == 1
      order.line_items.size.should == 1
    end

    it "should not update line item if one exists due to BSC spec per line item" do
      subject.add(variant, 1)
      line_item = subject.add(variant, 1)
      line_item.quantity.should == 1
      order.line_items.size.should == 1
    end

    it "should update order totals" do
      order.item_total.to_f.should == 0.00
      order.total.to_f.should == 0.00

      subject.add(variant, 1)

      order.item_total.to_f.should == variant.price
      order.total.to_f.should == variant.price
    end
    
  end
  
=begin
  context "#remove" do
    #let(:variant) { create(:variant) }
    let(:variant) { double('Variant', :name => "T-Shirt", :options_text => "Size: M") }

    context "given an invalid variant" do
      it "raises an exception" do
        expect {
          subject.remove(variant, 1)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'given quantity is not explicitly provided' do
      it 'should remove one line item' do
        line_item = subject.add(variant, 3)
        subject.remove(variant)

        line_item.reload.quantity.should == 2
      end
    end

    it 'should reduce line_item quantity if quantity is less the line_item quantity' do
      line_item = subject.add(variant, 3)
      subject.remove(variant, 1)

      line_item.reload.quantity.should == 2
    end

    it 'should remove line_item if quantity matches line_item quantity' do
      subject.add(variant, 1)
      subject.remove(variant, 1)

      order.reload.find_line_item_by_variant(variant).should be_nil
    end

    it "should update order totals" do
      order.item_total.to_f.should == 0.00
      order.total.to_f.should == 0.00

      subject.add(variant,2)

      order.item_total.to_f.should == 39.98
      order.total.to_f.should == 39.98

      subject.remove(variant,1)
      order.item_total.to_f.should == 19.99
      order.total.to_f.should == 19.99
    end

  end
=end

end