require 'rails_helper'

# Web 側（Sorcery セッション）の OAuth コールバックの分岐を検証する。
# 外部プロバイダとの通信を担う Sorcery のメソッド（login_from / create_from /
# login_at）だけをスタブし、コントローラ自身の分岐・redirect・flash を確認する。
RSpec.describe 'OAuths (Web セッション OAuth)', type: :request do
  # login_from / create_from は Sorcery が provider 名（文字列）を引数に取る。
  def stub_login_from(return_value)
    allow_any_instance_of(OauthsController).to receive(:login_from).and_return(return_value)
  end

  def stub_create_from(return_value)
    allow_any_instance_of(OauthsController).to receive(:create_from).and_return(return_value)
  end

  describe 'GET /oauth/callback' do
    # NOTE: コントローラは `warning:` flash を渡すが、ApplicationController の
    # add_flash_types は :success / :error / :info のみ登録しており :warning は
    # 未登録のため、この flash は実際には伝播しない（現状の実挙動）。
    # ここではログイン画面へ戻す（＝新規作成もログインもしない）ことを検証する。
    context 'ユーザーがプロバイダ側でキャンセルした場合' do
      it 'denied が付いていればログイン画面へ戻す' do
        expect_any_instance_of(OauthsController).not_to receive(:login_from)

        get '/oauth/callback', params: { provider: 'google', denied: '1' }

        expect(response).to redirect_to(login_path)
      end

      it 'error=ACCESS_DENIED でもログイン画面へ戻す' do
        expect_any_instance_of(OauthsController).not_to receive(:login_from)

        get '/oauth/callback', params: { provider: 'line', error: 'ACCESS_DENIED' }

        expect(response).to redirect_to(login_path)
      end

      it 'キャンセル時はユーザーを作らない' do
        expect do
          get '/oauth/callback', params: { provider: 'google', denied: '1' }
        end.not_to change(User, :count)
      end
    end

    context '既存ユーザーが login_from で解決できる場合' do
      let(:user) { create(:user) }

      before { stub_login_from(user) }

      it 'ユーザーページへ遷移し成功メッセージを出す' do
        get '/oauth/callback', params: { provider: 'google' }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:success]).to eq('Googleアカウントでログインしました')
      end

      it 'create_from は呼ばれない（新規ユーザーを作らない）' do
        expect_any_instance_of(OauthsController).not_to receive(:create_from)

        expect do
          get '/oauth/callback', params: { provider: 'google' }
        end.not_to change(User, :count)
      end
    end

    context 'login_from が nil で新規ユーザーを作成する場合' do
      let(:new_user) { create(:user) }

      before do
        stub_login_from(nil)
        stub_create_from(new_user)
      end

      it 'create_from の結果でログインしユーザーページへ遷移する' do
        get '/oauth/callback', params: { provider: 'line' }

        expect(response).to redirect_to(user_path(new_user))
        expect(flash[:success]).to eq('Lineアカウントでログインしました')
      end

      it 'セッションフィクセーション対策として reset_session と auto_login を行う' do
        expect_any_instance_of(OauthsController).to receive(:reset_session)
        expect_any_instance_of(OauthsController).to receive(:auto_login).with(new_user)

        get '/oauth/callback', params: { provider: 'line' }
      end
    end

    context 'ログイン処理中に例外が発生した場合' do
      before do
        allow_any_instance_of(OauthsController)
          .to receive(:login_from).and_raise(StandardError, 'boom')
      end

      it 'ログイン画面へ戻しエラーメッセージを出す' do
        get '/oauth/callback', params: { provider: 'google' }

        expect(response).to redirect_to(login_path)
        expect(flash[:error]).to eq('Googleアカウントでのログインに失敗しました')
      end
    end
  end

  describe 'POST /oauth/callback' do
    it 'GET と同じく callback を処理する' do
      user = create(:user)
      stub_login_from(user)

      post '/oauth/callback', params: { provider: 'google' }

      expect(response).to redirect_to(user_path(user))
    end
  end

  describe 'GET /oauth/:provider' do
    it 'login_at でプロバイダの認可画面へ委譲する' do
      expect_any_instance_of(OauthsController).to receive(:login_at).with('google')

      get '/oauth/google'
    end
  end
end
