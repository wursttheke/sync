require 'rails/all'
require_relative '../test_helper'
require_relative 'abstract_controller'
require_relative '../models/user'

describe Sync::OrderInfo do
  include TestHelper

  before do
    @unordered_scope = User.cool
    @simple_scope = User.ordered_simple
    @complex_scope = User.ordered_complex
  end

  describe '#initialize' do
    it 'extracts and stores the order info of a simple scope' do
      info = Sync::OrderInfo.new(@simple_scope)
      assert_kind_of Sync::OrderInfo, info
      assert_equal info.order_hash, {created_at: :desc}
    end

    # Multiple order statements
    it 'extracts and stores the order info of a complex scope' do
      info = Sync::OrderInfo.new(@complex_scope)
      assert_kind_of Sync::OrderInfo, info
      assert_equal info.order_hash, {created_at: :desc, age: :asc}
    end
    
    # Scope without order info
    it 'handles scopes without order info' do
      info = Sync::OrderInfo.new(@unordered_scope)
      assert_kind_of Sync::OrderInfo, info
      assert_equal info.order_hash, {}
    end

    it 'handles passed non-scope objects correctly' do
      info = Sync::OrderInfo.new(User.all)
      assert_kind_of Sync::OrderInfo, info
      assert_equal info.order_hash, {}
    end
  end

  describe '#directions_string' do
    it 'returns a string with directions' do
      info = Sync::OrderInfo.new(@complex_scope)
      assert_equal info.directions_string, '{"created_at":"desc","age":"asc"}'
    end
  end
  
  describe '#values' do
    it 'returns attributes of interest' do
      info = Sync::OrderInfo.new(@complex_scope)
      user = User.create!(age: 25)
      values = info.values(user)
      assert_equal values[:created_at], user.created_at.to_i
      assert_equal values[:age], 25
    end
  end
  
  describe '#values_string' do
    it 'returns attributes of interest in one comma-seperated string' do
      info = Sync::OrderInfo.new(@complex_scope)
      user = User.create!(age: 25)
      assert_equal info.values_string(user), "{\"created_at\":#{user.created_at.to_i},\"age\":25}"
      
    end
  end

  describe '#empty?' do
    it 'returns true if order_info contains no information' do
      info = Sync::OrderInfo.new(@unordered_scope)
      assert_equal info.empty?, true
    end

    it 'returns false if order_info contains information' do
      info = Sync::OrderInfo.new(@simple_scope)
      assert_equal info.empty?, false
    end
  end

end
