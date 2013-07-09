require 'simple_spec_helper'

describe Lolita::Adapter::CommonHelper do
  describe Lolita::Adapter::CommonHelper::Record do
    let(:orm_record){ double('orm_record') }
    let(:adapter){ double('adapter', fields: []) }
    subject(:record){ Lolita::Adapter::CommonHelper::Record.new adapter, orm_record }

    describe '#title' do
      context "record has title" do
        let(:orm_record){ double('orm_record', title: 'some title') }
        its(:title){ should eq('some title') }
      end

      context "record has name" do
        let(:orm_record){ double('orm_record', name: 'some name') }
        its(:title){ should eq('some name') }
      end

      context "record has content field" do
        let(:adapter){ double('adapter', fields: [double(type: 'int', name: 'id'), double(type: 'string', name: 'first_name')]) }
        let(:orm_record){ double('orm_record', first_name: 'Max') }
        its(:title){ should eq('Max') }
      end

      context "else, return klass name with id" do
        let(:orm_record){ double('orm_record', id: 9, class: double(lolita_model_name: double(human: 'Foo'))) }
        its(:title){ should eq('Foo 9') }
      end
    end
  end

  describe Lolita::Adapter::CommonHelper::PaginationBuilder do
    let(:unscoped){ double('unscoped') }
    let(:klass){ double('klass', unscoped: unscoped) }
    let(:adapter){ double('adapter', klass: klass) }
    let(:page){ 1 }
    let(:per){ 5 }
    let(:request){ double('request', headers: {}) }
    let(:options){ {request: request} }

    subject(:builder){ Lolita::Adapter::CommonHelper::PaginationBuilder.new(adapter, page, per, options) }
    describe '#params' do
      context "with params" do
        let(:request){ double('request', params: {a: 1}) }
        its(:params){ should eq({a: 1})}
      end

      context "without params" do
        its(:params){ should eq({})}
      end
    end

    describe '#request' do
      its(:request){ should eq(request) }
    end

    describe '#nested_criteria' do
      context "with nested params" do
        let(:request){ double('request', params: {nested: {category_id: 3}})}
        it "filters by nested data" do
          klass.should_receive(:where).with({category_id: 3})
          subject.nested_criteria
        end
      end
      context "without nested params" do
        its(:nested_criteria){ should be_nil }
      end
    end

    describe '#ability_criteria' do
      context "without" do
        its(:ability_criteria){ should be_nil }
      end

      context "with abilities" do
        let(:klass){ double('klass', accessible_by: double)}
        it "return accessible_by scope" do
          klass.should_receive(:accessible_by)
          subject.ability_criteria
       end
      end
    end

    describe '#sorting' do
      context "with sort params" do
        let(:request){ double('request', params: {s: 'name|surname,asc'}) }
        its(:sorting){ should eq('name,surname asc')}
      end

      context "without params" do
        its(:sorting){ should be_nil }
      end
    end
  end
end