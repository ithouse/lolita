require 'spec_helper'

describe 'UrlHelper' do
  it 'is overriden with Lolita`s UrlHelpers' do
    helper.should_receive :url_for_without_lolita
    helper.url_for :lolita_posts
  end
end
