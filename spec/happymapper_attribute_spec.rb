require 'spec_helper'

describe HappyMapper::Attribute do
  describe "initialization" do
    let(:attr) { HappyMapper::Attribute.new(:foo, String) }

    it 'should know that it is an attribute' do
      expect(attr.attribute?).to eq true
    end

    it 'should know that it is NOT an element' do
      expect(attr.element?).to eq false
    end
  end
end
