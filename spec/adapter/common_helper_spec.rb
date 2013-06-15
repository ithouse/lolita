require 'spec_helper'

describe Lolita::Adapter::CommonHelper do
  describe Lolita::Adapter::CommonHelper::Record do
    let(:orm_record){ double('orm_record') }
    subject(:record){ Lolita::Adapter::CommonHelper::Record.new double('adapter'), orm_record }

    describe '#title' do
      context "record has title" do
        let(:orm_record){ double('orm_record', title: 'some title') }
        its(:title){ should eq('some title') }
      end
    end
  end
end