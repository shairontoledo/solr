# These are all of the test methods used by the various connection + adapter tests
# Currently: Direct and HTTP
# By sharing these tests, we can make sure the adapters are doing what they're suppossed to
# while staying "dry"

module ConnectionTestMethods
  
  #def teardown
  #  @solr.delete_by_query('id:[* TO *]')
  #  @solr.commit
  #  assert_equal 0, @solr.query(:q=>'*:*').docs.size
  #end
  
  
  def test_default_options
    target = {
      :select_path => '/select',
      :update_path => '/update',
      :luke_path => '/admin/luke'
    }
    assert_equal target, @solr.adapter.default_options
  end
  
  # setting adapter options in Solr.connect method should set them in the adapter
  def test_set_adapter_options
    solr = Solr.connect(:http, :select_path=>'/select2')
    assert_equal '/select2', solr.adapter.opts[:select_path]
  end
  
  # setting connection options in Solr.connect method should set them in the connection
  def test_set_connection_options
    solr = Solr.connect(:http, :default_wt=>:json)
    assert_equal :json, solr.opts[:default_wt]
  end
  
  # If :wt is NOT :ruby, the format doesn't get wrapped in a Solr::Response class
  # Raw ruby can be returned by using :wt=>'ruby', not :ruby
  def test_raw_response_formats
    ruby_response = @solr.query(:q=>'*:*', :wt=>'ruby')
    assert ruby_response[:body].is_a?(String)
    assert ruby_response[:body]=~%r('wt'=>'ruby')
    # xml?
    xml_response = @solr.query(:q=>'*:*', :wt=>'xml')
    assert xml_response[:body]=~%r(<str name="wt">xml</str>)
    # json?
    json_response = @solr.query(:q=>'*:*', :wt=>'json')
    assert json_response[:body]=~%r("wt":"json")
  end
  
  def test_query_responses
    r = @solr.query(:q=>'*:*')
    assert r.is_a?(Solr::Response::Query::Base)
    # catch exceptions for bad queries
    assert_raise Solr::RequestError do
      @solr.query(:q=>'!')
    end
  end
  
  def test_query_response_docs
    @solr.add(:id=>1, :price=>1.00, :cat=>['electronics', 'something else'])
    @solr.commit
    r = @solr.query(:q=>'*:*')
    assert r.is_a?(Solr::Response::Query::Base)
    assert_equal Array, r.docs.class
    first = r.docs.first
    assert first.respond_to?(:price)
    assert first.respond_to?(:cat)
    assert first.respond_to?(:id)
    assert first.respond_to?(:timestamp)
    
    # test the has? method
    assert first.has?('price', 1.00)
    assert first.has?('cat', 'electronics')
    assert first.has?('cat', 'something else')
    
    assert first.has?('cat', /something/)
    
    # has? only works with strings at this time
    assert_nil first.has?(:cat)
    
    assert false == first.has?('cat', /zxcv/)
  end
  
  def test_add
    assert_equal 0, @solr.query(:q=>'*:*').total
    response = @solr.add(:id=>100)
    @solr.commit
    assert_equal 1, @solr.query(:q=>'*:*').total
    assert response.is_a?(Solr::Response::Update)
  end
  
  def test_delete_by_id
    @solr.add(:id=>100)
    @solr.commit
    total = @solr.query(:q=>'*:*').total
    assert_equal 1, total
    delete_response = @solr.delete_by_id(100)
    @solr.commit
    assert delete_response.is_a?(Solr::Response::Update)
    total = @solr.query(:q=>'*:*').total
    assert_equal 0, total
  end
  
  def test_delete_by_query
    @solr.add(:id=>1, :name=>'BLAH BLAH BLAH')
    @solr.commit
    assert_equal 1, @solr.query(:q=>'*:*').total
    response = @solr.delete_by_query('name:BLAH BLAH BLAH')
    @solr.commit
    assert response.is_a?(Solr::Response::Update)
    assert_equal 0, @solr.query(:q=>'*:*').total
  end
  
  def test_index_info
    response = @solr.index_info
    assert response.is_a?(Solr::Response::IndexInfo)
    # make sure the ? methods are true/false
    assert [true, false].include?(response.current?)
    assert [true, false].include?(response.optimized?)
    assert [true, false].include?(response.has_deletions?)
  end
  
end