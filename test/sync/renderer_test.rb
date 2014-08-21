require_relative '../test_helper'
require_relative '../models/user'

describe Sync::Renderer do
  include TestHelper

  class ApplicationController < ActionController::Base
  end

  let(:renderer){ Sync::Renderer.new }

  describe '#render' do
    it 'renders partial as string' do
      assert_equal "<h1>1<\/h1>", renderer.render(
        partial: 'sync/users/show', locals: { user: User.new }
      )
    end
  end
end
