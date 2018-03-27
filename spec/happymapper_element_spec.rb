require 'spec_helper'

describe HappyMapper::Element do
  describe "initialization" do
    let(:attr) { HappyMapper::Element.new(:foo, String) }

    it 'should know that it is an element' do
      expect(attr.element?).to eq true
    end

    it 'should know that it is NOT an attribute' do
      expect(attr.attribute?).to eq false
    end
  end
end
