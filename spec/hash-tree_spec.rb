require 'spec_helper'

include ApplicationHelpers

describe HashTree do
  describe "::from_json" do
    context "when using the books.json fixture" do
      let(:hashtree) { HashTree.from_json(File.read('spec/fixtures/books.json')) }

      subject { hashtree }

      it { should_not be_empty }
      the("hashtree.get('books').length") { should eql 3 }
    end

    context "when using an empty fixture" do
      subject { HashTree.from_json('') }

      it { should be_nil }
    end
  end

  describe "::from_json_path" do
    context "when using the books.json fixture" do
      subject { HashTree.from_json_path('spec/fixtures/books.json') }
      it { should_not be_empty }
    end
  end

  describe "::from_xml" do
    context "when using the books.xml fixture" do
      let(:hashtree) { HashTree.from_xml(File.read('spec/fixtures/books.xml')) }

      subject { hashtree }

      it { should_not be_empty }
      the("hashtree.get('books.book').length") { should eql 3 }
    end

    context "when using an empty fixture" do
      subject { HashTree.from_xml('') }

      it { should be_nil }
    end
  end

  describe "::from_xml_path" do
    context "when using the books.xml fixture" do
      subject { HashTree.from_xml_path('spec/fixtures/books.xml') }
      it { should_not be_empty }
    end
  end

  describe "::from_yml_path" do
    context "when using the books.yml fixture" do
      let(:hashtree) { HashTree.from_yml_path('spec/fixtures/books.yml') }

      subject { hashtree }

      it { should_not be_empty }
      the("hashtree.get('books').length") { should eql 3 }
    end
  end

  describe "#checksum" do
    context "with an empty hash" do
      specify { HashTree.new.checksum.should eql '99914b932bd37a50b983c5e7c90ae93b' }
    end

    with_books_fixture do
      specify { hashtree.checksum.should eql 'c15fddfa0bea3610663d019b8b5b4a4d' }
    end
  end

  describe "#children" do
    pending 'TOTEST'
  end

  describe "#clone_tree" do
    with_books_fixture do
      context "and cloning it" do
        subject { hashtree.clone_tree }

        its(:object_id) { should_not eql hashtree.object_id }
      end
    end
  end

  describe "#compact!" do
    fixture :hashtree, HashTree.new({ 'books' => [ { 'title' => 'Don Quixote' }, { 'title' => nil }, { 'title' => 'Steppenwolf', 'formats' => [nil, 'pdf', 'epub'] } ]}) do
      before { hashtree.compact! }

      the("hashtree.get('books.title')") { should eql ['Don Quixote', 'Steppenwolf'] }
      the("hashtree.get('books.formats')") { should eql ['pdf', 'epub'] }
    end
  end

  describe "#each" do
    pending 'TOTEST'
  end

  describe "#empty?" do
    fixture :ht, HashTree.new do
      it { should be_empty }
    end

    fixture :ht, HashTree.new({ 'book' => 'Steppenwolf' }) do
      it { should_not be_empty }
    end
  end

  describe "#exists?" do
    fixture :hashtree, HashTree.new({ 'books' => [ { 'title' => 'Don Quixote' }, { 'formats' => [{ 'price' => 999 }] } ]}) do
      the("hashtree.exists?('books.title')") { should be_true }
      the("hashtree.exists?('books.formats.price')") { should be_true }
      the("hashtree.exists?('books.unknown')") { should be_false }
    end
  end

  describe "#get" do
    fixture :books, HashTree.new({ 'books' => [ { 'title' => 'Don Quixote' }, { 'formats' => [{ 'nature' => 'pdf' }, {'nature' => 'epub' }] } ]}) do
      the("books.get('books.title')") { should eql "Don Quixote" }
      the("books.get('books.title', :force => Array)") { should eql ["Don Quixote"] }
      the("books.get('books.formats')") { should eql [{ 'nature' => 'pdf' }, {'nature' => 'epub' }] }
      the("books.get('books.formats.nature')") { should eql ['pdf', 'epub'] }
      the("books.get('books.name')") { should eql "" }
      the("books.get('books.name', :default => nil)") { should be_nil }
    end
  end

  describe "#keys_to_s!" do
    pending 'TOTEST'
  end

  describe "#id" do
    context "with an hash tree having the attribute id with the value 123" do
      subject { HashTree.new(:id => 123, :name => 'test') }

      its(:id) { should eql 123 }
    end
  end

  describe "#insert" do
    pending 'TOTEST'
  end

  describe "#inspect" do
    pending 'TOTEST'
  end

  describe "#merge" do
    pending 'TOTEST'
  end

  describe "#remove" do
    pending 'TOTEST'
  end

  describe "#rename_key!" do
    with_books_fixture do
      context "and renaming the key books.title for name" do
        before { hashtree.rename_key! 'books.title', 'name' }

        the("hashtree.exists?('books.title')") { should be_false }
        the("hashtree.exists?('books.name')") { should be_true }
      end

      context "and renaming the key books.formats.prices.currency for specie" do
        before { hashtree.rename_key! 'books.formats.prices.currency', 'specie' }

        the("hashtree.exists?('books.formats.prices.currency')") { should be_false }
        the("hashtree.exists?('books.formats.prices.specie')") { should be_true }
      end
    end
  end

  describe "#replace_values!" do
    with_books_fixture do
      the("hashtree.get('books.formats.nature')") { should include 'pdf' }

      context "and replacing value pdf for paper" do
        before { hashtree.replace_values!('pdf', 'paper') }
        the("hashtree.get('books.formats.nature')") { should_not include 'pdf' }
      end

      context "and replacing value unknown for paper" do
        before { hashtree.replace_values!('unknown', 'paper') }
        the("hashtree.get('books.formats.nature')") { should include 'pdf' }
      end
    end
  end

  describe "#set" do
    pending 'TOTEST'
  end

  describe "#slash" do
    with_book_fixture do
      context "and slashing book" do
        subject { hashtree.slash 'book' }

        its(:title) { should eql 'Steppenwolf' }
        the("hashtree.book['title']") { should eql 'Steppenwolf' }
      end

      context "and not slashing book" do
        its(:title) { should be_nil }
      end
    end
  end

  describe "#slash!" do
    with_book_fixture do
      context "and slashing book" do
        before { hashtree.slash! 'book' }

        its(:title) { should eql 'Steppenwolf' }
        the("hashtree.book") { should be_nil }
      end
    end
  end

  describe "#to_json" do
    with_books_fixture do
      context "and converting it to json" do
        subject { hashtree.to_json }

        it { should_not be_empty }
        it { should include '{"books":[{' }
        it { should include '"tags":["conflict","isolation","reality","animalistic"]' }
        it { should include '"author":["Fyodor Dostoyevsky"]' }
      end
    end
  end

  describe "#to_yaml" do
    pending 'TOTEST'
  end
end
