module ApplicationHelpers
  def with_book_fixture(&block)
    with_books_fixture('spec/fixtures/book.json', &block)
  end

  def with_books_fixture(file_path='spec/fixtures/books.json', &block)
    context "when using the " + file_path.split('/').last + " fixture" do
      let(:hashtree) { HashTree.from_json(File.read(file_path)) }

      subject { hashtree }

      self.instance_exec &block
    end
  end
end
