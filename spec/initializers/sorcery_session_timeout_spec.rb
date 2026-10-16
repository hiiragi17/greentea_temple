require 'rails_helper'

# Web 側（Administrate 管理画面など）の Cookie セッションに無操作タイムアウトが掛かっていることを固定する。
RSpec.describe 'Sorcery session timeout' do
  it 'enables the session_timeout submodule' do
    expect(Rails.application.config.sorcery.submodules).to include(:session_timeout)
  end

  it 'expires the session after 30 minutes of inactivity' do
    expect(Sorcery::Controller::Config.session_timeout).to eq(30.minutes)
    expect(Sorcery::Controller::Config.session_timeout_from_last_action).to be(true)
  end
end
