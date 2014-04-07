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

  # nodes are considered nodes when no more hash can be found in the child
  describe "#each" do
    subject do
      HashTree.new({ 'n1' => [
          { 'l11' => '' },
          { 'l12' => '', 'n11' => ['l111', 'l112'] },
          { 'l13' => '', 'n12' => [{'l121' => '', 'l122' => ''}, {}] },
          {              'n13' => {
                                    'n131' => {
                                                'n1311' => ['l311'], 'n1312' => {'l31121' => '', 'n13121' => ['l3121']}
                                              }
                                  }
          }
        ]})
    end
    
    it { expect { |b| subject.each(&b) }.to yield_successive_args(
      [{"l11"=>""}, "l11", "", "n1.l11"],
      [{"l12"=>"", "n11"=>["l111", "l112"]}, "l12", "", "n1.l12"],
      [{"l12"=>"", "n11"=>["l111", "l112"]}, "n11", "l111", "n1.n11"],
      [{"l12"=>"", "n11"=>["l111", "l112"]}, "n11", "l112", "n1.n11"],
      [{"l13"=>"", "n12"=>[{"l121"=>"", "l122"=>""}, {}]}, "l13", "", "n1.l13"],
      [{"l121"=>"", "l122"=>""}, "l121", "", "n1.n12.l121"],
      [{"l121"=>"", "l122"=>""}, "l122", "", "n1.n12.l122"],
      [{"n1311"=>["l311"], "n1312"=>{"l31121"=>"", "n13121"=>["l3121"]}}, "n1311", "l311", "n1.n13.n131.n1311"],
      [{"l31121"=>"", "n13121"=>["l3121"]}, "l31121", "", "n1.n13.n131.n1312.l31121"],
      [{"l31121"=>"", "n13121"=>["l3121"]}, "n13121", "l3121", "n1.n13.n131.n1312.n13121"]
    )}
  end

  describe "#each_node" do
    let!(:first_a1) { { 'a11' => 'a111' } }
    let!(:second_a1) { { 'a11' => 'a112', 'b11' => ['b111', 'b1112'] } }

    let!(:third_a1_first_b11) { {'b111' => 'b31111', 'b112' => 'b31112'} }
    let!(:third_a1_second_b11) { {'b111' => 'b31113'} }
    let!(:third_a1) { { 'a11' => 'a113', 'b11' => [third_a1_first_b11, third_a1_second_b11] } }

    let!(:fourth_a1_first_b11) { {'b111' => 'b41111', 'b112' => 'b41112'} }
    let!(:fourth_a1) { { 'a11' => 'a114', 'b11' => [fourth_a1_first_b11, {}, ['b112'], 'b112', 5] } }
    
    let!(:a1) { [first_a1, second_a1, third_a1, fourth_a1] }
    let!(:first_b1111) { { 'b1111' => 'b11111' } }
    let!(:second_b1111) { { 'b1111' => 'b11112' } }
    let!(:b11) { { 'b111' => [first_b1111, second_b1111] } }
    let!(:b1) { { 'b11' =>  b11 } }

    let!(:tree) { { 'a1' => a1, 'b1' => b1 } }

    subject { HashTree.new(tree) }

    it { expect { |b| subject.each_node(nil, &b) }.to_not yield_control }
    it { expect { |b| subject.each_node('', &b) }.to_not yield_control }
    it { expect { |b| subject.each_node('doesnotexist', &b) }.to_not yield_control }
    it { expect { |b| subject.each_node('does.not.exist', &b) }.to_not yield_control }
    it { expect { |b| subject.each_node('a1.doesnotexist', &b) }.to_not yield_control }

    # a node is not a leaf
    it { expect { |b| subject.each_node('a1.a11.a111', &b) }.to_not yield_control }


    it { expect { |b| subject.each_node('a1', &b) }.to yield_successive_args(
      [{'a1' => tree}, a1]
    )}   

    it { expect { |b| subject.each_node('a1.a11', &b) }.to yield_successive_args(
      [{'a1' => tree, 'a1.a11' => first_a1}, 'a111'],
      [{'a1' => tree, 'a1.a11' => second_a1}, 'a112'],
      [{'a1' => tree, 'a1.a11' => third_a1}, 'a113'],
      [{'a1' => tree, 'a1.a11' => fourth_a1}, 'a114']
    )}

    it { expect { |b| subject.each_node('a1.b11', &b) }.to yield_successive_args(
      [{'a1' => tree, 'a1.b11' => second_a1}, ['b111', 'b1112']],
      [{'a1' => tree, 'a1.b11' => third_a1}, [third_a1_first_b11, third_a1_second_b11]],
      [{'a1' => tree, 'a1.b11' => fourth_a1}, [fourth_a1_first_b11, {}, ['b112'], 'b112', 5]]
    )}

    it { expect { |b| subject.each_node('a1.b11.b111', &b) }.to yield_successive_args(
      [{'a1' => tree, 'a1.b11' => third_a1, 'a1.b11.b111' => third_a1_first_b11}, 'b31111'],
      [{'a1' => tree, 'a1.b11' => third_a1, 'a1.b11.b111' => third_a1_second_b11}, 'b31113'],
      [{'a1' => tree, 'a1.b11' => fourth_a1, 'a1.b11.b111' => fourth_a1_first_b11}, 'b41111']
    )}

    it { expect { |b| subject.each_node('b1', &b) }.to yield_successive_args(
      [{'b1' => tree}, b1]
    )}

    it { expect { |b| subject.each_node('b1.b11', &b) }.to yield_successive_args(
      [{'b1' => tree, 'b1.b11' => b1}, b11]
    )}

    it { expect { |b| subject.each_node('b1.b11.b111', &b) }.to yield_successive_args(
      [{'b1' => tree, 'b1.b11' => b1, 'b1.b11.b111' => b11}, [first_b1111, second_b1111]]
    )}
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
