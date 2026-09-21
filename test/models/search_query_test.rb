require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  test 'a query without a wildcard is a single piece' do
    assert_equal ['Chaussee 123'], SearchQuery.new('Chaussee 123').segments
  end

  test 'a wildcard splits the query into the pieces around it' do
    assert_equal %w[Chaussee 123], SearchQuery.new('Chaussee*123').segments
  end

  test 'repeated and trailing wildcards add no empty pieces' do
    assert_equal %w[Chaussee 123], SearchQuery.new('*Chaussee**123*').segments
  end

  test 'a query is indexable once one piece is trigram sized' do
    assert SearchQuery.new('Akte').indexable?
    assert SearchQuery.new('ab*Akte').indexable?
    assert_not SearchQuery.new('ab*cd').indexable?
    assert_not SearchQuery.new('').indexable?
    assert_not SearchQuery.new(nil).indexable?
  end

  test 'only pieces the index can answer end up in the match expression' do
    assert_equal %("Chaussee" AND "123"), SearchQuery.new('Chaussee*123').fts_match
    assert_equal %("Chaussee"), SearchQuery.new('Chaussee*12').fts_match
  end

  test 'a quote in the query is text rather than FTS syntax' do
    assert_equal %("Akte ""mit"" Zitat"), SearchQuery.new(%(Akte "mit" Zitat)).fts_match
  end

  test 'the glob pattern matches anywhere and spells out both cases' do
    assert_equal '*[aA][kK][tT][eE]*', SearchQuery.new('Akte').glob_pattern
  end

  test 'the glob pattern keeps the wildcard between the pieces' do
    assert_equal '*[cC][hH][aA][uU]*123*', SearchQuery.new('Chau*123').glob_pattern
  end

  test 'glob syntax in the query stands for itself' do
    assert_equal '*[?][[]*', SearchQuery.new('?[').glob_pattern
  end

  test 'a character with no single character other case stands for itself' do
    assert_equal '*[sS][tT][rR][aA]ß[eE]*', SearchQuery.new('Straße').glob_pattern
  end
end
